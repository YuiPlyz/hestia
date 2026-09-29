local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "NPC combat")
    ui:Toggle(section, "Kill Aura", "Combat.KillAura")
    ui:Choice(section, "Target priority", "Combat.Priority", { "Nearest", "LowestHP", "HighestHP" })
    ui:Toggle(section, "Boss priority", "Combat.BossPriority")
    ui:Number(section, "Range", "Combat.Range", 1, 50)
    ui:Number(section, "Attack delay", "Combat.AttackDelay", 0.1, 10)
    ui:Toggle(section, "Auto equip weapon", "Combat.AutoEquip")
    ui:Toggle(section, "Pause farming during threats", "Combat.PauseFarming")
    ui:Toggle(section, "Target indicator", "Combat.TargetIndicator")
    ui:Label(section, "Combat status", function()
        return h.Features.Combat and h.Features.Combat.Status or "Disabled"
    end)
    section = ui:Section(tab, "Survival")
    ui:Toggle(section, "Auto Heal", "Survival.AutoHeal", "UseSurvival")
    ui:Number(section, "Heal below (%)", "Survival.HealBelow", 1, 100)
    ui:Toggle(section, "Auto Eat", "Survival.AutoEat", "UseSurvival")
    ui:Number(section, "Eat below (%)", "Survival.EatBelow", 1, 100)
    ui:Toggle(section, "Auto Drink", "Survival.AutoDrink", "UseSurvival")
    ui:Number(section, "Drink below (%)", "Survival.DrinkBelow", 1, 100)
    ui:Toggle(section, "Auto Bandage", "Survival.AutoBandage", "UseSurvival")
    ui:Number(section, "Emergency health (%)", "Survival.EmergencyHealth", 1, 100)
    ui:Label(section, "Current target", function()
        local c = h.Features.Combat
        return c and c.Target and c.Target.Name or "None"
    end)
    ui:Label(section, "Enemy count", function()
        return h:Import("Utilities").Count(h.Registry.Enemies)
    end)
end
return Panel
