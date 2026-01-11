using Test

function parse_int(bytes)
    n = 0
    for byte in bytes
        n = 10n + byte - 0x30
    end
    return n
end

function parse_lines_slower(lines)
    sep = findfirst(isempty, lines)
    intervals = map(x -> parse.(Int, split(x, '-')), lines[1:sep-1])
    IDs = parse.(Int, lines[sep+1:end])
    return intervals, IDs
end

function parse_lines(lines)
    sep = findfirst(isempty, lines)

    intervals = fill((-1, -1), sep - 1)
    for (i, line) in enumerate(@view lines[1:sep-1])
        bytes = codeunits(line)
        int_sep = findfirst(==(UInt8('-')), bytes)
        a = parse_int(codeunits(@view line[1:int_sep-1]))
        b = parse_int(codeunits(@view line[int_sep+1:end]))
        intervals[i] = (a, b)
    end

    IDs = fill(-1, length(lines) - sep)
    for (i, line) in enumerate(@view lines[sep+1:end])
        IDs[i] = parse_int(codeunits(line))
    end
    return intervals, IDs
end

# Gemini optimized parsing, for reference
function parse_lines_fast(lines::Vector{String})
    # 1. Find the separator index (avoiding string comparison overhead)
    sep_idx = 0
    @inbounds for i in eachindex(lines)
        if isempty(lines[i])
            sep_idx = i
            break
        end
    end

    # 2. Pre-allocate results
    # We know exactly how many elements we need
    n_intervals = sep_idx - 1
    intervals = Vector{Vector{Int}}(undef, n_intervals)

    n_ids = length(lines) - sep_idx
    ids = Vector{Int}(undef, n_ids)

    # 3. Parse Intervals: "Min-Max"
    @inbounds for i in 1:n_intervals
        str = lines[i]
        bytes = codeunits(str)
        len = length(bytes)

        val = 0
        idx = 1

        # Parse first number until '-' (ASCII 45)
        while idx <= len
            b = bytes[idx]
            if b == 0x2d # '-'
                idx += 1
                break
            end
            val = 10 * val + (b - 0x30) # 0x30 is '0'
            idx += 1
        end
        num1 = val

        # Parse second number until end
        val = 0
        while idx <= len
            val = 10 * val + (bytes[idx] - 0x30)
            idx += 1
        end

        intervals[i] = [num1, val]
    end

    # 4. Parse IDs
    @inbounds for i in 1:n_ids
        str = lines[sep_idx+i]
        bytes = codeunits(str)
        val = 0
        for b in bytes
            val = 10 * val + (b - 0x30)
        end
        ids[i] = val
    end

    return intervals, ids
end


function solve_part1(intervals, IDs)
    #=
    sort IDs
    (sort intervals to better initialize bisection on ID1)

    for each interval (A, B)
        bisect ID1 the first ID >= A
        bisect ID2 the last ID <= B
        count all IDs between ID1 and ID2 that are not marked, mark them
    =#

    sort!(IDs)
    # sort!(intervals)
    # minID_ind_global = 1

    is_valid = falses(size(IDs))
    count = 0
    for (a, b) in intervals
        # # It is not faster to warm-start binary search
        # minID_ind = searchsortedfirst(IDs[minID_ind_global:end], a) + minID_ind_global - 1
        # minID_ind_global = minID_ind
        # maxID_ind = searchsortedlast(IDs[minID_ind:end], b) + minID_ind - 1
        minID_ind = searchsortedfirst(IDs, a)
        maxID_ind = searchsortedlast(IDs, b)
        for ID_ind in minID_ind:maxID_ind
            if !is_valid[ID_ind]
                is_valid[ID_ind] = true
                count += 1
            end
        end
    end
    return count
end

function solve_part1_naive(intervals, IDs)
    count = 0
    for ID in IDs
        for (a, b) in intervals
            if a <= ID <= b
                count += 1
                break
            end
        end
    end
    return count
end

function solve_part2(intervals)
    intervals = sort!(intervals)

    current_highest = 0
    count = 0
    for (a, b) in intervals
        if b > current_highest
            count += b - max(a, current_highest + 1) + 1
            current_highest = b
        end
    end
    count
end

function solve(lines; part1=false)
    intervals, IDs = parse_lines(lines)

    if part1
        return solve_part1(intervals, IDs)
    else
        return solve_part2(intervals)
    end
end

@test solve(readlines("data/day05_test.txt"); part1=true) == 3
@test solve(readlines("data/day05_test.txt")) == 14

println(solve(readlines("data/day05.txt"); part1=true))
println(solve(readlines("data/day05.txt")))


#=
- It is not faster to warm-start binary search
- 3 liner parse was already very good
- SubString is NOT faster but saves memory allocations
- Do not specify limit in split, it is just as fast without
- do not save lines[i] to line, just as fast to call it 3 times
=#