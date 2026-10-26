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
function sample_target(rng::AbstractRNG, graph::AbstractGraph, params::NetworkParams)
    n = nv(graph)
    return rand(rng, 1:n)
end

# Build the network, so that it contains lists to keep the edges 
function build_network(params::NetworkParams; rng::AbstractRNG=Random.default_rng())
    rng = params.seed >= 0 ? Random.MersenneTwister(params.seed) : rng
    foundation = build_foundation(params)
    n = nv(foundation)

    snapshots = SimpleDiGraph[foundation]
    step_edges = Vector{}[]
    edge_times = Dict{}()

    push!(step_edges, collect(SimpleEdge{Int}, edges(foundation)))

    for tick in 1:params.n_steps
        graph = copy(snapshots[end])
        added = SimpleEdge{Int}[]

        for _ in 1:params.edges_per_step
            src = rand(rng, 1:n)
            dst = sample_target(rng, graph, params)

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
    net = build_network(NetworkParams())
    # println("Network Simulation")

    for tick in 0:(n_ticks(net) - 1)
        graph = snapshot_at(net, tick)
        println("\nTick $tick:")
        println("  Nodes : ", collect(vertices(graph)))
        println("  Edges : ", collect(edges(graph)))
    end
end

main()