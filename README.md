# AdventOfCode2025

Times are measured using BenchmarkTools.jl and julia 1.12 on a MacBook Air M2 with:

```{julia}
lines = readlines("data/dayXY.txt")
@btime solve(lines; part1 = true)
@btime solve(lines)
```

<!-- BENCHMARK_TABLE_BEGIN -->
| File | Part 1 | Part 2 |
|:---|:---|:---|
| [`day01.jl`](./day01.jl) <!-- sha:b05b21051e5957b1a1e0e4ed466dd9acddd5c718b350216e9242c2d7a96012dc --> | 122.042 μs | 123.458 μs |
| [`day02.jl`](./day02.jl) <!-- sha:7783516fa6110f26620aa9dc9ecb42e2bd7df4b7b229eb41b5c6837b14da98c5 --> | 18.000 μs | 20.000 μs |
| [`day03.jl`](./day03.jl) <!-- sha:5f3573570cbeccd559a6dc3298cbe1e0cd231dbfcf92fcf175d09afb835dd8c8 --> | 101.334 μs | 116.917 μs |
| [`day03_bytes.jl`](./day03_bytes.jl) <!-- sha:f56ceb93264408aa74021040ad22f2a30cb58502d3cce58a69146509a4cf00c2 --> | 14.250 μs | 30.750 μs |
| [`day03_recursion.jl`](./day03_recursion.jl) <!-- sha:648e904f9e78e0260f9c3f9c20284d2b9e887b50110ecf5a9bb3b0b190010626 --> | 113.209 μs | 169.042 μs |
| [`day04.jl`](./day04.jl) <!-- sha:952fa97e5cb6cd7deee988a5775e6f7684238d0cd2bc41d61816ba26032f3782 --> | 214.875 μs | 3.813 ms |
| [`day04_DFS.jl`](./day04_DFS.jl) <!-- sha:2189ee28c1870f3c6e02722b32fa0949a0cd99e16f3af1586cdbc316a0cabef4 --> | 214.209 μs | 692.625 μs |
| [`day05.jl`](./day05.jl) <!-- sha:d9d95436d0172d5a45d31b2ac91dfe6683b3941c3e57fdf139e1f57763590c9f --> | 70.375 μs | 59.667 μs |
| [`day06.jl`](./day06.jl) <!-- sha:d432e050397a0d79c44e72e29419ed27aa5b387dfee0494b0f49b04f0ad7a1b0 --> | 54.916 μs | 50.208 μs |
| [`day07.jl`](./day07.jl) <!-- sha:27c888d1d5e151e45a8bab62ebaa77367c0fe307544f77b675f25730223e15f8 --> | 12.500 μs | 13.125 μs |
| [`day08.jl`](./day08.jl) <!-- sha:f9aed5a4af4c491dd2a45fe9385d265e889512487a2343b709d9213024556cf6 --> | 5.221 ms | 5.384 ms |
| [`day09.jl`](./day09.jl) <!-- sha:da5b56d44585357b6b220592c8c81ca7e80186ba223eeb88c766dce0c2e6bdf6 --> | 303.250 μs | 45.785 ms |
| **Total** | **6.460 ms** | **56.258 ms** |
<!-- BENCHMARK_TABLE_END -->

<!-- TODO: for each part, compute sum(min(day) for day in days) -->