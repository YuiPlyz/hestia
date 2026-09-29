local Pickup = {}
Pickup.__index = Pickup
function Pickup.new(h)
    return setmetatable({ H = h, Cooldowns = setmetatable({}, { __mode = "k" }) }, Pickup)
end
function Pickup:TryCollect(item)
    local h, c = self.H, self.H.Config.Farming
    if
        not h.Tasks:IsOwner("AutoPickup")
        or not h.Adapter:Valid(item)
        or (c.PickupRadius > 0 and h.Adapter:Distance(item) > c.PickupRadius)
        or h.Adapter:InventoryFull()
    then
        return false
    end
    if (self.Cooldowns[item] or 0) > os.clock() then
        return false
    end
    if
        not h:Import("Utilities").Allowed(
            item.Name,
            h.Adapter:Category(item),
            c.PickupWhitelist,
            c.PickupBlacklist,
            not c.AllItems and c.PickupCategories or nil
        )
    then
        return false
    end
    self.Cooldowns[item] = os.clock() + math.max(c.PickupDelay, 1)
    local ok, quantity, sent = h.Adapter:CollectItem(item)
    self.Status = ok and "Collected " .. item.Name or tostring(quantity or "Pickup rejected")
    if ok then
        h.State.Stats.Pickups = h.State.Stats.Pickups + (type(quantity) == "number" and quantity or 1)
    end
    return ok, sent
end
function Pickup:Start()
    self.H.Scheduler:Add("AutoPickup", 0.2, function()
        local h = self.H
        if os.clock() < (self.NextCollect or 0) then
            return
        end
        if not h.Adapter.Hooks.CollectItem then
            self.Status = "Missing CollectItem hook"
            h.Notifications:Send(
                "Pickup needs the game's CollectItem integration.",
                "HESTIA",
                "CollectItem",
                60
            )
            return
        end
        if h.Adapter:InventoryFull() then
            self.Status = "Inventory full"
            return
        end
        if not h.Tasks:Request("AutoPickup", 30) then
            self.Status = "Paused by " .. tostring(h.Tasks.Active)
            return
        end
        self.Status = "Searching (check range / filters)"
        if not self.Queue or self.Cursor > #self.Queue then
            self.Queue, self.Cursor = {}, 1
            for object in pairs(h.Registry.Items) do
                table.insert(self.Queue, object)
            end
        end
        while self.Cursor <= #self.Queue do
            local object = self.Queue[self.Cursor]
            self.Cursor = self.Cursor + 1
            if h.Registry.Items[object] then
                local collected, sent = self:TryCollect(object)
                if collected or sent then
                    self.NextCollect = os.clock() + h.Config.Farming.PickupDelay
                    break
                end
            end
        end
        h.Tasks:Release("AutoPickup")
    end, function()
        self:Stop()
    end)
end
function Pickup:Stop()
    self.Status = "Disabled"
    self.Queue, self.Cursor, self.NextCollect = nil, nil, nil
    self.H.Scheduler:Remove("AutoPickup")
    self.H.Tasks:Release("AutoPickup")
end
Pickup.Destroy = Pickup.Stop
return Pickup
