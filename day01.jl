using Test

function parse_rotation(rot)
    n = 0
    for (i, byte) in enumerate(codeunits(rot))
        i == 1 && continue
        n = 10n + byte - 0x30
    end
    if rot[1] == 'L'
        n = -n
    end
    return n
end

function solve1(lines)
    zero_count = 0
    p = 50
    for line in lines
        n = parse_rotation(line)
        p = mod(p + n, 100)
        zero_count += (p == 0)
    end
    return zero_count
end

function solve2_naive(lines)
    zero_count = 0
    p = 50
    for l in lines
        this_zero_count = 0
        n = parse_rotation(l)
        for step in repeat([sign(n)], abs(n))
            p += step
            if mod(p, 100) == 0
                this_zero_count += 1
            end
        end
        # @info l p this_zero_count
        zero_count += this_zero_count
    end
    return zero_count
end

function solve2(lines)
    zero_count = 0
    p = 50
    for l in lines
        n = parse_rotation(l)
        this_zero_count = 0
        q, next_p = fldmod(n + p, 100)  # This always gives next_p in [0, 99]
        this_zero_count = abs(q)

        # @info n+p q next_p
        # Treat cases were we arrive to/leave zero with negative rotation
        if n < 0 && next_p == 0
            this_zero_count += 1
        end
        if n < 0 && p == 0
            this_zero_count -= 1
        end

        # @info l p this_zero_count
        p = next_p
        zero_count += this_zero_count
    end
    return zero_count
end

# For debugging
lines_R = ["R50", "R0", "R50", "R100", "R150"]
#           100,   100,  150,   250,    400
#             1,     0,    0,     1,      2

lines_L = ["L50", "L0", "L50", "L100", "L150"]
#              0,     0,   -50,   -150,   -300
#              1,     0,    0,     1,      2

function solve(lines; part1=false)
    if part1
        return solve1(lines)
    else
        return solve2(lines)
    end
end

@test solve(lines_L; part1=true) == 3  # staying on 0 counts
@test solve(lines_L) == 4
@test solve(lines_R; part1=true) == 3
@test solve(lines_R) == 4

test_lines = readlines("data/day01_test.txt")
@test solve(test_lines; part1=true) == 3
@test solve(test_lines) == 6

lines = readlines("data/day01.txt")
println(solve(lines; part1=true))
println(solve(lines))
