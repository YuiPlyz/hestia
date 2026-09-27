-- HESTIA server services: startup metadata and per-player configuration only.
local http, replicated = game:GetService("HttpService"), game:GetService("ReplicatedStorage")
local players, run = game:GetService("Players"), game:GetService("RunService")
local root = replicated:WaitForChild("HESTIA")
local remote = Instance.new("RemoteFunction")
remote.Name = "HESTIA Config"
remote.Parent = replicated
local store = game:GetService("DataStoreService"):GetDataStore("HESTIA")
local validator, defaults = require(root.src.ConfigValidation), require(root.src.Config)
local last, memory, busy = {}, {}, {}
local function allowed(player)
    return run:IsStudio() or player:GetAttribute("HESTIA_Enabled") == true
end
remote.OnServerInvoke = function(player, action, folder, raw)
    if not allowed(player) then
        return false, "HESTIA permission required"
    end
    if action ~= "Save" and action ~= "Load" then
        return false, "Invalid action"
    end
    if folder ~= "HESTIA/survive-the-apocalypse" then
        return false, "Invalid config namespace"
    end
    local id = player.UserId
    if busy[id] or os.clock() - (last[id] or -math.huge) < 2 then
        return false, "Please wait before another config request"
    end
    last[id], busy[id] = os.clock(), true
    local ok, value = pcall(function()
        if action == "Save" then
            assert(type(raw) == "string" and #raw <= 60000, "Invalid config size")
            local data = http:JSONDecode(raw)
            assert(data.Schema == 1 and type(data.Config) == "table", "Invalid config schema")
            local clean = http:JSONEncode({ Schema = 1, Config = validator.Validate(data.Config, defaults) })
            if run:IsStudio() then
                memory[id] = clean
            else
                store:SetAsync("survive-the-apocalypse/" .. id, clean)
            end
            return "Saved"
        end
        local saved = run:IsStudio() and memory[id]
            or (not run:IsStudio() and store:GetAsync("survive-the-apocalypse/" .. id))
        assert(type(saved) == "string", "No saved HESTIA configuration")
        return saved
    end)
    busy[id] = nil
    return ok, value
end
players.PlayerRemoving:Connect(function(player)
    last[player.UserId], memory[player.UserId], busy[player.UserId] = nil, nil, nil
end)
-- One HTTP request per server startup, never per frame or per player.
local ok, result = pcall(function()
    local raw = http:GetAsync(root:GetAttribute("BaseURL") .. "version.json", true)
    local version = http:JSONDecode(raw)
    assert(version.name == "HESTIA" and type(version.version) == "string", "Invalid HESTIA version data")
    return raw
end)
if ok then
    root:SetAttribute("RemoteVersion", result)
else
    warn("[HESTIA] Startup version request failed; using installation metadata: " .. tostring(result))
end
root:SetAttribute("VersionReady", true)
