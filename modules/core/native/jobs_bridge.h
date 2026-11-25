#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void limen_jobs_shutdown(void);

#ifdef __cplusplus
}

#include "jobs.h"

bool limen_can_run_jobs();
bool limen_run_jobs(unsigned workers, size_t count, size_t minGrain, void* payload, limen::jobs::Kernel kernel,
	void* source, void* destination);
#endif
