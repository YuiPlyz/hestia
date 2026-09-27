local Widget = {}
Widget.__index = Widget
function Widget.new(ui)
    local self = setmetatable({ UI = ui }, Widget)
    self.Frame = ui.Make("Frame", ui.Gui, {
        Name = "HESTIA Status",
        Position = UDim2.new(1, -265, 0.5, -110),
        Size = UDim2.fromOffset(245, 200),
        BackgroundColor3 = Color3.fromRGB(20, 18, 28),
        BorderSizePixel = 0,
    })
    ui.Round(self.Frame, 10)
    local header = ui:Text(self.Frame, "HESTIA", UDim2.fromOffset(14, 8), UDim2.new(1, -58, 0, 28), 17)
    ui.ThemeManager:Track(header, "TextColor3")
    ui:Drag(header, self.Frame)
    ui:ButtonAt(self.Frame, "−", UDim2.new(1, -42, 0, 8), UDim2.fromOffset(28, 26), function()
        ui.H:Set("Interface.WidgetCollapsed", not ui.H.Config.Interface.WidgetCollapsed)
    end)
    self.Body = ui:Text(self.Frame, "", UDim2.fromOffset(14, 46), UDim2.new(1, -28, 1, -54), 13)
    self.Body.TextYAlignment = Enum.TextYAlignment.Top
    self.Body.TextWrapped = true
    return self
end
function Widget:Refresh()
    local h, c = self.UI.H, self.UI.H.Config.Interface
    self.Frame.Visible = c.Widget
    self.Frame.BackgroundTransparency = 1 - c.WidgetOpacity
    self.Frame.Size = UDim2.fromOffset(245, c.WidgetCollapsed and 44 or 200)
    self.Body.Visible = not c.WidgetCollapsed
    local percent = h.Adapter:GetFuelPercent()
    self.Body.Text = string.format(
        "Task       %s\n\nGenerator  %s\nScrap      %d\nRate       %.1f/min\nEnemies    %d",
        h.Tasks.Active or "Idle",
        percent and string.format("%.0f%%", percent) or "Unknown",
        h.State.Stats.Scrap,
        h.State.Stats.Scrap / math.max((os.clock() - h.State.StartedAt) / 60, 1 / 60),
        h:Import("Utilities").Count(h.Registry.Enemies)
    )
end
return Widget
