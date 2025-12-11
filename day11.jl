using Test

#=

Optimization:
1. a->b = number of paths from a to b
   answer2 = (you->dac * dac->fft * fft->end) + (you->fft * fft->dac * dac->end) (is one equal to zero?)

2. We can generate parent_of[] and have a vector n[index] which counts the path to out
   going up the tree, we add 1 to n[index] everytime an node is visited
   the same ??

3.
 - From start: mark all nodes as can_reach
 - from out: mark all nodes as can_exit


 - use sparse arrays
 - put big dimension last in array
 - separate code for p1 is not significantly faster, but it does allocate less memory
 - fill is as fast as undef initializing while providing easier debugging
=#

const T = Int16


to_int(b::UInt8) = b - UInt8('a')
to_int(bytes) = to_int(bytes[1]) * 676 + to_int(bytes[2]) * 26 + to_int(bytes[3]) + 1
to_int(s::AbstractString) = to_int(codeunits(s))

function parse_lines(lines)
    # TODO: try index2neighbors a length(lines) by 25 (max number of neibors form intut) matrix
    # in combination with an array storing the number of neibors of each node
    # 1 big allocation instead of multiple small ones
    index_of = fill(T(-1), 26^3)  # int(label) -> index
    children_of = fill(T[-1], length(lines))  # index -> children
    for (i, line) in enumerate(lines)
        node = to_int(@view codeunits(line)[1:3])
        index_of[node] = i
        children_of[i] = Vector{T}(undef, (length(line) - 4) ÷ 4)
        for j in eachindex(children_of[i])
            children_of[i][j] = to_int(@view codeunits(line)[4j+2:4j+4])
        end
    end
    index_of[to_int("out")] = length(index_of) + 1
    return index_of, children_of
end

function count_path_to_out!(is_cached, cache, index, dac, fft, index_of, children_of, dac_index, fft_index, out_index)
    if index == out_index
        return fft && dac
    end

    dac |= index == dac_index
    fft |= index == fft_index

    if is_cached[dac+1, fft+1, index]
        return cache[dac+1, fft+1, index]
    end

    n = 0
    for child in children_of[index]
        n += count_path_to_out!(is_cached, cache, index_of[child], dac, fft, index_of, children_of, dac_index, fft_index, out_index)
    end

    is_cached[dac+1, fft+1, index] = true
    cache[dac+1, fft+1, index] = n

    return n
end

function solve(lines; part1=false)
    index_of, children_of = parse_lines(lines)

    dac_index = index_of[to_int("dac")]
    fft_index = index_of[to_int("fft")]
    out_index = index_of[to_int("out")]

    if part1
        start_index = index_of[to_int("you")]
        dac = fft = true
    else
        start_index = index_of[to_int("svr")]
        dac = fft = false
    end

    # dac+1 (2), fft+1 (2), index (length(index_of)) -> Tuple(Bool, T}(is_visited, count)
    is_cached = falses(2, 2, length(index_of))
    cache = Array{Int,3}(undef, 2, 2, length(index_of))

    return count_path_to_out!(is_cached, cache, start_index, dac, fft, index_of, children_of, dac_index, fft_index, out_index)
end

test_lines1 = readlines("data/day11_test1.txt")
test_lines2 = readlines("data/day11_test2.txt")
@test solve(test_lines1; part1=true) == 5
@test solve(test_lines2) == 2

lines = readlines("data/day11.txt")
println(solve(lines; part1=true))
println(solve(lines))
