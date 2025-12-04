using Test

solve(lines; part1=false) = 0

@test solve(readlines("data/dayXY_test.txt"); part1=true) == 0
@test solve(readlines("data/dayXY_test.txt")) == 0

println(solve(readlines("data/dayXY.txt"); part1=true))
println(solve(readlines("data/dayXY.txt")))
