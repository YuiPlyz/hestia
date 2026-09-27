local Pickup = {}
Pickup.__index = Pickup

function Pickup.new(h)
    return setmetatable({
        H = h,

        -- Per-item retry cooldowns.
        Cooldowns = setmetatable({}, {
            __mode = "k",
        }),

        NextCollect = 0,
    }, Pickup)
end

local function safeCall(fn, ...)
    local ok, result1, result2, result3 = pcall(fn, ...)

    if not ok then
        warn("[HESTIA][Pickup] " .. tostring(result1))
        return false
    end

    return true, result1, result2, result3
end

function Pickup:IsAllowed(item)
    local h = self.H
    local config = h.Config
    local farming = config and config.Farming

    if not farming then
        return false
    end

    if not item or not item.Parent then
        return false
    end

    -- Validate item safely.
    local validOK, valid = safeCall(function()
        return h.Adapter:Valid(item)
    end)

    if not validOK or not valid then
        return false
    end

    -- Distance check.
    local distanceOK, distance = safeCall(function()
        return h.Adapter:Distance(item)
    end)

    if not distanceOK then
        return false
    end

    distance = tonumber(distance)

    if not distance then
        return false
    end

    local pickupRadius = tonumber(farming.PickupRadius) or 25

    if distance > pickupRadius then
        return false
    end

    -- Inventory check.
    local inventoryOK, inventoryFull = safeCall(function()
        return h.Adapter:InventoryFull()
    end)

    if inventoryOK and inventoryFull then
        return false
    end

    -- Item cooldown.
    local now = os.clock()
    local cooldown = self.Cooldowns[item]

    if cooldown and cooldown > now then
        return false
    end

    -- Filter / whitelist / blacklist.
    local utilities

    local importOK, importResult = safeCall(function()
        return h:Import("Utilities")
    end)

    if importOK then
        utilities = importResult
    end

    if utilities and utilities.Allowed then
        local category

        local categoryOK, categoryResult = safeCall(function()
            return h.Adapter:Category(item)
        end)

        if categoryOK then
            category = categoryResult
        end

        local allowedOK, allowed = safeCall(function()
            return utilities.Allowed(
                item.Name,
                category,
                farming.PickupWhitelist or {},
                farming.PickupBlacklist or {},
                farming.AllItems == false
                    and farming.PickupCategories
                    or nil
            )
        end)

        if allowedOK and not allowed then
            return false
        end
    end

    return true
end

function Pickup:TryCollect(item)
    local h = self.H
    local farming = h.Config and h.Config.Farming

    if not farming then
        return false
    end

    if not self:IsAllowed(item) then
        return false
    end

    local now = os.clock()

    -- Don't force a minimum 1-second cooldown.
    -- That could make fast pickup look broken.
    local retryDelay = tonumber(farming.PickupDelay) or 0.15

    retryDelay = math.max(retryDelay, 0.05)

    self.Cooldowns[item] = now + retryDelay

    local callOK, collected, quantity = safeCall(function()
        return h.Adapter:CollectItem(item)
    end)

    if not callOK then
        -- Allow another attempt sooner if the adapter errored.
        self.Cooldowns[item] = now + 0.1
        return false
    end

    if collected then
        if h.State and h.State.Stats then
            h.State.Stats.Pickups =
                (h.State.Stats.Pickups or 0)
                + (
                    type(quantity) == "number"
                    and quantity
                    or 1
                )
        end

        return true
    end

    return false
end

function Pickup:Process()
    local h = self.H
    local farming = h.Config and h.Config.Farming

    if not farming then
        return
    end

    if farming.Enabled == false then
        return
    end

    if os.clock() < self.NextCollect then
        return
    end

    -- Request ownership if a task manager exists.
    local ownsTask = true

    if h.Tasks then
        local ok, result = safeCall(function()
            return h.Tasks:Request("AutoPickup", 30)
        end)

        ownsTask = ok and result ~= false
    end

    if not ownsTask then
        return
    end

    local registry = h.Registry
    local items = registry and registry.Items

    if not items then
        if h.Tasks then
            pcall(function()
                h.Tasks:Release("AutoPickup")
            end)
        end

        return
    end

    local collectedSomething = false

    for item in pairs(items) do
        -- Registry may contain deleted/stale instances.
        if item and item.Parent then
            local ok, result = pcall(function()
                return self:TryCollect(item)
            end)

            if not ok then
                warn(
                    "[HESTIA][Pickup] Failed on "
                        .. tostring(item)
                        .. ": "
                        .. tostring(result)
                )
            elseif result then
                collectedSomething = true
                break
            end
        end
    end

    if collectedSomething then
        self.NextCollect =
            os.clock()
            + math.max(
                tonumber(farming.PickupDelay) or 0.15,
                0.05
            )
    end

    if h.Tasks then
        pcall(function()
            h.Tasks:Release("AutoPickup")
        end)
    end
end

function Pickup:Start()
    local h = self.H

    if not h or not h.Scheduler then
        warn("[HESTIA][Pickup] Scheduler missing")
        return
    end

    -- Prevent duplicate scheduler jobs.
    pcall(function()
        h.Scheduler:Remove("AutoPickup")
    end)

    h.Scheduler:Add(
        "AutoPickup",

        -- Scan frequently; PickupDelay controls successful pickup pacing.
        0.1,

        function()
            self:Process()
        end,

        function()
            self:Stop()
        end
    )

    print("[HESTIA][Pickup] AutoPickup started")
end

function Pickup:Stop()
    local h = self.H

    if h and h.Scheduler then
        pcall(function()
            h.Scheduler:Remove("AutoPickup")
        end)
    end

    if h and h.Tasks then
        pcall(function()
            h.Tasks:Release("AutoPickup")
        end)
    end

    self.NextCollect = 0
end

Pickup.Destroy = Pickup.Stop

return Pickup
