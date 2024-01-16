using Base: String
using UUIDs
using PyCall

# include("../blockchain/chain_module.jl")
# include("../util/globals.jl")
# include("../blockchain/blockchain.jl")

# Import python files
pushfirst!(PyVector(pyimport("sys")."path"), "wallet")
cryptography = pyimport("crypto_phy")

"""
An individual wallet for the miner in the system.
Keeps track of the miner's balance. Allows miner to
authorize transactions.
"""
mutable struct Wallet
    blockchain::Blockchain
    address::String
    private_key::PyObject # Comes from Python.
    public_key::String # Comes from Python.

    function Wallet(blockchain=nothing)
        if (blockchain === nothing)
            blockchain = Blockchain()
        end

        address = string(UUIDs.uuid4())[1:8]
        private_key = cryptography.gen_private_key()
        
        # Public key set up
        encrypted_public_key = cryptography.gen_public_key(private_key)
        public_key = cryptography.serialive_public_key(encrypted_public_key)
        
        new(blockchain, address, private_key, public_key)
    end
end

"""
Sign transactions.

...
# Arguments
- `private_key::PyObject` the private key object.
- `data::Any` the data to sign for.

- `return String` the signature
...
"""
function signtransaction(private_key, data)
    return cryptography.sign(private_key, data)
end

"""
Verify a signature based on the ORIGINAL public key AND data.

...
- `public_key::String` The public key object as a string IE deserialized.
- `data::String` The original data.
- `signature::String` The signature? TODO: write this.

- `return Bool` True on valid, False on invalid.
...
"""
function verifysignature(public_key, data, signature)
    return cryptography.verify_singature(public_key, data, signature)
end

"""
Calculate the balance of a given address considering the transaction 
data within the blockchain.

The balance is found by adding the output values that belong to the address,
since the most recent transactions by that address.

...
# Arguments
- `blockchain` the current chain.
- `address` the address of the wallet to calculate.

# Return
- `Int` calculated balance.
...
"""
function calculatebalance(blockchain, address)
    # Set forced balance to be changed'
    balance = STARTING_BALANCE
    
    # Check for blockchain.
    if blockchain === nothing
        return balance
    end

    # Calculate balance
    for block in blockchain.chain
        # Go through transactions of block
        for t in block.data
            # Rebuild transaction
            transaction = transactionfy_json(t)
            # Process transaction
            if transaction.input["address"] == address
                # We got a transaction
                balance = transaction.output[address]
            elseif address in keys(transaction.output)
                # Otherwise add to the balance from the output
                balance += transaction.output[address]
            end
        end
    end

    return balance
end

"""
Quickly calculate the wallet balance.

...
#Arguments
- `wallet::Wallet` the wallet to calculate.

#Return
- `Int` balance.
...
"""
function walletbalance(wallet::Wallet)
    return calculatebalance(wallet.blockchain, wallet.address)
end

# # Time to test
# function main()
#     # Define wallet
#     wallet = Wallet()
#     println("wallet: $wallet")

#     # data = Dict("Astral" => "LOTS_OF_ASTRAL")
#     # signature = cryptography.sign(wallet.private_key, data)
#     # println("signature: $signature")
# # 
#     # valid = cryptography.verify_singature(
#         # cryptography.serialive_public_key(wallet.public_key), 
#         # data, signature
#     # )
#     # println("valid: $valid")
# # 
#     # invalid = cryptography.verify_singature(
#         # cryptography.serialive_public_key(
#             # cryptography.gen_public_key(
#                 # cryptography.gen_private_key()
#             # )
#         # ),
#         # data,
#         # signature
#     # )
#     # println("invalid: $invalid")
# end

# main()