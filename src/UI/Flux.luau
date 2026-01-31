local Flux = loadstring(game:HttpGet"https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/fluxlib.txt")()
local Engine = loadstring(game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local Adapter = {
    Options = {},
    Tabs = {}
}

function Adapter:Track(id, element, initialValue)
    if not id then return element end
    local tracker = {
        Value = initialValue,
        Raw = element,
        SetValue = function(self, val)
            self.Value = val
        end
    }
    self.Options[tostring(id)] = tracker
    return tracker
end

function Adapter:ResolveIcon(i)
    if not i then return "" end
    if typeof(i) == "string" then
        if i:find("rbxassetid://") then
            local id = i:match("%d+")
            return "rbxassetid://" .. id
        elseif i:find("rbxasset") or i:find("/") or i:find("\\") or i:find("http") then
            return i
        elseif tonumber(i) then
            return "rbxassetid://" .. i
        end
    elseif typeof(i) == "number" then
        return "rbxassetid://" .. i
    end
    return ""
end

function Adapter:CreateWindow(config)
    local color = Color3.fromRGB(255, 110, 48) 
    if config.Theme == "Blue" then color = Color3.fromRGB(48, 110, 255)
    elseif config.Theme == "Green" then color = Color3.fromRGB(48, 255, 110) end

    self.Window = Flux:Window(config.Title, config.SubTitle or "7yd7 Hub", color, Enum.KeyCode.LeftControl)
    return self
end

function Adapter:AddTab(config)
    local Tab = self.Window:Tab(config.Title, Adapter:ResolveIcon(config.Icon))
    self.Tabs[config.Title] = Tab

    local Proxy = { Raw = Tab }
    
    function Proxy:AddSection(args)
        Tab:Line() 
        Tab:Label(args.Title)
        return Proxy 
    end
    
    function Proxy:AddParagraph(args) 
        local label = Tab:Label(args.Title .. ": " .. args.Content)
        local wrapper = {
            Raw = label,
            SetDesc = function(_, text) 
                pcall(function() label:SetText(args.Title.. ": " ..text) end)
            end,
            SetTitle = function(_, text) end 
        }
        return wrapper
    end
    
    function Proxy:AddButton(args) 
        local el = Tab:Button(args.Title or args.Name, args.Description or "", args.Callback)
        return Adapter:Track(args.Id or args.Title, el)
    end
    
    function Proxy:AddToggle(id, args)
        local val = args.Default or false
        local tracker
        local function callback(v)
            if tracker then tracker.Value = v end
            if args.Callback then args.Callback(v) end
        end
        local el = Tab:Toggle(args.Title, args.Description or "", val, callback)
        tracker = Adapter:Track(id, el, val)
        return tracker
    end
    
    function Proxy:AddSlider(id, args)
        local val = args.Default or 0
        local tracker
        local function callback(v)
            if tracker then tracker.Value = v end
            if args.Callback then args.Callback(v) end
        end
        local el = Tab:Slider(args.Title, args.Description or "", args.Min or 0, args.Max or 100, val, callback)
        tracker = Adapter:Track(id, el, val)
        return tracker
    end
    
    function Proxy:AddInput(id, args)
        local val = args.Default or ""
        local tracker
        local function callback(v)
            if args.Numeric then
                v = v:gsub("[^%d%.%-]", "")
            end
            if tracker then tracker.Value = v end
            if args.Callback then args.Callback(v) end
        end
        local el = Tab:Textbox(args.Title, args.Description or "", true, callback)
        tracker = Adapter:Track(id, el, val)
        return tracker
    end
    
    function Proxy:AddDropdown(id, args)
        local val = args.Default or ""
        local tracker
        local function callback(v)
            if tracker then tracker.Value = v end
            if args.Callback then args.Callback(v) end
        end
        local el = Tab:Dropdown(args.Title, args.Values or {}, callback)
        tracker = Adapter:Track(id, el, val)
        return tracker
    end

    function Proxy:AddBind(id, args)
        local el = Tab:Bind(args.Title, args.Default or Enum.KeyCode.Q, args.Callback)
        return Adapter:Track(id, el)
    end

    return Proxy
end

function Adapter:GetContext()
    return {
        Flux = Flux,
        Options = self.Options,
        Window = self.Window
    }
end

Engine.LoadAndBuild(Adapter)