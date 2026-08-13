local Fluent, SaveManager, InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local Engine = loadstring(getgenv().NEXS_PACKAGE and getgenv().NEXS_PACKAGE["src/Core/Engine.luau"] or game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local Adapter = {
    Tabs = {},
    Options = {}
}

function Adapter:CreateWindow(config)
    self.Window = Fluent:CreateWindow({
        Title = config.Title,
        SubTitle = config.SubTitle,
        TabWidth = config.TabWidth,
        Size = config.Size and UDim2.fromOffset(config.Size[1], config.Size[2]) or UDim2.fromOffset(580, 460),
        Acrylic = config.Acrylic ~= nil and config.Acrylic or true,
        Theme = config.Theme or "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    return self
end

function Adapter:AddTab(config)
    local Tab = self.Window:AddTab({ Title = config.Title, Icon = config.Icon or "" })
    
    local Proxy = {}
    function Proxy:AddParagraph(el) return Tab:AddParagraph({ Title = el.Title, Content = el.Content }) end
    function Proxy:AddButton(el) return Tab:AddButton({ Title = el.Title, Description = el.Description, Callback = el.Callback }) end
    function Proxy:AddToggle(id, el) 
        local t = Tab:AddToggle(id, { Title = el.Title, Default = el.Default, Callback = el.Callback })
        Adapter.Options[id] = t
    end
    function Proxy:AddSlider(id, el)
        local rounding = el.Rounding or 1
        if rounding > 0 and rounding < 1 then
            local str = tostring(rounding)
            if str:find(".") then
                rounding = #(str:split(".")[2])
            else
                rounding = 1
            end
        end
        local s = Tab:AddSlider(id, {
            Title = el.Title,
            Description = el.Description,
            Min = el.Min,
            Max = el.Max,
            Default = el.Default,
            Rounding = rounding,
            Callback = el.Callback
        })
        Adapter.Options[id] = s
    end
    function Proxy:AddInput(id, el)
        local cb = el.Callback
        local function sanitizedCallback(V)
            if el.Numeric then
                local n = V:gsub("[^%d%.%-]", "")
                if n ~= V then
                    Adapter.Options[id]:SetValue(n)
                end
                if cb then cb(n) end
            else
                if cb then cb(V) end
            end
        end
        local i = Tab:AddInput(id, { 
            Title = el.Title, 
            Default = el.Default, 
            Placeholder = el.Placeholder, 
            Description = el.Description,
            Numeric = el.Numeric,
            Finished = el.Finished,
            Callback = sanitizedCallback 
        })
        Adapter.Options[id] = i
        return i
    end
    function Proxy:AddSection(...)
        local args = {...}
        local title, icon
        if type(args[1]) == "table" then
            title = args[1].Title or args[1][1]
            icon = args[1].Icon or args[1][2]
        else
            title = args[1]
            icon = args[2]
        end
        return Tab:AddSection(title, icon)
    end
    function Proxy:AddDropdown(id, el)
        local function resolveDefault(defaultValue, values, isMulti)
            if isMulti then
                return defaultValue
            end
            if type(defaultValue) == "number" and type(values) == "table" then
                return values[defaultValue] or values[1]
            end
            return defaultValue
        end

        local function cloneTable(t)
            local out = {}
            for k, v in pairs(t or {}) do
                out[k] = v
            end
            return out
        end

        local function normalizeDropdownValue(value, isMulti)
            if not isMulti then
                return value
            end

            if value == nil then
                return {}
            end

            if type(value) == "table" then
                local isArray = (value[1] ~= nil) or (#value > 0)
                if isArray then
                    local out = {}
                    for _, v in ipairs(value) do
                        out[v] = true
                    end
                    return out
                end

                local out = {}
                for k, state in pairs(value) do
                    if state == true then
                        out[k] = true
                    end
                end
                return out
            end

            if type(value) == "string" or type(value) == "number" then
                return { [tostring(value)] = true }
            end

            return {}
        end

        local resolvedDefault = resolveDefault(el.Default, el.Values, el.Multi)
        local initialValue = resolvedDefault
        local tracker
        local lastKnownValue = normalizeDropdownValue(initialValue, el.Multi)
        local changedListeners = {}

        local function notifyChanged(value)
            for _, fn in ipairs(changedListeners) do
                pcall(fn, value)
            end
        end

        local function dropdownCallback(v)
            lastKnownValue = normalizeDropdownValue(v, el.Multi)
            notifyChanged(lastKnownValue)
            if el.Callback then
                el.Callback(lastKnownValue)
            end
        end

        local d = Tab:AddDropdown(id, {
            Title = el.Title,
            Values = el.Values,
            Default = resolvedDefault,
            Multi = el.Multi,
            Callback = dropdownCallback
        })

        tracker = {
            Raw = d,
            SetValues = function(self, values)
                local newValues = values or {}
                local ok = false
                if d and d.SetValues then
                    ok = pcall(function() d:SetValues(newValues) end)
                end
                if not ok and d and d.Refresh then
                    ok = pcall(function() d:Refresh(newValues) end)
                end
                if not ok and d and d.Set then
                    pcall(function() d:Set(newValues) end)
                end
            end,
            SetValue = function(self, value)
                lastKnownValue = normalizeDropdownValue(value, el.Multi)
                local ok = false
                if d and d.SetValue then
                    ok = pcall(function() d:SetValue(value) end)
                end
                if not ok and d and d.Set then
                    ok = pcall(function() d:Set(value) end)
                end
                if not ok and d and d.Select then
                    pcall(function() d:Select(value) end)
                end
                notifyChanged(lastKnownValue)
                if el.Callback then
                    pcall(function() el.Callback(lastKnownValue) end)
                end
            end,
            OnChanged = function(self, fn)
                if type(fn) == "function" then
                    table.insert(changedListeners, fn)
                end
                return self
            end
        }

        if d and d.OnChanged then
            pcall(function()
                d:OnChanged(function(v)
                    lastKnownValue = normalizeDropdownValue(v, el.Multi)
                end)
            end)
        end

        setmetatable(tracker, {
            __index = function(_, key)
                if key == "Value" then
                    if d and d.Value ~= nil then
                        return normalizeDropdownValue(d.Value, el.Multi)
                    end
                    return normalizeDropdownValue(lastKnownValue, el.Multi)
                end
                return d and d[key]
            end
        })

        Adapter.Options[id] = tracker
        return tracker
    end

    self.RawTabs = self.RawTabs or {}
    self.RawTabs[config.Title] = Tab
    self.Tabs[config.Title] = Proxy
    return Proxy
end

function Adapter:GetContext()
    return {
        Fluent = Fluent,
        SaveManager = SaveManager,
        InterfaceManager = InterfaceManager,
        Options = self.Options,
        ConfigManager = self.ConfigManager
    }
end

function Adapter:OnFinished()
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("7yd7Hub")
    if self.RawTabs and self.RawTabs.Settings then
        InterfaceManager:BuildInterfaceSection(self.RawTabs.Settings)
    end
    self.Window:SelectTab(1)
end

Engine.LoadAndBuild(Adapter)
