local Notifications = {}
Notifications.__index = Notifications
function Notifications.new(h)
    return setmetatable({ H = h, Last = {} }, Notifications)
end
function Notifications:Send(message, title, key, cooldown)
    if key and os.clock() - (self.Last[key] or -math.huge) < (cooldown or 10) then
        return
    end
    if key then
        self.Last[key] = os.clock()
    end
    self.H.Logger:Log("INFO", (title or "HESTIA") .. ": " .. message)
    if self.H.UI then
        self.H.UI:Notify(title or "HESTIA", message)
    end
end
return Notifications
