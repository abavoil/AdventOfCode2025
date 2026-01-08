using Test

mutable struct Composition
    c::Vector{Int}        # Current state
    k::Int                # Target sum/level
    n::Int              # Size of state

    M::Vector{Int}        # Limit per component
    S::Int                # Max level/total

    terminated::Bool
end

Composition(S, M) = Composition(zero(M), 0, length(M), M, S, false)

function _fill_buckets!(com::Composition, remainder, i)
    (; c, n, M) = com

    @inbounds for j in i:n
        cap = M[j]
        if remainder <= cap
            c[j] = remainder
            return j
        else
            c[j] = cap
            remainder -= cap
        end
    end
    return n + 1
end

function _advance_k!(com::Composition)
    (; c, n, S) = com
    com.k += 1
    if com.k > S
        com.terminated = true
        return com
    end

    last_used_bucket = _fill_buckets!(com, com.k, 1)
    c[last_used_bucket+1:n] .= 0
    com.terminated = last_used_bucket > n
end

function nexcom!(com::Composition)
    (; c, n) = com

    memory = c[n]
    c[n] = 0

    if memory == com.k
        _advance_k!(com)
        return com
    end

    @inbounds for i in n-1:-1:1
        if c[i] != 0
            c[i] -= 1
            last_used_bucket = _fill_buckets!(com, memory + 1, i + 1)
            if last_used_bucket > n
                _advance_k!(com)
            end
            return com
        end
    end
    return com
end

mutable struct Machine
    lights::BitVector
    buttons::Matrix{Int}
    buttons_sparse::Vector{Vector{Int}}
    joltages::Vector{Int}

    dependent_columns::Vector{Int}
    free_columns::Vector{Int}

    presses::Vector{Int}
    max_presses::Vector{Int}
    total_max_presses::Int

    initialized::Bool
end

zero_machine(n, m) = Machine(falses(n), zeros(Int, n, m), [sizehint!(Int[], n) for j in 1:m], zeros(Int, n), Int[], Int[], zeros(Int, m), zeros(Int, m), 0, false)

function Machine(line)
    bytes = codeunits(line)
    i_spaces = findall(==(UInt16(' ')), bytes)
    n, m = i_spaces[1] - 3, length(i_spaces) - 1
    machine = zero_machine(n, m)

    for i in 1:n
        machine.lights[i] = bytes[i+1] == UInt16('#')
    end

    for j in 1:m
        start = i_spaces[j] + 2
        stop = i_spaces[j+1] - 2
        for b in @view bytes[start:2:stop]
            i = b - 0x30 + 1
            machine.buttons[i, j] = true
            push!(machine.buttons_sparse[j], i)
        end
    end

    i = 1
    for b in @view bytes[i_spaces[end]+2:end-1]
        if b == UInt(',')
            i += 1
            continue
        end
        machine.joltages[i] = 10 * machine.joltages[i] + (b - 0x30)
    end
    return machine
end

function swap_lines!(x::AbstractVecOrMat, i1, i2)
    for j in axes(x, 2)
        x[i1, j], x[i2, j] = x[i2, j], x[i1, j]
    end
end

function run_gaussian_elimination!(machine::Machine)
    A = machine.buttons
    b1 = machine.lights
    b2 = machine.joltages
    empty!(machine.free_columns)
    empty!(machine.dependent_columns)

    n, m = size(A)
    i_piv = 1
    for j_piv in 1:m
        i_swap = findnext(!iszero, eachcol(A)[j_piv], i_piv)
        if isnothing(i_swap)
            push!(machine.free_columns, j_piv)
            continue
        end

        push!(machine.dependent_columns, j_piv)

        if i_swap != i_piv
            swap_lines!(A, i_piv, i_swap)
            swap_lines!(b1, i_piv, i_swap)
            swap_lines!(b2, i_piv, i_swap)
        end

        for i in i_piv+1:n
            A[i, j_piv] == 0 && continue

            d = gcd(A[i, j_piv], A[i_piv, j_piv])
            x = A[i_piv, j_piv] ÷ d
            y = A[i, j_piv] ÷ d

            # Li <- x Li - y Li_piv
            b1[i] = (x * b1[i] - y * b1[i_piv]) & 1
            b2[i] = x * b2[i] - y * b2[i_piv]
            for j in j_piv+1:m
                A[i, j] = x * A[i, j] - y * A[i_piv, j]
            end
            A[i, j_piv] = 0
        end

        i_piv += 1
    end
    # @show A
    return machine
end

function set_free_variables!(machine::Machine, vals)
    x = machine.presses
    for (j, v) in zip(machine.free_columns, vals)
        x[j] = v
    end
end

check_presses(machine::Machine) = machine.joltages - machine.buttons * machine.presses

"""Returns wether solution is positive integer valued"""
function solve_presses(machine)
    A = machine.buttons
    b = machine.joltages
    x = machine.presses

    m = size(A, 2)
    for (i, j) in Iterators.reverse(enumerate(machine.dependent_columns))
        x[j] = b[i]
        for k in j+1:m
            x[j] -= A[i, k] * x[k]
        end
        x[j], r = fldmod(x[j], A[i, j])
        (x[j] < 0 || x[j] > machine.max_presses[j] || r != 0) && return nothing
    end
    return x
end

function solve_lights(m::Machine)
    run_gaussian_elimination!(m)
    count = 0
    for (i, j) in enumerate(m.dependent_columns)
        if m.lights[i]
            count += 1
            for k in m.buttons_sparse[j]
                m.lights[k] = !m.lights[k]
            end
        end
    end
    return count
end

function solve_joltages(m::Machine)
    max_total_presses = div(sum(m.joltages), minimum(length, m.buttons_sparse), RoundUp)
    for (j, b) in enumerate(m.buttons_sparse)
        m.max_presses[j] = minimum(m.joltages[i] for i in b)
    end

    run_gaussian_elimination!(m)
    if isempty(m.free_columns)
        return sum(solve_presses(m))
    end
    c = Composition(max_total_presses, m.max_presses[m.free_columns])

    while !c.terminated
        set_free_variables!(m, c.c)
        presses = solve_presses(m)
        nexcom!(c)
        if !isnothing(presses)
            c.S = min(c.S, sum(presses))
        end
    end

    return c.S
end

function solve(lines; part1=false)
    f = part1 ? solve_lights : solve_joltages

    total = 0
    for line in lines
        total += f(Machine(line))
    end
    return total
end

test_lines = readlines("data/day10_test.txt")
@test solve(test_lines; part1=true) == 6
@test solve(test_lines) == 33

lines = readlines("data/day10.txt")
println(solve(lines; part1=true))
println(solve(lines))
