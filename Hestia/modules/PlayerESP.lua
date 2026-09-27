local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Players", function()
        local result = {}
        for _, player in ipairs(h.Services.Players:GetPlayers()) do
            if player ~= h.Services.Players.LocalPlayer and player.Character then
                result[player.Character] = "Player"
            end
        end
        return result
    end)
end
return Provider
