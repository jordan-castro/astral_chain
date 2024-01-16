using Core: println
## File handles single transaction methods.
## Not to be confused with transactoin_pool.jl

using UUIDs
using JSON

# include("wallet.jl")
# include("../util/globals.jl")

"""
A "document" for a currency exchange from a `sender_wallet` to 
one or more `recipient`s.

...
# Important
- `Transaction` must be built using named arguments.
...
"""
mutable struct Transaction
    sender_wallet # Can be nothing
    recipient # Can be nothing
    amount::Int
    id::String
    output::Dict
    input::Dict

    function Transaction(;
        sender_wallet=nothing,
        recipient=nothing,
        amount=nothing,
        id=nothing,
        output=nothing,
        input=nothing
    )
        # Set up ID
        id = (id === nothing) ? string(UUIDs.uuid4())[1:8] : id
        
        # Setup output
        output = (output === nothing) ?  transaction_output(
            sender_wallet,
            recipient,
            amount
        ) : output

        # Setup input
        input = (input === nothing) ? transaction_input(
            sender_wallet,
            output
        ) : input
        
        # Create new transaction
        new(sender_wallet, recipient, amount, id, output, input)
    end
end

## Transaction methods

"""
Generate the output of the `Transaction`.

...
# Arguments
- `sender_wallet::Wallet`: the wallet where the transaction is coming from.
- `recipient::String`: the address of the recipient wallet.
- `amount::Int`: the amount being sent.
- `return Dict` the output.
...
"""
function transaction_output(sender_wallet::Wallet, recipient, amount)
    # Grab wallet amount
    balance = walletbalance(sender_wallet)

    # Check that the sender_wallet has the currect amout that they want to send.
    if amount > balance
        throw("Amount exceeds balance")
    end

    # Create output
    return Dict{String, Any}(
        recipient => amount,
        sender_wallet.address => balance - amount 
    )
end

"""
Generate the input of the `Transaction`.

...
#Arguments
- `sender_wallet::Wallet` the wallet where the transaction comes from.
- `output::Dict` the transaction output.
- `return Dict` the input.
...
"""
function transaction_input(sender_wallet::Wallet, output)
    return Dict{String, Any}(
        "timestamp" => get_time(),
        "amount" => walletbalance(sender_wallet),
        "address" => sender_wallet.address,
        "public_key" => sender_wallet.public_key,
        "signature" => signtransaction(sender_wallet.private_key, output)
    )
end

"""
Update a transaction with for existing recipient. TODO allow new recipient.

...
# Arguments
- `transaction::Transaction` the transaction to update.
- `sender_wallet::Wallet` the wallet that is sending to `recipient`.
- `recipient::String` the address recieving the `amount` from `sender_wallet`.
- `amount::Int` the amount going to `recipient` from `sender_wallet`.
...
"""
function updatetransaction!(transaction::Transaction, sender_wallet::Wallet, recipient, amount)
    # Check that sender wallet is in transaction.output
    if haskey(transaction.output, sender_wallet.address)
        # Check that the `sender_wallet` can actually send the `amount`.
        if amount > transaction.output[sender_wallet.address]
            throw("Amout exceeds balance.")
        end
    else
        # Addrss does not exist
        throw("Address $(sender_wallet.address) does not exist.")
    end

    # Check if `recipient` is already in the `transaction` output.
    if recipient in keys(transaction.output)
        # Just add the amount
        transaction.output[recipient] += amount
    else
        # Handle new recipient
        transaction.output[recipient] = amount
    end

    # Update sender_wallet amount
    transaction.output[sender_wallet.address] -= amount

    # Recreate input
    transaction.input = transaction_input(sender_wallet, transaction.output)
end

"""
Convert `Transaction` to DICT for API and readibility.

...
# Arguments
- `transaction::Transaction` the transaction to convert to DICT.

# Return
- `DICT` data.
...
"""
function jsonify_transaction(transaction::Transaction)
    return Dict{String, Any}(
        "sender_wallet" => transaction.sender_wallet !== nothing ? Dict(
            "address" => transaction.sender_wallet.address,
        ) : nothing,
        "recipient" => transaction.recipient,
        "amount" => transaction.amount,
        "id" => transaction.id,
        "output" => transaction.output,
        "input" => transaction.input,
    )
end

"""
Convert JSON or DICT to `Transaction`.

...
# Arguments
- `json::String||DICT` the json representation as a String or the `Transaction` as a `Dict`.
- `is_json::Bool` wheter or not the `json` argument is actual JSON. False by default.

# Return
- `Transaction` transaction from json
...
"""
function transactionfy_json(json, is_json=false)
    if (is_json)
        # Parse json
        json = JSON.parse(json)
    end

    return Transaction(
        # recipient=data["recipient"],
        amount=json["amount"],
        id=json["id"],
        output=json["output"],
        input=json["input"]
    )
end

"""
Validate a transaction. Throws exception for invalid transaction.

...
# Arguments
- `transaction::Transaction` the transaction being validated.
...
"""
function isvalidtransaction(t::Transaction)
    # Check is mining reward
    if t.input == MINING_REWARD_INPUT
        # Check the value is MINING_REWARD
        if first(values(t.output)) != MINING_REWARD
            throw("Invalid mining reward.")
        end
        # End the function here
        return
    end

    # Grab total output
    output_total = sum(values(t.output))

    if t.input["amount"] != output_total
        throw("Invalid transaction output values.")
    end

    # Verify wallet
    if !verifysignature(t.input["public_key"], t.output, t.input["signature"],)
        throw("Invalid signature.")
    end
end

"""
Reward a miner.

...
# Arguments
- `miner_wallet` the miners wallet to be rewarded.
...
"""
function rewardtransaction(miner_wallet::Wallet)
    output = Dict{String, Any}()
    output[miner_wallet.address] = MINING_REWARD

    return Transaction(amount=MINING_REWARD, input=MINING_REWARD_INPUT, output=output)
end

# function main()
#     ### Test performance
#     # println("start")
#     # start = get_time()

#     # t = Transaction(sender_wallet=Wallet(), recipient="recipient", amount=100)
    
#     # println("finished")
#     # finished = get_time()

#     # println("Time taken is $((finished - start) / 1000)")

#     ### Test isvalidtransaction
#     # t = Transaction(sender_wallet=Wallet(), recipient="recipient", amount=100)
#     # t = rewardtransaction(Wallet())
#     # try
#     #     isvalidtransaction(t)
#     #     println("Valid")
#     # catch e
#     #     println(e)
#     # end

#     ### Test updatetransaction
#     # try
#         # updatetransaction!(t, Wallet(), "recipient", 100)
#     # catch e
#         # println(e)
#     # end
#     # println("\nt as json: $(jsonify_transaction(t))")

#     # # Restore 
#     # restored_t = transactionfy_json(jsonify_transaction(t))
#     # println("\nrestored_t: $(restored_t)")
# end

# main()