# The script to add or remove nodes.

nodes = []

"""
Register a new node to our list of nodes. Checks if node already exists.

    - @param port The port of the new node.
    - @return true on successfully added or false for already exists.
"""
function registerNode(port) # TODO: start new node.
    # Check if node already exists
    if port in nodes
        return false
    else
        # Add node
        push!(nodes, port)
        return true
    end
end

"""
Create JSON representation of nodes.

    - @return Dict of nodes.
"""
function jsonify_nodes()
    return JSON.json(nodes)
end

"""
Convert JSON data to list of nodes and adds them to the nodes.

    - @param nodes_json The nodes JSON
    - @return nothing.
"""
function convertjsontolist(nodes_json)
    # Parse JSON
    parsed = JSON.parse(nodes_json)

    for node in parsed
        push!(nodes, node)
    end
end