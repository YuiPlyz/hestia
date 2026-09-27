local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Structure repair")
    ui:Toggle(section, "Auto Repair", "Repair.Enabled")
    ui:Choice(section, "Priority", "Repair.Priority", { "Nearest", "LowestHealth" })
    ui:Number(section, "Radius", "Repair.Radius", 1, 100)
    ui:Number(section, "Repair interval", "Repair.Rate", 0.2, 10)
    ui:Toggle(section, "Emergency repair priority", "Repair.Emergency")
    ui:Number(section, "Emergency below (%)", "Repair.EmergencyBelow", 1, 100)
    section = ui:Section(tab, "Utilities")
    ui:Toggle(section, "Fullbright", "Visuals.Fullbright")
    ui:Toggle(section, "Debug logging", "Debug")
    ui:Label(section, "Structure health", function()
        return h.Features.Repair and h.Features.Repair.Status or "Disabled"
    end)
    ui:Button(section, "Rejoin this place", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, h.Services.Players.LocalPlayer)
    end)
end
return Panel
