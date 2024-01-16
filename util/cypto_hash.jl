"""
Create the block hash. Pass in a array of data. Returns a hash.
"""
function crypto_hash(last_hash, data, difficulty, nonce, timestamp)
    args = [last_hash, data, difficulty, nonce, timestamp]

    stringified_args = string(args)
    hash = bytes2hex(sha256(stringified_args))
    return string(hash)
end