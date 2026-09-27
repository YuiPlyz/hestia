"""HESTIA repository maintenance: generate declarative UI panels and source catalog."""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def write(path, text):
    (ROOT / path).write_text(text.strip() + '\n', encoding='utf-8')

def catalog(reference):
    source = Path(reference).read_text(encoding='utf-8-sig')
    section = source.split('local espDefinitions = {', 1)[1].split('-- Build per-ESP', 1)[0]
    items = {key: re.findall(r'"([^"\n]+)"', names) for key, names in re.findall(r'key\s*=\s*"([^"]+)".*?items\s*=\s*\{(.*?)\}', section, re.S)}
    extra = source.split('local extraItemCategories = {', 1)[1].split('for catName', 1)[0]
    for key, names in re.findall(r'(\w+)\s*=\s*\{([^{}]*)\}', extra):
        items[key] = re.findall(r'"([^"\n]+)"', names)
    items['Resource'].remove('Scrap')
    items['Scrap'] = ['Scrap']
    write('data/Items.lua', 'return {\n' + '\n'.join('    '+k+' = { '+', '.join(json.dumps(n) for n in v)+' },' for k,v in items.items()) + '\n}')
    weapons = source.split('local weaponSwingSpeeds = {',1)[1].split('\n}',1)[0]
    write('data/Weapons.lua', 'return {\n' + '\n'.join(f'    [{json.dumps(n)}] = {{ SwingDelay = {v} }},' for n,v in re.findall(r'\["([^"]+)"\]\s*=\s*([0-9.]+)', weapons)) + '\n}')

PANELS = {
 'Farming': [
  ('Scrap grinding', [
   ('T','Auto Grind Scrap','Farming.AutoScrap'), ('C','Target priority','Farming.ScrapPriority',['Nearest','Value']),
   ('N','Search radius','Farming.ScrapRadius',5,5000), ('N','Interaction delay','Farming.ScrapDelay',0.1,10),
   ('N','Target timeout','Farming.TargetTimeout',3,120), ('N','Stuck timeout','Farming.StuckTimeout',1,20), ('N','Path retries','Farming.PathRetries',0,10),
   ('J','Whitelist (JSON name: true)','Farming.ScrapWhitelist'), ('J','Blacklist (JSON name: true)','Farming.ScrapBlacklist')]),
  ('Item and fuel farming', [('T','Auto Item Farm','Farming.AutoItems'),('N','Item radius','Farming.ItemRadius',5,5000),('J','Item categories','Farming.ItemCategories'),('T','Build fuel reserve','Farming.AutoFuelFarm'),('N','Fuel reserve','Farming.FuelReserve',0,1000)]),
  ('Pickup', [('T','Auto Pickup','Farming.AutoPickup'),('T','All categories','Farming.AllItems'),('N','Pickup radius','Farming.PickupRadius',1,100),('N','Pickup delay','Farming.PickupDelay',0.1,10),('J','Whitelist','Farming.PickupWhitelist'),('J','Blacklist','Farming.PickupBlacklist'),('J','Category filters','Farming.PickupCategories')]),
  ('Storage', [('T','Auto Store','Storage.Enabled'),('T','Only when inventory full','Storage.OnlyWhenFull'),('J','Categories','Storage.Categories'),('J','Keep items','Storage.Keep'),('J','Minimum quantities','Storage.Minimum'),('N','Keep scrap','Storage.ScrapReserve',0,10000),('N','Keep fuel per type','Storage.FuelReserve',0,1000)])
 ],
 'Generator': [('Generator automation', [('T','Auto Fuel Generator','Generator.AutoFuel'),('N','Start below (%)','Generator.FuelBelow',1,99),('N','Stop at (%)','Generator.FuelUntil',2,100),('N','Emergency at (%)','Generator.EmergencyFuel',0,99),('N','Fuel search radius','Generator.FuelRadius',5,5000),('J','Fuel priority (JSON array)','Generator.FuelPriority')])],
 'Combat': [('NPC combat', [('T','Kill Aura','Combat.KillAura'),('C','Target priority','Combat.Priority',['Nearest','LowestHP','HighestHP']),('T','Boss priority','Combat.BossPriority'),('N','Range','Combat.Range',1,50),('N','Attack delay','Combat.AttackDelay',0.1,10),('T','Auto equip weapon','Combat.AutoEquip'),('T','Pause farming during threats','Combat.PauseFarming'),('T','Target indicator','Combat.TargetIndicator')]),
 ('Survival', [('T','Auto Heal','Survival.AutoHeal'),('N','Heal below (%)','Survival.HealBelow',1,100),('T','Auto Eat','Survival.AutoEat'),('N','Eat below (%)','Survival.EatBelow',1,100),('T','Auto Drink','Survival.AutoDrink'),('N','Drink below (%)','Survival.DrinkBelow',1,100),('T','Auto Bandage','Survival.AutoBandage'),('N','Emergency health (%)','Survival.EmergencyHealth',1,100)])],
 'Player': [('Movement', [('T','Override movement values','Player.OverrideMovement'),('T','Auto Sprint','Player.AutoSprint'),('N','Walk speed','Player.WalkSpeed',0,100),('N','Sprint speed','Player.SprintSpeed',0,150),('N','Jump power','Player.JumpPower',0,150),('T','Infinite Jump','Player.InfiniteJump'),('T','Bunny Hop','Player.BunnyHop'),('T','Noclip','Player.Noclip'),('T','Fly (WASD / Space / Ctrl)','Player.Fly'),('N','Fly speed','Player.FlySpeed',1,150)])],
 'Misc': [('Structure repair', [('T','Auto Repair','Repair.Enabled'),('C','Priority','Repair.Priority',['Nearest','LowestHealth']),('N','Radius','Repair.Radius',1,100),('N','Repair interval','Repair.Rate',0.2,10),('T','Emergency repair priority','Repair.Emergency'),('N','Emergency below (%)','Repair.EmergencyBelow',1,100)]),('Utilities', [('T','Fullbright','Visuals.Fullbright'),('T','Debug logging','Debug')])],
}

EXTRA = {
 'Generator': '''ui:Label(section, "Fuel", function() local p = h.Adapter:GetFuelPercent() return p and string.format("%s  %.0f%%", string.rep("|", math.floor(p / 10)), p) or "Unavailable" end)
    ui:Label(section, "Status", function() return h.Features.Generator and h.Features.Generator.Status or "Unavailable" end)
    ui:Label(section, "Current fuel", function() return h.Features.Generator and h.Features.Generator.CurrentFuel or "None" end)''',
 'Player': '''ui:Button(section, "Reset Movement", function() h.Features.Movement:Reset() end)''',
 'Combat': '''ui:Label(section, "Current target", function() local c = h.Features.Combat return c and c.Target and c.Target.Name or "None" end)
    ui:Label(section, "Enemy count", function() return h:Import("Utilities").Count(h.Registry.Enemies) end)''',
 'Misc': '''ui:Label(section, "Structure health", function() return h.Features.Repair and h.Features.Repair.Status or "Disabled" end)
    ui:Button(section, "Rejoin this place", function() game:GetService("TeleportService"):Teleport(game.PlaceId, h.Services.Players.LocalPlayer) end)''',
}

def panels():
    methods = {'T':'Toggle','N':'Number','C':'Choice','J':'JSON'}
    for name, sections in PANELS.items():
        lines = ['local Panel = {}','function Panel.Build(ui, tab, h)','    local section']
        for title, controls in sections:
            lines.append('    section = ui:Section(tab, '+json.dumps(title)+')')
            for kind, label, path, *args in controls:
                encoded = [('{ '+', '.join(json.dumps(s) for s in a)+' }') if isinstance(a,list) else str(a) for a in args]
                lines.append('    ui:'+methods[kind]+'(section, '+', '.join([json.dumps(label),json.dumps(path)]+encoded)+')')
        if name in EXTRA: lines.append('    '+EXTRA[name])
        lines.extend(['end','return Panel'])
        write('ui/'+name+'.lua','\n'.join(lines))

if __name__ == '__main__':
    panels()
    if len(sys.argv) > 1: catalog(sys.argv[1])
