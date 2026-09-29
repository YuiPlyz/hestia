local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Movement")
    ui:Toggle(section, "Override movement values", "Player.OverrideMovement")
    ui:Toggle(section, "Auto Sprint", "Player.AutoSprint")
    ui:Number(section, "Walk speed", "Player.WalkSpeed", 0, 100)
    ui:Number(section, "Sprint speed", "Player.SprintSpeed", 0, 150)
    ui:Number(section, "Jump power", "Player.JumpPower", 0, 150)
    ui:Toggle(section, "Infinite Jump", "Player.InfiniteJump")
    ui:Toggle(section, "Bunny Hop", "Player.BunnyHop")
    ui:Toggle(section, "Noclip", "Player.Noclip")
    ui:Toggle(section, "Fly (WASD / Space / Ctrl)", "Player.Fly")
    ui:Number(section, "Fly speed", "Player.FlySpeed", 1, 150)
    ui:Button(section, "Reset Movement", function()
        h.Features.Movement:Reset()
    end)
end
return Panel
