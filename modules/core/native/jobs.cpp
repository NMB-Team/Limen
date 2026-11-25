#include "jobs.h"

#include <algorithm>
#include <array>
#include <memory>
#include <stdexcept>

namespace limen::jobs {
namespace {

constexpr size_t external = static_cast<size_t>(-1);
constexpr size_t scratchSize = 64 * 1024;
struct Scratch {
	alignas(64) std::array<std::byte, scratchSize> bytes;
};

thread_local Context* activeContext = nullptr;
thread_local std::unique_ptr<Scratch> arena;
thread_local size_t used = 0;

}

bool Batch::is_cancelled() const noexcept {
	for (auto* batch = this; batch; batch = batch->parent) {
		if (batch->cancelled.load(std::memory_order_relaxed))
			return true;
	}
	return false;
}

bool Context::cancelled() const noexcept {
	return batch.is_cancelled();
}

std::span<std::byte> Context::scratch(size_t bytes) {
	const size_t offset = (used + 63) & ~size_t(63);
	if (bytes > scratchSize - offset)
		throw std::bad_alloc();

	if (!arena)
		arena.reset(new Scratch);
	used = offset + bytes;
	return {arena->bytes.data() + offset, bytes};
}

bool Context::run(size_t size, size_t grain, void* payload, Kernel kernel) {
	if (cancelled())
		return false;

	Batch child;
	scheduler.submit(child, size, grain, payload, kernel, {}, this);
	return scheduler.wait(child, true, this);
}

unsigned Scheduler::worker_limit() noexcept {
	const unsigned cpus = std::thread::hardware_concurrency();
	return cpus > 1 ? std::min(cpus - 1, 63u) : 0;
}

Scheduler::Scheduler(unsigned count) {
	count = std::min(count, worker_limit());
	queues.resize(std::max(1u, count));
	workers.reserve(count);
	try {
		for (size_t i = 0; i < count; ++i)
			workers.emplace_back(&Scheduler::worker, this, i);
	} catch (...) {
		shutdown();
		throw;
	}
}

Scheduler::~Scheduler() {
	shutdown();
}

void Scheduler::publish(Batch& batch) {
	auto& queue = queues[batch.queue];
	batch.older = queue.newest;
	if (queue.newest)
		queue.newest->newer = &batch;
	else
		queue.oldest = &batch;
	queue.newest = &batch;
	++readyBatches;

	const size_t chunks = 1 + (batch.size - 1) / batch.grain;
	const size_t wake = std::min(chunks, sleepers);
	for (size_t i = 0; i < wake; ++i)
		work.notify_one();
	if (workers.empty())
		work.notify_all();
	batch.ready.notify_all();
}

void Scheduler::remove(Batch& batch) {
	auto& queue = queues[batch.queue];
	if (batch.older)
		batch.older->newer = batch.newer;
	else
		queue.oldest = batch.newer;
	if (batch.newer)
		batch.newer->older = batch.older;
	else
		queue.newest = batch.older;

	batch.newer = batch.older = nullptr;
	--readyBatches;
}

void Scheduler::complete(Batch& batch) {
	batch.done = true;
	--pending;

	for (Batch* successor : batch.successors) {
		if (!successor->error && batch.error)
			successor->error = batch.error;
		if (batch.cancelled.load(std::memory_order_relaxed))
			successor->cancelled.store(true, std::memory_order_relaxed);
		if (--successor->dependencies == 0)
			publish(*successor);
	}

	batch.successors.clear();
	batch.ready.notify_all();
	if (workers.empty() || (closing && pending == 0))
		work.notify_all();
}

Scheduler::Claim Scheduler::claim(Batch* batch) {
	if (!batch)
		return {};

	const size_t begin = batch->next;
	const size_t end = batch->is_cancelled() ? batch->size
		: begin + std::min(batch->grain, batch->size - begin);
	batch->next = end;
	++batch->running;
	if (end == batch->size)
		remove(*batch);

	return {batch, begin, end};
}

Scheduler::Claim Scheduler::steal(size_t queue) {
	if (readyBatches == 0)
		return {};
	if (queues[queue].newest)
		return claim(queues[queue].newest);

	for (size_t i = 1; i < queues.size(); ++i) {
		if (auto* oldest = queues[(queue + i) % queues.size()].oldest)
			return claim(oldest);
	}
	return {};
}

void Scheduler::execute(Claim item, size_t queue) {
	Batch& batch = *item.batch;
	std::exception_ptr failure;
	if (!batch.is_cancelled()) {
		Context context(*this, batch, queue);
		auto* previous = activeContext;
		const size_t mark = used;
		activeContext = &context;
		try {
			batch.kernel(context, batch.payload, item.begin, item.end);
		} catch (...) {
			failure = std::current_exception();
		}
		used = mark;
		activeContext = previous;
	}

	std::lock_guard lock(mutex);
	if (failure) {
		if (!batch.error)
			batch.error = failure;
		batch.cancelled.store(true, std::memory_order_relaxed);
	}
	if (--batch.running == 0 && batch.next == batch.size)
		complete(batch);
}

void Scheduler::worker(size_t queue) {
	std::unique_lock lock(mutex);
	for (;;) {
		if (readyBatches == 0) {
			++sleepers;
			work.wait(lock, [&] { return readyBatches != 0 || (closing && pending == 0); });
			--sleepers;
			if (readyBatches == 0)
				break;
		}

		const auto item = steal(queue);
		lock.unlock();
		execute(item, queue);
		lock.lock();
	}
}

void Scheduler::submit(Batch& batch, size_t size, size_t grain, void* payload, Kernel kernel,
	std::span<Batch* const> dependencies) {
	if (activeContext)
		throw std::logic_error("Nested jobs must use Context::run");
	submit(batch, size, grain, payload, kernel, dependencies, nullptr);
}

void Scheduler::submit(Batch& batch, size_t size, size_t grain, void* payload, Kernel kernel,
	std::span<Batch* const> dependencies, Context* parent) {
	if (size == 0 || grain == 0 || !kernel)
		throw std::invalid_argument("Jobs require a kernel and nonempty ranges");

	std::lock_guard lock(mutex);
	if (closing && !parent)
		throw std::logic_error("Job scheduler is shut down");
	if ((batch.owner && batch.owner != this) || !batch.done)
		throw std::logic_error("Job batch is already in use");

	for (Batch* predecessor : dependencies) {
		if (!predecessor || predecessor == &batch || predecessor->owner != this)
			throw std::invalid_argument("Invalid job dependency");
	}

	size_t linked = 0;
	try {
		for (; linked < dependencies.size(); ++linked) {
			auto* predecessor = dependencies[linked];
			if (!predecessor->done)
				predecessor->successors.push_back(&batch);
		}
	} catch (...) {
		while (linked != 0) {
			auto* predecessor = dependencies[--linked];
			if (!predecessor->done)
				predecessor->successors.pop_back();
		}
		throw;
	}

	batch.owner = this;
	batch.parent = parent ? &parent->batch : nullptr;
	batch.kernel = kernel;
	batch.payload = payload;
	batch.size = size;
	batch.grain = grain;
	batch.next = batch.running = batch.dependencies = 0;
	batch.queue = parent && parent->queue != external ? parent->queue : preferred++ % queues.size();
	batch.done = false;
	batch.error = nullptr;
	batch.cancelled.store(false, std::memory_order_relaxed);
	++pending;

	for (Batch* predecessor : dependencies) {
		if (!predecessor->done) {
			++batch.dependencies;
			continue;
		}
		if (!batch.error && predecessor->error)
			batch.error = predecessor->error;
		if (predecessor->cancelled.load(std::memory_order_relaxed))
			batch.cancelled.store(true, std::memory_order_relaxed);
	}

	if (batch.dependencies == 0)
		publish(batch);
}

void Scheduler::cancel(Batch& batch) {
	std::lock_guard lock(mutex);
	if (batch.owner != this)
		throw std::invalid_argument("Unknown job batch");
	if (!batch.done)
		batch.cancelled.store(true, std::memory_order_relaxed);
}

bool Scheduler::wait(Batch& batch, bool assist) {
	if (activeContext)
		throw std::logic_error("A job cannot wait for an external batch");
	return wait(batch, assist, nullptr);
}

bool Scheduler::wait(Batch& batch, bool assist, Context* parent) {
	std::unique_lock lock(mutex);
	if (batch.owner != this)
		throw std::invalid_argument("Unknown job batch");

	while (!batch.done) {
		const size_t queue = parent ? parent->queue : external;
		const auto item = (assist && batch.dependencies == 0 && batch.next < batch.size) ? claim(&batch)
			: workers.empty() && !parent ? steal(0) : Claim{};
		if (item.batch) {
			lock.unlock();
			execute(item, queue);
			lock.lock();
		} else if (workers.empty() && !parent) {
			work.wait(lock);
		} else {
			batch.ready.wait(lock);
		}
	}

	if (batch.error)
		std::rethrow_exception(batch.error);
	return !batch.is_cancelled();
}

void Scheduler::shutdown() {
	if (activeContext)
		throw std::logic_error("A job cannot shut down a scheduler");

	std::lock_guard shutdownLock(lifecycle);
	{
		std::unique_lock lock(mutex);
		closing = true;
		work.notify_all();
		while (workers.empty() && pending != 0) {
			const auto item = steal(0);
			if (item.batch) {
				lock.unlock();
				execute(item, external);
				lock.lock();
			} else {
				work.wait(lock, [&] { return readyBatches != 0 || pending == 0; });
			}
		}
	}

	for (auto& thread : workers)
		if (thread.joinable())
			thread.join();
}

}
