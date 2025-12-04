using Test

function isroll(room, i, j; n=size(room, 1), m=size(room, 2))
    if i < 1 || i > n
        return false
    end
    
    if j < 1 || j > m
        return false
    end
    
    return room[i, j] == '@'
end

function isforkliftable(room, i, j; kwargs...)
    rolls_around = 0
    for di in [-1, 0, 1], dj in [-1, 0, 1]
        if di == 0 && dj == 0
            continue
        end
        if isroll(room, i+di, j+dj; kwargs...)
            rolls_around += 1
        end
    end

    return rolls_around < 4
end

function forklift_coordinates!(next_room, room; kwargs...)
    forklifted_count = 0
    for i in axes(room, 1), j in axes(room, 2)
        if isroll(room, i, j; kwargs...) && isforkliftable(room, i, j; kwargs...)
            next_room[i, j] = 'x'
            forklifted_count += 1
        end
    end
    room .= next_room
    return forklifted_count
end

function solve(lines; part1=false)
    room = permutedims(reduce(hcat, collect.(lines)))
    next_room = copy(room)
    n, m = size(room)
    count = 0
    while true
        iteration_count = forklift_coordinates!(next_room, room; n=n, m=m)
        count += iteration_count
        if iteration_count == 0 || part1
            break
        end
    end
    return count
end

@test solve(readlines("data/day04_test.txt"); part1=true) == 13
@test solve(readlines("data/day04_test.txt")) == 43

println(solve(readlines("data/day04.txt"); part1=true))
println(solve(readlines("data/day04.txt")))