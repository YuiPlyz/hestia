local Survival = {}
Survival.__index = Survival
function Survival.new(h)
    return setmetatable({ H = h }, Survival)
end
function Survival:Step()
    local h, config = self.H, self.H.Config.Survival
    local v = h.Adapter:Vitals()
    local kind
    if config.AutoHeal and v.Health < config.HealBelow then
        kind = "Heal"
    elseif config.AutoBandage and v.Bleeding then
        kind = "Bandage"
    elseif config.AutoEat and v.Hunger < config.EatBelow then
        kind = "Eat"
    elseif config.AutoDrink and v.Thirst < config.DrinkBelow then
        kind = "Drink"
    end
    if not kind then
        h.Tasks:Release("Survival")
        self.Status = "Stable"
        return
    end
    local emergency = v.Health <= config.EmergencyHealth
    if not h.Tasks:Request("Survival", emergency and 100 or 70) then
        self.Status = "Paused"
        return
    end
    self.Status = kind
    h.Adapter:UseSurvival(kind)
    h.Tasks:Release("Survival")
end
function Survival:Start()
    self.H.Scheduler:Add("Survival", 1, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Survival:Stop()
    self.H.Scheduler:Remove("Survival")
    self.H.Tasks:Release("Survival")
end
Survival.Destroy = Survival.Stop
return Survival
