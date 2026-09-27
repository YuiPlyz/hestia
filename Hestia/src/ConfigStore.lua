local Store = {}
Store.__index = Store
local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = clone(child)
    end
    return result
end
local function merge(target, source, path)
    for key, value in pairs(source) do
        local old = target[key]
        if old ~= nil and type(old) == type(value) then
            local keyPath = path .. tostring(key)
            local map = keyPath:match("Whitelist$")
                or keyPath:match("Blacklist$")
                or keyPath == "Farming.ItemCategories"
                or keyPath == "Farming.PickupCategories"
                or keyPath == "Storage.Categories"
                or keyPath == "Storage.Keep"
                or keyPath == "Storage.Minimum"
                or keyPath == "Teleports.Saved"
            if type(value) == "table" and next(old) ~= nil and #old == 0 and not map then
                merge(old, value, keyPath .. ".")
            else
                target[key] = clone(value)
            end
        end
    end
end
function Store.new(h)
    return setmetatable({ H = h }, Store)
end
function Store:Export()
    return self.H.Services.HttpService:JSONEncode({ Schema = 1, Config = self.H.Config })
end
function Store:Import(raw)
    assert(type(raw) == "string" and #raw <= 60000, "HESTIA configuration is too large")
    local payload = self.H.Services.HttpService:JSONDecode(raw)
    assert(payload.Schema == 1 and type(payload.Config) == "table", "HESTIA unsupported config schema")
    local validated = self.H:Import("ConfigValidation").Validate(payload.Config, self.H.Config)
    merge(self.H.Config, validated, "")
    self.H:SyncFeatures()
    self.H.UI.ThemeManager:Apply()
    return true
end
function Store:Save()
    local ok, reason = self.H.Adapter:Call("SaveConfig", "HESTIA/survive-the-apocalypse", self:Export())
    if ok then
        self.H.Notifications:Send("Configuration saved.")
    end
    return ok, reason
end
function Store:Load()
    local ok, value = self.H.Adapter:Call("LoadConfig", "HESTIA/survive-the-apocalypse")
    if not ok then
        return false, value
    end
    local success, err = pcall(function()
        self:Import(value)
    end)
    return success, err
end
return Store
