local Version = {}
local function parts(value)
    local a, b, c = tostring(value):match("^(%d+)%.(%d+)%.(%d+)$")
    assert(a, "HESTIA expected numeric major.minor.patch version")
    return { tonumber(a), tonumber(b), tonumber(c) }
end
function Version.IsNewer(remote, installed)
    local a, b = parts(remote), parts(installed)
    for i = 1, 3 do
        if a[i] ~= b[i] then
            return a[i] > b[i]
        end
    end
    return false
end
function Version.Check(h)
    if h.VersionChecked then
        return
    end
    h.VersionChecked = true
    local raw = h.Root:GetAttribute("RemoteVersion")
    if not raw then
        h.Logger:Log("WARN", "Version information unavailable")
        return
    end
    local data = h.Services.HttpService:JSONDecode(raw)
    assert(data.name == "HESTIA", "HESTIA invalid version metadata")
    h.Release = data
    if Version.IsNewer(data.version, h.Version) then
        h.Notifications:Send(
            "Installed: " .. h.Version .. "\nLatest: " .. data.version,
            "HESTIA Update Available"
        )
    end
end
return Version
