using Graphs
using CSV
using Graphs
"""
Terminal Command: 
using Pkg
Pkg.add(["CSV", "DataFrames", "Graphs"])
"""

# Graph Sample taken from https://arxiv.org/pdf/1312.097
edges = CSV.read("graph_sample.csv", DataFrame)

nodes = CSV.read("node_states_sample.csv", DataFrame)

# Build a sample graph
graph = SimpleDiGraph(nrow(nodes))
for row in eachrow(edges)
    add_edge!(graph, row.source, row.target)
end

function contagion(graph, kernel, node_states)
    # Go through every node in the graph
    for node in vertices(graph)
        for neighbor in neighbors(graph, node)
            if node_states[neighbor] == 1
                if kernel()
                    new_states[node] = 1
                end
            end
        end
    end
    return new_states
end

# # Run the file 
# function main()
#     local_node_states = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
#     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

#     for i in 1:20
#         local_node_states = contagion(
#             graph,
#             kernel,
#             local_node_states
#         )
#     end

#     println(local_node_states)
# end

  for i in 1:20
        nodes_df.state = contagion(
            graph,
            kernel,
            nodes_df.state
        )
    end
println(nodes_df.state)