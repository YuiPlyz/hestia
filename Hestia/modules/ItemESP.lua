local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Items", function()
        local result = {}
        for object in pairs(h.Registry.Items) do
            result[object] = h.Registry.Scrap[object] and "Scrap"
                or h.Registry.Fuel[object] and "Fuel"
                or h.Adapter:Category(object)
        end
        return result
    end)
end
return Provider
