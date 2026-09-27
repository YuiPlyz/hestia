local ItemFarm = {}
function ItemFarm.new(h)
    return h:Import("FarmWorker").new(h, "ItemFarm", {
        Registry = "Items",
        Priority = 40,
        Stat = "Pickups",
        Radius = function()
            return h.Config.Farming.ItemRadius
        end,
        Filter = function(object)
            return h.Config.Farming.ItemCategories[h.Adapter:Category(object)] == true
        end,
        Ready = function()
            return not h.Adapter:InventoryFull()
        end,
    })
end
return ItemFarm
