using Test

const DIRECTIONS = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1), (0, 1),
    (1, -1), (1, 0), (1, 1),
]

function is_roll(is_roll_, i, j; n=size(is_roll_, 1), m=size(is_roll_, 2))
    (i < 1 || i > n) && return false
    (j < 1 || j > m) && return false
    return is_roll_[i, j]
end

function solve(lines; part1=false)
    is_roll_ = permutedims(reduce(hcat, collect.(lines))) .== '@'
    n, m = size(is_roll_)

    stack = Tuple{Int,Int}[]
    sizehint!(stack, n * m)
    in_stack = falses(n, m)  # Check if a roll is in the stack in O(1)

    for i in 1:n, j in 1:m
        if is_roll(is_roll_, i, j; n, m)
            rolls_around = 0
            for di in [-1, 0, 1], dj in [-1, 0, 1]
                di == 0 && dj == 0 && continue

                if is_roll(is_roll_, i + di, j + dj; n, m)
                    rolls_around += 1
                end
            end

            if rolls_around < 4
                push!(stack, (i, j))
                in_stack[i, j] = true
            end
        end
    end

    if part1
        return length(stack)
    end

    forklifted_count = 0
    while !isempty(stack)
        i, j = pop!(stack)
        in_stack[i, j] = false

        if !is_roll(is_roll_, i, j; n, m)
            println("($i, $j) is not a roll")
            continue
        end


        rolls_around = 0
        for di in [-1, 0, 1], dj in [-1, 0, 1]
            di == 0 && dj == 0 && continue

            if is_roll(is_roll_, i + di, j + dj; n, m)
                rolls_around += 1
            end
        end

        if rolls_around < 4
            forklifted_count += 1
            is_roll_[i, j] = false

            for di in [-1, 0, 1], dj in [-1, 0, 1]
                di == 0 && dj == 0 && continue

                ni, nj = i + di, j + dj
                if is_roll(is_roll_, ni, nj; n, m) && !in_stack[ni, nj]
                    push!(stack, (ni, nj))
                    in_stack[ni, nj] = true
                end
            end
        end
    end

    return forklifted_count
end

# Minimal gains by having an array counting the number of neighboring rolls
function solve_(lines; part1=false)
    is_roll_ = permutedims(reduce(hcat, collect.(lines))) .== '@'
    n, m = size(is_roll_)

    stack = Tuple{Int,Int}[]
    sizehint!(stack, n * m)
    in_stack = falses(n, m)  # Check if a roll is in the stack in O(1)
    rolls_around = zeros(Int8, n, m)

    for i in 1:n, j in 1:m
        if is_roll(is_roll_, i, j; n, m)
            for di in [-1, 0, 1], dj in [-1, 0, 1]
                di == 0 && dj == 0 && continue

                ni, nj = i + di, j + dj
                (ni < 1 || ni > n) && continue
                (nj < 1 || nj > m) && continue

                rolls_around[ni, nj] += 1
            end
        end
    end

    for i in 1:n, j in 1:m
        if is_roll(is_roll_, i, j; n, m) && rolls_around[i, j] < 4
            push!(stack, (i, j))
            in_stack[i, j] = true
        end
    end

    if part1
        return length(stack)
    end

    forklifted_count = 0
    while !isempty(stack)
        i, j = pop!(stack)
        in_stack[i, j] = false

        if !is_roll(is_roll_, i, j; n, m)
            println("($i, $j) is not a roll")
            continue
        end

        if rolls_around[i, j] < 4
            forklifted_count += 1
            is_roll_[i, j] = false

            for di in [-1, 0, 1], dj in [-1, 0, 1]
                di == 0 && dj == 0 && continue

                ni, nj = i + di, j + dj
                (ni < 1 || ni > n) && continue
                (nj < 1 || nj > m) && continue

                rolls_around[ni, nj] -= 1
                if is_roll(is_roll_, ni, nj; n, m) && !in_stack[ni, nj]
                    push!(stack, (ni, nj))
                    in_stack[ni, nj] = true
                end
            end
        end
    end

    return forklifted_count
end

# Gemini proposition for optimizing my solution
function solve_optimized(lines; part1=false)
    # 1. Setup Dimensions & Padding
    # We use padding to avoid bounds checking inside the hot loop.
    n_in, m_in = length(lines), length(lines[1])
    rows, cols = n_in + 2, m_in + 2

    # 'grid' stores the state. 'counts' caches neighbor info.
    # We flatten them to 1D arrays for performance (Linear Indexing)
    len = rows * cols
    grid = falses(len)
    counts = zeros(Int8, len)
    in_stack = falses(len)

    # 2. Fill Grid
    # Map input (i, j) -> padded memory layout
    # Julia is Column-Major: index = (col-1)*rows + row
    for j in 1:m_in
        # Extract the byte array for the column-equivalent logic
        # But lines are row-strings. 
        # lines[i][j] maps to grid row=i+1, col=j+1
        for i in 1:n_in
            if codeunits(lines[i])[j] == UInt8('@')
                grid[(j)*rows+(i+1)] = true
            end
        end
    end

    # 3. Pre-calculate Neighbors & Populate Stack
    # Neighbor offsets for a column-major matrix
    offsets = (-1, 1, -rows, rows, -rows - 1, -rows + 1, rows - 1, rows + 1)

    stack = Int[]
    sizehint!(stack, n_in * m_in)

    # Iterate only the valid inner area
    for c in 2:(cols-1)
        # Start index for this column (row 2)
        idx = (c - 1) * rows + 2

        for r in 2:(rows-1)
            if grid[idx]
                # Count neighbors once
                n_count = 0
                for off in offsets
                    n_count += grid[idx+off]
                end
                counts[idx] = n_count

                # If unstable, add to stack
                if n_count < 4
                    push!(stack, idx)
                    in_stack[idx] = true
                end
            end
            idx += 1
        end
    end

    if part1
        return length(stack)
    end

    # 4. Processing Loop (Merged & Fast)
    forklifted_count = 0

    while !isempty(stack)
        idx = pop!(stack)
        in_stack[idx] = false # Reset stack flag

        # Determine if actually removable (it might have been added, 
        # but then neighbors changed? No, count only goes down.)
        # Just check if it's still there (in case of duplicate adds, though in_stack prevents that)
        if !grid[idx]
            continue
        end

        # REMOVE
        grid[idx] = false
        forklifted_count += 1

        # PROPAGATE
        # Update neighbors' counts immediately
        for off in offsets
            n_idx = idx + off

            # If the neighbor exists, decrement its support count
            if grid[n_idx]
                counts[n_idx] -= 1

                # If it drops below 4, it becomes unstable
                if counts[n_idx] < 4 && !in_stack[n_idx]
                    push!(stack, n_idx)
                    in_stack[n_idx] = true
                end
            end
        end
    end

    return forklifted_count
end

@test solve(readlines("data/day04_test.txt"); part1=true) == 13
@test solve(readlines("data/day04_test.txt")) == 43

println(solve(readlines("data/day04.txt"); part1=true))
println(solve(readlines("data/day04.txt")))

#=
What worked:
 - fast small calculations over big memory (Vector vs Set)
 - For a stack, use an Vector + a boolean array to check "is it in the stack?"

Further optimizations:
 - Use an array keeping track of the number of neighbors of each roll
 - Pad the arrays to avoid bounds checking
 - Use linear indexing
=#