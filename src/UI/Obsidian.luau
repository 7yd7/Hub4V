local HttpService = game:GetService("HttpService")
local Engine = loadstring(getgenv().NEXS_PACKAGE and getgenv().NEXS_PACKAGE["src/Core/Engine.luau"] or game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(getgenv().NEXS_PACKAGE and getgenv().NEXS_PACKAGE["src/Library/Obsidian.luau"] or game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Library/Obsidian.luau"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

if not Library then
    warn("[7yd7 Hub] Failed to load Obsidian library.")
    return
end

local Adapter = {
    Options = {},
    Tabs = {},
    RawTabs = {}
}

function Adapter:CreateWindow(config)
    local iconVal = 95816097006870
    if config.iconLogo and config.iconLogo ~= "" then
        iconVal = config.iconLogo
    elseif config.Logo and config.Logo ~= "" then
        iconVal = config.Logo
    end

    self.Window = Library:CreateWindow({
        Title = config.Title or "7yd7 Hub v4",
        Footer = config.SubTitle or "7yd7 Hub v4",
        Icon = iconVal,
        NotifySide = "Right",
        ShowCustomCursor = true,
    })
    return self
end

function Adapter:AddTab(config)
    local tabIcon = config.Icon
    if typeof(tabIcon) == "string" and tabIcon:find("rbxassetid://") then
        local tLower = string.lower(config.Title or "")
        if tLower:find("main") or tLower:find("home") then
            tabIcon = "home"
        elseif tLower:find("setting") or tLower:find("config") then
            tabIcon = "settings"
        elseif tLower:find("combat") or tLower:find("pvp") or tLower:find("kill") then
            tabIcon = "shield"
        elseif tLower:find("player") or tLower:find("stat") then
            tabIcon = "user"
        elseif tLower:find("misc") or tLower:find("other") then
            tabIcon = "boxes"
        elseif tLower:find("teleport") or tLower:find("map") then
            tabIcon = "map"
        elseif tLower:find("shop") or tLower:find("buy") then
            tabIcon = "shopping-cart"
        else
            tabIcon = "boxes"
        end
    end

    local Tab = self.Window:AddTab(config.Title or "Tab", tabIcon)

    local activeGroupbox
    local sectionIndex = 0
    local Proxy = { Raw = Tab }

    local function resolveSectionPosition(args)
        local side
        if args and args.SectionPosition then
            side = args.SectionPosition
        else
            side = (sectionIndex % 2 == 0) and "Left" or "Right"
        end
        sectionIndex = sectionIndex + 1
        return side
    end

    local function ensureGroupbox(el)
        if not activeGroupbox then
            local side = (sectionIndex % 2 == 0) and "Left" or "Right"
            sectionIndex = sectionIndex + 1
            if side == "Left" then
                activeGroupbox = Tab:AddLeftGroupbox("General")
            else
                activeGroupbox = Tab:AddRightGroupbox("General")
            end
        end
        return activeGroupbox
    end

    function Proxy:AddSection(args)
        local title
        local sectionPos
        local icon
        if typeof(args) == "table" then
            title = args.Title or args[1] or ""
            sectionPos = resolveSectionPosition(args)
            icon = args.Icon
            if icon and icon ~= "" then
                icon = Engine.GetIcon(icon)
            end
        else
            title = tostring(args or "")
            sectionPos = resolveSectionPosition()
        end

        if title == "" then
            title = "Section " .. sectionIndex
        end

        if sectionPos == "Left" then
            activeGroupbox = Tab:AddLeftGroupbox(title, icon)
        else
            activeGroupbox = Tab:AddRightGroupbox(title, icon)
        end
        return Proxy
    end

    function Proxy:AddParagraph(el)
        local g = ensureGroupbox(el)
        local text = (el.Title and el.Title ~= "") and (el.Title .. "\n" .. (el.Content or "")) or (el.Content or "")
        local labelIdx = "Label_" .. HttpService:GenerateGUID(false):gsub("-", "")
        local labelObj = g:AddLabel(text, true, labelIdx)

        local paraWrapper = {
            SetTitle = function(_, title)
                el.Title = title
                local newText = (el.Title and el.Title ~= "") and (el.Title .. "\n" .. (el.Content or "")) or (el.Content or "")
                pcall(function() labelObj:SetText(newText) end)
            end,
            SetText = function(_, content)
                el.Content = content
                local newText = (el.Title and el.Title ~= "") and (el.Title .. "\n" .. (el.Content or "")) or (el.Content or "")
                pcall(function() labelObj:SetText(newText) end)
            end,
            Raw = labelObj
        }
        paraWrapper.SetDesc = paraWrapper.SetText
        paraWrapper.SetContent = paraWrapper.SetText
        return paraWrapper
    end

    function Proxy:AddButton(el)
        local g = ensureGroupbox(el)
        local btnObj = g:AddButton({
            Text = el.Title or "Button",
            Func = el.Callback,
            Tooltip = el.Description
        })
        return btnObj
    end

    function Proxy:AddToggle(id, el)
        local g = ensureGroupbox(el)
        local cleanId = tostring(id)
        local toggleObj = g:AddToggle(cleanId, {
            Text = el.Title or "Toggle",
            Default = el.Default or false,
            Callback = el.Callback,
            Tooltip = el.Description
        })

        local optWrapper = {
            SetValue = function(_, v)
                pcall(function() toggleObj:SetValue(v) end)
            end,
            OnChanged = function(_, cb)
                pcall(function() toggleObj:OnChanged(cb) end)
            end,
            Raw = toggleObj
        }
        setmetatable(optWrapper, {
            __index = function(t, k)
                if k == "Value" then
                    return toggleObj.Value
                end
                return toggleObj[k]
            end
        })

        Adapter.Options[id] = optWrapper
        return toggleObj
    end

    function Proxy:AddSlider(id, el)
        local g = ensureGroupbox(el)
        local cleanId = tostring(id)
        
        local rounding = el.Rounding or 1
        if rounding > 0 and rounding < 1 then
            local str = tostring(rounding)
            if str:find(".") then
                rounding = #(str:split(".")[2])
            else
                rounding = 1
            end
        end

        local sliderObj = g:AddSlider(cleanId, {
            Text = el.Title or "Slider",
            Min = el.Min or 0,
            Max = el.Max or 100,
            Default = el.Default or 0,
            Rounding = rounding,
            Callback = el.Callback,
            Tooltip = el.Description
        })

        local optWrapper = {
            SetValue = function(_, v)
                pcall(function() sliderObj:SetValue(v) end)
            end,
            OnChanged = function(_, cb)
                pcall(function() sliderObj:OnChanged(cb) end)
            end,
            Raw = sliderObj
        }
        setmetatable(optWrapper, {
            __index = function(t, k)
                if k == "Value" then
                    return sliderObj.Value
                end
                return sliderObj[k]
            end
        })

        Adapter.Options[id] = optWrapper
        return sliderObj
    end

    function Proxy:AddInput(id, el)
        local g = ensureGroupbox(el)
        local cleanId = tostring(id)

        local cb = el.Callback
        local function sanitizedCallback(V)
            if el.Numeric then
                local n = V:gsub("[^%d%.%-]", "")
                if n ~= V then
                    pcall(function() Adapter.Options[id]:SetValue(n) end)
                end
                if cb then cb(n) end
            else
                if cb then cb(V) end
            end
        end

        local inputObj = g:AddInput(cleanId, {
            Text = el.Title or "Input",
            Default = el.Default or "",
            Placeholder = el.Placeholder or "",
            Numeric = el.Numeric or false,
            Finished = el.Finished or false,
            Callback = sanitizedCallback,
            Tooltip = el.Description
        })

        local optWrapper = {
            SetValue = function(_, v)
                pcall(function() inputObj:SetValue(v) end)
            end,
            OnChanged = function(_, cb)
                pcall(function() inputObj:OnChanged(cb) end)
            end,
            Raw = inputObj
        }
        setmetatable(optWrapper, {
            __index = function(t, k)
                if k == "Value" then
                    return inputObj.Value
                end
                return inputObj[k]
            end
        })

        Adapter.Options[id] = optWrapper
        return inputObj
    end

    function Proxy:AddDropdown(id, el)
        local g = ensureGroupbox(el)
        local cleanId = tostring(id)

        local initialDefault = el.Default
        if type(initialDefault) == "number" and el.Values then
            initialDefault = el.Values[initialDefault] or el.Values[1] or ""
        elseif type(initialDefault) == "string" and el.Values then
            local found = false
            for _, v in ipairs(el.Values) do
                if v == initialDefault then
                    found = true
                    break
                end
            end
            if not found then
                initialDefault = el.Values[1] or ""
            end
        end

        local dropdownObj = g:AddDropdown(cleanId, {
            Text = el.Title or "Dropdown",
            Values = el.Values or {},
            Default = initialDefault,
            Multi = el.Multi or false,
            Callback = el.Callback,
            Tooltip = el.Description
        })

        local optWrapper = {
            Raw = dropdownObj,
            SetValue = function(_, v)
                pcall(function() dropdownObj:SetValue(v) end)
            end,
            SetValues = function(_, values)
                pcall(function() dropdownObj:SetValues(values) end)
            end,
            OnChanged = function(_, cb)
                pcall(function() dropdownObj:OnChanged(cb) end)
            end
        }
        setmetatable(optWrapper, {
            __index = function(t, k)
                if k == "Value" then
                    return dropdownObj.Value
                end
                return dropdownObj[k]
            end
        })

        Adapter.Options[id] = optWrapper
        return dropdownObj
    end

    self.RawTabs[config.Title] = Tab
    self.Tabs[config.Title] = Proxy
    return Proxy
end

function Adapter:GetContext()
    return {
        Library = Library,
        Options = self.Options,
        Window = self.Window
    }
end

function Adapter:OnFinished()
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("7yd7Hub")
    SaveManager:SetFolder("7yd7Hub/configs")

    if self.RawTabs and self.RawTabs.Settings then
        pcall(function()
            ThemeManager:ApplyToTab(self.RawTabs.Settings)
            --SaveManager:BuildConfigSection(self.RawTabs.Settings)
        end)
    end
    
    SaveManager:LoadAutoloadConfig()
end

Engine.LoadAndBuild(Adapter)
