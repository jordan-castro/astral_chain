## Api script.

using Base: IOError
using Core:println

using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests

include("../util/globals.jl")
include("../util/multi_nodes.jl")
include("nodes.jl")
include("synch.jl") 

include("../blockchain/chain_module.jl")
# Module calls
include("../wallet/wallet_module.jl")

# Set up the node
port = ROOT_NODE

# TransactionPool
pool = TransactionPool()

# Miner wallet
wallet = Wallet()

# If partner `from multi_nodes.jl` then use a different root. Currently only allowing 1000
if partner
    port = rand(ROOT_NODE:ROOT_NODE + 1000)
    # Create blockchain from ROOT_NODE
    blockchain = getchain(ROOT_NODE)
else
    # We are at the root node
    blockchain = Blockchain()
    registerNode(ROOT_NODE)
end

# Add blockchain to wallet
wallet.blockchain = blockchain
route("/") do
    "Welcome to the Astral Blockchain implemented in Julia."
end

# To see the current chain.
route("/blockchain") do 
    # print(jsonify_chain(blockchain.chain))
    Genie.Renderer.Json.json(blockchain.chain)
end

# For mining.
route("/blockchain/mine") do
    # Add transaction
    addtransaction!(pool, rewardtransaction(wallet))

    # Add transaction to blockchain block data
    addblock!(blockchain.chain, transactiondata(pool))

    # Clear transactions
    clear_blockchain_transactions!(pool, blockchain)

    # Send sync request as async to not block up the server.
    @async sendsyncrequest(blockchain)

    # Return the mined block as json
    Genie.Renderer.Json.json(last(blockchain.chain))
end

# The route for list of nodes
route("/nodes") do
    # A json representation of nodes
    jsonify_nodes()
end

# Add node to list of registeredNodes
route("/nodes/register", method=POST) do
    # Grab json pay load
    data = jsonpayload()["port"]

    if data !== nothing
        registerNode(data)

        # Display the message
        JSON.json(
            Dict(
                "message" => "New nodes have been added for port $data",
                "total_nodes" => length(nodes)
            )
        )
    else
        "Please input a valid node."
    end
end

# Resolve the blockchain conflicts, I.E. which is the valid chain.
route("/nodes/resolve", method=POST) do
    # Grab blockchain data
    data = jsonpayload()
    # Try and replace chain
    try
        replacechain!(blockchain, blockchainify_json(data, true).chain)

        # Only if the port is ROOT_NODE
        if port == ROOT_NODE
            # When replaced go ahead and synchronize the other chains of nodes.
            synchchains(blockchain)
        end
        println("Chain successfully replaced")
        ""
    catch e
        println("$e")
        ""
    end
end

# Create new transactions
route("wallet/transact", method=POST) do 
    # Grab data
    data = jsonpayload()
    # Look for a transaction
    transaction = findtransaction(pool, wallet.address)

    if transaction !== nothing
        updatetransaction!(
            transaction, 
            wallet,
            data["recipient"], 
            data["amount"]
        )
    else
        transaction = Transaction(
            sender_wallet=wallet, 
            recipient=data["recipient"], 
            amount=data["amount"]
        )
    end

    # Add to the pool
    addtransaction!(pool, transaction)

    # Print the transaction JSON
    Genie.Renderer.Json.json(transaction)
end

# The wallet info route
route("wallet/info") do
    # Just output the wallet data
    Genie.Renderer.Json.json(
        Dict(
            "address" => wallet.address,
            "balance" => walletbalance(wallet)
        )
    ) 
end

# Start application
Genie.AppServer.startup(async=false, port=port)