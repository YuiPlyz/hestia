-- HESTIA optional local persistence; unavailable filesystem functions leave JSON export usable.
local LocalConfig = {}
function LocalConfig.Create(filesystem)
    local folder = "HESTIA/survive-the-apocalypse"
    local filename = folder .. "/settings.json"
    local hooks = {}
    local canSave = type(filesystem.Write) == "function"
        and type(filesystem.MakeFolder) == "function"
        and type(filesystem.IsFolder) == "function"
    local canLoad = type(filesystem.Read) == "function" and type(filesystem.IsFile) == "function"
    hooks.SaveConfig = function(namespace, raw)
        if namespace ~= folder then
            return false, "Invalid HESTIA config namespace"
        end
        if not canSave then
            return false, "Local file saving unavailable. Use Settings > Export config."
        end
        if type(raw) ~= "string" or #raw > 60000 then
            return false, "Invalid HESTIA configuration size"
        end
        local ok, reason = pcall(function()
            for _, path in ipairs({ "HESTIA", folder }) do
                if not filesystem.IsFolder(path) then
                    filesystem.MakeFolder(path)
                end
            end
            filesystem.Write(filename, raw)
        end)
        return ok, reason
    end
    hooks.LoadConfig = function(namespace)
        if namespace ~= folder then
            return false, "Invalid HESTIA config namespace"
        end
        if not canLoad then
            return false, "Local file loading unavailable. Use Settings > Import config."
        end
        local ok, value = pcall(function()
            assert(filesystem.IsFile(filename), "No saved HESTIA configuration")
            local raw = filesystem.Read(filename)
            assert(type(raw) == "string" and #raw <= 60000, "Invalid HESTIA configuration size")
            return raw
        end)
        return ok, value
    end
    return hooks, canSave, canLoad
end
return LocalConfig
