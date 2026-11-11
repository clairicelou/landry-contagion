# Combine the statistics from all simulations into one csv
# Usage: julia --project=. src/combine_results.jl output stats_file_1 stats_file_2 ...
function main(args)
    output = args[1]
    inputs = args[2:end]

    open(output, "w") do out
        println(out, readlines(inputs[1])[1])
        for path in inputs
            for line in readlines(path)[2:end]
                isempty(strip(line)) || println(out, line)
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
