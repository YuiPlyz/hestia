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
            local c = h.Config.Farming
            return h:Import("Utilities").Allowed(
                object.Name,
                h.Adapter:Category(object),
                c.ItemWhitelist,
                c.ItemBlacklist,
                c.ItemCategories
            )
        end,
        Ready = function()
            return not h.Adapter:InventoryFull()
        end,
    })
end
return ItemFarm
