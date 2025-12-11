# ==============================================================================
# SCRIPT HISTORY & ARCHITECTURE SUMMARY
# For future LLMs/Developers improving this code
# ==============================================================================
#
# GOAL:
#   Automatically discover `dayXY.jl` solutions, benchmark their `solve` function
#   against `data/dayXY.txt`, and update a Markdown table in `README.md`.
#   Only re-runs benchmarks if the source file content (hash) has changed.
#
# ARCHITECTURE:
#   1. File Discovery: Regex `^day\d{2}(_.*)?\.jl$`.
#   2. Caching: Calculates SHA256 of the file. Reads existing README to see if
#      hash matches. If yes, skips benchmark. Stores hash as HTML comment.
#   3. Isolation: Modules + shadowed println.
#   4. Output: Table format `| File | Part 1 | Part 2 |`. Memory info removed.
#              Includes a Total Sum row (Sum of BEST time per Day/Part).
#
# CRITICAL IMPLEMENTATION DETAILS (Do not regress):
#   0. DO NOT remove essential information from this summary.
#   1. World Age / Julia 1.12+ Compatibility:
#      - Use `solve_func = Core.eval(mod, :solve)` to retrieve the handle.
#      - Use `Base.invokelatest(solve_func, ...)` to execute it.
#   2. Output Formatting:
#      - Table entries for filenames must be clickable relative links 
#        (e.g., [`day01.jl`](./day01.jl)).
#   3. Total Calculation:
#      - If multiple files exist for the same day (e.g. day01.jl, day01_opt.jl),
#        the Total row must sum only the MINIMUM time for that day.
# ==============================================================================

using BenchmarkTools
using Printf
using SHA

# --- Configuration ---
README_FILE = "README.md"
DATA_DIR = "data"
MARKER_START = "<!-- BENCHMARK_TABLE_BEGIN -->"
MARKER_END = "<!-- BENCHMARK_TABLE_END -->"

FILES_TO_EXCLUDE = []

# ---------------------

function get_target_files()
    pattern = r"^day\d{2}(_.*)?\.jl$"
    files = filter(f -> occursin(pattern, f), readdir())
    filter!(f -> !(f in FILES_TO_EXCLUDE), files)
    return sort(files)
end

function get_data_for_file(filename)
    m = match(r"(day\d+)", filename)
    if isnothing(m)
        @warn "Could not extract day number from $filename"
        return nothing
    end

    txt_name = m[1] * ".txt"
    txt_path = joinpath(DATA_DIR, txt_name)

    if !isfile(txt_path)
        @warn "Data file not found: $txt_path"
        return nothing
    end

    return readlines(txt_path)
end

function calculate_file_hash(filename)
    return bytes2hex(open(sha256, filename))
end

# Simplified to just show time, no memory/allocs
function format_benchmark_result(trial::BenchmarkTools.Trial)
    min_time = minimum(trial.times)
    return BenchmarkTools.prettytime(min_time)
end

# Helper to parse "123.4 μs" back to nanoseconds (Float64) for summation
function parse_time_ns(t_str::String)
    s = strip(t_str)
    # Handle error strings or empty strings
    if s in ["Fail", "Err", "LoadErr", "NoSolve"] || isempty(s)
        return 0.0
    end

    # Regex to capture number and unit. 
    # Matches "123.45" and "μs" / "ms" / "s" / "ns"
    m = match(r"([\d\.]+)\s*([a-zµμ]+)", s)
    if isnothing(m)
        return 0.0
    end

    val = try
        parse(Float64, m[1])
    catch
        0.0
    end
    unit = m[2]

    mult = if unit == "ns"
        1.0
    elseif unit == "μs" || unit == "µs"
        1000.0
    elseif unit == "ms"
        1e6
    elseif unit == "s"
        1e9
    elseif unit == "m"
        60.0 * 1e9
    else
        0.0
    end

    return val * mult
end

# Parses the README to find existing results and hashes
# Returns Dict: filename => (hash, part1_str, part2_str)
function parse_existing_results()
    if !isfile(README_FILE)
        return Dict{String,Tuple{String,String,String}}()
    end

    content = read(README_FILE, String)

    # Extract content between markers
    m_block = match(Regex("(?s)$MARKER_START(.*)$MARKER_END"), content)
    if isnothing(m_block)
        return Dict{String,Tuple{String,String,String}}()
    end

    table_block = m_block[1]
    results = Dict{String,Tuple{String,String,String}}()

    # Regex to capture: | [`filename`](...) <!-- sha:HASH --> | Result1 | Result2 |
    row_pattern = r"\|\s*\[`([^`]+)`\].*?<!-- sha:(\w+) -->\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|"

    for line in split(table_block, '\n')
        m_row = match(row_pattern, line)
        if !isnothing(m_row)
            fname = m_row[1]
            fhash = m_row[2]
            res1 = m_row[3]
            res2 = m_row[4]
            results[fname] = (fhash, res1, res2)
        end
    end

    return results
end

function run_benchmark(filename)
    println("  -> Benchmarking $filename (Fresh run)...")

    lines_data = get_data_for_file(filename)
    if isnothing(lines_data)
        return ("Err", "Err")
    end

    mod = Module()

    # Silence println
    Core.eval(mod, quote
        println(args...) = nothing
    end)

    try
        Base.include(mod, filename)
    catch e
        @error "Error loading $filename" exception = e
        return ("LoadErr", "LoadErr")
    end

    solve_func = try
        Core.eval(mod, :solve)
    catch
        @warn "Function 'solve' not found in $filename"
        return ("NoSolve", "NoSolve")
    end

    # --- Part 1 ---
    print("     Part 1... ")
    str1 = try
        b1 = @benchmark Base.invokelatest($solve_func, $lines_data; part1=true)
        format_benchmark_result(b1)
    catch e
        "Fail"
    end
    println(str1)

    # --- Part 2 ---
    print("     Part 2... ")
    str2 = try
        b2 = @benchmark Base.invokelatest($solve_func, $lines_data; part1=false)
        format_benchmark_result(b2)
    catch e
        "Fail"
    end
    println(str2)

    return (str1, str2)
end

function generate_table(results_list)
    # results_list contains tuples: (filename, hash, result1, result2)
    header = "| File | Part 1 | Part 2 |\n|:---|:---|:---|\n"

    # Dictionaries to track the Minimum time (ns) per Day Number
    # Key: Day Number (Int), Value: Time in nanoseconds
    min_p1_by_day = Dict{Int,Float64}()
    min_p2_by_day = Dict{Int,Float64}()

    rows = map(results_list) do (file, fhash, s1, s2)
        # 1. Parse times
        t1_ns = parse_time_ns(s1)
        t2_ns = parse_time_ns(s2)

        # 2. Extract Day Number to group results
        # e.g. "day02.jl" -> 2, "day02_opt.jl" -> 2
        m = match(r"day(\d+)", file)
        if !isnothing(m)
            day_num = parse(Int, m[1])

            # Update min for Part 1 (only if valid time > 0)
            if t1_ns > 0.0
                current = get(min_p1_by_day, day_num, Inf)
                if t1_ns < current
                    min_p1_by_day[day_num] = t1_ns
                end
            end

            # Update min for Part 2
            if t2_ns > 0.0
                current = get(min_p2_by_day, day_num, Inf)
                if t2_ns < current
                    min_p2_by_day[day_num] = t2_ns
                end
            end
        end

        # We inject the hash as an HTML comment immediately after the link
        "| [`$file`](./$file) <!-- sha:$fhash --> | $s1 | $s2 |"
    end

    # Sum of the BEST times for each day
    total_p1_ns = sum(values(min_p1_by_day))
    total_p2_ns = sum(values(min_p2_by_day))

    # Format the totals
    total_str1 = BenchmarkTools.prettytime(total_p1_ns)
    total_str2 = BenchmarkTools.prettytime(total_p2_ns)

    total_row = "| **Total (Best of each day)** | **$total_str1** | **$total_str2** |"

    return header * join(rows, "\n") * "\n" * total_row
end

function update_readme(table_content)
    if !isfile(README_FILE)
        @warn "$README_FILE not found. Creating one."
        write(README_FILE, "$MARKER_START\n$MARKER_END\n")
    end

    content = read(README_FILE, String)
    pattern = Regex("(?s)($MARKER_START).*?($MARKER_END)")

    if !occursin(pattern, content)
        println("\nMarkers not found in README. Appending table to end.")
        open(README_FILE, "a") do io
            println(io, "\n" * MARKER_START)
            println(io, table_content)
            println(io, MARKER_END)
        end
    else
        replacement = "$MARKER_START\n$table_content\n$MARKER_END"
        new_content = replace(content, pattern => replacement)
        write(README_FILE, new_content)
        println("\nREADME.md updated successfully.")
    end
end

function main()
    files = get_target_files()
    existing_data = parse_existing_results() # Dict(filename => (hash, r1, r2))

    final_results = [] # List of (filename, hash, r1, r2)

    println("Checking $(length(files)) files against cache...")

    for file in files
        current_hash = calculate_file_hash(file)

        # Check if file exists in cache and hash matches
        if haskey(existing_data, file)
            (old_hash, old_r1, old_r2) = existing_data[file]

            if old_hash == current_hash
                println("  [SKIP] $file (No changes detected)")
                push!(final_results, (file, current_hash, old_r1, old_r2))
                continue
            end
        end

        # If we are here: File is new OR Hash mismatch
        (r1, r2) = run_benchmark(file)
        push!(final_results, (file, current_hash, r1, r2))
    end

    if !isempty(final_results)
        table = generate_table(final_results)
        update_readme(table)
    else
        println("No results to write.")
    end
end

main()