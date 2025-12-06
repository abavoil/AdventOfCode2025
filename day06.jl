using Test

function part1_(lines)
    vals = permutedims(reduce(hcat, parse.(Int, split(line)) for line in lines[1:end-1]))
    operations = map(s -> ifelse(only(s) == '+', +, *), split(lines[end]))
    # println(split(lines[end]))
    for (op, col) in zip(operations, eachcol(vals))
        # println(op, col)
        # println(reduce(op, col))
    end
    return sum(reduce(op, col) for (op, col) in zip(operations, eachcol(vals)))
end


function solve(lines; part1=false)
    numbers = ifelse(part1, eachrow, eachcol)
    bytes = permutedims(reduce(hcat, codeunits.(lines)))
    block_starts = findall(b -> b == UInt8('+') || b == UInt8('*'), codeunits(last(lines)))
    push!(block_starts, size(bytes, 2) + 1)
    
    total_sum = 0
    for block_i in 1:length(block_starts) - 1
        block_start = block_starts[block_i]
        block_end = block_starts[block_i + 1] - 1

        block = @view bytes[1:end-1, block_start:block_end]
        plus = bytes[end, block_start] == UInt8('+')
        col_value = ifelse(plus, 0, 1)
        for digits in numbers(block)
            this_number = 0
            for d in digits
                if 0x30 <= d <= 0x39
                    this_number = 10this_number + (d - 0x30)
                end
            end
            if this_number != 0
                col_value = ifelse(plus, +, *)(this_number, col_value)
            end
        end
        total_sum += col_value
    end
    return total_sum
end

test_lines = readlines("data/day06_test.txt") 
@test solve(test_lines; part1=true) == 4277556
@test solve(test_lines) == 3263827

lines = readlines("data/day06.txt")
println(solve(lines; part1=true))
println(solve(lines))


#= TODO:
 - write twice the looping over the block depending on part 1/2 to not have this `bytes` matrix,
 - or have some non-allocating wrapper around `lines`

=#