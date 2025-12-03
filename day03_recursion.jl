using BenchmarkTools

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

maximum_subnumber(line, len) = _maximum_subnumber(parse.(Int8, collect(line)), len)[1]
maximum_subnumber(n::Integer, len) = maximum_subnumber(string(n), len)
solve(lines; partA=false) = sum(maximum_subnumber(l, ifelse(partA, 2, 12)) for l in lines)

@test solve(readlines("data/day3_test.txt"); partA=true) == 357
@test solve(readlines("data/day3_test.txt")) == 3121910778619

lines = readlines("data/day3.txt")
@btime solve($lines; partA=true)
@btime solve($lines)
