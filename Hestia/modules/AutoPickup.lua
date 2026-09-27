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
        or h.Adapter:Distance(item) > c.PickupRadius
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
    local ok, quantity = h.Adapter:CollectItem(item)
    if ok then
        h.State.Stats.Pickups = h.State.Stats.Pickups + (type(quantity) == "number" and quantity or 1)
    end
    return ok
end
function Pickup:Start()
    self.H.Scheduler:Add("AutoPickup", 0.2, function()
        local h = self.H
        if os.clock() < (self.NextCollect or 0) then
            return
        end
        if not h.Tasks:Request("AutoPickup", 30) then
            return
        end
        for object in pairs(h.Registry.Items) do
            if self:TryCollect(object) then
                self.NextCollect = os.clock() + h.Config.Farming.PickupDelay
                break
            end
        end
        h.Tasks:Release("AutoPickup")
    end, function()
        self:Stop()
    end)
end
function Pickup:Stop()
    self.H.Scheduler:Remove("AutoPickup")
    self.H.Tasks:Release("AutoPickup")
end
Pickup.Destroy = Pickup.Stop
return Pickup
