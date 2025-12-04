using Test

function _maximum_subnumber(digits, len)
    if len == 0
        return 0, true
    end
    
    @views for d in 9:-1:0
        i = findfirst(x -> x == d, digits[1:end-len+1])
        if !isnothing(i)
            result, is_valid = _maximum_subnumber(digits[i+1:end], len-1)
            if is_valid
                return result + d * 10^(len-1), true
            end
        end
    end
    return -1, false
end

maximum_subnumber(line, len) = _maximum_subnumber(parse.(Int, collect(line)), len)[1]
maximum_subnumber(n::Integer, len) = maximum_subnumber(string(n), len)
solve(lines; part1=false) = sum(maximum_subnumber(l, ifelse(part1, 2, 12)) for l in lines)

@test solve(readlines("data/day03_test.txt"); part1=true) == 357
@test solve(readlines("data/day03_test.txt")) == 3121910778619

println(solve(readlines("data/day03.txt"); part1=true))
println(solve(readlines("data/day03.txt")))
