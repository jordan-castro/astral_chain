using Base:number_from_hex
using SHA
using JSON

# include("../util/globals.jl")
# include("blockchain.jl")
# include("../wallet/wallet_module.jl")

include("../util/cypto_hash.jl")
include("../util/hex_to_binary.jl")

"""
Block: a unit of storage.
Store transactions in a blockchain that supports a cryptocurrency.
"""
struct Block
    last_hash::String
    data::Array
    difficulty::Int64
    nonce::Int64
    timestamp::Int64
    hash::String

    # Constructor
    function Block(last_hash, data, difficulty, nonce, timestamp=nothing, hash=nothing)
        if (timestamp === nothing)
            timestamp = get_time()
        end
        if (hash === nothing)
            hash = crypto_hash(last_hash, data, difficulty, nonce, timestamp)
        end

        new(last_hash, data, difficulty, nonce, timestamp, hash)
    end
end

"""
Create a new block. Will return block once proof of work requirement is met.
```
last_block: The previous block in the chain,
data: The data for the new block.
```
"""
function mine_block(last_block::Block, data)
    # Create new block info
    timestamp = get_time()
    last_hash = last_block.hash
    difficulty = adjust_difficulty(last_block, timestamp)
    nonce = 0
    hash = crypto_hash(last_hash, data, difficulty, nonce, timestamp)

    # Loop until the leading 0's requirement is met.
    # AKA loop while leading 0's requirement is not met.
    while hex_to_binary(hash)[1:difficulty] != "0" ^ difficulty
        nonce += 1
        # Grab the current timestamp
        timestamp = get_time()
        # Regen difficulty
        difficulty = adjust_difficulty(last_block, timestamp)
        # Regen hash
        hash = crypto_hash(last_hash, data, difficulty, nonce, timestamp)
        # Some quick nigger shit just incase we get an infinite Loop
    end

    return Block(last_hash, data, difficulty, nonce, timestamp, hash)
end

"""
Calculate the difficulty according to the `MINE_RATE`.
Increase the difficulty for quickly mined blocks.
Decrease the difficulty for slowly mined blocks.
```
Params => 
    last_block => the last Block.
    new_timestamp => the most recent time_stamp

Return Int64. Adjusted difficulty
```
"""
function adjust_difficulty(last_block::Block, new_timestamp)
    # If the rate is too fast add one
    if ((new_timestamp - last_block.timestamp) / 1000) < MINE_RATE
        return last_block.difficulty + 1
    end

    # Subtract one if and only if the last_block.difficulty - 1 is greater than 1
    if (last_block.difficulty - 1) > 1
        return last_block.difficulty - 1
    end

    # Default difficulty 
    return 1
end

"""
Grab the genesis block anywhere within the project.
Returns a `Block`
"""
function genesis_block()
    return Block("genesis_last_hash", [], 3, 1, 0, "gen_hash")
end

"""
Checks if the block is valid.

    - The block.last_hash must equal the last_block.hash.
    - The block must meet the proof of requirement. AKA number of zeros.
    - The difficulty must only adjust by one.
    - block hash must have a valid combination of block fields.

    @param last_block The last block.
    @param block The block being validated.
"""
function is_valid_block(last_block::Block, block::Block)
    # Check last hash with last_block hash
    if block.last_hash != last_block.hash
        throw("Last hash is not same.")
    end
    # Check proof of requirement met
    if hex_to_binary(block.hash)[1:block.difficulty] != "0" ^ block.difficulty
        throw("Proof of requirement not met.") 
    end
    # Check difficulty only changed by one
    if abs(last_block.difficulty - block.difficulty) > 1
        throw("Difficulty can only be adjusted by one.")
    end
    # Reconstruct hash
    recon_hash = crypto_hash(
        block.last_hash, 
        block.data, 
        block.difficulty, 
        block.nonce, 
        block.timestamp
    )

    # Checking hash is not corrupted
    if block.hash != recon_hash
        throw("Hash has been corrupted.")
    end
end

"""
Converts block to JSON representation.

    - @param block The Block to JSONify
    - @retrun string
"""
function jsonify_block(block::Block)
    return JSON.json(values(block))
end

"""
Converts JSON to block representation.

    - @param json The json to Blockify.
    - @param parsed If the json is already parsed. Default is false.
    - @return Block
"""
function blockifyjson(json, parsed=false)
    if (parsed == false)
        block_data = JSON.parse(json)
    else
        block_data = json
    end

    return Block(
        block_data["last_hash"],
        block_data["data"],
        block_data["difficulty"],
        block_data["nonce"],
        block_data["timestamp"],
        block_data["hash"]
    )
end

# function main()
#     chain = Blockchain()
# end

# main()