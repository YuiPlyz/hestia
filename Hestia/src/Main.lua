local Hestia = {}
Hestia.__index = Hestia
Hestia.Name, Hestia.Version, Hestia.Game = "HESTIA", "1.0.0", "Survive the Apocalypse"
local featureSwitches = {
    ScrapFarm = "Farming.AutoScrap",
    ItemFarm = "Farming.AutoItems",
    FuelFarm = "Farming.AutoFuelFarm",
    Generator = "Generator.AutoFuel",
    AutoPickup = "Farming.AutoPickup",
    AutoStore = "Storage.Enabled",
    Combat = "Combat.KillAura",
    Repair = "Repair.Enabled",
}
function Hestia.new(root, hooks)
    local importer = require(root.src.Importer).new(root)
    local self = setmetatable({
        Root = root,
        Importer = importer,
        Modules = importer.Cache,
        Features = {},
        Enabled = {},
        Hooks = hooks,
    }, Hestia)
    return self
end
function Hestia:Import(name)
    return self.Importer:Import(name)
end
function Hestia:Get(path)
    local value = self.Config
    for key in path:gmatch("[^.]+") do
        value = value[key]
    end
    return value
end
function Hestia:Set(path, value)
    local patch, node, keys = {}, nil, {}
    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end
    node = patch
    for i = 1, #keys - 1 do
        node[keys[i]] = {}
        node = node[keys[i]]
    end
    node[keys[#keys]] = value
    self:Import("ConfigValidation").Validate(patch, self.Config)
    node = self.Config
    for i = 1, #keys - 1 do
        assert(node[keys[i]], "HESTIA unknown config path")
        node = node[keys[i]]
    end
    assert(node[keys[#keys]] ~= nil, "HESTIA unknown config path")
    node[keys[#keys]] = value
    self:SyncFeatures()
    if self.UI then
        self.UI.ThemeManager:Apply()
    end
end
function Hestia:SyncFeatures()
    for name, path in pairs(featureSwitches) do
        local wanted = self:Get(path)
        local feature = self.Features[name]
        if feature and wanted ~= self.Enabled[name] then
            if wanted then
                feature:Start()
            else
                feature:Stop()
            end
            self.Enabled[name] = wanted
            self.Notifications:Send(name .. (wanted and " enabled." or " disabled."))
        end
    end
end
function Hestia:Start()
    if self.State and self.State.Running then
        return self
    end
    assert(not self.Unloaded, "HESTIA create a fresh instance after unload")
    local ok, err = xpcall(function()
        self.Services = self:Import("Services")
        self.Config =
            self.Services.HttpService:JSONDecode(self.Services.HttpService:JSONEncode(self:Import("Config")))
        self.State = self:Import("State")()
        self.Registry = self.State.Registry
        self.Logger = self:Import("Logger").new(self.Config)
        self.Connections = self:Import("Connections").new()
        self.Notifications = self:Import("Notifications").new(self)
        self.Scheduler = self:Import("Scheduler").new(self)
        self.Adapter = self:Import("GameAdapter").new(self, self.Hooks or self:Import("Hooks"))
        self.Tasks = self:Import("TaskManager").new(function(active, previous)
            if self.Navigator then
                self.Navigator:Cancel(previous)
            end
            self.Logger:Log("DEBUG", "Active task: " .. (active or "Idle"))
        end)
        self.Navigator = self:Import("Navigator").new(self)
        self.Adapter:Start()
        self.ConfigStore = self:Import("ConfigStore").new(self)
        self.UI = self:Import("Interface").new(self)
        for _, name in ipairs({
            "ScrapFarm",
            "ItemFarm",
            "FuelFarm",
            "Generator",
            "AutoPickup",
            "AutoStore",
            "Combat",
            "Repair",
            "Survival",
            "Movement",
            "Teleports",
            "ESP",
            "Lighting",
        }) do
            local success, result = xpcall(function()
                return self:Import(name).new(self)
            end, debug.traceback)
            if success then
                self.Features[name] = result
                self.Logger:Log("SUCCESS", name)
            else
                self.State.Errors[name] = result
                self.Logger:Log("ERROR", name .. ": " .. result)
            end
        end
        self.UI:Start()
        for _, name in ipairs({ "Survival", "Movement", "ESP", "Lighting" }) do
            local feature = self.Features[name]
            if feature then
                local success, reason = pcall(function()
                    feature:Start()
                end)
                if not success then
                    pcall(function()
                        feature:Destroy()
                    end)
                    self.State.Errors[name] = reason
                    self.Logger:Log("ERROR", reason)
                end
            end
        end
        self:SyncFeatures()
        local checked, reason = pcall(function()
            self:Import("Version").Check(self)
        end)
        if not checked then
            self.Logger:Log("WARN", "Version check: " .. tostring(reason))
        end
        self.State.Running = true
        self.Notifications:Send("Successfully loaded.", "HESTIA v" .. self.Version)
        self.Logger:Log("SUCCESS", "Ready.")
    end, debug.traceback)
    if not ok then
        self:Unload()
        error("HESTIA initialization failed: " .. tostring(err), 0)
    end
    return self
end
function Hestia:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    if self.State then
        self.State.Running = false
    end
    local function safely(label, callback)
        local ok, err = pcall(callback)
        if not ok then
            warn("[HESTIA] Cleanup " .. label .. ": " .. tostring(err))
        end
    end
    if self.Scheduler then
        safely("scheduler", function()
            self.Scheduler:Destroy()
        end)
    end
    for name, feature in pairs(self.Features) do
        if feature.Destroy then
            safely(name, function()
                feature:Destroy()
            end)
        end
    end
    if self.Navigator then
        safely("navigation", function()
            self.Navigator:Cancel()
        end)
    end
    if self.Tasks then
        safely("tasks", function()
            self.Tasks:ReleaseAll()
        end)
    end
    if self.Adapter then
        safely("adapter", function()
            self.Adapter:Destroy()
        end)
    end
    if self.Connections then
        safely("connections", function()
            self.Connections:DisconnectAll()
        end)
    end
    if self.UI then
        safely("UI", function()
            self.UI:Destroy()
        end)
    end
    if self.Registry then
        for _, registry in pairs(self.Registry) do
            table.clear(registry)
        end
    end
    table.clear(self.Features)
    table.clear(self.Enabled)
    self.Importer:Clear()
    print("[HESTIA] Unloaded successfully.")
end
return Hestia
