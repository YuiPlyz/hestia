local Settings = {}
function Settings.Build(ui, tab, h)
    local section = ui:Section(tab, "HESTIA appearance")
    ui:JSON(section, "Accent [R,G,B]", "Interface.Accent")
    ui:Choice(section, "Menu key", "Interface.MenuKey", { "RightShift", "RightControl", "F4", "Insert" })
    ui:Choice(section, "Notification side", "Interface.NotificationSide", { "Right", "Left" })
    ui:Toggle(section, "Floating widget", "Interface.Widget")
    ui:Toggle(section, "Collapse widget", "Interface.WidgetCollapsed")
    ui:Number(section, "Widget opacity", "Interface.WidgetOpacity", 0.1, 1)
    section = ui:Section(tab, "Configuration")
    local raw = ""
    local box = ui:Input(section, "Configuration JSON", function()
        return raw
    end, function(value)
        raw = value
    end)
    box.MultiLine = true
    ui:Button(section, "Export config to text field", function()
        raw = h.ConfigStore:Export()
        box.Text = raw
        box:CaptureFocus()
    end)
    ui:Button(section, "Import config from text field", function()
        raw = box.Text
        h.ConfigStore:Import(raw)
        h.Notifications:Send("Configuration imported.")
    end)
    ui:Button(section, "Save configuration", function()
        local ok, reason = h.ConfigStore:Save()
        if not ok then
            h.Notifications:Send(tostring(reason))
        end
    end)
    ui:Button(section, "Load configuration", function()
        local ok, err = h.ConfigStore:Load()
        if not ok then
            h.Notifications:Send(tostring(err))
        end
    end)
    section = ui:Section(tab, "Release and diagnostics")
    ui:Label(section, "Installed", function()
        return h.Version
    end)
    ui:Label(section, "Channel", function()
        return h.Release and h.Release.channel or h.Root:GetAttribute("Channel")
    end)
    ui:Label(section, "Latest checked at installation", function()
        return h.Release and h.Release.version or "Unavailable"
    end)
    ui:Button(section, "Print changelog", function()
        for _, line in ipairs(h.Release and h.Release.changelog or {}) do
            h.Logger:Log("INFO", line)
        end
    end)
    ui:Button(section, "Print diagnostics", function()
        for _, line in ipairs(h.Logger.History) do
            print(line)
        end
    end)
    ui:Button(section, "Unload HESTIA", function()
        h:Unload()
    end)
end
return Settings
