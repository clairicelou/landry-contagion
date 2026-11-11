using Graphs
using Random

include("contagion.jl")

# Read an edge list csv into a directed graph
function load_edgelist(path)
    lines = readlines(path)[2:end]
    pairs = [parse.(Int, split(line, ",")) for line in lines if !isempty(strip(line))]
    graph = SimpleDiGraph(maximum(maximum.(pairs)))
    for (s, t) in pairs
        add_edge!(graph, s, t)
    end
    return graph
end

# Infection probability based on the number of infected neighbors
function make_kernel(name, p, threshold)
    if name == "simple"
        return k -> 1 - (1 - p)^k             # each infected neighbor can infect
    elseif name == "complex"
        return k -> k >= threshold ? p : 0.0  # needs at least `threshold` infected neighbors
    else
        error("Unknown kernel: $name (use simple or complex)")
    end
end

# Usage: julia --project=. src/run_simulation.jl edgelist kernel p threshold steps seed output
function main(args)
    edgelist, kernel_name = args[1], args[2]
    p = parse(Float64, args[3])
    threshold = parse(Int, args[4])
    steps = parse(Int, args[5])
    seed = parse(Int, args[6])
    output = args[7]

    rng = MersenneTwister(seed)
    graph = load_edgelist(edgelist)
    kernel = make_kernel(kernel_name, p, threshold)

    seed_node = rand(rng, 1:nv(graph))
    parents, infection_step = run_cascade(graph, kernel, seed_node, steps; rng=rng)

    # Save the cascade tree, one row per infected node
    open(output, "w") do file
        println(file, "node,parent,step")
        for node in vertices(graph)
            infection_step[node] >= 0 && println(file, "$node,$(parents[node]),$(infection_step[node])")
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
