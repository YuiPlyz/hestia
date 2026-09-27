-- HESTIA Studio installer. Paste this file into the Command Bar in Edit mode.
local Repository = { Owner = "YuiPlyz", Name = "hestia", Channel = "main", InstallDemo = false }
local HttpService = game:GetService("HttpService")
assert(
    game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),
    "HESTIA installer requires Studio Edit mode"
)
assert(
    Repository.Channel == "main" or Repository.Channel == "beta" or Repository.Channel == "dev",
    "HESTIA invalid channel"
)
local base = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    Repository.Owner,
    Repository.Name,
    Repository.Channel
)
local source, reason
for attempt = 1, 3 do
    local ok, result = pcall(HttpService.GetAsync, HttpService, base .. "src/Installer.lua", true)
    if ok then
        source = result
        break
    end
    reason = result
    if attempt < 3 then
        task.wait(attempt)
    end
end
assert(source, "HESTIA installer download failed: " .. tostring(reason))
local bootstrap = Instance.new("ModuleScript")
bootstrap.Name = "HESTIA Installer"
bootstrap.Source = source
bootstrap.Parent = game:GetService("ServerStorage")
local ok, result = xpcall(function()
    return require(bootstrap).Install(Repository)
end, debug.traceback)
bootstrap:Destroy()
assert(ok, "HESTIA installation failed: " .. tostring(result))
print("[HESTIA] Installed. Start a Play test to launch HESTIA.")
