using Test

const Point = NTuple{2,Int}

# Si l'intérieur strict est connexe, alors DFS/BFS suffit pour le remplir
# sinon il faut un tableau en plus et une fonction compute_is_inside qui calcule la rotation de la courbe autour du point

next(arr, i) = arr[mod1(i + 1, length(arr))]
next(arr, i_perm, perm) = next(arr, perm[i_perm])
# TODO: add tests

prev(arr, i) = arr[mod1(i - 1, length(arr))]
prev(arr, i_perm, perm) = prev(arr, perm[i_perm])
# TODO: add tests

function compute_curvature(p1, p2, p3)
    s1 = p2 .- p1
    s2 = p3 .- p2
    curvature = sign(s1[1] * s2[2] - s1[2] * s2[1])
    return curvature
end
@test compute_curvature([1, 0], [1, 1], [0, 1]) == 1
@test compute_curvature([0, 1], [1, 1], [1, 0]) == -1
@test compute_curvature([1, 1], [1, 0], [0, 0]) == -1

function corners(points)
    return (circshift(points, -p_i + 2)[1:3] for p_i in eachindex(points))
end
@test collect(corners([1, 2, 3])) == [[3, 1, 2], [1, 2, 3], [2, 3, 1]]

compute_accel(p1, p2, p3) = @. sign(p1 - 2 * p2 + p3)
@test compute_accel([1, 0], [1, 1], [0, 1]) == [-1, -1]
@test compute_accel([0, 1], [1, 1], [1, 0]) == [-1, -1]
@test compute_accel([1, 1], [1, 0], [0, 0]) == [-1, 1]

function sort_anticlockwise!(points)
    curvature_sign = similar(points, Int)  # 1: anticlockwise, -1: clockwise
    accel = similar(points)
    total_curvature = 0

    for (p_i, (p1, p2, p3)) in enumerate(corners(points))
        c = compute_curvature(p1, p2, p3)
        total_curvature += c
        curvature_sign[p_i] = c
        accel[p_i] = @. sign(p1 - 2 * p2 + p3)
    end

    if total_curvature < 0
        reverse!(points)
        reverse!(curvature_sign)
        reverse!(accel)
        curvature_sign .-= -curvature_sign
    end
    return curvature_sign, accel
end

function _valid_orientation(orientation, accel, diag)
    ccw_turn = orientation > 0
    accel_and_q_in_same_quadrant = all(@. accel * diag > 0)
    return ccw_turn == accel_and_q_in_same_quadrant
end
@test _valid_orientation(1, (1, 1), (1, 1)) == true
@test _valid_orientation(1, (1, 1), (1, -1)) == false
@test _valid_orientation(1, (1, 1), (-1, 1)) == false
@test _valid_orientation(1, (1, 1), (-1, -1)) == false
@test _valid_orientation(-1, (1, 1), (1, 1)) == false
@test _valid_orientation(-1, (1, 1), (1, -1)) == true
@test _valid_orientation(-1, (1, 1), (-1, 1)) == true
@test _valid_orientation(-1, (1, 1), (-1, -1)) == true

function valid_orientation(points, orientation_sign, accel, i, j)
    diag = points[j] .- points[i]
    return _valid_orientation(orientation_sign[i], accel[i], diag) &&
           _valid_orientation(orientation_sign[j], accel[j], .-diag)
end

function intersects(u1, u2, v1, v2)
    # Do segments u = ]u1, u2[ and v = ]v1, v2[] intersect (no edge cases)
    if u1 == v1 || u1 == v2 || u2 == v1 || u2 == v2
        return false
    end
    c1 = compute_curvature(u1, u2, v1)
    c2 = compute_curvature(u2, v1, v2)
    c3 = compute_curvature(v1, v2, u1)
    c4 = compute_curvature(v2, u1, u2)
    return (c1 == c2) && (c3 == c4) && (c1 != c3)
end
@test intersects([0, 1], [1, 1], [0, 0], [1, 0]) == false  # =
@test intersects([0, 0], [0, 1], [1, 0], [1, 1]) == false  # ||
@test intersects([0, 1], [1, 1], [1, 0], [2, 0]) == false  # -_
@test intersects([0, 1], [0, 2], [1, 0], [1, 1]) == false #  i!
@test intersects([0, 1], [1, 1], [1, 0], [2, 0]) == false  # -|
@test intersects([1, 0], [1, 1], [0, 1], [2, 1]) == false  # T
@test intersects([0, 1], [2, 1], [1, 0], [1, 2]) == true  # +
@test intersects([0, 1], [1, 1], [0, 1], [2, 0]) == false  # --

function rect_not_intersected(points, p, q, sorted_xy, sorted_xy_inds; can_break=falses(size(points)))
    n = length(points)
    A, B = extrema.((p, q))

    # Set to true, and eliminate all points that are not inbetween v1 and v2 in any dimension (no chance of breaking)
    can_break .= true
    for dim in 1:2
        kmin = searchsortedfirst(sorted_xy[dim], A[dim])
        kmax = searchsortedlast(sorted_xy[dim], B[dim])
        # @show 1, kmin, kmax, n
        kmin > kmax && continue
        # @show [1:kmin; kmax:n]
        for k in [1:kmin; kmax:n]  # Check indices
            # @show k
            # @show sorted_xy[dim][k]
            can_break[sorted_xy_inds[dim][k]] = false
        end
    end

    for i in eachindex(points)
        !can_break[i] && continue
        if all(A .<= points[i] .<= B)
            return false  # point i is inside the rectangle
        end
    end

    for i in eachindex(points)
        if can_break[i] && next(can_break, i)
            if intersects(A, B, points[i], next(points, i))
                return false
            end
        end
    end
    # Check for edges

    return true
end

function rect_not_intersected_naive(points, i, j)
    p = points[i]
    q = points[j]
    A = (min(p[1], q[1]), min(p[2], q[2]))
    B = (max(p[1], q[1]), max(p[2], q[2]))

    # println("A: $A, B: $B")

    for (i, r) in enumerate(points)
        # println("$i: $r")
        r == p || r == q && continue
        if A[1] < r[1] < B[1] && A[2] < r[2] < B[2]
            # println("$r is inside the rectangle")
            return false  # r is inside the rectangle
        end

        r_next = next(points, i)
        r_next == p || r_next == q && continue

        if intersects(A, B, r, r_next)
            # println("diagonal [$A, $B] intersects with [$r, $(next(points, i))]")
            return false
        end
    end

    return true
end
test_points = [(6, 1), (10, 1), (10, 7), (8, 7), (8, 5), (1, 5), (1, 3), (6, 3)]
# test points:
#   7#6
#   # #
# 1#8 #
# #   #
# #   5#4
# #     #
# 2#####3

valid_pairs = [
    [minmax(i, mod1(i + 1, length(test_points))) for i in eachindex(test_points)]
    (1, 5)
    (1, 7)  # Even if outside
    (2, 4)
    (2, 5)
    (2, 8)
    (3, 5)
    (4, 6)  # Even if outside
    (5, 7)
    (5, 8)
    (6, 8)
]
for i in eachindex(test_points)
    for j in i+2:lastindex(test_points)
        intersected = ((i, j) in valid_pairs)
        # println("Testing points $i = $(test_points[i]) and $j = $(test_points[j])")
        @test rect_not_intersected_naive(test_points, i, j) == intersected
        @test rect_not_intersected_naive(test_points, j, i) == intersected
    end
end

function solve(lines; part1=false)
    points = [Point(parse.(Int, split(line, ','))) for line in lines]
    min_i, max_i = extrema(x -> x[1], points)
    min_j, max_j = extrema(x -> x[2], points)
    map!(p -> p .- (min_i - 1, min_j - 1), points)

    curvature_sign, accel = sort_anticlockwise!(points)

    sorted_x_inds = sortperm(points; by=p -> p[1])
    sorted_y_inds = sortperm(points; by=p -> p[2])
    sorted_x = [points[i][1] for i in sorted_x_inds]
    sorted_y = [points[i][2] for i in sorted_y_inds]

    sorted_xy_inds = (sorted_x_inds, sorted_y_inds)
    sorted_xy = (sorted_x, sorted_y)

    can_break_buffer = falses(size(points))

    max_pair = [points[1], points[1]]
    max_area = 0
    for i in eachindex(points)
        p = points[i]

        for j in i+2:lastindex(points)
            # @show (i, j)
            q = points[j]
            δ = q .- p

            area = (abs(δ[1]) + 1) * (abs(δ[2]) + 1)
            area < max_area && continue

            if !part1
                if !valid_orientation(points, curvature_sign, accel, i, j)
                    # println("Stopped at 1: $((i, j))")
                    continue
                end

                # if !rect_is_inside(points, p, q, sorted_xy, sorted_xy_inds; can_break=can_break_buffer)
                #     println("Stopped at 2: $((i, j))")
                #     continue
                # end

                if !rect_not_intersected_naive(points, i, j)
                    # println("Stopped at 2: $((i, j))")
                    continue
                end

                # println("Valid rectangle: $((i, j))")
            end

            if area > max_area
                max_area = area
                max_pair .= [p, q]
            end
        end
    end
    return max_area
end

test_lines = readlines("data/day09_test.txt")
@test solve(test_lines; part1=true) == 50
@test solve(test_lines) == 24

lines = readlines("data/day09.txt")
println(solve(lines; part1=true))
println(solve(lines))


# i = findfirst(s -> s == "11,1", lines)
# deleteat!(lines, i)
# insert!(lines, i, "11,2")
# insert!(lines, i, "10,2")
# insert!(lines, i, "10,1")



#=
Optimisations:
 - Optimize part1 and translate it to part2
 - Use searchsortedfirst and searchsortedlast
 - save on unnecessary operations
=#


# Δ = 100
# vals = Δ .+ [5, 6, 7, 6, 2, 10, 1, 3, 4, 4, 8, 7, 3]
# min_, max_ = Δ + 3, Δ + 7
# sorted_indices = sortperm(vals)

# i_of_min, i_of_max = findfirst(==(min_), vals), findfirst(==(max_), vals)
# println("min = $(vals[i_of_min]), max = $(vals[i_of_max]) (excluded)")
# i1 = searchsortedfirst(sorted_indices, i_of_min; by=x -> vals[x] - v1)
# i2 = searchsortedlast(sorted_indices, i_of_max; by=x -> vals[x] - v2)
# println(vals[sorted_indices[i1:i2]])

# sorted_vals = view(vals, sorted_indices)
# i1 = searchsortedfirst(sorted_vals, min_ + 1)
# i2 = searchsortedlast(sorted_vals, max_ - 1)
# println(vals[sorted_indices[i1:i2]])