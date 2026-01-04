-- hooks/pre_install.lua
-- Returns download information for a specific version
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook

---@diagnostic disable: undefined-global
-- luacheck: globals RUNTIME

function PLUGIN:PreInstall(ctx)
    local http = require("http")

    local function url_escape_version(v)
        -- Convert '+' to '%2B' (same behavior as the official install script)
        return (v:gsub("+", "%%2B"))
    end

    local function get_target()
        -- The upstream script checks `uname -ms`, while in mise/vfox we use the injected `RUNTIME` object
        local os_name = (RUNTIME.osType or ""):lower()
        local arch = RUNTIME.archType

        if os_name == "darwin" and arch == "arm64" then
            return "darwin-aarch64"
        end
        if os_name == "darwin" and arch == "amd64" then
            return "darwin-x86_64"
        end
        if os_name == "linux" and arch == "amd64" then
            return "linux-x86_64"
        end

        error("Unsupported platform: " .. tostring(RUNTIME.osType) .. " " .. tostring(RUNTIME.archType))
    end

    local cli_moonbit = os.getenv("CLI_MOONBIT") or "https://cli.moonbitlang.com"
    local version = ctx.version or os.getenv("MOONBIT_INSTALL_VERSION") or "latest"
    local target = get_target()

    if os.getenv("MOONBIT_INSTALL_DEV") ~= nil and os.getenv("MOONBIT_INSTALL_DEV") ~= "" then
        target = target .. "-dev"
    end

    local escaped_version = url_escape_version(version)
    local url = cli_moonbit .. "/binaries/" .. escaped_version .. "/moonbit-" .. target .. ".tar.gz"

    local sha256
    local sha_url = url .. ".sha256"
    local resp, err = http.get({ url = sha_url })
    if err == nil and resp ~= nil and resp.status_code == 200 and resp.body ~= nil then
        sha256 = (resp.body:match("^%s*([0-9a-fA-F]+)%s"))
    end

    return {
        version = version,
        url = url,
        sha256 = sha256,
        note = "Downloading moonbit " .. version,
    }
end

-- Helper function for platform detection (uncomment and modify as needed)
--[[
local function get_platform()
    -- RUNTIME object is provided by mise/vfox
    -- RUNTIME.osType: "Windows", "Linux", "Darwin"
    -- RUNTIME.archType: "amd64", "386", "arm64", etc.

    local os_name = RUNTIME.osType:lower()
    local arch = RUNTIME.archType

    -- Map to your tool's platform naming convention
    -- Adjust these mappings based on how your tool names its releases
    local platform_map = {
        ["darwin"] = {
            ["amd64"] = "darwin-amd64",
            ["arm64"] = "darwin-arm64",
        },
        ["linux"] = {
            ["amd64"] = "linux-amd64",
            ["arm64"] = "linux-arm64",
            ["386"] = "linux-386",
        },
        ["windows"] = {
            ["amd64"] = "windows-amd64",
            ["386"] = "windows-386",
        }
    }

    local os_map = platform_map[os_name]
    if os_map then
        return os_map[arch] or "linux-amd64"  -- fallback
    end

    -- Default fallback
    return "linux-amd64"
end
--]]
