local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Structures", function()
        local result = {}
        for object in pairs(h.Registry.Structures) do
            result[object] = "Structure"
        end
        for object in pairs(h.Registry.Chest) do
            result[object] = "Chest"
        end
        for object in pairs(h.Registry.Generator) do
            result[object] = "Generator"
        end
        return result
    end)
end
return Provider
