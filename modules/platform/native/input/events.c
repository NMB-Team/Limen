#include "platform_internal.h"
#include <limits.h>

static SDL_AtomicInt text_editing;
static vclosure* event_watch_callback = nullptr;
static limen_event* event_watch_template = nullptr;
static bool event_watch_registered = false;
static SDL_AtomicInt event_watch_enabled;
static bool queue_events;

#ifdef _MSC_VER
static __declspec(thread) unsigned int event_watch_depth;
#else
static _Thread_local unsigned int event_watch_depth;
#endif

bool limen_in_event_watch(void) {
	return event_watch_depth != 0;
}

typedef struct {
	limen_event event;
	char* text;
	SDL_MouseID mouse;
	SDL_MouseButtonFlags buttons;
	bool coalescible;
} queued_event;

enum { INITIAL_EVENT_CAPACITY = 256, EVENT_BATCH_SIZE = 64 };
enum { EVENT_READY = 1, EVENT_DEFERRED = 2 };

static SDL_SpinLock event_queue_lock;
static queued_event initial_events[INITIAL_EVENT_CAPACITY];
static queued_event* event_queue = initial_events;
static size_t event_capacity = INITIAL_EVENT_CAPACITY;
static size_t event_head;
static size_t event_count;
static bool event_queue_failed;
static bool coalesce_motion;

// only the SDL main thread consumes this batch
static queued_event event_batch[EVENT_BATCH_SIZE];
static size_t batch_next;
static size_t batch_count;

static bool translate_window_event(const SDL_Event* source, limen_event* destination) {
	if (source->type < SDL_EVENT_WINDOW_FIRST || source->type > SDL_EVENT_WINDOW_LAST) {
		return false;
	}

	destination->type = WindowState;
	destination->window = source->window.windowID;

	switch (source->type) {
		case SDL_EVENT_WINDOW_SHOWN:
			destination->state = Show;
			break;
		case SDL_EVENT_WINDOW_HIDDEN:
			destination->state = Hide;
			break;
		case SDL_EVENT_WINDOW_EXPOSED:
			destination->state = Expose;
			destination->value = source->window.data1;
			break;
		case SDL_EVENT_WINDOW_MOVED:
			destination->state = Move;
			destination->mouseX = source->window.data1;
			destination->mouseY = source->window.data2;
			break;
		case SDL_EVENT_WINDOW_RESIZED:
			destination->state = Resize;
			destination->mouseX = source->window.data1;
			destination->mouseY = source->window.data2;
			break;
		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
			destination->state = PixelResize;
			destination->mouseX = source->window.data1;
			destination->mouseY = source->window.data2;
			break;
		case SDL_EVENT_WINDOW_MINIMIZED:
			destination->state = Minimize;
			break;
		case SDL_EVENT_WINDOW_MAXIMIZED:
			destination->state = Maximize;
			break;
		case SDL_EVENT_WINDOW_RESTORED:
			destination->state = Restore;
			break;
		case SDL_EVENT_WINDOW_MOUSE_ENTER:
			destination->state = Enter;
			break;
		case SDL_EVENT_WINDOW_MOUSE_LEAVE:
			destination->state = Leave;
			break;
		case SDL_EVENT_WINDOW_FOCUS_GAINED:
			destination->state = Focus;
			break;
		case SDL_EVENT_WINDOW_FOCUS_LOST:
			destination->state = Blur;
			break;
		case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
			destination->state = Close;
			break;
		default:
			return false;
	}

	return true;
}

static bool translate_mouse_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_MOUSE_MOTION:
			destination->type = MouseMove;
			destination->window = source->motion.windowID;
			destination->mouseX = (int)source->motion.x;
			destination->mouseY = (int)source->motion.y;
			destination->mouseXRel = (int)source->motion.xrel;
			destination->mouseYRel = (int)source->motion.yrel;

			return true;
		case SDL_EVENT_MOUSE_BUTTON_DOWN:
		case SDL_EVENT_MOUSE_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_MOUSE_BUTTON_DOWN ? MouseDown : MouseUp;
			destination->window = source->button.windowID;
			destination->button = source->button.button;
			destination->mouseX = (int)source->button.x;
			destination->mouseY = (int)source->button.y;

			return true;
		case SDL_EVENT_MOUSE_WHEEL:
			destination->type = MouseWheel;
			destination->window = source->wheel.windowID;
			destination->wheelDelta = source->wheel.integer_y;

			if (source->wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
				destination->wheelDelta *= -1;

			destination->mouseX = (int)source->wheel.mouse_x;
			destination->mouseY = (int)source->wheel.mouse_y;

			return true;
		default:
			return false;
	}
}

static bool translate_keyboard_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_KEY_DOWN:
		case SDL_EVENT_KEY_UP:
			destination->type = source->type == SDL_EVENT_KEY_DOWN ? KeyDown : KeyUp;
			destination->window = source->key.windowID;
			destination->keyCode = source->key.key;
			destination->scanCode = source->key.scancode;
			destination->modifier = source->key.mod;
			destination->keyRepeat = source->type == SDL_EVENT_KEY_DOWN && source->key.repeat;

			return true;
		case SDL_EVENT_TEXT_EDITING:
			SDL_SetAtomicInt(&text_editing, 1);

			return false;
		case SDL_EVENT_TEXT_INPUT:
			{
				uint32_t key_code = 0;
				size_t length = 0;

				while (length < sizeof(key_code) && source->text.text[length] != '\0')
					++length;

				memcpy(&key_code, source->text.text, length);
				destination->type = TextInput;
				destination->window = source->text.windowID;
				destination->keyCode = (int)key_code;
				destination->value = 2;

				return true;
			}
		case SDL_EVENT_KEYMAP_CHANGED:
			destination->type = KeyMapChanged;

			return true;
		default:
			return false;
	}
}

static bool translate_touch_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_FINGER_DOWN:
			destination->type = TouchDown;
			break;
		case SDL_EVENT_FINGER_MOTION:
			destination->type = TouchMove;
			break;
		case SDL_EVENT_FINGER_UP:
			destination->type = TouchUp;
			break;
		case SDL_EVENT_FINGER_CANCELED:
			destination->type = TouchCanceled;
			break;
		default:
			return false;
	}

	destination->window = source->tfinger.windowID;
	destination->mouseX = (int)(source->tfinger.x * 10000);
	destination->mouseY = (int)(source->tfinger.y * 10000);
	destination->reference = (int)source->tfinger.fingerID;
	destination->touchId = (int64_t)source->tfinger.touchID;
	destination->fingerId = (int64_t)source->tfinger.fingerID;
	destination->touchX = source->tfinger.x;
	destination->touchY = source->tfinger.y;
	destination->touchDX = source->tfinger.dx;
	destination->touchDY = source->tfinger.dy;
	destination->pressure = source->tfinger.pressure;

	return true;
}

static bool translate_pen_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_PEN_PROXIMITY_IN:
		case SDL_EVENT_PEN_PROXIMITY_OUT:
			destination->type = source->type == SDL_EVENT_PEN_PROXIMITY_IN ? PenProximityIn : PenProximityOut;
			destination->window = source->pproximity.windowID;
			destination->penId = (int)source->pproximity.which;
			destination->penState = (int)source->pproximity.pen_state;

			return true;
		case SDL_EVENT_PEN_DOWN:
		case SDL_EVENT_PEN_UP:
			destination->type = source->type == SDL_EVENT_PEN_DOWN ? PenDown : PenUp;
			destination->window = source->ptouch.windowID;
			destination->penId = (int)source->ptouch.which;
			destination->penState = (int)source->ptouch.pen_state;
			destination->penX = source->ptouch.x;
			destination->penY = source->ptouch.y;
			destination->penEraser = source->ptouch.eraser;

			return true;
		case SDL_EVENT_PEN_MOTION:
			destination->type = PenMove;
			destination->window = source->pmotion.windowID;
			destination->penId = (int)source->pmotion.which;
			destination->penState = (int)source->pmotion.pen_state;
			destination->penX = source->pmotion.x;
			destination->penY = source->pmotion.y;

			return true;
		case SDL_EVENT_PEN_BUTTON_DOWN:
		case SDL_EVENT_PEN_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_PEN_BUTTON_DOWN ? PenButtonDown : PenButtonUp;
			destination->window = source->pbutton.windowID;
			destination->penId = (int)source->pbutton.which;
			destination->penState = (int)source->pbutton.pen_state;
			destination->penX = source->pbutton.x;
			destination->penY = source->pbutton.y;
			destination->button = source->pbutton.button;

			return true;
		case SDL_EVENT_PEN_AXIS:
			destination->type = PenAxis;
			destination->window = source->paxis.windowID;
			destination->penId = (int)source->paxis.which;
			destination->penState = (int)source->paxis.pen_state;
			destination->penX = source->paxis.x;
			destination->penY = source->paxis.y;
			destination->penAxis = source->paxis.axis;
			destination->penValue = source->paxis.value;

			return true;
		default:
			return false;
	}
}

static bool translate_gamepad_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_GAMEPAD_ADDED:
			destination->type = GControllerAdded;
			destination->reference = source->gdevice.which;

			return true;
		case SDL_EVENT_GAMEPAD_REMOVED:
			destination->type = GControllerRemoved;
			destination->reference = source->gdevice.which;

			return true;
		case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
		case SDL_EVENT_GAMEPAD_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_GAMEPAD_BUTTON_DOWN ? GControllerDown : GControllerUp;
			destination->reference = source->gbutton.which;
			destination->button = source->gbutton.button;

			return true;
		case SDL_EVENT_GAMEPAD_AXIS_MOTION:
			destination->type = GControllerAxis;
			destination->reference = source->gaxis.which;
			destination->button = source->gaxis.axis;
			destination->value = source->gaxis.value;

			return true;
		default:
			return false;
	}
}

static bool translate_joystick_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_JOYSTICK_AXIS_MOTION:
			destination->type = JoystickAxisMotion;
			destination->reference = source->jaxis.which;
			destination->button = source->jaxis.axis;
			destination->value = source->jaxis.value;

			return true;
		case SDL_EVENT_JOYSTICK_BALL_MOTION:
			destination->type = JoystickBallMotion;
			destination->reference = source->jball.which;
			destination->button = source->jball.ball;
			destination->mouseXRel = source->jball.xrel;
			destination->mouseYRel = source->jball.yrel;

			return true;
		case SDL_EVENT_JOYSTICK_HAT_MOTION:
			destination->type = JoystickHatMotion;
			destination->reference = source->jhat.which;
			destination->button = source->jhat.hat;
			destination->value = source->jhat.value;

			return true;
		case SDL_EVENT_JOYSTICK_BUTTON_DOWN:
		case SDL_EVENT_JOYSTICK_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_JOYSTICK_BUTTON_DOWN ? JoystickButtonDown : JoystickButtonUp;
			destination->reference = source->jbutton.which;
			destination->button = source->jbutton.button;

			return true;
		case SDL_EVENT_JOYSTICK_ADDED:
		case SDL_EVENT_JOYSTICK_REMOVED:
			destination->type = source->type == SDL_EVENT_JOYSTICK_ADDED ? JoystickAdded : JoystickRemoved;
			destination->reference = source->jdevice.which;

			return true;
		default:
			return false;
	}
}

static bool translate_drop_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_DROP_BEGIN:
			destination->type = DropStart;
			break;
		case SDL_EVENT_DROP_FILE:
		case SDL_EVENT_DROP_TEXT:
			destination->type = source->type == SDL_EVENT_DROP_FILE ? DropFile : DropText;
			break;
		case SDL_EVENT_DROP_COMPLETE:
			destination->type = DropEnd;
			break;
		default:
			return false;
	}

	destination->window = source->drop.windowID;

	return true;
}

static bool translate_event_fields(const SDL_Event* source, limen_event* destination) {
	destination->timestamp = (int64_t)source->common.timestamp;

	if (source->type == SDL_EVENT_QUIT) {
		destination->type = Quit;

		return true;
	}

	return translate_window_event(source, destination) || translate_mouse_event(source, destination) || translate_keyboard_event(source, destination) || translate_touch_event(source, destination) || translate_gamepad_event(source, destination) ||
	       translate_joystick_event(source, destination) || translate_drop_event(source, destination) || translate_pen_event(source, destination);
}

static const char* event_text(const SDL_Event* source) {
	switch (source->type) {
		case SDL_EVENT_TEXT_INPUT:
			return source->text.text;
		case SDL_EVENT_DROP_FILE:
		case SDL_EVENT_DROP_TEXT:
			return source->drop.data;
		default:
			return nullptr;
	}
}

static void copy_event_text(limen_event* destination, const char* text) {
	if (text == nullptr)
		return;

	if (destination->type == TextInput)
		destination->inputChar = hl_to_utf16(text);
	else
		destination->dropFile = hl_copy_bytes(text, (int)strlen(text) + 1);
}

bool limen_translate_event(const SDL_Event* source, limen_event* destination) {
	if (!translate_event_fields(source, destination))
		return false;

	copy_event_text(destination, event_text(source));
	return true;
}

static void copy_event_fields(const limen_event* source, limen_event* destination) {
	memcpy((char*)destination + sizeof(hl_type*), (const char*)source + sizeof(hl_type*), sizeof(limen_event) - sizeof(hl_type*));
}

static bool grow_event_queue(void) {
	if (event_capacity > SIZE_MAX / sizeof(*event_queue) / 2)
		return false;

	queued_event* expanded = SDL_malloc(2 * event_capacity * sizeof(*expanded));
	if (expanded == nullptr)
		return false;

	size_t first = event_capacity - event_head;
	memcpy(expanded, event_queue + event_head, first * sizeof(*expanded));
	memcpy(expanded + first, event_queue, event_head * sizeof(*expanded));

	if (event_queue != initial_events)
		SDL_free(event_queue);
	event_queue = expanded;
	event_head = 0;
	event_capacity *= 2;
	return true;
}

static void enqueue_event(const SDL_Event* source, const limen_event* event, const char* text) {
	// queue storage never holds pointers into HashLink or SDL's temporary memory
	char* owned_text = text != nullptr ? SDL_strdup(text) : nullptr;

	SDL_LockSpinlock(&event_queue_lock);
	bool coalescible = coalesce_motion && source->type == SDL_EVENT_MOUSE_MOTION;
	if (coalescible && event_count != 0) {
		size_t last = (event_head + event_count - 1) & (event_capacity - 1);
		queued_event* previous = &event_queue[last];
		if (previous->coalescible && previous->event.window == event->window &&
		    previous->mouse == source->motion.which && previous->buttons == source->motion.state) {
			int64_t dx = (int64_t)previous->event.mouseXRel + event->mouseXRel;
			int64_t dy = (int64_t)previous->event.mouseYRel + event->mouseYRel;
			if (dx >= INT_MIN && dx <= INT_MAX && dy >= INT_MIN && dy <= INT_MAX) {
				previous->event = *event;
				previous->event.mouseXRel = (int)dx;
				previous->event.mouseYRel = (int)dy;
				SDL_UnlockSpinlock(&event_queue_lock);
				return;
			}
		}
	}

	if ((text == nullptr || owned_text != nullptr) && (event_count < event_capacity || grow_event_queue())) {
		size_t tail = (event_head + event_count) & (event_capacity - 1);
		event_queue[tail] = (queued_event){
			.event = *event,
			.text = owned_text,
			.mouse = coalescible ? source->motion.which : 0,
			.buttons = coalescible ? source->motion.state : 0,
			.coalescible = coalescible,
		};
		++event_count;
		owned_text = nullptr;
	} else {
		event_queue_failed = true;
	}
	SDL_UnlockSpinlock(&event_queue_lock);

	if (owned_text != nullptr)
		SDL_free(owned_text);
}

static void refill_event_batch(void) {
	SDL_LockSpinlock(&event_queue_lock);
	bool failed = event_queue_failed;
	event_queue_failed = false;
	if (!failed) {
		batch_count = SDL_min(event_count, EVENT_BATCH_SIZE);
		batch_next = 0;

		size_t first = SDL_min(batch_count, event_capacity - event_head);
		memcpy(event_batch, event_queue + event_head, first * sizeof(*event_batch));
		memcpy(event_batch + first, event_queue, (batch_count - first) * sizeof(*event_batch));
		event_head = (event_head + batch_count) & (event_capacity - 1);
		event_count -= batch_count;
	}
	SDL_UnlockSpinlock(&event_queue_lock);

	if (failed)
		hl_error("Could not queue SDL event");
}

static void clear_event_queue(void) {
	for (size_t index = batch_next; index < batch_count; ++index)
		SDL_free(event_batch[index].text);
	for (size_t index = 0; index < event_count; ++index)
		SDL_free(event_queue[(event_head + index) & (event_capacity - 1)].text);

	if (event_queue != initial_events)
		SDL_free(event_queue);
	event_queue = initial_events;
	event_capacity = INITIAL_EVENT_CAPACITY;
	event_head = event_count = 0;
	batch_next = batch_count = 0;
	event_queue_failed = false;
	coalesce_motion = false;
}

static bool SDLCALL event_watch(void* userdata, SDL_Event* source) {
	(void)userdata;
	limen_event fields = {};
	if (!translate_event_fields(source, &fields))
		return true;

	const char* text = event_text(source);
	if (queue_events) {
		enqueue_event(source, &fields, text);
		if (!SDL_GetAtomicInt(&event_watch_enabled))
			return true;
	}

	vdynamic* stack_top;
	hl_thread_info* thread = hl_get_thread();
	bool registered_thread = thread == nullptr;
	int blocking = registered_thread ? 0 : thread->gc_blocking;

	if (registered_thread)
		hl_register_thread(&stack_top);
	for (int depth = 0; depth < blocking; ++depth)
		hl_blocking(false);

	limen_event* event = (limen_event*)hl_alloc_obj(event_watch_template->t);
	copy_event_fields(&fields, event);
	copy_event_text(event, text);

	bool is_exception = false;
	vdynamic* arguments[] = { (vdynamic*)event };
	++event_watch_depth;
	vdynamic* exception = hl_dyn_call_safe(event_watch_callback, arguments, 1, &is_exception);
	--event_watch_depth;
	if (is_exception)
		hl_print_uncaught_exception(exception);

	if (registered_thread)
		hl_unregister_thread();
	for (int depth = 0; depth < blocking; ++depth)
		hl_blocking(true);

	return true;
}

HL_PRIM void HL_NAME(set_event_watch_enabled)(bool enabled) {
	SDL_SetAtomicInt(&event_watch_enabled, enabled);
}
DEFINE_PRIM(_VOID, set_event_watch_enabled, _BOOL);

HL_PRIM void HL_NAME(set_mouse_motion_coalescing)(bool enabled) {
	SDL_LockSpinlock(&event_queue_lock);
	if (coalesce_motion != enabled) {
		if (event_count != 0)
			event_queue[(event_head + event_count - 1) & (event_capacity - 1)].coalescible = false;
		coalesce_motion = enabled;
	}
	SDL_UnlockSpinlock(&event_queue_lock);
}
DEFINE_PRIM(_VOID, set_mouse_motion_coalescing, _BOOL);

int limen_take_queued_event(limen_event* target, limen_event* deferred, bool (*should_defer)(void)) {
	if (!queue_events)
		return should_defer() ? EVENT_DEFERRED : 0;

	if (batch_next == batch_count) {
		refill_event_batch();
		if (batch_count == 0) {
			// the SDL watch already captured the events, so discard SDL's duplicate queue in one pass
			hl_blocking(true);
			SDL_PumpEvents();
			SDL_FlushEvents(SDL_EVENT_FIRST, SDL_EVENT_LAST);
			hl_blocking(false);

			if (batch_next == batch_count)
				refill_event_batch();
			if (batch_next == batch_count)
				return should_defer() ? EVENT_DEFERRED : 0;
		}
	}

	queued_event* next = &event_batch[batch_next++];
	bool defer = should_defer();
	limen_event* destination = defer ? deferred : target;
	copy_event_fields(&next->event, destination);
	if (next->text != nullptr) {
		copy_event_text(destination, next->text);
		SDL_free(next->text);
		next->text = nullptr;
	}

	return EVENT_READY | (defer ? EVENT_DEFERRED : 0);
}

HL_PRIM void HL_NAME(pump_events)() {
	SDL_Event source;

	while (SDL_PollEvent(&source)) {}
}
DEFINE_PRIM(_VOID, pump_events, _NO_ARG);

HL_PRIM void HL_NAME(copy_event)(limen_event* source, limen_event* destination) {
	copy_event_fields(source, destination);
}
DEFINE_PRIM(_VOID, copy_event, _DYN _DYN);

#ifdef LIMEN_BUILD_TESTS
static SDL_malloc_func event_test_malloc;
static SDL_calloc_func event_test_calloc;
static SDL_realloc_func event_test_realloc;
static SDL_AtomicInt event_test_allocations;

static void* SDLCALL count_event_malloc(size_t size) {
	SDL_AddAtomicInt(&event_test_allocations, 1);
	return event_test_malloc(size);
}

static void* SDLCALL count_event_calloc(size_t count, size_t size) {
	SDL_AddAtomicInt(&event_test_allocations, 1);
	return event_test_calloc(count, size);
}

static void* SDLCALL count_event_realloc(void* address, size_t size) {
	SDL_AddAtomicInt(&event_test_allocations, 1);
	return event_test_realloc(address, size);
}

HL_PRIM bool HL_NAME(test_install_sdl_allocation_counter)() {
	if (event_test_malloc != nullptr || SDL_WasInit(0) != 0 || SDL_GetNumAllocations() > 0)
		return false;

	SDL_free_func free_memory;
	SDL_GetMemoryFunctions(&event_test_malloc, &event_test_calloc, &event_test_realloc, &free_memory);
	return SDL_SetMemoryFunctions(count_event_malloc, count_event_calloc, count_event_realloc, free_memory);
}
DEFINE_PRIM(_BOOL, test_install_sdl_allocation_counter, _NO_ARG);

HL_PRIM int HL_NAME(test_sdl_allocations)() {
	return SDL_GetAtomicInt(&event_test_allocations);
}
DEFINE_PRIM(_I32, test_sdl_allocations, _NO_ARG);

HL_PRIM int HL_NAME(test_push_motion)(int window, int count, int start) {
	int pushed = 0;
	hl_blocking(true);
	for (; pushed < count; ++pushed) {
		SDL_Event source = {};
		source.type = SDL_EVENT_MOUSE_MOTION;
		source.motion.windowID = (SDL_WindowID)window;
		source.motion.x = start + pushed + 0.75f;
		source.motion.xrel = -1.75f;
		source.motion.yrel = 2.25f;
		if (!SDL_PushEvent(&source))
			break;
	}
	hl_blocking(false);
	return pushed;
}
DEFINE_PRIM(_I32, test_push_motion, _I32 _I32 _I32);

HL_PRIM bool HL_NAME(test_push_text)(int window) {
	char text[] = "caf\xc3\xa9";
	SDL_Event source = {};
	source.type = SDL_EVENT_TEXT_EDITING;
	source.edit.windowID = (SDL_WindowID)window;
	source.edit.text = text;
	if (!SDL_PushEvent(&source))
		return false;

	source = (SDL_Event){};
	source.type = SDL_EVENT_TEXT_INPUT;
	source.text.windowID = (SDL_WindowID)window;
	source.text.text = text;
	if (!SDL_PushEvent(&source))
		return false;

	source = (SDL_Event){};
	source.type = SDL_EVENT_DROP_TEXT;
	source.drop.windowID = (SDL_WindowID)window;
	source.drop.data = text;
	return SDL_PushEvent(&source);
}
DEFINE_PRIM(_BOOL, test_push_text, _I32);

HL_PRIM int HL_NAME(test_hotplug)() {
	SDL_VirtualJoystickDesc device;
	SDL_INIT_INTERFACE(&device);
	device.type = SDL_JOYSTICK_TYPE_GAMEPAD;
	device.naxes = SDL_GAMEPAD_AXIS_COUNT;
	device.nbuttons = SDL_GAMEPAD_BUTTON_COUNT;
	SDL_JoystickID id = SDL_AttachVirtualJoystick(&device);
	return id != 0 && SDL_DetachVirtualJoystick(id) ? (int)id : 0;
}
DEFINE_PRIM(_I32, test_hotplug, _NO_ARG);

HL_PRIM bool HL_NAME(test_queue_input_events)() {
	SDL_Event source = {};
	source.type = SDL_EVENT_FINGER_MOTION;
	source.tfinger.windowID = 7;
	source.tfinger.touchID = UINT64_C(0xf123456789abcdef);
	source.tfinger.fingerID = UINT64_C(0x123456789abcdef0);
	source.tfinger.x = 0.125f;
	source.tfinger.y = 0.875f;
	source.tfinger.dx = -0.0625f;
	source.tfinger.dy = 0.03125f;
	source.tfinger.pressure = 0.5f;

	if (!SDL_PushEvent(&source))
		return false;

	source = (SDL_Event){};
	source.type = SDL_EVENT_PEN_AXIS;
	source.paxis.windowID = 8;
	source.paxis.which = 0xf1234567;
	source.paxis.pen_state = SDL_PEN_INPUT_DOWN | SDL_PEN_INPUT_ERASER_TIP | SDL_PEN_INPUT_IN_PROXIMITY;
	source.paxis.x = 12.25f;
	source.paxis.y = 34.5f;
	source.paxis.axis = SDL_PEN_AXIS_XTILT;
	source.paxis.value = -45.5f;

	return SDL_PushEvent(&source);
}
DEFINE_PRIM(_BOOL, test_queue_input_events, _NO_ARG);
#endif

void limen_set_event_watch(vclosure* callback, limen_event* event, bool queued) {
	if (event_watch_registered) {
		hl_blocking(true);
		SDL_RemoveEventWatch(event_watch, nullptr);
		hl_blocking(false);
		event_watch_registered = false;
		hl_remove_root(&event_watch_callback);
		hl_remove_root(&event_watch_template);
		clear_event_queue();
	}

	queue_events = queued;
	SDL_SetAtomicInt(&text_editing, 0);
	event_watch_callback = callback;
	event_watch_template = callback != nullptr ? event : nullptr;

	if (callback != nullptr) {
		hl_add_root(&event_watch_callback);
		hl_add_root(&event_watch_template);

		if (!SDL_AddEventWatch(event_watch, nullptr)) {
			hl_remove_root(&event_watch_callback);
			hl_remove_root(&event_watch_template);
			event_watch_callback = nullptr;
			event_watch_template = nullptr;
			hl_error("Could not register SDL event watch");
		}

		event_watch_registered = true;
	}
}

HL_PRIM bool HL_NAME(is_text_input_shown)() {
	bool result = SDL_SetAtomicInt(&text_editing, 0) != 0;

	return result;
}
DEFINE_PRIM(_BOOL, is_text_input_shown, _NO_ARG);
