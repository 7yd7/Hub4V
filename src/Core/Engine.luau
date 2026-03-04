local HttpService = game:GetService("HttpService")
local Engine = {}

Engine.ProjectFolder = "7yd7Hub"
Engine.AssetFolder = Engine.ProjectFolder .. "/Assets/icon"

function Engine.GetBaseUrl()
    local url = getgenv().NEXS_BASE_URL or ""
    if url:sub(-1) == "/" then url = url:sub(1, -2) end
    return url
end

function Engine.Fetch(path)
    local baseUrl = Engine.GetBaseUrl()
    local s, r = pcall(function() return game:HttpGet(baseUrl .. "/" .. path) end)
    return s and r or nil
end

function Engine.GetIcon(name)
    if not name or name == "" then return nil end
    local lowerName = string.lower(tostring(name))
    if lowerName:sub(1, 2) == "i-" then
        local rawName = lowerName:sub(3)
        local fileName = "i-" .. rawName .. ".png"
        local localPath = Engine.AssetFolder .. "/" .. fileName
        
        pcall(function()
            if not isfolder("7yd7Hub") then makefolder("7yd7Hub") end
            if not isfolder("7yd7Hub/Assets") then makefolder("7yd7Hub/Assets") end
            if not isfolder("7yd7Hub/Assets/icon") then makefolder("7yd7Hub/Assets/icon") end
        end)

        if isfile(localPath) then
            local s, asset = pcall(function() return getcustomasset(localPath) end)
            if s and asset then return asset end
        end

        local baseUrl = Engine.GetBaseUrl()
        if baseUrl == "" then return nil end 
        local fullUrl = baseUrl .. "/Assets/icon/" .. fileName

        local success, content = pcall(function() return game:HttpGet(fullUrl) end)
        if success and content and content:sub(1, 1) ~= "<" and content ~= "" then
            pcall(function() writefile(localPath, content) end)
            if typeof(getcustomasset) == "function" then
                local s, asset = pcall(function() return getcustomasset(localPath) end)
                return s and asset or nil
            end
        end
        return nil
    end
    return name
end

function Engine.RunAction(code, params, context)
    if not code or code == "" then return end
    local scriptFunc, err = loadstring("local Value, Options = ...; " .. code)
    if not scriptFunc then warn("[7yd7 Engine] Syntax Error: " .. tostring(err)) return end
    local env = setmetatable({ HttpService = HttpService, Fetch = Engine.Fetch, GetIcon = Engine.GetIcon }, {__index = getfenv(0)})
    if context then for k, v in pairs(context) do env[k] = v end end
    setfenv(scriptFunc, env)
    local val = params and params.Value
    local opt = params and params.Options or (context and context.Options)
    if params and params.Sync then pcall(scriptFunc, val, opt)
    else task.spawn(function() pcall(scriptFunc, val, opt) end) end
end

local function addElementsToTab(tabObj, elementsArray, adapter, EngineRef)
    if not elementsArray then return end
    for _, el in ipairs(elementsArray) do
        local scriptCode = el.Script
        if el.SectionTitle then tabObj:AddSection({ Title = el.SectionTitle, Icon = EngineRef.GetIcon(el.SectionIcon), SectionPosition = el.SectionPosition }) end

        if el.Type == "Logic" then EngineRef.RunAction(scriptCode, {Value = tabObj, Sync = true}, adapter:GetContext())
        elseif el.Type == "Paragraph" then tabObj:AddParagraph({ Title = el.Title or "", Content = el.Content or "" })
        elseif el.Type == "Button" then tabObj:AddButton({ Id = el.Id, Title = el.Title or "Button", Description = el.Description or "", Callback = function() EngineRef.RunAction(scriptCode, nil, adapter:GetContext()) end })
        elseif el.Type == "Toggle" then tabObj:AddToggle(el.Id or el.Title, { Title = el.Title or "Toggle", Default = el.Default or false, Callback = function(V) EngineRef.RunAction(scriptCode, {Value = V}, adapter:GetContext()) end })
        elseif el.Type == "Slider" then tabObj:AddSlider(el.Id or el.Title, { Title = el.Title or "Slider", Default = el.Default or 0, Min = el.Min or 0, Max = el.Max or 100, Rounding = el.Rounding or 1, Callback = function(V) EngineRef.RunAction(scriptCode, {Value = V}, adapter:GetContext()) end })
        elseif el.Type == "Input" then tabObj:AddInput(el.Id or el.Title, { Title = el.Title or "Input", Default = el.Default or "", Placeholder = el.Placeholder or "", Callback = function(V) EngineRef.RunAction(scriptCode, {Value = V}, adapter:GetContext()) end })
        elseif el.Type == "Dropdown" then tabObj:AddDropdown(el.Id or el.Title, { Title = el.Title or "Dropdown", Values = el.Values or {}, Default = el.Default or 1, Multi = el.Multi or false, Callback = function(V) EngineRef.RunAction(scriptCode, {Value = V}, adapter:GetContext()) end })
        elseif el.Type == "Section" then tabObj:AddSection({ Title = el.Title, Icon = EngineRef.GetIcon(el.Icon), SectionPosition = el.SectionPosition })
        end
    end
end

local function collectIcons(tabs, set)
    if not tabs then return end
    for _, t in ipairs(tabs) do
        if t.Icon then set[t.Icon] = true end
        if t.Elements then
            for _, el in ipairs(t.Elements) do
                if el.SectionIcon then set[el.SectionIcon] = true end
                if el.Type == "Section" and el.Icon then set[el.Icon] = true end
            end
        end
    end
end

function Engine.LoadAndBuild(adapter)
    local rawData = Engine.Fetch("Script/Default.json")
    if not rawData then warn("[7yd7 Engine] Failed to load Default JSON") return end

    local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(rawData) end)
    if not decodeSuccess then warn("[7yd7 Engine] JSON Parse Error in Default.json") return end

    local currentGameData = nil
    local currentGameName = nil

    local gamesDataRaw = Engine.Fetch("Script/Games.json")
    if gamesDataRaw then
        local sDec, games = pcall(function() return HttpService:JSONDecode(gamesDataRaw) end)
        if sDec then
            local currentGame
            for _, g in pairs(games) do
                if tostring(g.id) == tostring(game.PlaceId) then currentGame = g break end
            end

            if currentGame and currentGame.path then
                local gameConfigRaw = Engine.Fetch("Script/Games/" .. currentGame.path)
                if gameConfigRaw then
                    local sDec2, gData = pcall(function() return HttpService:JSONDecode(gameConfigRaw) end)
                    if sDec2 and gData then
                        currentGameData = gData
                        currentGameName = currentGame.name
                    end
                end
            end
        end
    end

    local iconSet = {}
    if data.Window then
        if data.Window.Logo then iconSet[data.Window.Logo] = true end
        if data.Window.iconLogo then iconSet[data.Window.iconLogo] = true end
    end
    collectIcons(data.Tabs, iconSet)
    if currentGameData and currentGameData.Tabs then collectIcons(currentGameData.Tabs, iconSet) end

    local threads = 0
    for name, _ in pairs(iconSet) do
        threads = threads + 1
        task.spawn(function()
            Engine.GetIcon(name)
            threads = threads - 1
        end)
    end

    if threads > 0 then
        local start = tick()
        repeat task.wait() until threads == 0 or (tick() - start) > 10
    end

    local winData = data.Window or {}
    local windowTitle = winData.Title or "7yd7 Hub v4"
    local windowSub = winData.SubTitle or ""

    pcall(function()
        local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        windowTitle = windowTitle:gsub("{PlaceName}", placeName):gsub("{PlaceId}", tostring(game.PlaceId))
        windowSub = windowSub:gsub("{PlaceName}", placeName):gsub("{PlaceId}", tostring(game.PlaceId))
    end)
    
    local Window = adapter:CreateWindow({
        Title = windowTitle, SubTitle = windowSub, TabWidth = winData.TabWidth or 160,
        Size = winData.Size, Acrylic = winData.Acrylic, Theme = winData.Theme,
        Logo = Engine.GetIcon(winData.Logo),
        iconLogo = Engine.GetIcon(winData.iconLogo)
    })

    for _, tabData in ipairs(data.Tabs or {}) do
        tabData.Icon = Engine.GetIcon(tabData.Icon)
        local Tab = Window:AddTab(tabData)
        addElementsToTab(Tab, tabData.Elements, adapter, Engine)
    end

    if currentGameData and currentGameData.Tabs then
        local Dashboard = Window:AddTab({ Title = currentGameName, Icon = Engine.GetIcon("I-game") })
        for _, category in ipairs(currentGameData.Tabs) do
            if category.Title then
                Dashboard:AddParagraph({ Title = "— " .. category.Title .. " —", Content = "" })
            end
            addElementsToTab(Dashboard, category.Elements, adapter, Engine)

            local DedicatedTab = Window:AddTab({
                Title = category.Title or "Category",
                Icon = Engine.GetIcon(category.Icon)
            })
            addElementsToTab(DedicatedTab, category.Elements, adapter, Engine)
        end
    end
    
    if adapter.OnFinished then adapter:OnFinished() end
end

return Engine
