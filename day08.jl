const Point = NTuple{3,Int}

distance(points, i, j) = sum((points[i] .- points[j]) .^ 2)

function minheap_find(parent, x)
    root = x
    while parent[root] != root  # find root
        root = parent[root]
    end

    while parent[x] != root  # update all x's on the way
        x, parent[x] = parent[x], root
    end

    return root
end

function minheap_union(parent, size, rank, x, y)
    x = minheap_find(parent, x)
    y = minheap_find(parent, y)

    if x == y
        return
    end

    if rank[x] < rank[y]
        x, y = y, x
    end

    parent[y] = x
    size[x] += size[y]
    if rank[x] == rank[y]
        rank[x] += 1
    end
end

# 9 gives 24
# 11 gives 30
function solve(lines; part1=false)
    n = length(lines)
    max_pair = ifelse(part1, ifelse(length(lines) == 20, 10, 1000), n)

    stop_condition = ifelse(part1,
        (size_i, pair_order) -> pair_order == max_pair,
        (size_i, pair_order) -> size_i == n)
    points = [Point(parse.(Int, split(line, ','))) for line in lines]

    dists = fill(typemax(Int), n, n)
    for i in 1:n, j in i+1:n
        dists[i, j] = sum((points[i] .- points[j]) .^ 2)
    end


    parent_ = collect(1:n)
    size_ = fill(1, n)
    rank = fill(0, n)

    step = 10max_pair
    N = div(n * (n + 1), 2)
    for start in 1:step:N
        stop = min(N, start + step - 1)
        ordering = partialsortperm(eachindex(dists), start:stop; by=i -> dists[i])
        for (pair_order, pair_ind) in enumerate(ordering)
            (i, j) = Tuple(CartesianIndices(dists)[pair_ind])
            minheap_union(parent_, size_, rank, i, j)
            if stop_condition(size_[minheap_find(parent_, i)], pair_order)
                if part1
                    return prod(partialsort(unique(size_), 1:3; rev=true))
                else
                    @show dists[i, j]
                    return points[i][1] * points[j][1]
                end
            end
        end
    end
end

lines = readlines("data/day08.txt")
println(solve(lines; part1=false))
@btime solve($lines; part1=true)

#=

Optimization:
 - instead of chunking the loop over the ranked pairs, chunk over the distances:
   1. from 0 to 100
   2. from 100 to 1000
   3. ... from 100^k to 100^(k+1)
   recompute the distance matrix at each chunk, setting dist[i, j] to typemax if distance is not in chunk, with first check on x, y and z

=#