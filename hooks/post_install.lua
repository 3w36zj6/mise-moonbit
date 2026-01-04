-- hooks/post_install.lua
-- Performs additional setup after installation
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version or ctx.runtimeVersion or "latest"

    local function sh_quote(s)
        -- POSIX shell single-quote escaping
        return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
    end

    local function run(cmd, err_msg)
        local code = os.execute(cmd)
        if code ~= 0 then
            error(err_msg .. " (cmd=" .. cmd .. ")")
        end
    end

    local cli_moonbit = os.getenv("CLI_MOONBIT") or "https://cli.moonbitlang.com"
    local bin_dir = path .. "/bin"
    local exe = bin_dir .. "/moon"
    local lib_dir = path .. "/lib"

    -- Make bundled binaries executable
    run("test -d " .. sh_quote(bin_dir) .. "", "bin directory not found after extraction")
    run(
        "find " .. sh_quote(bin_dir) .. " -maxdepth 1 -type f -exec chmod +x {} +",
        "Failed to make moonbit binaries executable"
    )
    -- Make internal/tcc executable if present
    os.execute(
        "test -f " .. sh_quote(bin_dir .. "/internal/tcc") .. " && chmod +x " .. sh_quote(bin_dir .. "/internal/tcc")
    )

    -- Create AGENTS.md symlink if available
    local prompt_md = bin_dir .. "/internal/moon-pilot/lib/prompt/moonbitlang.mbt.md"
    local agents_md = path .. "/AGENTS.md"
    os.execute(
        "test -f "
            .. sh_quote(prompt_md)
            .. " && rm -f "
            .. sh_quote(agents_md)
            .. " && ln -s "
            .. sh_quote(prompt_md)
            .. " "
            .. sh_quote(agents_md)
    )

    -- Download and extract core
    run("mkdir -p " .. sh_quote(lib_dir), "Failed to create lib directory")
    run("rm -rf " .. sh_quote(lib_dir .. "/core"), "Failed to remove existing core")

    local core_uri = cli_moonbit .. "/cores/core-" .. version .. ".tar.gz"
    local core_dest = lib_dir .. "/core.tar.gz"
    run(
        "curl --fail --location --progress-bar --output " .. sh_quote(core_dest) .. " " .. sh_quote(core_uri),
        'Failed to download core from "' .. core_uri .. '"'
    )
    run(
        "tar xf " .. sh_quote(core_dest) .. " --directory=" .. sh_quote(lib_dir),
        'Failed to extract core to "' .. lib_dir .. '"'
    )
    run("rm -f " .. sh_quote(core_dest), "Failed to remove core archive")

    -- Bundle core
    run("test -x " .. sh_quote(exe), "moon executable not found")

    -- Run bundling with PATH set to the installation bin
    local path_env = "PATH=" .. sh_quote(bin_dir)
    local moon_home_env = "MOON_HOME=" .. sh_quote(path)
    local src_dir = sh_quote(lib_dir .. "/core")

    run(
        path_env
            .. " "
            .. moon_home_env
            .. " "
            .. sh_quote(exe)
            .. " bundle --warn-list -a --all --source-dir "
            .. src_dir,
        "Failed to bundle core"
    )

    if version == "nightly" then
        run(
            path_env
                .. " "
                .. moon_home_env
                .. " "
                .. sh_quote(exe)
                .. " bundle --warn-list -a --target llvm --source-dir "
                .. src_dir,
            "Failed to bundle core for llvm backend"
        )
    end

    run(
        path_env
            .. " "
            .. moon_home_env
            .. " "
            .. sh_quote(exe)
            .. " bundle --warn-list -a --target wasm-gc --source-dir "
            .. src_dir
            .. " --quiet",
        "Failed to bundle core to wasm-gc"
    )

    -- Quick smoke test
    local ok = os.execute(sh_quote(exe) .. " version > /dev/null 2>&1")
    if ok ~= 0 then
        error("moon installation appears to be broken")
    end
end
