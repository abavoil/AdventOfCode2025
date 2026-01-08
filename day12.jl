using Test

bytes2int(bytes) = 10 * bytes[1] + bytes[2] - 528  # 528 = 10 * 0x30 + 0x30

function parse_shape_areas(lines, splits)
    shape_areas = zeros(Int, length(splits))

    for (i, s) in enumerate(splits)
        area = 0
        @inbounds @simd for ii in s-3:s-1
            @inbounds for j in 1:3
                area += codeunits(lines[ii])[j] == UInt16('#')  # faster than ifelse
            end
        end
        shape_areas[i] = area
    end

    return shape_areas
end

function criterium1(line, shape_areas)
    cu = codeunits(line)
    n = bytes2int(@view cu[1:2])
    m = bytes2int(@view cu[4:5])

    shape_area = 0
    for i_shape in eachindex(shape_areas)
        count = bytes2int(@view cu[5+3i_shape:5+3i_shape+1])
        shape_area += count * shape_areas[i_shape]
    end
    field_area = n * m
    return field_area >= shape_area
end

function criterium2(line)
    cu = codeunits(line)
    n = bytes2int(@view cu[1:2])
    m = bytes2int(@view cu[4:5])

    total_shape_count = 0
    for i_shape in eachindex(shape_areas)
        count = bytes2int(@view cu[5+3i_shape:5+3i_shape+1])
        total_shape_count += count
    end
    return n * m >= 9 * total_shape_count
end


function check_assumption(lines)
    #=
    Assumption: either canvas size < a and shapes trivially don't fit, or canvas size >= A and shapes trivially fit
    if any a <= canvas size < A, return false, else return true

        a = dot(shape_counts, shape_areas)
    A = 9 * total_shape_count

    criterium 1: if field_area < a, shapes don't fit
    criterium 2: If field_area >= A, shapes can fit
    if a <= field_area < A, shapes could fit, we need an actual algorithm

    n*m: | n*m < a | n*m == a | a < n*m < A | n*m == A | n*m > A
    ct1:   true      false      false        false      false
    ct2:   false     false      false        true       true
    fit:   no        ?          ?             yes        yes

    check for 


    We check that the non trivial case does not happen, thus we can use either of the two criteria to get the actual answer
    =#
    splits = findall(isempty, lines)
    shape_areas = parse_shape_areas(lines, splits)

    for line in @view lines[splits[end]+1:end]
        cu = codeunits(line)
        n = bytes2int(@view cu[1:2])
        m = bytes2int(@view cu[4:5])

        occupied_area = 0
        nb_shapes = 0
        for i_shape in eachindex(shape_areas)
            count = bytes2int(@view cu[5+3i_shape:5+3i_shape+1])
            occupied_area += count * shape_areas[i_shape]
            nb_shapes += count
        end
        if occupied_area <= n * m < 9nb_shapes  # In the unknown zone
            return false
        end
    end
    return true
end

function solve(lines; part1=false)
    !part1 && return
    splits = findall(isempty, lines)
    shape_areas = parse_shape_areas(lines, splits)

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
@test check_assumption(lines)

println(solve(lines; part1=true))
