local HttpService = game:GetService("HttpService")
local Engine = {}

Engine.ProjectFolder = "7yd7Hub"
Engine.AssetFolder = Engine.ProjectFolder .. "/Assets/icon"

local iconCache = {}
local foldersCreated = false
local DEBUG = (getgenv and getgenv().NEXS_DEBUG) == true

local function debugLog(msg)
    if DEBUG then
        warn("[7yd7 Engine][Debug] " .. tostring(msg))
    end
end

local function ensureFolders()
    if foldersCreated then return end
    foldersCreated = true
    pcall(function()
        if not isfolder("7yd7Hub") then makefolder("7yd7Hub") end
        if not isfolder("7yd7Hub/Assets") then makefolder("7yd7Hub/Assets") end
        if not isfolder("7yd7Hub/Assets/icon") then makefolder("7yd7Hub/Assets/icon") end
    end)
end

function Engine.GetBaseUrl()
    local url = getgenv().NEXS_BASE_URL or ""
    if url:sub(-1) == "/" then url = url:sub(1, -2) end
    return url
end

function Engine.Fetch(path)
    local pkg = getgenv().NEXS_PACKAGE
    if pkg and typeof(pkg[path]) == "string" then
        return pkg[path]
    end
    local baseUrl = Engine.GetBaseUrl()
    local s, r = pcall(function() return game:HttpGet(baseUrl .. "/" .. path) end)
    return s and r or nil
end

function Engine.GetIcon(name)
    if not name or name == "" then return nil end
    local lowerName = string.lower(tostring(name))
    if lowerName:sub(1, 2) == "i-" then
        if iconCache[name] then
            return iconCache[name]
        end
        
        local fileName = tostring(name) .. ".png"
        local localPath = Engine.AssetFolder .. "/" .. fileName

        local pkg = getgenv().NEXS_PACKAGE
        local b64 = getgenv().NEXS_B64DECODE and pkg and pkg["Assets/icon/" .. fileName]
        if b64 then
            ensureFolders()
            local okD, data = pcall(getgenv().NEXS_B64DECODE, b64)
            if okD and data then
                pcall(function() writefile(localPath, data) end)
                local s, asset = pcall(function() return getcustomasset(localPath) end)
                if s and asset then
                    iconCache[name] = asset
                    return asset
                end
            end
        end

        if isfile(localPath) then
            local s, asset = pcall(function() return getcustomasset(localPath) end)
            if s and asset then
                iconCache[name] = asset
                return asset
            end
        end

        local baseUrl = Engine.GetBaseUrl()
        if baseUrl == "" then return nil end 
        local fullUrl = baseUrl .. "/Assets/icon/" .. fileName

        local success, content = pcall(function() return game:HttpGet(fullUrl) end)
        if success and content and content:sub(1, 1) ~= "<" and content ~= "" then
            ensureFolders()
            pcall(function() writefile(localPath, content) end)
            if typeof(getcustomasset) == "function" then
                local s, asset = pcall(function() return getcustomasset(localPath) end)
                if s and asset then
                    iconCache[name] = asset
                    return asset
                end
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

local function makeElementSyncKey(el)
    local idPart = tostring(el.Id or el.Title or "")
    return (el.Type or "Unknown") .. "::" .. idPart
end

local function registerSyncedControl(syncStore, key, control)
    if not syncStore.controls[key] then
        syncStore.controls[key] = {}
    end
    table.insert(syncStore.controls[key], control)

    if syncStore.values[key] ~= nil and control and control.SetValue then
        syncStore.busy[key] = true
        pcall(function() control:SetValue(syncStore.values[key]) end)
        syncStore.busy[key] = nil
    end
end

local function broadcastControlValue(syncStore, key, sourceControl, value)
    syncStore.values[key] = value
    local controls = syncStore.controls[key]
    if not controls then return end
    for _, control in ipairs(controls) do
        if control ~= sourceControl and control and control.SetValue then
            pcall(function() control:SetValue(value) end)
        end
    end
end

local function makeControlCallback(el, scriptCode, context, EngineRef, syncStore, sourceControlRef)
    local key = makeElementSyncKey(el)
    return function(V)
        if syncStore.busy[key] then return end
        syncStore.busy[key] = true
        broadcastControlValue(syncStore, key, sourceControlRef.value, V)
        EngineRef.RunAction(scriptCode, {Value = V}, context)
        syncStore.busy[key] = nil
    end
end

local function addElementsToTab(tabObj, elementsArray, adapter, EngineRef, syncStore, context)
    if not elementsArray then return end
    local elementBuilders = {
        Logic = function(el, scriptCode)
            EngineRef.RunAction(scriptCode, {Value = tabObj, Sync = true}, context)
        end,
        Paragraph = function(el)
            tabObj:AddParagraph({ Title = el.Title or "", Content = el.Content or "" })
        end,
        Button = function(el, scriptCode)
            tabObj:AddButton({
                Id = el.Id,
                Title = el.Title or "Button",
                Description = el.Description or "",
                Callback = function() EngineRef.RunAction(scriptCode, nil, context) end
            })
        end,
        Section = function(el)
            tabObj:AddSection({ Title = el.Title, Icon = EngineRef.GetIcon(el.Icon), SectionPosition = el.SectionPosition })
        end
    }

    for _, el in ipairs(elementsArray) do
        local scriptCode = el.Script
        if el.SectionTitle then tabObj:AddSection({ Title = el.SectionTitle, Icon = EngineRef.GetIcon(el.SectionIcon), SectionPosition = el.SectionPosition }) end

        if elementBuilders[el.Type] then
            elementBuilders[el.Type](el, scriptCode)
        elseif el.Type == "Toggle" or el.Type == "Slider" or el.Type == "Input" or el.Type == "Dropdown" then
            local key = makeElementSyncKey(el)
            local optionId = el.Id or el.Title
            local sourceControlRef = { value = nil }
            local callback = makeControlCallback(el, scriptCode, context, EngineRef, syncStore, sourceControlRef)

            local control
            if el.Type == "Toggle" then
                control = tabObj:AddToggle(optionId, {
                    Title = el.Title or "Toggle",
                    Default = el.Default or false,
                    Callback = callback
                })
            elseif el.Type == "Slider" then
                control = tabObj:AddSlider(optionId, {
                    Title = el.Title or "Slider",
                    Default = el.Default or 0,
                    Min = el.Min or 0,
                    Max = el.Max or 100,
                    Rounding = el.Rounding or 1,
                    Callback = callback
                })
            elseif el.Type == "Input" then
                control = tabObj:AddInput(optionId, {
                    Title = el.Title or "Input",
                    Default = el.Default or "",
                    Placeholder = el.Placeholder or "",
                    Callback = callback
                })
            elseif el.Type == "Dropdown" then
                control = tabObj:AddDropdown(optionId, {
                    Title = el.Title or "Dropdown",
                    Values = el.Values or {},
                    Default = el.Default or 1,
                    Multi = el.Multi or false,
                    Callback = callback
                })
            end

            if not control and optionId ~= nil and adapter and adapter.Options then
                control = adapter.Options[tostring(optionId)] or adapter.Options[optionId]
            end

            if control then
                sourceControlRef.value = control
                registerSyncedControl(syncStore, key, control)
                local resolved = el.Default
                if resolved == nil then
                    if el.Type == "Toggle" then resolved = false
                    elseif el.Type == "Slider" then resolved = 0
                    elseif el.Type == "Input" then resolved = ""
                    elseif el.Type == "Dropdown" then resolved = (el.Values or {})[1]
                    end
                end
                if resolved ~= nil then control.Default = resolved end
            end
        end
    end
end

local function countSectionsInElements(elementsArray)
    local total = 0
    if not elementsArray then return total end
    for _, el in ipairs(elementsArray) do
        if el.SectionTitle then total = total + 1 end
        if el.Type == "Section" then total = total + 1 end
    end
    return total
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

local function idMatches(targetId, placeId)
    if targetId == nil then return false end

    if type(targetId) == "table" then
        for _, candidate in pairs(targetId) do
            if tostring(candidate) == tostring(placeId) then
                return true
            end
        end
        return false
    end

    return tostring(targetId) == tostring(placeId)
end

local function entryMatchesPlace(entry, placeId)
    if type(entry) ~= "table" then return false end
    if idMatches(entry.id, placeId) then return true end
    if idMatches(entry.ids, placeId) then return true end
    return false
end

local function resolveGameMatch(games, placeId)
    local fallbackGame = nil

    for _, g in pairs(games) do
        local subplaces = g.subplaces
        if type(subplaces) == "table" then
            for subName, sub in pairs(subplaces) do
                if type(sub) == "table" and entryMatchesPlace(sub, placeId) then
                    return {
                        game = g,
                        path = sub.path,
                        subName = subName,
                        name = sub.name or subName or g.name,
                    }
                end
            end
        end

        if entryMatchesPlace(g, placeId) then
            fallbackGame = {
                game = g,
                path = g.path,
                subName = nil,
                name = g.name,
            }
        end
    end

    return fallbackGame
end

local function buildConfigCandidates(pathValue, subName)
    if type(pathValue) ~= "string" or pathValue == "" then
        return {}
    end

    if pathValue:sub(-5):lower() == ".json" then
        return { pathValue }
    end

    local candidates = { pathValue .. ".json" }
    if subName and subName ~= "" then
        table.insert(candidates, pathValue .. "/" .. subName .. ".json")
    end
    return candidates
end

local function fetchGameConfig(pathValue, subName)
    local candidates = buildConfigCandidates(pathValue, subName)
    for _, candidatePath in ipairs(candidates) do
        local raw = Engine.Fetch("Script/Games/" .. candidatePath)
        if raw then
            local sDec, gData = pcall(function() return HttpService:JSONDecode(raw) end)
            if sDec and gData then
                return gData, candidatePath
            end
        end
    end
    return nil, nil
end

function Engine.LoadAndBuild(adapter)
    local t0 = tick()
    local syncStore = {
        controls = {},
        values = {},
        busy = {}
    }

    local rawData, gamesDataRaw
    local fetchThreads = 2
    task.spawn(function()
        rawData = Engine.Fetch("Script/Default.json")
        fetchThreads = fetchThreads - 1
    end)
    task.spawn(function()
        gamesDataRaw = Engine.Fetch("Script/Games.json")
        fetchThreads = fetchThreads - 1
    end)

    local waitStart = tick()
    repeat task.wait() until fetchThreads == 0 or (tick() - waitStart) > 5
    debugLog(string.format("Fetch Default/Games finished in %.3fs", tick() - waitStart))

    if not rawData then warn("[7yd7 Engine] Failed to load Default JSON") return end

    local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(rawData) end)
    if not decodeSuccess then warn("[7yd7 Engine] JSON Parse Error in Default.json") return end
    debugLog("Default.json parsed")

    local currentGameData = nil
    local currentGameName = nil

    if gamesDataRaw then
        local sDec, games = pcall(function() return HttpService:JSONDecode(gamesDataRaw) end)
        if sDec then
            local resolvedGame = resolveGameMatch(games, game.PlaceId)

            if resolvedGame and resolvedGame.path then
                local gData, matchedPath = fetchGameConfig(resolvedGame.path, resolvedGame.subName)
                if gData then
                    currentGameData = gData
                    currentGameName = resolvedGame.name
                    if getgenv().NEXS_DEBUG_GAMES then
                        warn(string.format("[7yd7 Engine] Matched PlaceId=%s -> %s", tostring(game.PlaceId), tostring(matchedPath or resolvedGame.path)))
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
    local iconCount = 0
    for name, _ in pairs(iconSet) do
        threads = threads + 1
        iconCount = iconCount + 1
        task.spawn(function()
            Engine.GetIcon(name)
            threads = threads - 1
        end)
    end

    if threads > 0 then
        local start = tick()
        repeat task.wait() until threads == 0 or (tick() - start) > 4
        debugLog(string.format("Icon warmup finished in %.3fs (%d icons)", tick() - start, iconCount))
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
    local sharedContext = adapter:GetContext()

    local settingsExists = false
    for _, tabData in ipairs(data.Tabs or {}) do
        if tabData.Title == "Settings" then settingsExists = true; break end
    end
    if not settingsExists then
        table.insert(data.Tabs, { Title = "Settings", Icon = "I-config", Elements = {} })
    end
    for _, tabData in ipairs(data.Tabs or {}) do
        if tabData.Title == "Settings" then
            tabData.Elements = tabData.Elements or {}
            table.insert(tabData.Elements, { Type = "Section", Title = "Config Manager", Icon = "I-config" })
            table.insert(tabData.Elements, { Type = "Logic", Script = [[
                local ok, CM = pcall(function()
                    local src = Fetch("src/Core/configs.luau")
                    return src and loadstring(src)()
                end)
                if not ok or not CM then return end
                local cm = CM.new(Options)
                cm:SetFolder("7yd7Hub/configs")
                cm:IgnoreIndexes({ "_CMSaveAs", "_CMDropdown" })
                Value:AddInput("_CMSaveAs", { Title = "Config Name", Placeholder = "Enter config name..." })
                local saveInput = Options["_CMSaveAs"]
                local selected
                local function unique(name)
                    if not cm:Exists(name) then return name end
                    local n = 1
                    while cm:Exists(name .. "_" .. n) do n = n + 1 end
                    return name .. "_" .. n
                end
                local function onSave()
                    local name = saveInput and saveInput.Value or ""
                    if name ~= "" then
                        name = unique(name)
                        cm:Save(name)
                        if saveInput and saveInput.SetValue then saveInput:SetValue(name) end
                        if dd and dd.SetValues then
                            local nl = cm:List()
                            if #nl == 0 then nl = {"No configs"} end
                            dd:SetValues(nl)
                        end
                        if dd then selected = name end
                    end
                end
                Value:AddButton({ Title = "Save As", Callback = onSave })
                local list = cm:List()
                if #list == 0 then list = {"No configs"} end
                selected = list[1]
                Value:AddDropdown("_CMDropdown", { Title = "Config List", Values = list, Default = selected, Callback = function(v) selected = v end })
                local dd = Options["_CMDropdown"]
                local function refreshDD()
                    local nl = cm:List()
                    if #nl == 0 then nl = {"No configs"} end
                    if dd and dd.SetValues then dd:SetValues(nl) end
                end
                Value:AddButton({ Title = "Load", Callback = function()
                    if selected and selected ~= "No configs" then cm:Load(selected) end
                end })
                Value:AddButton({ Title = "Overwrite", Callback = function()
                    if selected and selected ~= "No configs" then cm:Save(selected) end
                end })
                Value:AddButton({ Title = "Delete", Callback = function()
                    if selected and selected ~= "No configs" then cm:Delete(selected); refreshDD(); selected = nil end
                end })
                local resetBusy = false
                Value:AddButton({ Title = "Reset All", Callback = function()
                    if resetBusy then return end
                    resetBusy = true
                    for id, opt in pairs(Options) do
                        if opt and opt.Value ~= nil and tostring(id):sub(1, 3) ~= "_CM" then
                            local def = opt.Default
                            if def == nil then
                                local t = type(opt.Value)
                                if t == "boolean" then def = false
                                elseif t == "number" then def = 0
                                elseif t == "string" then def = ""
                                end
                            end
                            if def ~= nil then
                                if opt.SetValue then
                                    opt._silent = true
                                    pcall(function() opt:SetValue(def) end)
                                    opt._silent = nil
                                else
                                    opt.Value = def
                                end
                            end
                        end
                    end
                    resetBusy = false
                end })
                Value:AddSection({ Title = "Autoload Config", Icon = GetIcon("I-cloud") })
                local autoloadPara = Value:AddParagraph({ Title = "", Content = "Current autoload config: " .. (cm:GetAutoloadConfig() or "none") })
                local function updateAutoloadText()
                    local a = cm:GetAutoloadConfig()
                    if autoloadPara and autoloadPara.SetDesc then
                        autoloadPara:SetDesc("Current autoload config: " .. (a or "none"))
                    end
                end
                Value:AddButton({ Title = "Set as Autoload", Callback = function()
                    if selected and selected ~= "No configs" then
                        cm:SetAutoloadConfig(selected)
                        updateAutoloadText()
                    end
                end })
                Value:AddButton({ Title = "Reset Autoload", Callback = function()
                    cm:ResetAutoloadConfig()
                    updateAutoloadText()
                end })
                cm:LoadAutoloadConfig()
                getgenv()._ConfigManager = cm
            ]]})
            break
        end
    end

    for i, tabData in ipairs(data.Tabs or {}) do
        local tabStart = tick()
        tabData.Icon = Engine.GetIcon(tabData.Icon)
        tabData._SectionCount = countSectionsInElements(tabData.Elements) + ((tabData.SectionTitle or tabData.SectionTitleFi) and 1 or 0)
        local Tab = Window:AddTab(tabData)
        if i == 1 and winData.Discord then
            for _, disc in ipairs(winData.Discord) do
                if Tab.AddDiscord then
                    Tab:AddDiscord(disc.Title or "Discord", { Invite = disc.Server })
                end
            end
        end
        addElementsToTab(Tab, tabData.Elements, adapter, Engine, syncStore, sharedContext)
        debugLog(string.format("Built tab '%s' in %.3fs", tostring(tabData.Title), tick() - tabStart))
    end

    if currentGameData and currentGameData.Tabs then
        local dashboardSectionCount = 0
        for _, category in ipairs(currentGameData.Tabs) do
            dashboardSectionCount = dashboardSectionCount + countSectionsInElements(category.Elements)
        end
        local Dashboard = Window:AddTab({
            Title = currentGameName,
            Icon = Engine.GetIcon("I-game"),
            _SectionCount = dashboardSectionCount
        })
        for _, category in ipairs(currentGameData.Tabs) do
            addElementsToTab(Dashboard, category.Elements, adapter, Engine, syncStore, sharedContext)

            local DedicatedTab = Window:AddTab({
                Title = category.Title or "Category",
                Icon = Engine.GetIcon(category.Icon),
                _SectionCount = countSectionsInElements(category.Elements)
            })
            addElementsToTab(DedicatedTab, category.Elements, adapter, Engine, syncStore, sharedContext)
        end
    end

    if adapter.OnFinished then adapter:OnFinished() end
    debugLog(string.format("LoadAndBuild completed in %.3fs", tick() - t0))
end

return Engine
