## Sync nodes data

using HTTP

# include("nodes.jl")
# include("../util/globals.jl")
# include("../blockchain/chain_module.jl")

"""
Sync all the nodes chains on the network.

    - @param chain The new valid chain.
"""
function synchchains(chain)
    # Loop through nodes
    for node in nodes
        # No need to update root node
        if node != ROOT_NODE
            # Sometimes the request dosent go through. The node could have been killed
            try
                HTTP.request("POST", "http://localhost:$node/nodes/resolve", ["Content-Type" => "application/json"], jsonify_chain(chain))
            catch e
                println("$e")
                # If error is connection refused then drop that node
                if e === IOError
                    deleteat!(nodes, first(node))
                end
            end
        end
    end
end

"""
Send Sync request to ROOT_NODE.
Only the ROOT_NODE can send chains to other nodes.
All other nodes have to send there chain to the ROOT_NODE to be 
checked for replacement.

    - @param chain The chain to resolve.
"""
function sendsyncrequest(chain)
    # Send request to ROOT_NODE
    HTTP.request("POST", "http://localhost:$ROOT_NODE/nodes/resolve", ["Content-Type" => "application/json"], jsonify_chain(chain))
end

"""
Get a chain at the passed port.

    - @param port The port to grab the chain at.
    - @return Blockchain
"""
function getchain(port)
    response = HTTP.request("GET", "http://localhost:$port/blockchain")
    # Convert body to string
    response_body = String(UInt8.(response.body))

    # return blockchain
    return blockchainify_json(response_body) 
end

"""
Update the `nodes` list.
"""
function updatenodes!()
    # Grab nodes from ROOT_NODE
    response = HTTP.request("GET", "http://localhost:$ROOT_NODE/nodes")
    # Convert body to string
    response_body = String(UInt8.(response.body))

    convertjsontolist(response_body)
end