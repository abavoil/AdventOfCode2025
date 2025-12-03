using BenchmarkTools

function maximum_subnumber(line, out_len)
    a = codeunits(line)
    in_len = length(a)
    
    out = 0
    current_ind = 1
    
    # We build a number with 'out_len' digits
    for remaining in out_len:-1:1
        limit = in_len - remaining + 1
        
        max_val = 0x00
        max_ind = -1
        
        # Scan the window for the largest digit
        @inbounds for i in current_ind:limit
            byte = a[i]
            if byte > max_val
                max_val = byte
                max_ind = i
                if byte == 0x39  # 0x39 is ASCII for '9'. 
                    break
                end
            end
        end
        
        out = out * 10 + (max_val - 0x30)  # 0x30 is ASCII for '0'
        current_ind = max_ind + 1
    end
    
    return out
end

function solve(lines; partA=false)
    len = ifelse(partA, 2, 12)
    total = 0
    for line in lines
        total += maximum_subnumber(line, len)
    end
    return total
end

@test solve(readlines("data/day03_test.txt"); partA=true) == 357
@test solve(readlines("data/day03_test.txt")) == 3121910778619

lines = readlines("data/day03.txt")
@btime solve($lines; partA=true)
@btime solve($lines)
