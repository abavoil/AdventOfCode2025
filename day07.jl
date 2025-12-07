using Test

function solve1(lines_)
    lines = map(codeunits, lines_)

    n, m = length(lines), length(lines[1])
    splitter = UInt8('^')

    j_source = findfirst(==(UInt8('S')), lines[1])
    
    is_beam = falses(m)
    is_beam[j_source] = true
    count = 0

    for line in @view lines[3:2:end]
        for (j, char) in enumerate(line)
            if is_beam[j] && char == splitter
                is_beam[j-1] = is_beam[j+1] = true
                is_beam[j] = false
                count += 1
            end
        end
    end
    return count
end

function solve2(lines_)
    lines = map(codeunits, lines_)
    
    n, m = length(lines), length(lines[1])
    splitter = UInt8('^')

    j_source = findfirst(==(UInt8('S')), lines[1])
    
    is_beam = falses(m)
    is_beam[j_source] = true
    
    timelines = zeros(Int, m)
    next_timelines = copy(timelines)
    timelines[j_source] = 1

    for line in @view lines[3:2:end]
        for (j, char) in enumerate(line)
            if is_beam[j] && char == splitter
                is_beam[j-1] = is_beam[j+1] = true
                is_beam[j] = false

                next_timelines[j-1] += timelines[j]
                next_timelines[j+1] += timelines[j]
                next_timelines[j] = 0
            end
        end
        timelines .= next_timelines
    end
    return sum(timelines)
end

solve(lines; part1=false) = if part1 solve1(lines) else solve2(lines) end

test_lines = readlines("data/day07_test.txt")
@test solve(test_lines; part1=true) == 21
@test solve(test_lines) == 40

lines = readlines("data/day07.txt")
println(solve(lines; part1=true))
println(solve(lines))


#= TODO:
 - Is there really a need to rewrite the whole function because only the inner most operation is different ?
 - is an if reduced at compile time if always the same branch is taken ? Do I need a macro ?
=#