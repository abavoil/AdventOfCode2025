using Test

lines = readlines("data/day2_test.txt")

# make this readable
# x |> mapreduce (x |> split ',', vcat)
#   |> map (x |> split '-' |> map parse(Int))
intervals1bis(lines) = map(
    x -> parse.(Int, split(x, '-')),
    Iterators.flatmap(x -> split(x, ',', keepempty=false), lines)
)

n_length(n) = floor(Int, log10(n)) + 1
@test n_length(123) == 3
@test n_length(100) == 3

factor(seq_len, n_rep) = sum(10^(seq_len*i) for i in 0:n_rep-1)
@test factor(1, 3) == 111
@test factor(3, 2) == 1001
@test factor(2, 3) == 10101

repeat(seq, n_rep, seq_len=floor(Int, log10(seq)) + 1) = seq * factor(seq_len, n_rep)
@test repeat(9, 3) == 999
@test repeat(987, 2) == 987987
@test repeat(98, 3) == 989898

min_n_rep_(seq_len, a_len) = max(2, ceil(Int, a_len / seq_len))
@test min_n_rep_(2, 2) == 2
@test min_n_rep_(3, 10) == 4
@test min_n_rep_(3, 9) == 3

max_n_rep_(seq_len, b_len) = floor(Int, b_len / seq_len)
@test max_n_rep_(2, 2) == 1
@test max_n_rep_(3, 17) == 5
@test max_n_rep_(3, 15) == 5

first_digits(n, nb_digits; n_len=n_length(n)) = div(n, 10^(n_len - nb_digits))
@test first_digits(1234, 2) == 12
@test first_digits(1000, 2) == 10

function min_seq_(seq_len, n_rep, a; f=factor(seq_len, n_rep), a_len=n_length(a))
    min_seq = 10^(seq_len - 1)
    if min_seq * f < a
        min_seq = first_digits(a, seq_len; n_len=a_len)  # possibly re-use length(a)
    end
    if min_seq * f < a
        min_seq += 1
    end
    return min_seq
end
@test min_seq_(3, 2, 1) == 100
@test min_seq_(3, 2, 123000) == 123
@test min_seq_(3, 2, 123123) == 123
@test min_seq_(3, 2, 123124) == 124

function max_seq_(seq_len, n_rep, b; f=factor(seq_len, n_rep), b_len=n_length(b))
    max_seq = 10^seq_len - 1
    if max_seq * f > b
        max_seq = first_digits(b, seq_len; n_len=b_len)
    end
    if max_seq * f > b
        max_seq -= 1
    end
    return max_seq
end
@test max_seq_(3, 2, 10^6) == 999
@test max_seq_(3, 2, 987987) == 987
@test max_seq_(3, 2, 987986) == 986

sum_a_to_b(a, b) = round(Int, (b * (b+1) - (a-1) * a) / 2)
@test sum_a_to_b(1, 10) == 55
@test sum_a_to_b(4, 11) == 60  # 55 - 6 + 11

function invalid_ids!(invalid_ids, a, b; partA=false)
    a_len = n_length(a)
    b_len = n_length(b)
    # TODO: invert the two loops, so that n_rep = 2 for part 1, cf. notes at the bottom
    for seq_len in 1:div(b_len, 2)
        # How many times should I need to repeat 1 such that 1...1 > a
        # How many times can I repeat 9 such that 9...9 < b
        min_n_rep = min_n_rep_(seq_len, a_len) # Smallest n such that n * seq_len >= a_len
        max_n_rep = max_n_rep_(seq_len, b_len) # Largest n such that n * seq_len <= b_len
        for n_rep in min_n_rep:max_n_rep
            partA && n_rep != 2 && continue
            f = factor(seq_len, n_rep)
            min_seq = min_seq_(seq_len, n_rep, a; f=f, a_len=a_len)  # 1..1, first seq_len digits of a if min_seq * f < a, += 1 if min_sec * f < a
            max_seq = max_seq_(seq_len, n_rep, b; f=f, b_len=b_len)  # 9..9, first seq_len digits of b if max_seq * f > b, -= 1 if max_seq * f > b
            for seq in min_seq:max_seq
                union!(invalid_ids, seq * f)
            end
        end
    end
    invalid_ids
end
invalid_ids(a, b) = invalid_ids!(Set{Int}(), a, b)
@test invalid_ids(11, 22) == Set([11, 22])
@test invalid_ids(95, 115) == Set([99, 111])
@test invalid_ids(998, 1012) == Set([999, 1010])
@test invalid_ids(1188511880, 1188511890) == Set([1188511885])
@test invalid_ids(222220, 222224) == Set([222222])
@test invalid_ids(1698522, 1698528) == Set()
@test invalid_ids(446443, 446449) == Set([446446])
@test invalid_ids(38593856, 38593862) == Set([38593859])
@test invalid_ids(565653, 565659) == Set([565656])
@test invalid_ids(824824821, 824824827) == Set([824824824])
@test invalid_ids(2121212118, 2121212124) == Set([2121212121])

function solve(lines; partA=false)
    invalid_ids = Set{Int}()
    for (a, b) in intervals(lines)
        invalid_ids!(invalid_ids, a, b; partA=partA)
    end
    return sum(invalid_ids)
end

@test solve(readlines("data/day2_test.txt"); partA=true) == 1227775554
@test solve(readlines("data/day2_test.txt")) == 4174379265
@btime solve(readlines("data/day2.txt"); partA=true)
@btime solve(readlines("data/day2.txt"))


#= TODO
1. Instead of using a set, we can check wether the repeated sequence is itself a repeating sequence, and only add to the count if it is not (is_primitive)

2. Notes for part 1

a, b = 95, 115
min_n_rep = 2
max_n_rep = n_length(b)

n_rep = 2
min_seq = first_digits(a, ceil(Int, n_length(a) / n_rep))
if repeat(min_seq, n_rep) < a
    min_seq += 1
end
max_seq = 10^n_rep - 1
if repeat(max_seq, n_rep) > b
    max_seq = first_digits(b, ceil(Int, n_length(b) / n_rep))
end
if repeat(max_seq, n_rep) > b
    max_seq -= 1
end

=#