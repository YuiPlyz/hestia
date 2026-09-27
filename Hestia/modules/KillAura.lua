-- HESTIA facade; Combat owns the single attack scheduler.
local KillAura = {}
function KillAura.new(h)
    return {
        Start = function()
            h:Set("Combat.KillAura", true)
        end,
        Stop = function()
            h:Set("Combat.KillAura", false)
        end,
        GetTarget = function()
            return h.Features.Combat:GetTarget()
        end,
    }
end
return KillAura
