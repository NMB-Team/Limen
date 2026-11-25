#include "jobs.h"

#include <array>
#include <atomic>
#include <barrier>
#include <cstdlib>
#include <iostream>
#include <latch>
#include <stdexcept>
#include <string_view>

using namespace limen::jobs;

static void require(bool condition) {
	if (!condition)
		throw std::runtime_error("Job scheduler test assertion failed");
}

static void count(Context&, void* data, size_t begin, size_t end) {
	static_cast<std::atomic_size_t*>(data)->fetch_add(end - begin, std::memory_order_relaxed);
}

static void graph(unsigned workers) {
	Scheduler scheduler(workers);
	Batch a, b, join;
	std::atomic_size_t total = 0;
	scheduler.submit(a, 16384, 256, &total, count);
	scheduler.submit(b, 3072, 192, &total, count);
	const std::array dependencies{&a, &b};
	scheduler.submit(join, 1, 1, &total, [](Context&, void* data, size_t, size_t) {
		require(static_cast<std::atomic_size_t*>(data)->load() == 19456);
	}, dependencies);
	require(scheduler.wait(join));
	require(scheduler.wait(a) && scheduler.wait(b));

	scheduler.submit(a, 1, 1, &total, [](Context& context, void* data, size_t, size_t) {
		auto scratch = context.scratch(64);
		scratch[0] = std::byte{83};
		require(context.run(128, 8, data, [](Context& inner, void* data, size_t begin, size_t end) {
			inner.scratch(128)[0] = std::byte{19};
			require(inner.run(end - begin, 2, data, count));
		}));
		require(scratch[0] == std::byte{83});
	});
	require(scheduler.wait(a, workers == 0));
	require(total.load() == 19584);
}

static void failures(unsigned workers) {
	Scheduler scheduler(workers);
	Batch first, next, blocked;
	std::atomic_size_t unexpected = 0;
	scheduler.submit(first, 1, 1, nullptr, [](Context& context, void*, size_t, size_t) {
		context.run(1, 1, nullptr, [](Context&, void*, size_t, size_t) {
			throw std::runtime_error("nested failure");
		});
	});
	const std::array dependencies{&first};
	scheduler.submit(next, 8, 1, &unexpected, count, dependencies);
	try {
		scheduler.wait(next);
		require(false);
	} catch (const std::runtime_error& error) {
		require(std::string_view(error.what()) == "nested failure");
	}
	require(unexpected == 0);

	std::latch entered(1), release(1);
	struct Gate {
		std::latch& entered;
		std::latch& release;
	} gate{entered, release};
	scheduler.submit(first, 1, 1, &gate, [](Context& context, void* data, size_t, size_t) {
		auto& gate = *static_cast<Gate*>(data);
		gate.entered.count_down();
		gate.release.wait();
		require(context.cancelled());
	});
	std::jthread waiter([&] { require(!scheduler.wait(first)); });
	entered.wait();
	scheduler.submit(blocked, 1024, 16, &unexpected, count, dependencies);
	scheduler.cancel(first);
	release.count_down();
	waiter.join();
	require(!scheduler.wait(blocked));
	require(unexpected == 0);

	struct InvalidWait {
		Scheduler& scheduler;
		Batch& batch;
	} invalid{scheduler, first};
	scheduler.submit(first, 1, 1, &invalid, [](Context&, void* data, size_t, size_t) {
		auto& invalid = *static_cast<InvalidWait*>(data);
		invalid.scheduler.wait(invalid.batch);
	});
	bool rejected = false;
	try {
		scheduler.wait(first);
	} catch (const std::logic_error&) {
		rejected = true;
	}
	require(rejected);
}

static void concurrent(unsigned workers) {
	Scheduler scheduler(workers);
	std::array<std::atomic_size_t, 4> totals{};
	std::barrier start(4);
	std::vector<std::jthread> producers;
	for (auto& total : totals) {
		producers.emplace_back([&] {
			Batch a, b;
			const std::array dependency{&a};
			start.arrive_and_wait();
			for (int i = 0; i < 100; ++i) {
				scheduler.submit(a, 1024, 16, &total, count);
				scheduler.submit(b, 256, 16, &total, count, dependency);
				require(scheduler.wait(b));
			}
		});
	}
	producers.clear();
	for (const auto& total : totals)
		require(total.load() == 128000);

	Batch a, b;
	scheduler.submit(a, 4096, 17, &totals[0], count);
	const std::array dependency{&a};
	scheduler.submit(b, 127, 3, &totals[0], count, dependency);
	std::jthread other([&] { scheduler.shutdown(); });
	scheduler.shutdown();
	other.join();
	require(scheduler.wait(b));
	require(totals[0].load() == 132223);

	bool rejected = false;
	try {
		scheduler.submit(a, 1, 1, &totals[0], count);
	} catch (const std::logic_error&) {
		rejected = true;
	}
	require(rejected);
}

int main() {
	try {
		for (unsigned workers : {0u, 1u, 2u, 4u}) {
			if (workers > Scheduler::worker_limit())
				break;
			graph(workers);
			failures(workers);
			concurrent(workers);
			std::cout << "Job checks passed with " << workers << " workers\n";
		}
	} catch (const std::exception& error) {
		std::cerr << error.what() << '\n';
		return EXIT_FAILURE;
	}
}
