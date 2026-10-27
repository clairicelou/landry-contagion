using Graphs
using Random
using Graphs: SimpleEdge



"""
Create using a temporal network with edge targets having uniform probability for each step
Then construct an empty network of only nodes, no edges and keep lists[] to track the nodes and edges
Main() Simulates the edges and ticks based on the parameters below and outputs to the consule
"""

Base.@kwdef struct NetworkParams
    foundation::Symbol = :empty
    n_nodes::Int = 15    
    n_steps::Int = 5
    edges_per_step::Int = 2
    reciprocity::Float64 = 0.0
    popularity::Float64 = 0.0 # Chance a target is picked by in-degree instead of uniformly
    closure::Float64 = 0.0 # Chance an edge closes a triad instead of using the rules below
    seed::Int = 42 # Seed makes the generation non-random
end

struct TemporalNetwork
    snapshots::Vector{SimpleDiGraph}
    step_edges::Vector{Vector{SimpleEdge{Int}}}
    edge_times::Vector{Int}
    params::NetworkParams
end

node_count(net::TemporalNetwork) = nv(net.snapshots[1])
n_ticks(net::TemporalNetwork) = length(net.snapshots)
snapshot_at(net::TemporalNetwork, t::Integer) = net.snapshots[t+1]
edges_at(net::TemporalNetwork, t::Integer) = net.step_edges[t+1]

# Create the Graph
function build_foundation(params::NetworkParams)
    return SimpleDiGraph(params.n_nodes)
end

# Uniform Probability
# TODO: Add weights and determine by Popularity
# TODO: Add triadic closure
# Choose where a new edge from src points, falling back to the next rule when one does not apply
function sample_target(rng::AbstractRNG, graph::AbstractGraph, src::Integer, params::NetworkParams)
    n = nv(graph)

    # Only draw the random number if the rule is on, so default params give the same network as before
    if params.closure > 0 && rand(rng) < params.closure
        dst = sample_closure(rng, graph, src)
        dst != 0 && return dst
    end

    if params.popularity > 0 && rand(rng) < params.popularity
        return sample_popular(rng, graph)
    end

    return rand(rng, 1:n)
end

# Pick an index with probability proportional to its weight
function sample_weighted(rng::AbstractRNG, weights::AbstractVector{<:Real})
    total = sum(weights)
    r = rand(rng) * total
    running = 0.0

    for (i, w) in enumerate(weights)
        running += w
        r <= running && return i
    end

    return length(weights)
end

# Popularity
# Weight is in-degree + 1 so nodes with no followers can still be picked (initial attractiveness)
function sample_popular(rng::AbstractRNG, graph::AbstractGraph)
    weights = [indegree(graph, v) + 1 for v in vertices(graph)]
    return sample_weighted(rng, weights)
end

# Triadic closure
# Pick someone src already follows (f), then pick another follower of f
# Followees with a lot of followers are less likely to be picked, based on L ~ 1/deg(f) from the whiteboard
# Returns 0 if there is no one to close a triad with
function sample_closure(rng::AbstractRNG, graph::AbstractGraph, src::Integer)
    followed = outneighbors(graph, src)
    isempty(followed) && return 0

    # src follows each f, so indegree(f) is at least 1
    weights = [1 / indegree(graph, f) for f in followed]
    f = followed[sample_weighted(rng, weights)]

    candidates = filter(j -> j != src && !has_edge(graph, src, j), inneighbors(graph, f))
    isempty(candidates) && return 0

    return rand(rng, candidates)
end

# Build the network, so that it contains lists to keep the edges 
function build_network(params::NetworkParams; rng::AbstractRNG=Random.default_rng())
    rng = params.seed >= 0 ? Random.MersenneTwister(params.seed) : rng
    foundation = build_foundation(params)
    n = nv(foundation)
    # NEXT WEEK (Nov 4): n is fixed here. Once new nodes are added over time, n needs to grow each tick

    snapshots = SimpleDiGraph[foundation]
    step_edges = Vector{}[]
    edge_times = Dict{}()

    push!(step_edges, collect(SimpleEdge{Int}, edges(foundation)))

    for tick in 1:params.n_steps
        graph = copy(snapshots[end])
        added = SimpleEdge{Int}[]

        # NEXT WEEK (Nov 4): Add new nodes here at each tick (add_vertex!)
        # When a node is created, connect it to already existing nodes using a probability function
        # Add those edges to `added` and `edge_times` the same way as the edges below

        for _ in 1:params.edges_per_step
            src = rand(rng, 1:n)
            dst = sample_target(rng, graph, src, params)

            src == dst && continue
            has_edge(graph, src, dst) && continue

            add_edge!(graph, src, dst)
            push!(added, SimpleEdge(src, dst))
            edge_times[SimpleEdge(src, dst)] = tick

            if rand(rng) < params.reciprocity && !has_edge(graph, dst, src)
                add_edge!(graph, dst, src)
                push!(added, SimpleEdge(dst, src))
                edge_times[SimpleEdge(dst, src)] = tick
            end
        end

        push!(snapshots, graph)
        push!(step_edges, added)
    end

    ordered_times = [get(edge_times, e, 0) for e in edges(snapshots[end])]
    return TemporalNetwork(snapshots, step_edges, ordered_times, params)
end

# Simulation 
function main()
    # Try popularity, closure, and reciprocity, leave them out for the uniform network
    net = build_network(NetworkParams(popularity=0.5, closure=0.3, reciprocity=0.2))
    # println("Network Simulation")

    for tick in 0:(n_ticks(net) - 1)
        graph = snapshot_at(net, tick)
        println("\nTick $tick:")
        println("  Nodes : ", collect(vertices(graph)))
        println("  Edges : ", collect(edges(graph)))
    end
end

main()