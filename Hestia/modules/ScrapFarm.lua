local ScrapFarm = {}
function ScrapFarm.new(h)
    local config = h.Config.Farming
    return h:Import("FarmWorker").new(h, "ScrapFarm", {
        Registry = "Scrap",
        Priority = 50,
        Stat = "Scrap",
        Radius = function()
            return config.ScrapRadius
        end,
        Delay = function()
            return config.ScrapDelay
        end,
        Best = function()
            return config.ScrapPriority == "Value"
        end,
        Filter = function(object)
            return h:Import("Utilities")
                .Allowed(object.Name, "Scrap", config.ScrapWhitelist, config.ScrapBlacklist)
        end,
        Ready = function()
            return not h.Adapter:InventoryFull()
        end,
    })
end
return ScrapFarm
