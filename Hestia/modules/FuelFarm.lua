local FuelFarm = {}
function FuelFarm.new(h)
    return h:Import("FarmWorker").new(h, "FuelFarm", {
        Registry = "Fuel",
        Priority = 40,
        Stat = "Pickups",
        Radius = function()
            return h.Config.Generator.FuelRadius
        end,
        Ready = function()
            local amount = 0
            for _, item in ipairs(h.Adapter:GetInventory()) do
                if item.Category == "Fuel" then
                    amount = amount + item.Quantity
                end
            end
            return amount < h.Config.Farming.FuelReserve and not h.Adapter:InventoryFull()
        end,
    })
end
return FuelFarm
