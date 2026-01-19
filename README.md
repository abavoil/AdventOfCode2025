# AdventOfCode2025

Times are measured using BenchmarkTools.jl and julia 1.12 on a MacBook Air M2 with:

```{julia}
lines = readlines("data/dayXY.txt")
@btime solve(lines; part1 = true)
@btime solve(lines)
```

Total times only consider the best time of each day.

<!-- BENCHMARK_TABLE_BEGIN -->
| File | Part 1 | Part 2 |
|:---|:---|:---|
| [`day01.jl`](./day01.jl) <!-- sha:b09dd4e273db0844e2bffa118859463d8ff5faf30c3206d0f58e8977fafdd92c --> | 22.125 μs | 22.250 μs |
| [`day02.jl`](./day02.jl) <!-- sha:276a0c237b1103fc39978c043858ed0e8b60a4eb9be7a0588e14e07bba42754b --> | 11.375 μs | 13.292 μs |
| [`day03.jl`](./day03.jl) <!-- sha:f56ceb93264408aa74021040ad22f2a30cb58502d3cce58a69146509a4cf00c2 --> | 13.791 μs | 29.791 μs |
| [`day04.jl`](./day04.jl) <!-- sha:0cdac85d4a7a36dec0f56839620e92ea9cb14d2bd29354a3f50242bf5613f48e --> | 143.250 μs | 413.458 μs |
| [`day05.jl`](./day05.jl) <!-- sha:0e544f7d3103e781809d356634ef7d4429d2fd1c968b7d1c2bdedeebfe1c7335 --> | 20.583 μs | 12.250 μs |
| [`day06.jl`](./day06.jl) <!-- sha:6bf2a129350462dc0ad328add8663eb92d033720baf0e239b0b4f7bc03b4ca29 --> | 54.334 μs | 50.916 μs |
| [`day07.jl`](./day07.jl) <!-- sha:27c888d1d5e151e45a8bab62ebaa77367c0fe307544f77b675f25730223e15f8 --> | 12.500 μs | 13.125 μs |
| [`day08.jl`](./day08.jl) <!-- sha:f4eca3c20a30f2e56ed91afda2b5b3d505b43390de93f4c518c5262608dd20f3 --> | 4.224 ms | 4.557 ms |
| [`day09.jl`](./day09.jl) <!-- sha:60003398aa8d4785f8025310abd560c9e528df6771e6b66f0b92e04eaf6e0da5 --> | 6.717 μs | 2.898 μs |
| [`day10.jl`](./day10.jl) <!-- sha:cba933429b856b64382169bf3e7e3aaf1b0c78a5145fab97be2e1056e60fd556 --> | 155.125 μs | 27.112 ms |
| [`day11.jl`](./day11.jl) <!-- sha:aac63750d129eadf0ce454267f9983c5264bb942ea82f5838171e44cfdf0364a --> | 19.792 μs | 39.000 μs |
| [`day12.jl`](./day12.jl) <!-- sha:babb0bbfb84857eb74204b516791020321aeb81e0a35cb9601a3a9b095037392 --> | 8.097 μs | 18.119 ns |
| **Total (Best of each day)** | **4.692 ms** | **32.266 ms** |
<!-- BENCHMARK_TABLE_END -->

<!-- TODO: for each part, compute sum(min(day) for day in days) -->