local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Enemies", function()
        local result = {}
        for object in pairs(h.Registry.Enemies) do
            local hp = h.Adapter:Health(object)
            if hp and hp > 0 then
                result[object] = "Enemy"
            end
        end
        return result
    end)
end
return Provider
