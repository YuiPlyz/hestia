local Installer = {}
function Installer.Install(repository)
    local http = game:GetService("HttpService")
    local base = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/",
        repository.Owner,
        repository.Name,
        repository.Channel
    )
    local directory = (repository.Directory or ""):gsub("^/+", ""):gsub("/+$", "")
    assert(
        not directory:find("..", 1, true) and (directory == "" or directory:match("^[%w_/%-]+$")),
        "HESTIA invalid repository directory"
    )
    if directory ~= "" then
        base = base .. directory .. "/"
    end
    local cache = {}
    local function fetch(path)
        if cache[path] then
            return cache[path]
        end
        assert(
            type(path) == "string"
                and not path:find("..", 1, true)
                and not path:match("^/")
                and path:match("^[%w_./%-]+$"),
            "HESTIA invalid path"
        )
        local reason
        for attempt = 1, 3 do
            local ok, result = pcall(http.GetAsync, http, base .. path, true)
            if ok and #result > 0 then
                cache[path] = result
                return result
            end
            reason = result
            warn(string.format("[HESTIA] Retry %d/3: %s (%s)", attempt, tostring(path), tostring(reason)))
            if attempt < 3 then
                task.wait(attempt)
            end
        end
        error("HESTIA failed to download " .. path .. ": " .. tostring(reason))
    end
    local manifestRaw = fetch("manifest.json")
    local manifest = http:JSONDecode(manifestRaw)
    assert(manifest.name == "HESTIA" and type(manifest.modules) == "table", "HESTIA invalid manifest")
    local marks = {}
    local function validate(name)
        assert(manifest.modules[name], "HESTIA missing dependency: " .. name)
        assert(marks[name] ~= "loading", "HESTIA dependency cycle: " .. name)
        if marks[name] == "done" then
            return
        end
        marks[name] = "loading"
        for _, dependency in ipairs(manifest.modules[name].dependencies or {}) do
            validate(dependency)
        end
        marks[name] = "done"
    end
    for name in pairs(manifest.modules) do
        validate(name)
    end
    local staging = Instance.new("Folder")
    staging.Name = "HESTIA"
    local client, server, demo
    local ok, err = xpcall(function()
        staging:SetAttribute("Manifest", manifestRaw)
        staging:SetAttribute("BaseURL", base)
        staging:SetAttribute("Channel", repository.Channel)
        staging:SetAttribute("VersionReady", false)
        local versionOk, version = pcall(fetch, "version.json")
        if versionOk then
            staging:SetAttribute("RemoteVersion", version)
        end
        local paths = {}
        for name, entry in pairs(manifest.modules) do
            assert(not paths[entry.path], "HESTIA duplicate module path: " .. entry.path)
            paths[entry.path] = true
            local success, source = pcall(fetch, entry.path)
            if not success and not entry.optional then
                error(source)
            end
            if success then
                local parent, segments = staging, string.split(entry.path, "/")
                for i = 1, #segments - 1 do
                    local folder = parent:FindFirstChild(segments[i])
                    if not folder then
                        folder = Instance.new("Folder")
                        folder.Name = segments[i]
                        folder.Parent = parent
                    end
                    parent = folder
                end
                local module = Instance.new("ModuleScript")
                module.Name = segments[#segments]:gsub("%.lua$", "")
                module.Source = source
                module.Parent = parent
                print("[HESTIA] Installed " .. name)
            else
                warn("[HESTIA] Optional module unavailable: " .. name .. "\n" .. tostring(source))
            end
        end
        client = Instance.new("LocalScript")
        client.Name = "HESTIA Client"
        client.Source = fetch(manifest.entrypoints.client)
        server = Instance.new("Script")
        server.Name = "HESTIA Server"
        server.Source = fetch(manifest.entrypoints.server)
        if repository.InstallDemo then
            staging.src.Hooks.Source = fetch("examples/DemoHooks.lua")
            demo = Instance.new("Script")
            demo.Name = "HESTIA Demo"
            demo.Source = fetch("examples/Demo.server.lua")
        end
    end, debug.traceback)
    if not ok then
        staging:Destroy()
        if client then
            client:Destroy()
        end
        if server then
            server:Destroy()
        end
        if demo then
            demo:Destroy()
        end
        error(err)
    end
    -- Download and validate the whole package before touching an existing installation.
    local targets = {
        { game:GetService("ReplicatedStorage"), staging },
        { game:GetService("StarterPlayer").StarterPlayerScripts, client },
        { game:GetService("ServerScriptService"), server },
    }
    for _, pair in ipairs(targets) do
        local previous = pair[1]:FindFirstChild(pair[2].Name)
        if previous then
            previous:Destroy()
        end
        pair[2].Parent = pair[1]
    end
    local priorDemo = game:GetService("ServerScriptService"):FindFirstChild("HESTIA Demo")
    if priorDemo then
        priorDemo:Destroy()
    end
    if demo then
        demo.Parent = game:GetService("ServerScriptService")
    end
    return staging
end
return Installer
