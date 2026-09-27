local replicated = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local root = replicated:WaitForChild("HESTIA", 20)
assert(root, "HESTIA package missing")
local player = players.LocalPlayer
if not game:GetService("RunService"):IsStudio() and player:GetAttribute("HESTIA_Enabled") ~= true then
    local deadline = os.clock() + 15
    repeat
        task.wait(0.2)
    until player:GetAttribute("HESTIA_Enabled") == true or os.clock() > deadline
    if player:GetAttribute("HESTIA_Enabled") ~= true then
        return
    end
end
local deadline = os.clock() + 12
repeat
    task.wait(0.1)
until root:GetAttribute("VersionReady") or os.clock() > deadline
local hooks = table.clone(require(root.src.Hooks))
local remote = replicated:WaitForChild("HESTIA Config", 10)
if remote then
    hooks.SaveConfig = hooks.SaveConfig
        or function(folder, raw)
            return remote:InvokeServer("Save", folder, raw)
        end
    hooks.LoadConfig = hooks.LoadConfig
        or function(folder)
            return remote:InvokeServer("Load", folder)
        end
end
local app = require(root.src.Main).new(root, hooks)
app:Start()
local destroying
destroying = script.Destroying:Connect(function()
    app:Unload()
    destroying:Disconnect()
end)
app.Connections:Add("HESTIA.ClientLifecycle", destroying)
