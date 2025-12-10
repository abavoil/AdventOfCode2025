using Test

const Point = NTuple{3,Int}

distance(points, i, j) = sum((points[i] .- points[j]) .^ 2)

function DSU_find(parent, x)  # Disjoint Set Union
    root = x
    while parent[root] != root  # find root
        root = parent[root]
    end

    while parent[x] != root  # update all x's on the way
        x, parent[x] = parent[x], root
    end

    return root
end

function DSU_union_size(parent, size, x, y)
    x = DSU_find(parent, x)
    y = DSU_find(parent, y)

    if x == y
        return
    end

    if size[x] < size[y]
        x, y = y, x
    end

    parent[y] = x
    size[x] += size[y]
end

# 9 gives 24
# 11 gives 30
function solve(lines; part1=false)
    n = length(lines)
    final_pair = ifelse(length(lines) == 20, 10, 1000)

    stop_condition = ifelse(part1,
        (size_i, pair_order) -> pair_order == final_pair,
        (size_i, pair_order) -> size_i == n)
    points = [Point(parse.(Int, split(line, ','))) for line in lines]

    dists = fill(typemax(Int), n, n)
    for i in 1:n, j in i+1:n
        dists[i, j] = sum((points[i] .- points[j]) .^ 2)
    end

    parent_ = collect(1:n)
    size_ = fill(1, n)

    step = ifelse(part1, n, 10n)
    N = div(n * (n + 1), 2)
    for start in 1:step:N
        stop = min(N, start + step - 1)
        ordering = partialsortperm(eachindex(dists), start:stop; by=i -> dists[i])
        for (pair_order, pair_ind) in enumerate(ordering)
            (i, j) = Tuple(CartesianIndices(dists)[pair_ind])
            DSU_union_size(parent_, size_, i, j)
            if stop_condition(size_[DSU_find(parent_, i)], pair_order)
                if part1
                    return prod(partialsort(unique(size_), 1:3; rev=true))
                else
                    return points[i][1] * points[j][1]
                end
            end
        end
    end
end

test_lines = readlines("data/day08_test.txt")
@test solve(test_lines; part1=true) == 40
@test solve(test_lines) == 25272

lines = readlines("data/day08.txt")
println(solve(lines; part1=true))
println(solve(lines))


#=

Optimization:
 - instead of chunking the loop over the ranked pairs, chunk over the distances:
   1. from 0 to 100
   2. from 100 to 1000
   3. ... from 100^k to 100^(k+1)
   recompute the distance matrix at each chunk, setting dist[i, j] to typemax if distance is not in chunk, with first check on x, y and z


Closest point to given point (Not for this problem, but keep this in mind) :
 - groupd coordinates into cubic chunks of size sqrt(10000) = 100.
    1. We have a point, p, in chunk c = (i, j, k)
    2. We iterate over chunks in sorted by increasing center-to-center Manhattan distance from chunk (i, j, k), starting with itself, then its 6 direct neighbors, then its 8 (edges) + 8 (corners) neighbors, etc. until we find a cluster that contains another point
    3. c' = (i', j', k') and max_manhattan_chunk_dist = sum(abs.(c - c'))
    4. The point closest to p, p_closest, is guaranteed to be in chunks with minimum distance to (i', j', k') less than max_manhattan_chunk_dist (adjust if not using manhattan for point-to-point distance) iterate over points of chunks with maximum distance > sum(max(0, abs(c - c' - 1))) and minimum distance < max_manhattan_chunk_dist

=#