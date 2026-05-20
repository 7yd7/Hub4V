local BASE_URL = "https://raw.githubusercontent.com/7yd7/Hub4V/Menu/"
getgenv().NEXS_BASE_URL = BASE_URL

local function import(path)
	local fullUrl = BASE_URL .. "/" .. path
	local success, content = pcall(function() return game:HttpGet(fullUrl) end)
	if not success then warn("Failed to import: " .. path) return nil end
	local loadResult = loadstring(content)()
	return loadResult
end

--[[
if queue_on_teleport and not getgenv().Nexs_Queued then
	getgenv().Nexs_Queued = true
	queue_on_teleport('loadstring(game:HttpGet("' .. BASE_URL .. '/client.luau"))()')
end
]]

local Notifications = import("src/notifications.luau")
getgenv().NexsNotifications = Notifications


local Loader = import("src/Loader.luau")
Notifications.Notify("System", "Select the UI you want to use.", 3)
local uiOptions = {
    { Name = "Fluent", Path = "src/UI/Fluent.luau", Recommended = true },
    { Name = "Rayfield", Path = "src/UI/Rayfield.luau" },
    { Name = "WindUI", Path = "src/UI/WindUI.luau", Recommended = true  },
    { Name = "Maclib", Path = "src/UI/Maclib.luau"},
    { Name = "Obsidian", Path = "src/UI/Obsidian.luau", Recommended = true },
    -- It doesn't work anymore 😭 { Name = "Dummy", Path = "src/UI/Dummy.luau" },
    { Name = "Flux", Path = "src/UI/Flux.luau" },
    { Name = "NOTHING", Path = "src/UI/NOTHING.luau"}
}

local instance
instance = Loader.Create({
    UIs = uiOptions,
    Rights = "7yd7 Hub v4",
    OnSelect = function(selected)
        if instance then
            instance.Close()
            instance.Loading(function()
                import(selected.Path)
            Notifications.Notify("System Ready", "7yd7 Hub has been loaded successfully.", 3)
            end)
        end
    end

})
