local Logger = {}
Logger.__index = Logger
function Logger.new(config)
    return setmetatable({ Config = config, History = {} }, Logger)
end
function Logger:Log(level, message)
    if level == "DEBUG" and not self.Config.Debug then
        return
    end
    local text = string.format("[HESTIA][%s] %s", level, tostring(message))
    table.insert(self.History, text)
    if #self.History > 100 then
        table.remove(self.History, 1)
    end
    if level == "ERROR" or level == "WARN" then
        warn(text)
    else
        print(text)
    end
end
return Logger
