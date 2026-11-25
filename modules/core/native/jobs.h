#pragma once

#include <atomic>
#include <condition_variable>
#include <cstddef>
#include <exception>
#include <mutex>
#include <span>
#include <thread>
#include <vector>

namespace limen::jobs {

class Scheduler;
class Context;
using Kernel = void (*)(Context&, void*, size_t begin, size_t end);

// a batch and its payload must stay alive through wait or shutdown
class Batch {
	friend class Scheduler;
	friend class Context;

	Scheduler* owner = nullptr;
	Batch* parent = nullptr;
	Kernel kernel = nullptr;
	void* payload = nullptr;
	size_t size = 0, grain = 0, next = 0, running = 0, dependencies = 0;
	size_t queue = 0;
	Batch* newer = nullptr;
	Batch* older = nullptr;
	bool done = true;
	std::atomic_bool cancelled = false;
	std::exception_ptr error;
	std::vector<Batch*> successors;
	std::condition_variable ready;

	bool is_cancelled() const noexcept;

public:
	Batch() = default;
	Batch(const Batch&) = delete;
	Batch& operator=(const Batch&) = delete;
};

class Context {
	friend class Scheduler;
	Scheduler& scheduler;
	Batch& batch;
	size_t queue;

	Context(Scheduler& scheduler, Batch& batch, size_t queue)
		: scheduler(scheduler), batch(batch), queue(queue) {}

public:
	bool cancelled() const noexcept;
	std::span<std::byte> scratch(size_t bytes);
	bool run(size_t size, size_t grain, void* payload, Kernel kernel);
};

// kernels own disjoint output ranges and must not access the HashLink or SDL event APIs
class Scheduler {
	friend class Context;

	struct Queue {
		Batch* newest = nullptr;
		Batch* oldest = nullptr;
	};

	struct Claim {
		Batch* batch = nullptr;
		size_t begin = 0, end = 0;
	};

	std::mutex lifecycle;
	std::mutex mutex;
	std::condition_variable work;
	std::vector<Queue> queues;
	std::vector<std::thread> workers;
	size_t preferred = 0;
	size_t pending = 0;
	size_t readyBatches = 0;
	size_t sleepers = 0;
	bool closing = false;

	void publish(Batch& batch);
	void remove(Batch& batch);
	void complete(Batch& batch);
	Claim claim(Batch* batch);
	Claim steal(size_t queue);
	void execute(Claim item, size_t queue);
	void worker(size_t queue);
	void submit(Batch& batch, size_t size, size_t grain, void* payload, Kernel kernel,
		std::span<Batch* const> dependencies, Context* parent);
	bool wait(Batch& batch, bool assist, Context* parent);

public:
	explicit Scheduler(unsigned workers);
	~Scheduler();

	static unsigned worker_limit() noexcept;
	size_t worker_count() const noexcept { return workers.size(); }

	// dependencies refer to submitted batches from this scheduler, including completed batches
	void submit(Batch& batch, size_t size, size_t grain, void* payload, Kernel kernel,
		std::span<Batch* const> dependencies = {});
	void cancel(Batch& batch);

	// joins all ranges, returning false on cancellation or rethrowing the first failure
	bool wait(Batch& batch, bool assist = true);
	void shutdown();
};

}
