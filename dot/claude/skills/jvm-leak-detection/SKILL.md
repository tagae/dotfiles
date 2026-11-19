---
name: jvm-leak-detection
description: >
  Finds memory leaks in a JVM server under sustained, production-like load with JDK Flight
  Recorder, and asserts on bytes retained per request. Use when writing, running, or diagnosing a
  leak test for a Java or Kotlin service.
---

JVM leak detection under load
=============================

The leaks that hurt in production grow with traffic. Find them by putting the app under
sustained, production-like load and measuring what it retains as the request count grows. Use the
JDK Flight Recorder (JFR) to record what the app retains, and why.

App under test
--------------

- Run it in its own process, not inside the test JVM, so that the load generator's allocations
  stay out of the recording.
- Use production JVM options: same GC, fixed heap sized like production (`-Xms` = `-Xmx`),
  `-XX:+ExitOnOutOfMemoryError`.
- Use the production runtime classpath, plus only what the production image provides or what runs
  separately there (for example DB migrations).
- Back it with real dependencies (Testcontainers). Start it on a free port and wait until its
  health endpoint is up. Generate keys and secrets at runtime. Isolate anything that discovers
  peers (cluster name, bind address).
- Keep configuration that deviates from production in one overlay file, with a reason next to
  each deviation.
- Start the recording from the command line:

  ```
  -XX:StartFlightRecording:name=load-test,settings=default,memory-leaks=gc-roots,jdk.ObjectCountAfterGC#enabled=true,filename=app.jfr,dumponexit=true
  -XX:+UnlockExperimentalVMOptions -XX:ObjectCountCutOffPercent=0.01
  ```

  `memory-leaks=gc-roots` samples old objects with their allocation stack trace and their path to
  a GC root. `jdk.ObjectCountAfterGC` records a class histogram after each full GC. The default
  cut-off is 0.5% of the heap; lowering it shows leaks while they are still small.

Traffic
-------

- Send a weighted mix of production-like scenarios. Give each one an expected status, and fail
  the test on any unexpected response. Make the schedule deterministic (seeded shuffle). Use a
  fixed number of concurrent clients that send requests as fast as the app answers.
- Draw identities (tenants, clients, users) from fixed populations, as in production, so that
  legitimate per-key state stops growing during warm-up.
- Add scenarios where the caller picks the keys (unknown client IDs, random headers, invalid
  tokens), with a fresh value on every request. Unbounded growth hides in state keyed by
  caller-controlled input: metric tags, caches, maps, interned strings.
- Give operations that are expensive by design (password hashing) a low weight. Lift limits that
  would reject most of the traffic (rate limits), but keep their code path running.

Measurement
-----------

- Warm up, then run N rounds of equal size. After each round, force a full GC with
  `jcmd <pid> GC.run`. Each of these GCs is a checkpoint. At the end, run
  `jcmd <pid> JFR.dump name=load-test filename=…`. `jcmd` can exit with 0 even when the command
  failed, so also check its output for `Exception`.
- Parse the recording with `jdk.jfr.consumer.RecordingFile`. Checkpoints are the
  `jdk.GarbageCollection` events with cause `Diagnostic Command`. Join them by `gcId` to
  `jdk.ObjectCountAfterGC`, and to the `jdk.GCHeapSummary` and `jdk.MetaspaceSummary` events where
  `when` is `After GC`. For threads, take `jdk.JavaThreadStatistics.activeCount` from the last
  event before each checkpoint. For classes, take loaded minus unloaded from the last
  `jdk.ClassLoadingStatistics` event before it.
- Assert on the least-squares slope of live heap against request count, in bytes retained per
  request. Do not assert on the difference between the first and last checkpoints. Also bound how
  much the thread and loaded-class counts grow.
- Calibrate the thresholds on a run without leaks, and leave about an order of magnitude of
  headroom (for example, 2 bytes per request without leaks and a limit of 32). Record the measured
  baseline in a comment next to the limits.

Report
------

Write a report next to the recording, so that a failure in CI can be acted on without rerunning
the test:

- Load per scenario: requests, status counts, p50 and p99 latency, and a few sample unexpected
  responses.
- Checkpoints: live heap, metaspace, threads and classes, plus the slope.
- Growing classes: the diff of the class histograms at the first and last checkpoints, sorted by
  growth in size. Mark classes missing from the first histogram, because they were below the
  cut-off and their growth is overstated.
- Leak candidates: `jdk.OldObjectSample` events allocated after warm-up, grouped by the first
  stack frame in the project's own code (where a fix would go). Show each group's reference chain
  up to its GC root: follow `referrer`, then its `field` or `array`, up to `root.description`.
- Standard views: the output of `jfr view <view> app.jfr` for `memory-leaks-by-class`,
  `memory-leaks-by-site`, `allocation-by-site`, `gc`, `hot-methods`, `exception-count`,
  `contention-by-site` and `thread-count`. Point to JDK Mission Control for interactive digging.

Wiring
------

- Put the load test in its own test suite or task, for example a Gradle `JvmTestSuite` named
  `loadTest`. Pass the app's classpath and config paths through a `CommandLineArgumentProvider`
  whose properties carry input annotations.
- The task must never be up to date or come from cache (`doNotTrackState`), and predictive test
  selection must not skip it.
- Run it in a CI stage behind a parameter. Publish the JUnit results, and archive the report,
  recording, views and app log, also when the test fails.
- When the test finds a leak, keep the test failing and report the cause: growing class,
  allocation site, path to GC root, and bytes per request.
