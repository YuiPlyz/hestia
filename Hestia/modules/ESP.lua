local ESP = {}
ESP.__index = ESP
function ESP.new(h)
    return setmetatable({ H = h, Providers = {}, Objects = {}, Cursor = 1, Queue = {} }, ESP)
end
function ESP:Register(name, provider)
    self.Providers[name] = provider
end
function ESP:Remove(object)
    local record = self.Objects[object]
    if record then
        record.Highlight:Destroy()
        record.Gui:Destroy()
        self.Objects[object] = nil
    end
end
function ESP:Create(object, category)
    local root = self.H.Adapter:Root(object)
    if not root then
        return
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "HESTIA " .. category
    highlight.Adornee = object
    highlight.FillTransparency = 0.75
    highlight.Parent = self.H.UI.Gui
    local gui = Instance.new("BillboardGui")
    gui.Name = "HESTIA " .. category
    gui.Adornee = root
    gui.Size = UDim2.fromOffset(180, 48)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Parent = self.H.UI.Gui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextStrokeTransparency = 0.4
    label.Parent = gui
    self.Objects[object] = { Highlight = highlight, Gui = gui, Label = label, Category = category }
end
function ESP:InRange(distance, category)
    local maximum = self.H.Config.Visuals.MaxDistance
    return (maximum == 0 or distance <= maximum)
        and (category.MaxDistance == 0 or distance <= category.MaxDistance)
end
function ESP:Reconcile()
    local desired = {}
    for _, provider in pairs(self.Providers) do
        for object, category in pairs(provider()) do
            local config = self.H.Config.Visuals.Categories[category]
            if
                config
                and config.Enabled
                and self.H.Adapter:Valid(object)
                and self:InRange(self.H.Adapter:Distance(object), config)
            then
                desired[object] = category
            end
        end
    end
    for object, record in pairs(self.Objects) do
        if desired[object] ~= record.Category then
            self:Remove(object)
        end
    end
    table.clear(self.Queue)
    for object, category in pairs(desired) do
        if not self.Objects[object] then
            self:Create(object, category)
        end
        table.insert(self.Queue, object)
    end
    self.Cursor = math.min(self.Cursor, math.max(1, #self.Queue))
end
function ESP:Update()
    local h = self.H
    -- At most 100 objects per tick; large populations rotate through the queue.
    for _ = 1, math.min(100, #self.Queue) do
        local object = self.Queue[self.Cursor]
        self.Cursor = self.Cursor % #self.Queue + 1
        local record = self.Objects[object]
        if record then
            if not h.Adapter:Valid(object) then
                self:Remove(object)
            else
                local c = h.Config.Visuals.Categories[record.Category]
                local distance = h.Adapter:Distance(object)
                local visible = c.Enabled and self:InRange(distance, c)
                local color = Color3.fromRGB(table.unpack(c.Color))
                record.Highlight.Enabled = visible and c.Highlight
                record.Highlight.FillColor, record.Highlight.OutlineColor = color, color
                record.Gui.Enabled = visible and (c.Name or c.Distance or c.Health)
                record.Gui.Adornee = h.Adapter:Root(object)
                record.Label.TextColor3 = color
                record.Label.TextSize = h.Config.Visuals.TextSize
                record.Highlight.FillTransparency = h.Config.Visuals.FillTransparency
                record.Highlight.OutlineTransparency = h.Config.Visuals.OutlineTransparency
                local text = {}
                if c.Name then
                    table.insert(text, object.Name)
                end
                if c.Distance then
                    table.insert(text, string.format("%.0f studs", distance))
                end
                local hp, maximum = h.Adapter:Health(object)
                if c.Health and hp and maximum then
                    table.insert(text, string.format("%.0f/%.0f HP", hp, maximum))
                end
                record.Label.Text = table.concat(text, "  ")
            end
        end
    end
end
function ESP:Start()
    for _, provider in ipairs({ "ItemESP", "MobESP", "PlayerESP", "StructureESP" }) do
        self.H:Import(provider).Register(self, self.H)
    end
    self.H.Scheduler:Add("ESP.Registry", 0.5, function()
        self:Reconcile()
    end, function()
        self:Stop()
    end)
    self.H.Scheduler:Add("ESP.Update", 0.1, function()
        self:Update()
    end, function()
        self:Stop()
    end)
end
function ESP:Stop()
    self.H.Scheduler:Remove("ESP.Registry")
    self.H.Scheduler:Remove("ESP.Update")
    for object in pairs(self.Objects) do
        self:Remove(object)
    end
    table.clear(self.Queue)
end
ESP.Destroy = ESP.Stop
return ESP
