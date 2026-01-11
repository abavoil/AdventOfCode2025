const DIRECTIONS = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1), (0, 1),
    (1, -1), (1, 0), (1, 1),
]

function parse(lines)
    n = length(lines)
    m = length(lines[1])
    is_roll = falses(n + 2, m + 2)
    n_neigh = zeros(UInt8, n + 2, m + 2)

    for (i, line) in enumerate(lines)
        for (j, byte) in enumerate(codeunits(line))

            byte == UInt8('@') || continue

            is_roll[i+1, j+1] = true
            for (di, dj) in DIRECTIONS
                di == dj == 0 && continue
                n_neigh[i+di+1, j+dj+1] += 1
            end

        end
    end
    return n, m, is_roll, n_neigh
end

function part1(lines)
    n, m, is_roll, n_neigh = parse(lines)

    nb_removed_rolls = 0
    for i in 1:n, j in 1:m
        is_roll[i+1, j+1] || continue
        n_neigh[i+1, j+1] < 4 || continue
        nb_removed_rolls += 1
    end
    return nb_removed_rolls
end

function part2(lines)
    n, m, is_roll, n_neigh = parse(lines)

    stack = fill((0, 0), 0)

    for i in 1:n, j in 1:m
        is_roll[i+1, j+1] || continue
        n_neigh[i+1, j+1] < 4 || continue
        push!(stack, (i, j))
    end


    nb_removed_rolls = 0
    while !isempty(stack)
        i, j = pop!(stack)
        is_roll[i+1, j+1] || continue
        n_neigh[i+1, j+1] < 4 || continue

        is_roll[i+1, j+1] = false
        for (di, dj) in DIRECTIONS
            n_neigh[i+di+1, j+dj+1] -= 1
            push!(stack, (i + di, j + dj))
        end
        nb_removed_rolls += 1
    end
    return nb_removed_rolls
end

lines = readlines("data/day04.txt")
@btime part1(lines)
@btime part2(lines)