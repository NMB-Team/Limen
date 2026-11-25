#include "jobs_bridge.h"
#include "limen_native.h"

#include <SDL3/SDL.h>
#include <algorithm>
#include <array>
#include <system_error>

namespace {

struct MainJobs {
	explicit MainJobs(unsigned workers) : scheduler(workers) {}

	limen::jobs::Scheduler scheduler;
	limen::jobs::Batch batch;
};

// platform quit joins the workers outside the DLL loader lock
MainJobs* mainJobs = nullptr;
bool unavailable = false;

}

void limen_jobs_shutdown() {
	if (mainJobs) {
		hl_blocking(true);
		delete mainJobs;
		mainJobs = nullptr;
		hl_blocking(false);
	}
	unavailable = false;
}

HL_PRIM void HL_NAME(stop_native_jobs)() {
	if (SDL_IsMainThread())
		limen_jobs_shutdown();
}
DEFINE_PRIM(_VOID, stop_native_jobs, _NO_ARG);

bool limen_can_run_jobs() {
	return SDL_IsMainThread() && SDL_WasInit(SDL_INIT_VIDEO);
}

bool limen_run_jobs(unsigned workers, size_t count, size_t minGrain, void* payload, limen::jobs::Kernel kernel,
	void* source, void* destination) {
	if (!limen_can_run_jobs() || unavailable)
		return false;

	if (!mainJobs) {
		if (limen::jobs::Scheduler::worker_limit() == 0)
			return false;

		try {
			mainJobs = new MainJobs(workers);
		} catch (const std::system_error&) {
			unavailable = true;
			return false;
		} catch (const std::bad_alloc&) {
			return false;
		}
	}

	// workers borrow only nonmoving, pointer-free HashLink byte storage
	struct Blocking {
		std::array<void*, 2> roots;

		Blocking(void* source, void* destination) : roots{source, destination} {
			for (auto& root : roots)
				if (root)
					hl_add_root(&root);
			hl_blocking(true);
		}

		~Blocking() {
			hl_blocking(false);
			for (auto& root : roots)
				if (root)
					hl_remove_root(&root);
		}
	} blocking(source, destination);

	const size_t grain = (std::max)(minGrain, count / ((mainJobs->scheduler.worker_count() + 1) * 2));
	mainJobs->scheduler.submit(mainJobs->batch, count, grain, payload, kernel);
	return mainJobs->scheduler.wait(mainJobs->batch);
}
