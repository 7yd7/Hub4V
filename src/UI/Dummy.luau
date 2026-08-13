local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2zu/OPEN-SOURCE-UI-ROBLOX/refs/heads/main/X2ZU%20UI%20ROBLOX%20OPEN%20SOURCE/DummyUi-leak-by-x2zu/fetching-main/Tools/Framework.luau"))()
local Engine = loadstring(getgenv().NEXS_PACKAGE and getgenv().NEXS_PACKAGE["src/Core/Engine.luau"] or game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local Adapter = {
    Options = {},
    Tabs = {}
}

function Adapter:Track(id, element)
    if not id or not element then return element end
    local wrapper = setmetatable({
        SetValue = function(_, val)
            if element.SetValue then 
                element:SetValue(val)
            elseif element.SetText then
                element:SetText(tostring(val))
            elseif element.SetCode then
                element:SetCode(tostring(val))
            end
        end,
        SetValues = function(_, values)
            local newValues = values or {}
            local ok = pcall(function() element:SetValues(newValues) end)
            if not ok then pcall(function() element:Refresh(newValues) end) end
        end,
        Raw = element
    }, {
        __index = function(_, k)
            if k == "Value" then return element.Value or element.CurrentValue end
            return element[k]
        end
    })
    self.Options[tostring(id)] = wrapper
    return wrapper
end

function Adapter:ResolveIcon(i)
    if not i then return nil end
    if typeof(i) == "string" then
        if i:lower():find("rbxasset") or i:find("/") or i:find("\\") then
            return {
                Image = i,
                ImageRectSize = Vector2.new(0, 0),
                ImageRectPosition = Vector2.new(0, 0)
            }
        end
        return string.lower(i)
    end
    return i
end

function Adapter:CreateWindow(config)
    local theme = "Dark"
    if config.Theme == "Amethyst" or config.Theme == "Purple" then
        theme = "Amethyst"
    end

    self.Window = Library:Window({
        Title = config.Title,
        Desc = config.SubTitle or "7yd7 Hub",
        Icon = Adapter:ResolveIcon(config.Icon) or 105059922903197,
        Theme = theme,
        Config = {
            Keybind = Enum.KeyCode.LeftControl,
            Size = config.Size and UDim2.fromOffset(config.Size[1], config.Size[2]) or UDim2.new(0, 500, 0, 400),
            Folder = "7yd7Hub",
            File = "DummyConfig"
        },
        CloseUIButton = {
            Enabled = true,
            Text = "7yd7"
        }
    })
    return self
end

function Adapter:AddTab(config)
    local Tab = self.Window:Tab({
        Title = config.Title,
        Icon = Adapter:ResolveIcon(config.Icon) or "star"
    })
    self.Tabs[config.Title] = Tab

    local Proxy = { Raw = Tab }
    
    function Proxy:AddSection(args)
        Tab:Section({ Title = args.Title })
        return Proxy
    end
    
    function Proxy:AddParagraph(args) 
        local sec = Tab:Section({Title = args.Title, Desc = args.Content})
        local wrapper = {
            Raw = sec,
            SetDesc = function(_, text)
                pcall(function() sec:Refresh(args.Title, text) end)
            end
        }
        return wrapper
    end
    
    function Proxy:AddButton(args) 
        local el = Tab:Button({
            Title = args.Title or args.Name,
            Desc = args.Description or "",
            Callback = args.Callback
        })
        return Adapter:Track(args.Id or args.Title, el)
    end
    
    function Proxy:AddToggle(id, args)
        local el = Tab:Toggle({
            Title = args.Title,
            Desc = args.Description or "",
            Value = args.Default or false,
            Callback = args.Callback
        })
        return Adapter:Track(id, el)
    end
    
    function Proxy:AddSlider(id, args)
        local el = Tab:Slider({
            Title = args.Title,
            Min = args.Min or 0,
            Max = args.Max or 100,
            Rounding = args.Rounding or 1,
            Value = args.Default or 0,
            Callback = args.Callback
        })
        return Adapter:Track(id, el)
    end
    
    function Proxy:AddInput(id, args)
        local tracker
        local function callback(val)
            local out = val
            if args.Numeric then
                out = val:gsub("[^%d%.%-]", "")
            end
            if tracker then tracker.Value = out end
            if args.Callback then args.Callback(out) end
        end
        local el = Tab:Textbox({
            Title = args.Title,
            Desc = args.Description or "",
            Placeholder = args.Placeholder or "Enter value...",
            Value = args.Default or "",
            Callback = callback
        })
        tracker = Adapter:Track(id, el)
        tracker.Value = args.Default or ""
        return tracker
    end
    
    function Proxy:AddDropdown(id, args)
        local tracker
        local function callback(val)
            if tracker then tracker.Value = val end
            if args.Callback then args.Callback(val) end
        end
        local el = Tab:Dropdown({
            Title = args.Title,
            List = args.Values or {},
            Value = args.Default or "",
            Callback = callback
        })
        tracker = Adapter:Track(id, el)
        tracker.Value = args.Default or ""
        tracker.SetValue = function(_, v) 
             pcall(function() el:Refresh(args.Values, v) end)
        end
        return tracker
    end

    return Proxy
end

function Adapter:GetContext()
    return {
        Library = Library,
        Options = self.Options,
        Window = self.Window
    }
end

Engine.LoadAndBuild(Adapter)