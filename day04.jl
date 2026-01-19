using Test

const DIRECTIONS = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1), (0, 1),
    (1, -1), (1, 0), (1, 1),
]

function parse_lines(lines)
    n = length(lines)
    is_roll = falses(n + 2, n + 2)
    n_neigh = zeros(UInt8, n + 2, n + 2)

    @inbounds for (i, line) in enumerate(lines)
        for (j, byte) in enumerate(codeunits(line))

            byte == UInt8('@') || continue

            is_roll[i+1, j+1] = true
            for (di, dj) in DIRECTIONS
                di == dj == 0 && continue
                ii = i + di + 1
                jj = j + dj + 1
                n_neigh[ii, jj] += 0x1
            end

        end
    end
    return n, is_roll, n_neigh
end

function parse_lines_(lines)
    n = length(lines)
    is_roll = falses(n + 2, n + 2)
    n_neigh = zeros(UInt8, n + 2, n + 2)

    @inbounds for i in 2:n+1
        bytes = codeunits(lines[i-1])
        for j in 2:n+1
            bytes[j-1] == UInt8('@') || continue

            is_roll[i, j] = true
            for (di, dj) in DIRECTIONS
                di == dj == 0 && continue
                ii = i + di
                jj = j + dj
                n_neigh[ii, jj] += 0x1
            end
        end
    end
    return n, is_roll, n_neigh
end

function solve_part1(lines)
    n, is_roll, n_neigh = parse_lines(lines)

    nb_removed_rolls = 0
    @inbounds for j in 1:n, i in 1:n
        is_roll[i+1, j+1] || continue
        n_neigh[i+1, j+1] < 0x4 || continue
        nb_removed_rolls += 1
    end
    return nb_removed_rolls
end

function solve_part2(lines)
    n, is_roll, n_neigh = parse_lines(lines)

    stack = fill((0, 0), 0)

    @inbounds for j in 1:n, i in 1:n
        is_roll[i+1, j+1] || continue
        n_neigh[i+1, j+1] < 0x4 || continue
        push!(stack, (i, j))
    end


    nb_removed_rolls = 0
    @inbounds while !isempty(stack)
        i, j = pop!(stack)
        is_roll[i+1, j+1] || continue
        n_neigh[i+1, j+1] < 0x4 || continue

        is_roll[i+1, j+1] = false
        for (di, dj) in DIRECTIONS
            n_neigh[i+di+1, j+dj+1] -= 0x1
            push!(stack, (i + di, j + dj))
        end
        nb_removed_rolls += 1
    end
    return nb_removed_rolls
end

function solve(lines; part1=false)
    if part1
        return solve_part1(lines)
    else
        return solve_part2(lines)
    end
end

test_lines = readlines("data/day04_test.txt")
@test solve(test_lines; part1=true) == 13
@test solve(test_lines) == 43

lines = readlines("data/day04.txt")
println(solve(lines; part1=true))
println(solve(lines))
