HEX_TO_BINARY_CONVERSION_TABLE = Dict(
    '0' => "0000",
    '1' => "0001",
    '2' => "0010",
    '3' => "0011",
    '4' => "0100",
    '5' => "0101",
    '6' => "0110",
    '7' => "0111",
    '8' => "1000",
    '9' => "1001",
    'a' => "1010",
    'b' => "1011",
    'c' => "1100",
    'd' => "1101",
    'e' => "1110",
    'f' => "1111"
)

"""
Converts hex to binary to make the difficulty of the hash that much more.
"""
function hex_to_binary(hex_string)
    binary_string = ""
    # Loop through the characters in the Hex
    for char in hex_string
        # Convert the characters and add to string
        binary_string = string(binary_string, HEX_TO_BINARY_CONVERSION_TABLE[char])
    end
    return binary_string
end
