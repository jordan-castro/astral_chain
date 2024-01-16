# How many seconds a new block should be mined at.
MINE_RATE = 4

# The root node
ROOT_NODE = 8081

# Wallet starting balance TODO: change to 0.
STARTING_BALANCE = 1000

# Mining reward
MINING_REWARD = 50
MINING_REWARD_INPUT = Dict{String, Any}("address" => "*--ASTRAL-mining-reward--*")


"""
Grab the current time since epoch in milliseconds.
"""
function get_time()
    return round(Int64, time() * 1000)
end