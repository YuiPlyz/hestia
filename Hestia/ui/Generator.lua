local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Generator automation")
    ui:Toggle(section, "Auto Fuel Generator", "Generator.AutoFuel")
    ui:Number(section, "Start below (%)", "Generator.FuelBelow", 1, 99)
    ui:Number(section, "Stop at (%)", "Generator.FuelUntil", 2, 100)
    ui:Number(section, "Emergency at (%)", "Generator.EmergencyFuel", 0, 99)
    ui:Number(section, "Fuel search radius", "Generator.FuelRadius", 5, 5000)
    ui:JSON(section, "Fuel priority (JSON array)", "Generator.FuelPriority")
    ui:Label(section, "Fuel", function()
        local p = h.Adapter:GetFuelPercent()
        return p and string.format("%s  %.0f%%", string.rep("|", math.floor(p / 10)), p) or "Unavailable"
    end)
    ui:Label(section, "Status", function()
        return h.Features.Generator and h.Features.Generator.Status or "Unavailable"
    end)
    ui:Label(section, "Current fuel", function()
        return h.Features.Generator and h.Features.Generator.CurrentFuel or "None"
    end)
end
return Panel
