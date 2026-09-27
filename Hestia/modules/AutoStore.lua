local Store = {}
Store.__index = Store
function Store.new(h)
    return setmetatable({ H = h }, Store)
end
function Store:Step()
    local h, config = self.H, self.H.Config.Storage
    if config.OnlyWhenFull and not h.Adapter:InventoryFull() then
        h.Tasks:Release("AutoStore")
        h.Navigator:Cancel("AutoStore")
        return
    end
    local storage = h.Adapter:GetStorage()
    if not storage then
        self.Status = "Storage unavailable"
        h.Tasks:Release("AutoStore")
        h.Navigator:Cancel("AutoStore")
        return
    end
    local totals, selected, amount = {}, nil, nil
    local inventory = h.Adapter:GetInventory()
    for _, item in ipairs(inventory) do
        totals[item.Name] = (totals[item.Name] or 0) + item.Quantity
    end
    for _, item in ipairs(inventory) do
        if config.Categories[item.Category] and not config.Keep[item.Name] then
            local reserve = config.Minimum[item.Name] or 0
            if item.Category == "Scrap" then
                reserve = math.max(reserve, config.ScrapReserve)
            end
            if item.Category == "Fuel" then
                reserve = math.max(reserve, config.FuelReserve)
            end
            local excess = math.min(item.Quantity, totals[item.Name] - reserve)
            if excess > 0 then
                selected, amount = item.Instance, excess
                break
            end
        end
    end
    if not selected then
        self.Status = "Nothing to store"
        h.Tasks:Release("AutoStore")
        h.Navigator:Cancel("AutoStore")
        return
    end
    if not h.Tasks:Request("AutoStore", h.Adapter:InventoryFull() and 55 or 35) then
        self.Status = "Paused"
        return
    end
    self.Status = h.Navigator:Step("AutoStore", storage, 5)
    if self.Status == "Arrived" and h.Tasks:IsOwner("AutoStore") then
        local ok, confirmed = h.Adapter:StoreItem(selected, amount, storage)
        if ok then
            h.State.Stats.Stored = h.State.Stats.Stored
                + (type(confirmed) == "number" and confirmed or amount)
        end
        h.Tasks:Release("AutoStore")
    end
end
function Store:Start()
    self.H.Scheduler:Add("AutoStore", 0.5, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Store:Stop()
    self.H.Scheduler:Remove("AutoStore")
    self.H.Tasks:Release("AutoStore")
    self.H.Navigator:Cancel("AutoStore")
end
Store.Destroy = Store.Stop
return Store
