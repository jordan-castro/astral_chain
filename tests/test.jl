include("../blockchain/chain_module.jl")
include("../wallet/wallet_module.jl")

function main()
    println("start")
    pool = TransactionPool()
    chain = Blockchain()
    wallet = Wallet()

    new_chain = Blockchain()
    
    addtransaction!(pool, rewardtransaction(wallet))

    addblock!(new_chain.chain, transactiondata(pool))

    clear_blockchain_transactions!(pool, chain)

    json_chain = blockchainify_json(jsonify_chain(new_chain))

    replacechain!(chain, json_chain.chain)

    # println(jsonify_chain(chain))

    println("finish")
end

main()
