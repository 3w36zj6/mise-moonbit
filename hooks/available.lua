-- hooks/available.lua
-- Returns a list of available versions for the tool
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook

function PLUGIN:Available(ctx)
    -- MoonBit official distributions are hosted at cli.moonbitlang.com.
    -- The service provides "latest" and "nightly", so this plugin exposes those two options.
    -- To install a specific release, run `mise install moonbit@<VERSION>`.
    return {
        { version = "latest", note = "latest" },
        { version = "nightly", note = "nightly" },
    }
end
