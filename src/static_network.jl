
using Graphs
using Random # randomly sample degrees and select nodes later

function create_static_network(n)
    # Create a directed graph with n nodes and no edges
    graph = SimpleDiGraph(n)

    return graph
end

function sample_power_law(n, alpha, max_degree)
    # Possible degree values
    degrees = collect(1:max_degree)

    # Calculate the probability weight for each degree
    weights = [1 / k^alpha for k in degrees]

    # Convert weights into probabilities
    probabilities = weights / sum(weights)

    # Sample one degree for each node
    samples = Int[]

    # Sample a degree for each node
    for i in 1:n
        r = rand() # Generate a random number between 0 and 1
        cumulative = 0.0 # Start the cumulative probability at 0
# This loop checks the possible degrees one at a time until it finds which one corresponds to our random number.
        for k in eachindex(degrees)
            cumulative += probabilities[k] # Add the current degree's probability
# Check if the random number falls within this degree's range
            if r < cumulative
                push!(samples, degrees[k])  # Add the selected degree to samples
                break # Stop checking degrees for this node
            end
        end
    end

    return samples # Return the sampled degrees for all nodes
end


# Check basic requirements for directed degree sequences
function valid_degree_totals(kin, kout)
    n = length(kin) # Gets the number of nodes.

    # Each node needs an in-degree and out-degree
    if length(kout) != n # Makes sure every node has both an incoming and outgoing degree
        return false
    end

    # Degrees must be between 0 and n-1
    if any(k -> k < 0 || k >= n, kin) || # Checks whether any degree is negative or too large
       any(k -> k < 0 || k >= n, kout)
        return false
    end

    # Total incoming edges must equal total outgoing edges
    return sum(kin) == sum(kout) 
end


# Randomly pair outgoing and incoming stubs (configuration model)
# Self-loops and duplicate edges are fixed by swapping targets, which keeps the degrees the same
function configuration_model(kin, kout; max_swaps=100 * sum(kout))
    n = length(kin)
    sources = reduce(vcat, [fill(i, kout[i]) for i in 1:n])
    targets = shuffle!(reduce(vcat, [fill(i, kin[i]) for i in 1:n]))
    m = length(sources)

    # Count how many times each edge appears
    counts = Dict{Tuple{Int,Int},Int}()
    for e in 1:m
        counts[(sources[e], targets[e])] = get(counts, (sources[e], targets[e]), 0) + 1
    end
    is_bad(e) = sources[e] == targets[e] || counts[(sources[e], targets[e])] > 1
    is_free(s, t) = s != t && get(counts, (s, t), 0) == 0

    swaps = 0
    for e in 1:m
        while is_bad(e)
            swaps += 1
            swaps > max_swaps && return nothing

            f = rand(1:m)
            s1, t1, s2, t2 = sources[e], targets[e], sources[f], targets[f]
            # Swap targets only if both new edges are valid
            (is_free(s1, t2) && is_free(s2, t1) && (s1, t2) != (s2, t1)) || continue

            counts[(s1, t1)] -= 1
            counts[(s2, t2)] -= 1
            targets[e], targets[f] = t2, t1
            counts[(s1, t2)] = 1
            counts[(s2, t1)] = 1
        end
    end

    graph = create_static_network(n)
    for e in 1:m
        add_edge!(graph, sources[e], targets[e])
    end
    return graph
end


# Generate a static directed network
function generate_network(n, alpha=2.5; verbose=true, max_resamples=10_000)

    for resample in 1:max_resamples

        # randomly generate the in-degree and out-degree for every node in my directed network
        kin = sample_power_law(n, alpha, n - 1)
        kout = sample_power_law(n, alpha, n - 1)

        # Resample if total in-degree and out-degree don't match
        valid_degree_totals(kin, kout) || continue

        # Connect the stubs, resample if it fails
        graph = configuration_model(kin, kout)
        graph === nothing && continue

        if verbose
            println("Degree resamples needed: ", resample)
            println("In-degrees: ", kin)
            println("Out-degrees: ", kout)
            println("Number of edges: ", ne(graph))
        end

        return graph
    end

    error("Could not generate a network with n=$n, alpha=$alpha after $max_resamples degree samples.")
end


# Save the network as an edge list with a source,target header
function save_edgelist(graph, path)
    mkpath(dirname(abspath(path)))
    open(path, "w") do file
        println(file, "source,target")
        for edge in edges(graph)
            println(file, "$(src(edge)),$(dst(edge))")
        end
    end
end


# Usage: julia --project=. src/static_network.jl n alpha seed output_path
# With no arguments it uses n=5, alpha=2.5, seed=42 and writes network_edges.csv
function main(args)
    n = length(args) >= 1 ? parse(Int, args[1]) : 5
    alpha = length(args) >= 2 ? parse(Float64, args[2]) : 2.5
    seed = length(args) >= 3 ? parse(Int, args[3]) : 42
    output = length(args) >= 4 ? args[4] : "network_edges.csv"

    # Seed the global random number generator so the same seed gives the same network
    Random.seed!(seed)

    graph = generate_network(n, alpha; verbose=isempty(args))
    save_edgelist(graph, output)
end

# Only run when this file is run directly, not when it is included
if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
