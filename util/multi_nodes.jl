## Creates partner node.

using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--node", "-n"
            help = "Open a partner node. Default when not on local IP."
    end
    return parse_args(s)
end

# Check if --node || -n was passed in.
function check()
    parsed_args = parse_commandline()
    for (arg,val) in parsed_args
        if (arg == "node" || arg == "n")
            return val == "true"
        end
    end
end

partner = check()