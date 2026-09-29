local Utilities = {}
local function hasSelection(filter)
    for _, selected in pairs(filter or {}) do
        if selected == true then
            return true
        end
    end
    return false
end
function Utilities.Allowed(name, category, whitelist, blacklist, categories)
    if blacklist and blacklist[name] then
        return false
    end
    if hasSelection(whitelist) and not whitelist[name] then
        return false
    end
    if hasSelection(categories) and not categories[category] then
        return false
    end
    return true
end
function Utilities.Nearest(h, registry, radius, predicate, score)
    local best, value = nil, math.huge
    for object in pairs(registry) do
        if h.Adapter:Valid(object) then
            local distance = h.Adapter:Distance(object)
            if (radius == 0 or distance <= radius) and (not predicate or predicate(object)) then
                local rank = score and score(object, distance) or distance
                if rank < value then
                    best, value = object, rank
                end
            end
        end
    end
    return best
end
function Utilities.Duration(seconds)
    return string.format(
        "%02d:%02d:%02d",
        math.floor(seconds / 3600),
        math.floor(seconds / 60) % 60,
        math.floor(seconds) % 60
    )
end
function Utilities.Count(set)
    local count = 0
    for _ in pairs(set) do
        count = count + 1
    end
    return count
end
return Utilities
