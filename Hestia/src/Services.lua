local result = {}
for _, name in ipairs({
    "Players",
    "RunService",
    "CollectionService",
    "PathfindingService",
    "UserInputService",
    "TweenService",
    "Lighting",
    "HttpService",
    "ReplicatedStorage",
    "StarterGui",
}) do
    result[name] = game:GetService(name)
end
result.Workspace = workspace
return result
