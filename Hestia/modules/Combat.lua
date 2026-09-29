local Combat = {}
Combat.__index = Combat
function Combat.new(h)
    return setmetatable({ H = h, LastAttack = 0 }, Combat)
end
function Combat:GetEnemies()
    return self.H.Adapter:GetEnemies()
end
function Combat:GetTarget()
    return self.H:Import("NPCTargeting").Select(self.H)
end
function Combat:AttackTarget(target)
    local h = self.H
    if not h.Adapter:Valid(target) or h.Adapter:Distance(target) > h.Config.Combat.Range then
        return false
    end
    local hp = h.Adapter:Health(target)
    if not hp or hp <= 0 then
        return false
    end
    if h.Config.Combat.AutoEquip then
        h.Adapter:EquipWeapon()
    end
    local character = h.Adapter:Character()
    local tool = character and character:FindFirstChildOfClass("Tool")
    local data = tool and h:Import("Weapons")[tool.Name]
    local delay = math.max(h.Config.Combat.AttackDelay, data and data.SwingDelay or 0.4)
    if os.clock() - self.LastAttack < delay then
        return false
    end
    self.LastAttack = os.clock()
    local ok, reason = h.Adapter:AttackTarget(target)
    self.Status = ok and "Hit confirmed" or tostring(reason or "Attack rejected")
    if ok then
        h.State.Stats.Attacks = h.State.Stats.Attacks + 1
    end
    return ok
end
function Combat:Step()
    local h = self.H
    self.Target = self:GetTarget()
    if not self.Target then
        self.Status = "Searching for NPCs"
        h.Tasks:Release("Combat")
    end
    if self.Indicator then
        self.Indicator:Destroy()
        self.Indicator = nil
    end
    if not self.Target then
        return
    end
    if h.Config.Combat.PauseFarming then
        if not h.Tasks:Request("Combat", 80) then
            return
        end
    else
        h.Tasks:Release("Combat")
    end
    if h.Config.Combat.TargetIndicator then
        self.Indicator = Instance.new("Highlight")
        self.Indicator.Name = "HESTIA Target"
        self.Indicator.Adornee = self.Target
        self.Indicator.FillTransparency = 1
        self.Indicator.OutlineColor = Color3.fromRGB(255, 170, 100)
        self.Indicator.Parent = h.UI.Gui
    end
    if self.Target:GetAttribute("Boss") or h:Import("Enemies")[self.Target.Name] == "Boss" then
        h.Notifications:Send("Boss detected.", "HESTIA Combat", "Boss", 30)
    end
    self:AttackTarget(self.Target)
end
function Combat:Start()
    self.H.Scheduler:Add("Combat", 0.1, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Combat:Stop()
    self.H.Scheduler:Remove("Combat")
    self.H.Tasks:Release("Combat")
    self.Target = nil
    self.Status = "Disabled"
    if self.Indicator then
        self.Indicator:Destroy()
        self.Indicator = nil
    end
end
Combat.Destroy = Combat.Stop
return Combat
