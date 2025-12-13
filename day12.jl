
bytes2int(bytes) = 10 * bytes[1] + bytes[2] - 528  # 528 = 10 * 0x30 + 0x30

function solve(lines; part1=false)
    @assert part1
    splits = findall(isempty, lines)
    shape_areas = zeros(Int, length(splits))

    for (i, s) in enumerate(splits)
        area = 0
        for line in @view lines[s-3:s-1]
            for c in codeunits(line)
                if c == UInt16('#')
                    area += 1
                end
            end
        end
        shape_areas[i] = area
    end

    can_fit = 0
    for line in @view lines[splits[end]+1:end]
        cu = codeunits(line)
        n = bytes2int(@view cu[1:2])
        m = bytes2int(@view cu[4:5])

        shape_area = 0
        for i_shape in eachindex(shape_areas)
            count = bytes2int(@view cu[5+3i_shape:5+3i_shape+1])
            shape_area += count * shape_areas[i_shape]
        end
        field_area = n * m
        if field_area >= shape_area
            can_fit += 1
        end
    end

    return can_fit
end

lines = readlines("data/day12.txt")
# No test since real input is much easier than the real problem
println(solve(lines; part1=true))

# for line in @view lines[splits[end]+1:end]
#     n = 0
#     m = 0
#     i = 1

#     while codeunits(line)[i] != UInt16('x')
#         n = 10n + codeunits(line)[i] - UInt16('0')
#         i += 1
#     end
#     i += 1

#     while codeunits(line)[i] != UInt16(':')
#         m = 10m + codeunits(line)[i] - UInt16('0')
#         i += 1
#     end
#     i += 2

#     field_area = n * m

#     shape_area = 0
#     for i_shape in eachindex(shape_areas)
#         count = 0
#         while i <= length(line) && codeunits(line)[i] != UInt16(' ')
#             count = 10count + codeunits(line)[i] - UInt16('0')
#             i += 1
#         end
#         i += 1
#         shape_area += count * shape_areas[i_shape]
#     end

#     if field_area >= shape_area
#         can_fit += 1
#     end
# end

