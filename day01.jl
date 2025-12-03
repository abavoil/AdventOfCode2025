using Test

function parse_rotation(rot)
	n = parse(Int, rot[2:end])
	if rot[1] == 'L'
		n = -n
	end
	return n
end

function solveA(lines)
	zero_count = 0
	p = 50
	for l in lines
		n = parse_rotation(l)
		p = mod(p + n, 100)
		zero_count += (p == 0)
	end
	return zero_count
end

function solveB_naive(lines)
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
		@info l p this_zero_count
		zero_count += this_zero_count
	end
	return zero_count
end

function solveB(lines)
	zero_count = 0
	p = 50
	for l in lines
		n = parse_rotation(l)
		this_zero_count = 0
		q, next_p = fldmod(n+p, 100)  # This always gives next_p in [0, 99]
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
lines_R = [
	"R50", "R0", "R50", "R100", "R150"
	# 100,   100,  150,   250,    400
	# 1,     0,    0,     1,      2
]
lines_L = [
	"L50", "L0", "L50", "L100", "L150"
	# 0,     0,   -50,   -150,   -300
	# 1,     0,    0,     1,      2
]

function solve(lines; partA=false)
	if partA
		return solveA(lines)
	else
		return solveB(lines)
	end
end

@test solve(readlines("data/day01_test.txt"); partA=true) == 3
@test solve(readlines("data/day01_test.txt")) == 6
@test solve(lines_L; partA=true) == 3  # staying on 0 counts
@test solve(lines_L) == 4
@test solve(lines_R; partA=true) == 3
@test solve(lines_R) == 4
println(solve(readlines("data/day01.txt"); partA=true))
println(solve(readlines("data/day01.txt")))
