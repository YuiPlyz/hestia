local Combat = {}
Combat.__index = Combat

function Combat.new(h)
    return setmetatable({
        H = h,
        Target = nil,
        Indicator = nil,
        IndicatorTarget = nil,

        LastAttack = 0,
        LastBossNotification = 0,
        LastBoss = nil,
    }, Combat)
end

local function safeCall(label, fn)
    local ok, a, b, c = pcall(fn)

    if not ok then
        warn(
            "[HESTIA][Combat][" .. tostring(label) .. "] "
                .. tostring(a)
        )

        return false
    end

    return true, a, b, c
end

--------------------------------------------------
-- Enemy list
--------------------------------------------------

function Combat:GetEnemies()
    local h = self.H

    local ok, enemies = safeCall("GetEnemies", function()
        return h.Adapter:GetEnemies()
    end)

    if not ok or type(enemies) ~= "table" then
        return {}
    end

    return enemies
end

--------------------------------------------------
-- Target selection
--------------------------------------------------

function Combat:GetTarget()
    local h = self.H

    local ok, targeting = safeCall("NPCTargeting", function()
        return h:Import("NPCTargeting")
    end)

    if not ok or not targeting or not targeting.Select then
        return nil
    end

    local selectOK, target = safeCall("SelectTarget", function()
        return targeting.Select(h)
    end)

    if not selectOK then
        return nil
    end

    return target
end

--------------------------------------------------
-- Validate target
--------------------------------------------------

function Combat:IsValidTarget(target)
    local h = self.H

    if not target then
        return false
    end

    if typeof(target) == "Instance" and not target.Parent then
        return false
    end

    local validOK, valid = safeCall("Valid", function()
        return h.Adapter:Valid(target)
    end)

    if not validOK or not valid then
        return false
    end

    local healthOK, health = safeCall("Health", function()
        return h.Adapter:Health(target)
    end)

    if not healthOK then
        return false
    end

    health = tonumber(health)

    if not health or health <= 0 then
        return false
    end

    return true
end

--------------------------------------------------
-- Distance
--------------------------------------------------

function Combat:GetDistance(target)
    local h = self.H

    local ok, distance = safeCall("Distance", function()
        return h.Adapter:Distance(target)
    end)

    if not ok then
        return math.huge
    end

    return tonumber(distance) or math.huge
end

--------------------------------------------------
-- Weapon data
--------------------------------------------------

function Combat:GetWeapon()
    local h = self.H

    local characterOK, character = safeCall("Character", function()
        return h.Adapter:Character()
    end)

    if not characterOK or not character then
        return nil, nil
    end

    local tool = character:FindFirstChildOfClass("Tool")

    if not tool then
        return nil, nil
    end

    local weaponData

    local weaponsOK, weapons = safeCall("Weapons", function()
        return h:Import("Weapons")
    end)

    if weaponsOK and type(weapons) == "table" then
        weaponData = weapons[tool.Name]
    end

    return tool, weaponData
end

--------------------------------------------------
-- Auto equip
--------------------------------------------------

function Combat:EnsureWeapon()
    local h = self.H

    local tool, data = self:GetWeapon()

    if tool then
        return tool, data
    end

    if not h.Config.Combat.AutoEquip then
        return nil, nil
    end

    safeCall("EquipWeapon", function()
        return h.Adapter:EquipWeapon()
    end)

    -- Equip can take a frame or two.
    local deadline = os.clock() + 0.35

    repeat
        task.wait()

        tool, data = self:GetWeapon()

        if tool then
            return tool, data
        end
    until os.clock() >= deadline

    return nil, nil
end

--------------------------------------------------
-- Attack
--------------------------------------------------

function Combat:AttackTarget(target)
    local h = self.H
    local config = h.Config.Combat

    if not self:IsValidTarget(target) then
        return false
    end

    --------------------------------------------------
    -- Range
    --------------------------------------------------

    local range =
        tonumber(config.Range)
        or 12

    if self:GetDistance(target) > range then
        return false
    end

    --------------------------------------------------
    -- Weapon
    --------------------------------------------------

    local tool, weaponData = self:EnsureWeapon()

    if config.AutoEquip and not tool then
        return false
    end

    --------------------------------------------------
    -- Attack cooldown
    --------------------------------------------------

    local configuredDelay =
        tonumber(config.AttackDelay)
        or 0.1

    local weaponDelay = 0.4

    if weaponData then
        weaponDelay =
            tonumber(weaponData.SwingDelay)
            or weaponDelay
    end

    -- Do not attack faster than either configured
    -- delay or the weapon's own swing delay.
    local attackDelay =
        math.max(
            configuredDelay,
            weaponDelay
        )

    local now = os.clock()

    if now - self.LastAttack < attackDelay then
        return false
    end

    --------------------------------------------------
    -- Revalidate immediately before attacking
    --------------------------------------------------

    if not self:IsValidTarget(target) then
        return false
    end

    if self:GetDistance(target) > range then
        return false
    end

    --------------------------------------------------
    -- Attack
    --------------------------------------------------

    local attackOK, success = safeCall("AttackTarget", function()
        return h.Adapter:AttackTarget(target)
    end)

    if not attackOK or success == false then
        return false
    end

    -- Set cooldown only after the adapter accepted
    -- the attack.
    self.LastAttack = now

    --------------------------------------------------
    -- Stats
    --------------------------------------------------

    if h.State then
        h.State.Stats =
            h.State.Stats
            or {}

        h.State.Stats.Attacks =
            (h.State.Stats.Attacks or 0)
            + 1
    end

    return true
end

--------------------------------------------------
-- Indicator
--------------------------------------------------

function Combat:RemoveIndicator()
    if self.Indicator then
        pcall(function()
            self.Indicator:Destroy()
        end)

        self.Indicator = nil
    end

    self.IndicatorTarget = nil
end

function Combat:UpdateIndicator(target)
    local h = self.H
    local config = h.Config.Combat

    if not config.TargetIndicator then
        self:RemoveIndicator()
        return
    end

    if not target then
        self:RemoveIndicator()
        return
    end

    -- Don't destroy/recreate it every 0.1 seconds.
    if
        self.Indicator
        and self.IndicatorTarget == target
        and self.Indicator.Parent
    then
        return
    end

    self:RemoveIndicator()

    local highlight = Instance.new("Highlight")

    highlight.Name = "HESTIA Target"
    highlight.Adornee = target

    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0

    highlight.OutlineColor =
        Color3.fromRGB(
            255,
            170,
            100
        )

    local parent =
        h.UI
        and h.UI.Gui

    highlight.Parent =
        parent
        or target

    self.Indicator = highlight
    self.IndicatorTarget = target
end

--------------------------------------------------
-- Boss detection
--------------------------------------------------

function Combat:IsBoss(target)
    local h = self.H

    if not target then
        return false
    end

    local attributeBoss = false

    if typeof(target) == "Instance" then
        local ok, result = pcall(function()
            return target:GetAttribute("Boss")
        end)

        attributeBoss =
            ok
            and result == true
    end

    if attributeBoss then
        return true
    end

    local enemiesOK, enemies = safeCall("Enemies", function()
        return h:Import("Enemies")
    end)

    if
        enemiesOK
        and type(enemies) == "table"
        and enemies[target.Name] == "Boss"
    then
        return true
    end

    return false
end

function Combat:NotifyBoss(target)
    if not self:IsBoss(target) then
        return
    end

    local h = self.H
    local now = os.clock()

    -- Notify immediately for a different boss.
    -- For the same boss, prevent notification spam.
    if
        self.LastBoss == target
        and now - self.LastBossNotification < 30
    then
        return
    end

    self.LastBoss = target
    self.LastBossNotification = now

    if h.Notifications then
        safeCall("BossNotification", function()
            h.Notifications:Send(
                "Boss detected: " .. tostring(target.Name),
                "HESTIA Combat",
                "Boss",
                30
            )
        end)
    end
end

--------------------------------------------------
-- Task ownership
--------------------------------------------------

function Combat:RequestTask()
    local h = self.H

    if not h.Config.Combat.PauseFarming then
        if h.Tasks then
            pcall(function()
                h.Tasks:Release("Combat")
            end)
        end

        return true
    end

    if not h.Tasks then
        return true
    end

    local ok, granted = safeCall("TaskRequest", function()
        return h.Tasks:Request(
            "Combat",
            80
        )
    end)

    return ok and granted ~= false
end

--------------------------------------------------
-- Main combat step
--------------------------------------------------

function Combat:Step()
    local h = self.H

    if
        not h
        or not h.Config
        or not h.Config.Combat
        or not h.Adapter
    then
        return
    end

    --------------------------------------------------
    -- Find target
    --------------------------------------------------

    local target = self:GetTarget()

    if not self:IsValidTarget(target) then
        target = nil
    end

    self.Target = target

    --------------------------------------------------
    -- No target
    --------------------------------------------------

    if not target then
        self:RemoveIndicator()

        self.LastBoss = nil

        if h.Tasks then
            pcall(function()
                h.Tasks:Release("Combat")
            end)
        end

        return
    end

    --------------------------------------------------
    -- Request combat control
    --------------------------------------------------

    if not self:RequestTask() then
        return
    end

    --------------------------------------------------
    -- Update UI
    --------------------------------------------------

    self:UpdateIndicator(target)

    --------------------------------------------------
    -- Boss detection
    --------------------------------------------------

    self:NotifyBoss(target)

    --------------------------------------------------
    -- Attack
    --------------------------------------------------

    self:AttackTarget(target)
end

--------------------------------------------------
-- Start
--------------------------------------------------

function Combat:Start()
    local h = self.H

    if not h or not h.Scheduler then
        warn(
            "[HESTIA][Combat] Scheduler unavailable"
        )

        return
    end

    -- Prevent duplicate scheduler registrations.
    pcall(function()
        h.Scheduler:Remove("Combat")
    end)

    h.Scheduler:Add(
        "Combat",
        0.1,

        function()
            local ok, err = pcall(function()
                self:Step()
            end)

            if not ok then
                warn(
                    "[HESTIA][Combat] "
                        .. tostring(err)
                )
            end
        end,

        function()
            self:Stop()
        end
    )

    print("[HESTIA][Combat] Started")
end

--------------------------------------------------
-- Stop
--------------------------------------------------

function Combat:Stop()
    local h = self.H

    if h and h.Scheduler then
        pcall(function()
            h.Scheduler:Remove("Combat")
        end)
    end

    if h and h.Tasks then
        pcall(function()
            h.Tasks:Release("Combat")
        end)
    end

    self.Target = nil
    self.LastBoss = nil

    self:RemoveIndicator()
end

Combat.Destroy = Combat.Stop

return Combat
