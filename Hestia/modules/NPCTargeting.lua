local Targeting = {}
function Targeting.Select(h)
    local config = h.Config.Combat
    return h:Import("Utilities").Nearest(h, h.Adapter:GetEnemies(), config.Range, function(object)
        if not object:IsA("Model") then
            return false
        end
        local hp = h.Adapter:Health(object)
        return hp ~= nil and hp > 0 and not h.Services.Players:GetPlayerFromCharacter(object)
    end, function(object, distance)
        local hp = h.Adapter:Health(object)
        local score = distance
        if config.Priority == "LowestHP" then
            score = hp
        elseif config.Priority == "HighestHP" then
            score = -hp
        end
        local boss = object:GetAttribute("Boss") or h:Import("Enemies")[object.Name] == "Boss"
        return score - (config.BossPriority and boss and 10000000 or 0)
    end)
end
return Targeting
