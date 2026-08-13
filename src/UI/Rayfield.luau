local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Engine = loadstring(getgenv().NEXS_PACKAGE and getgenv().NEXS_PACKAGE["src/Core/Engine.luau"] or game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local Adapter = {
    Options = {},
    Tabs = {}
}

function Adapter:Track(id, element, defaultValue)
    if not id then return element end
    local tracker = {
        Value = defaultValue,
        Raw = element,
        SetValue = function(self, val)
            self.Value = val
            if element.Set then element:Set(val)
            elseif element.SetText then element:SetText(tostring(val)) end
        end,
        SetValues = function(self, values)
            if element.Refresh then element:Refresh(values or {})
            elseif element.Set then element:Set(values or {}) end
        end
    }
    self.Options[tostring(id)] = tracker
    return tracker
end

function Adapter:CreateWindow(config)
    self.Window = Rayfield:CreateWindow({
        Name = config.Title,
        LoadingTitle = config.Title,
        LoadingSubtitle = config.SubTitle,
        ConfigurationSaving = { Enabled = true, FolderName = "7yd7Hub", FileName = "Config" },
        KeySystem = false,
        Theme = "Default"
    })
    return self
end

function Adapter:AddTab(config)
    local icon = config.Icon or 0
    if typeof(icon) == "string" then
        local lower = icon:lower()
        if lower:find("rbxassetid://") then
            icon = tonumber(icon:match("%d+")) or 4483345998
        elseif lower:find("rbxasset") or icon:find("/") or icon:find("\\") then
            icon = 4483345998 
        else
            icon = string.lower(icon)
        end
    end
    
    local Tab
    local success = pcall(function()
        Tab = self.Window:CreateTab({ Name = tostring(config.Title), Icon = icon })
    end)
    if not success or not Tab then
        Tab = self.Window:CreateTab(tostring(config.Title or "Tab"), icon or 4483345998)
    end
    self.Tabs[config.Title] = Tab

    local Proxy = { Raw = Tab }
    
    function Proxy:AddParagraph(args) 
        local t, c = tostring(args.Title or ""), tostring(args.Content or "")
        local s, r = pcall(function() return Tab:CreateParagraph({Title = t, Content = c}) end)
        if not s then s, r = pcall(function() return Tab:CreateParagraph(t, c) end) end
        return {
            Raw = r,
            SetDesc = function(_, text)
                local ok = pcall(function() r:Set(t .. ": " .. text) end)
                if not ok then pcall(function() r:SetText(t .. ": " .. text) end) end
            end
        }
    end
    
    function Proxy:AddButton(args) 
        local t, cb = tostring(args.Title or args.Name or "Button"), args.Callback
        local s, r = pcall(function() return Tab:CreateButton({Name = t, Callback = cb}) end)
        if not s then s, r = pcall(function() return Tab:CreateButton(t, cb) end) end
        return Adapter:Track(args.Id or args.Title, r)
    end
    function Proxy:AddToggle(id, args)
        local t, v, cb = tostring(args.Title or "Toggle"), args.Default, args.Callback
        local tracker
        local function callback(val)
            if tracker then tracker.Value = val end
            if cb then cb(val) end
        end
        local s, r = pcall(function() return Tab:CreateToggle({Name = t, CurrentValue = v, Flag = id, Callback = callback}) end)
        if not s then s, r = pcall(function() return Tab:CreateToggle(t, v, id, callback) end) end
        tracker = Adapter:Track(id, r, v)
        return tracker
    end
    function Proxy:AddSlider(id, args)
        local t, min, max, def, inc, cb = tostring(args.Title or "Slider"), args.Min or 0, args.Max or 100, args.Default or 0, args.Rounding or 1, args.Callback
        local tracker
        local function callback(val)
            if tracker then tracker.Value = val end
            if cb then cb(val) end
        end
        local s, r = pcall(function() return Tab:CreateSlider({Name = t, Range = {min, max}, Increment = inc, CurrentValue = def, Flag = id, Callback = callback}) end)
        if not s then s, r = pcall(function() return Tab:CreateSlider(t, min, max, def, inc, id, callback) end) end
        tracker = Adapter:Track(id, r, def)
        return tracker
    end
    function Proxy:AddInput(id, args)
        local t, def, ph, cb = tostring(args.Title or "Input"), tostring(args.Default or ""), tostring(args.Placeholder or ""), args.Callback
        local tracker
        local function callback(val)
            local out = val
            if args.Numeric then
                out = val:gsub("[^%d%.%-]", "")
            end
            if tracker then tracker.Value = out end
            if cb then cb(out) end
        end
        local s, r = pcall(function() return Tab:CreateInput({Name = t, CurrentValue = def, PlaceholderText = ph, Callback = callback}) end)
        if not s then s, r = pcall(function() return Tab:CreateInput(t, def, ph, callback) end) end
        tracker = Adapter:Track(id, r, def)
        return tracker
    end
    function Proxy:AddSection(args)
        local t = tostring(args.Title or "Section")
        pcall(function() Tab:CreateSection(t) end)
        return Proxy
    end

    function Proxy:AddDropdown(id, args)
        local t, o, def, m, cb = tostring(args.Title or "Dropdown"), args.Values or {}, args.Default, args.Multi, args.Callback
        
        local currentOpt = def
        if type(def) == "string" then currentOpt = {def} end 

        local tracker
        local function callback(val)
            local out = val
            if not m and type(val) == "table" then
                out = val[1]
            end

            if tracker then tracker.Value = out end
            if cb then cb(out) end
        end
        
        local s, r = pcall(function() return Tab:CreateDropdown({Name = t, Options = o, CurrentOption = currentOpt, MultipleOptions = m, Flag = id, Callback = callback}) end)
        if not s then s, r = pcall(function() return Tab:CreateDropdown(t, o, def, m, id, callback) end) end
        
        tracker = Adapter:Track(id, r, def)
        tracker.SetValues = function(_, v) 
            if r.Refresh then r:Refresh(o, true)
            elseif r.Set then r:Set(currentOpt) end
        end
        return tracker
    end

    return Proxy
end

function Adapter:GetContext()
    return {
        Rayfield = Rayfield,
        Options = self.Options
    }
end

Engine.LoadAndBuild(Adapter)