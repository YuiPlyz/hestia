local Importer = {}
Importer.__index = Importer
function Importer.new(root, manifest, requireModule)
    manifest = manifest or game:GetService("HttpService"):JSONDecode(root:GetAttribute("Manifest"))
    return setmetatable(
        { Root = root, Manifest = manifest, Require = requireModule or require, Cache = {}, Loading = {} },
        Importer
    )
end
function Importer:Import(name)
    local entry = self.Manifest.modules[name]
    if not entry then
        for _, candidate in pairs(self.Manifest.modules) do
            if candidate.path == name then
                entry = candidate
                break
            end
        end
    end
    assert(entry, "HESTIA unknown module: " .. tostring(name))
    local path = entry.path
    if self.Cache[path] ~= nil then
        return self.Cache[path]
    end
    assert(not self.Loading[path], "HESTIA dependency cycle at " .. path)
    self.Loading[path] = true
    local ok, result = xpcall(function()
        for _, dependency in ipairs(entry.dependencies or {}) do
            self:Import(dependency)
        end
        local object = self.Root
        for part in path:gmatch("[^/]+") do
            object = object:FindFirstChild((part:gsub("%.lua$", "")))
            assert(object, "HESTIA missing installed module: " .. path)
        end
        print("[HESTIA] Loading " .. path .. "...")
        return self.Require(object)
    end, debug.traceback)
    self.Loading[path] = nil
    if not ok then
        error(result, 0)
    end
    self.Cache[path] = result
    return result
end
function Importer:Clear()
    table.clear(self.Cache)
    table.clear(self.Loading)
end
return Importer
