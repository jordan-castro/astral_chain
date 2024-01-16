using JSON

# include("block.jl")
# include("../wallet/wallet_module.jl")
include("../util/globals.jl")
# include("../util/test_modules.jl")


"""
Blockchain "object". Holds a chain of `Block`s.

Is `mutable` because the chain changes almost always.
"""
# mutable struct Blockchain 
mutable struct Blockchain
    # A chain is a array || list of blocks
    chain::Array{Block}

    function Blockchain(chain=nothing)
        if (chain === nothing)
            chain = [genesis_block()]
        end
        new(chain)
    end
end

"""
Add a block to the chain. 

    - @param chain the blockchain chain.
    - @param data the data of the new block.
"""
function addblock!(chain, data)
    # Add to the chain the mined_block
    push!(chain, mine_block(last(chain), data))
end

"""
Replaces LOCAL chain with incoming chain if

    - incoming chain is longer than LOCAL.
    - incoming chain is formatted properly.

    - @param local_chain The local Blockchain instance.
    - @param incoming_chain The incoming chain list.
"""
function replacechain!(local_chain::Blockchain, incoming_chain)
    # Check length
    if length(incoming_chain) <= length(local_chain.chain)
        throw("Can not replace chain: Incoming chain must be longer")
    end
    # Validate chain
    try
        isvalid_chain(incoming_chain)
    catch e
        throw("Can not replace chain. The incoming chain is invalid: $e")
    end

    # Change chain
    local_chain.chain = incoming_chain
end

"""
Validate the passed chain.

    - Chain must start with the genesis_block.
    - Blocks must be formatted correctly.

    @param chain -> The chain to validate
    @return nothing
"""
function isvalid_chain(chain)
    # Check that shit is the same
    if string(chain[1]) != string(genesis_block())
        throw("The genesis block must be valid.")
    end
    
    for i in 2:length(chain)
        # Validate each block
        is_valid_block(chain[i - 1], chain[i])
    end

    # Validate transactions in chain
    isvalid_transaction_chain(chain)
end

"""
Enforce the rules of the chain composed of blocks to transactions.

# !!! Important
- throws exception on failure .

# Rules
- Each transaction must only appear once in the chain.
- There can only be one mining reward per block.
- Each transaction must be valid.

...
# Arguments 
- `chain` a blockchains **CHAIN**
...
"""
function isvalid_transaction_chain(chain)
    tran_ids = []

    # Loop through chain
    for i in 1:length(chain)
        block = chain[i]
        # Default value, might change below
        has_mining_reward = false

        for t in block.data
            transaction = transactionfy_json(t)
            # Check if transactoin id is currently already in tran_ids.
            if transaction.id in tran_ids
                throw("Transaction $(transaction.id)")
            end
            # Add transaction id
            push!(tran_ids, transaction.id)

            # Check if transaction is a MINING_REWARD
            if transaction.input == MINING_REWARD_INPUT
                # Check that mining reward has not been activated
                if has_mining_reward == true
                    throw("There can only be one mining reward per block. 
                    Check block with hash $(block.hash)")
                end
                has_mining_reward = true
            else
                # Check historic balance is the same as transaction.input["amount"]
                historic_balance = calculatebalance(
                    Blockchain(chain), 
                    transaction.input["address"]
                )

                if historic_balance != transaction.input["amount"]
                    throw("Transaction $(transactoin.id) has invalid input amount.")
                end
            end

            # Validate transaction
            isvalidtransaction(transaction)
        end
    end
end

"""
Creates JSON rep of blockchain.

    - @param chain The blockchain.
    - @return string
"""
function jsonify_chain(chain::Blockchain)
    return JSON.json(chain.chain)
end

"""
Convert Blockchain JSON into a Blockchain object.

    - @param json The json to convert.
    - @param parsed Is the json already parsed? Defaults to false.
    - @return Blockchain
"""
function blockchainify_json(json, parsed=false)
    if parsed == false
        # Parse json data
        blockchain_data = JSON.parse(json)
    else
        blockchain_data = json
    end
    chain = []

    # Loop through data
    for block in blockchain_data
        push!(chain, blockifyjson(block, true))
    end
    
    # return chain
    return Blockchain(chain)
end

# function main()
#     print("start")
#     chain = Blockchain()
#     wallet = Wallet()

#     new_chain = Blockchain()

#     addblock!(new_chain.chain, rewardtransaction(wallet))

#     replacechain!(chain, new_chain.chain)
#     print("finish")
# end

# main()
