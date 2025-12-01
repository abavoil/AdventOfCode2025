function parse_rotation(rot)
	n = parse(Int, rot[2:end])
	if rot[1] == 'L'
		n = -n
	end
	return n
end

function solveA(lines)
	zero_count = 0
	position = 50
	for rotation in lines
		n = parse_rotation(rotation)
		position = mod(position + n, 100)
		@info rotation, parse_rotation(rotation), position
		if position == 0
			zero_count += 1
		end
	end
	return zero_count
end

function solveB(lines)
	zero_count = 0
	position = 50
	for rotation in lines
		n = parse_rotation(rotation)
		next_position = position + n
		if (mod(next_position, 100) == 0)
			zero_count += 1
			@info "- land tick (" * string(zero_count) * ")"
		end
		if ((position != 0) && (next_position < 0 || next_position > 100))
			zero_count += 1
			@info "- pass tick (" * string(zero_count) * ")"
		end

		position = mod(next_position, 100)
		@info rotation, parse_rotation(rotation), position
	end
	return zero_count
end

lines = readlines("data/day1A.txt")
solveB(lines)
# 2615 too low