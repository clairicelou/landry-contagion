using Graphs

# Read a cascade tree csv
function load_cascade(path)
    lines = readlines(path)[2:end]
    rows = [parse.(Int, split(line, ",")) for line in lines if !isempty(strip(line))]
    return [r[1] for r in rows], [r[2] for r in rows]
end

# Number of steps from the seed to the deepest node
function cascade_depth(nodes, parents)
    parent_of = Dict(zip(nodes, parents))
    depth = Dict{Int,Int}()
    function get_depth(v)
        haskey(depth, v) && return depth[v]
        d = parent_of[v] == 0 ? 0 : get_depth(parent_of[v]) + 1
        depth[v] = d
        return d
    end
    return maximum(get_depth(v) for v in nodes)
end

# Structural virality: average distance between all pairs of nodes in the tree
function structural_virality(nodes, parents)
    n_infected = length(nodes)
    n_infected <= 1 && return 0.0

    tree = SimpleGraph(maximum(nodes))
    for (v, p) in zip(nodes, parents)
        p != 0 && add_edge!(tree, p, v)
    end

    total = 0
    for u in nodes
        d = gdistances(tree, u)
        total += sum(d[v] for v in nodes)
    end
    return total / (n_infected * (n_infected - 1))
end

# Usage: julia --project=. src/compute_statistics.jl cascade_csv seed output
function main(args)
    cascade_path, seed, output = args[1], args[2], args[3]
    nodes, parents = load_cascade(cascade_path)

    open(output, "w") do file
        println(file, "seed,size,depth,virality")
        println(file, "$seed,$(length(nodes)),$(cascade_depth(nodes, parents)),$(structural_virality(nodes, parents))")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
