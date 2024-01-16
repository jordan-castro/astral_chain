using JSON

# include("transaction.jl")

# include("../blockchain/chain_module.jl")

"""
Holds the `Transaction`s of the `Blockchain`.
"""
mutable struct TransactionPool
    transaction_map::Dict

    function TransactionPool(transaction_map=nothing)
        new(Dict())
    end
end

"""
Add a new `Transaction` in the pool.

...
# Arguments
- `pool::TransactionPool` the pool to recieve the transaction `t`.
- `t::Transaction` the transaction being added to the `pool`.
...
"""
function addtransaction!(pool::TransactionPool, t::Transaction)
    pool.transaction_map[t.id] = t
end

"""
Find a transaction within the pool.

...
# Arguments
- `pool::TransactionPool` the pool being searched.
- `address::String` the address of the transaction being looked for.

# Return 
- `Transaction` the transaction if found.
...
"""
function findtransaction(pool::TransactionPool, address::String)
    for t in values(pool.transaction_map)
        # Check address matches
        if t.input["address"] == address
            return t
        end
    end
end

"""
TransactionPool in Dict form.

...
# Arguments
- `pool::TransactionPool` the pool.

# Return
- `Dict` Dictionary rep.
...
"""
function transactiondata(pool::TransactionPool)
    data = []

    # Loop through transactions in the pool
    for transaction in values(pool.transaction_map)
        # Add the transactions
        push!(data, jsonify_transaction(transaction))
    end
    # Return the pool data
    return data
end

"""
Delete blockchain recorded transactions from the transaction pool.

...
# Arguments
- `pool::TransactionPool` the pool.
- `blockchain::Blockchain` the blockchain to be removed.
...
"""
function clear_blockchain_transactions!(pool::TransactionPool, blockchain::Blockchain)
    # Loop through blocks in chain
    for block in blockchain.chain
        # Here I don't convert to Transaction just use the Dictionary.
        for transaction in block.data
            # Attempt a delete
            try 
                delete!(pool.transaction_map, transaction["id"])
            catch e KeyError
                # Continue the loop
                continue
            end
        end
    end
end

# function main()
#     pool = TransactionPool()
#     blockchain = Blockchain()
#     wallet = Wallet(blockchain)

#     start = get_time()

#     for i in 1:10
#         addtransaction!(pool, rewardtransaction(wallet))

#         addblock!(blockchain.chain, transactiondata(pool))

#         println("latest block added is $(last(blockchain.chain))")

#         clear_blockchain_transactions!(pool, blockchain)
#     end

#     finish = get_time()
#     println("length taken: $((finish - start) / 1000)")

#     print("wallet balance is $(walletbalance(wallet))")
#     # # Add transaction
#     # addtransaction!(pool, rewardtransaction(wallet))
#     # print("Transaction added")

#     # # Add transaction to blockchain block data
#     # addblock!(blockchain.chain, transactiondata(pool))
#     # print("block added")

#     # # Clear transactions
#     # clear_blockchain_transactions!(pool, blockchain)
#     # print("cleared")

#     # addtransaction!(pool, rewardtransaction(Wallet()))
#     # addtransaction!(pool, rewardtransaction(Wallet()))

#     # print("pool_json: $(transactiondata(pool))")

#     # clear_blockchain_transactions!(pool, Blockchain())

#     # print("pool_json: $(transactiondata(pool))")
# end

# main()