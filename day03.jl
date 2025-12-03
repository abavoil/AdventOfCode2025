using Test

function maximum_subnumber(line, out_len)
    a = parse.(Int, collect(line))
    in_len = length(a)

    out = 0
    current_ind = 1  # Over the input digits

    # We build a number with 'out_len' digits
    for remaining in out_len:-1:1
        limit = in_len - remaining + 1

        max_val = 0
        max_ind = -1

        # Scan the window for the largest digit
        @inbounds for i in current_ind:limit
            digit = a[i]
            if digit > max_val
                max_val = digit
                max_ind = i
                if max_val == 9
                    break
                end
            end
        end

        current_ind = max_ind + 1
        out = 10out + max_val
    end

    return out
end

maximum_subnumber(n::Int, out_len) = maximum_subnumber(string(n), out_len)
solve(lines; part1=false) = sum(maximum_subnumber(l, ifelse(part1, 2, 12)) for l in lines)

@test solve(readlines("data/day03_test.txt"); part1=true) == 357
@test solve(readlines("data/day03_test.txt")) == 3121910778619

lines = readlines("data/day03.txt")
println(solve(lines; part1=true))
println(solve(lines))


#= What worked:
 - use bytes instead of converting
 - use readlines, it is fast
 - out = 10out + d is cool

What didn't:
 - dynamic programming was not required : there is no downside of picking a 9 since we verify there is enough room left
 - funnily enough, usign UInt8 is as fast as Int, but it does allocate half (?!) as less bytes
    a = parse.(UInt8, collect(line))
    max_val = 0x0
    if max_val == 0x9
=#
