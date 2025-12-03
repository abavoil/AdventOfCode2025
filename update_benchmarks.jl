using BenchmarkTools
using Printf

# --- Configuration ---
README_FILE = "README.md"
DATA_DIR = "data"
MARKER_START = "<!-- BENCHMARK_TABLE_BEGIN -->"
MARKER_END = "<!-- BENCHMARK_TABLE_END -->"

# Files to skip
FILES_TO_EXCLUDE = ["day03_ben.jl"] 

# ---------------------

function get_target_files()
    # Matches "day01.jl", "day02_test.jl", but NOT "day02A.jl"
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

function run_benchmark(filename)
    println("\nProcessing $filename ...")
    
    lines_data = get_data_for_file(filename)
    if isnothing(lines_data)
        return nothing
    end

    mod = Module()
    
    # 1. Silence println
    Core.eval(mod, quote
        println(args...) = nothing
    end)
    
    # 2. Execute the file
    try
        Base.include(mod, filename)
    catch e
        @error "Error loading $filename" exception=e
        return nothing
    end

    # 3. Retrieve 'solve' safely (fix for Julia 1.12+ World Age issues)
    solve_func = try
        Core.eval(mod, :solve)
    catch
        @warn "Function 'solve' not found in $filename"
        return nothing
    end

    # 4. Benchmark
    # Part 1
    print("  -> Benchmarking Part 1... ")
    t1 = try
        b1 = @benchmark Base.invokelatest($solve_func, $lines_data; part1=true)
        minimum(b1.times)
    catch e
        println("Failed: ", e)
        return nothing
    end
    println(BenchmarkTools.prettytime(t1))

    # Part 2
    print("  -> Benchmarking Part 2... ")
    t2 = try
        b2 = @benchmark Base.invokelatest($solve_func, $lines_data; part1=false)
        minimum(b2.times)
    catch e
        println("Failed: ", e)
        return nothing
    end
    println(BenchmarkTools.prettytime(t2))

    return (t1, t2)
end

function format_duration(t_nanos)
    return BenchmarkTools.prettytime(t_nanos)
end

function generate_table(results)
    header = "| File | Part 1 | Part 2 |\n|:---|:---:|:---:|\n"
    rows = map(results) do (file, t1, t2)
        "| `$file` | $(format_duration(t1)) | $(format_duration(t2)) |"
    end
    return header * join(rows, "\n")
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
    results = []

    for file in files
        res = run_benchmark(file)
        if !isnothing(res)
            push!(results, (file, res[1], res[2]))
        end
    end

    if !isempty(results)
        table = generate_table(results)
        update_readme(table)
    else
        println("No results to write.")
    end
end

main()

# ==============================================================================
# SCRIPT HISTORY & ARCHITECTURE SUMMARY
# For future LLMs/Developers improving this code
# ==============================================================================
#
# GOAL:
#   Automatically discover `dayXY.jl` solutions, benchmark their `solve` function
#   against `data/dayXY.txt`, and update a Markdown table in `README.md`.
#
# ARCHITECTURE:
#   1. File Discovery: Uses strict Regex `^day\d{2}(_.*)?\.jl$` to match files 
#      like `day01.jl` or `day03_optimized.jl`, but exclude `day02A.jl`.
#   2. Data Loading: Loads input from `data/dayXY.txt` based on the filename number,
#      ignoring any `lines` variable defined inside the script.
#   3. Isolation: Each script is `include`d into a fresh `Module()` to prevent
#      namespace collisions.
#   4. Output Silencing: `println` is shadowed inside the module to suppress 
#      terminal noise during file loading, while allowing other side effects.
#
# CRITICAL IMPLEMENTATION DETAILS (Do not regress):
#   1. World Age / Julia 1.12+ Compatibility:
#      - We cannot access `mod.solve` directly (e.g., `getfield(mod, :solve)`) 
#        because the function exists in a "newer world" than the runner script.
#      - FIX: Use `solve_func = Core.eval(mod, :solve)` to retrieve the handle 
#        within the module's world.
#      - FIX: Use `Base.invokelatest(solve_func, ...)` to execute it.
#   2. README Updating:
#      - We use string interpolation for the replacement block rather than Regex 
#        backreferences (like `\1`) to avoid artifact injection in the output table.
#   3. Exclusions:
#      - `FILES_TO_EXCLUDE` allows manual skipping of broken/debug files that 
#        match the naming pattern.
#
# CURRENT LIMITATIONS:
#   - Assumes every file defines a function `solve(lines; part1=Bool)`.
#   - Side effects other than `println` (e.g., `display`, `@btime` inside the file)
#     are NOT suppressed and will run during inclusion.
# ==============================================================================