local Engine = loadstring(game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local WindUI
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    WindUI = ok and result or nil
end

if not WindUI then 
    warn("[7yd7 Hub] Failed to load WindUI library.")
    return 
end

local Adapter = {
    Tabs = {},
    Options = {}
}

local function getWindIcon(name)
    if not name or name == "" then return nil end
    if name:find(":") then return name end
    return Engine.GetIcon(name)
end

function Adapter:CreateWindow(config)
    local theme = config.Theme or "Dark"
    if theme == "Darker" then theme = "Dark" end 

    local win = WindUI:CreateWindow({
        Title = config.Title,
        Author = config.SubTitle or "7yd7 Hub",
        Folder = "7yd7Hub",
        Icon = getWindIcon(config.iconLogo) or "solar:folder-2-bold-duotone",
        Size = config.Size and UDim2.fromOffset(config.Size[1], config.Size[2]) or UDim2.fromOffset(580, 460),
        Transparent = config.Acrylic == false and false or true,
        Theme = theme,
        MinimizeKey = Enum.KeyCode.LeftControl,
        NewElements = true,
        
        HideSearchBar = false,
        OpenButton = {
            Title = "Open Hub",
            Enabled = true,
            Draggable = true,
            Scale = 0.5
        },
        Topbar = {
            Height = 44,
            ButtonsType = "Mac"
        }
    })
    self.Window = win
    getgenv().Window = win
    return self
end

function Adapter:AddTab(config)
    local Tab = self.Window:Tab({
        Title = config.Title or "Tab",
        Icon = getWindIcon(config.Icon),
    })

    local activeContainer = Tab
    local openSingleSection = (tonumber(config._SectionCount) == 1)
    if config.SectionTitle or config.SectionTitleFi then
        activeContainer = Tab:Section({
            Title = config.SectionTitle or config.SectionTitleFi,
            Opened = openSingleSection,
        })
    end

    local Proxy = {}

    function Proxy:AddSection(...)
        local args = {...}
        local title, textSize, icon
        if type(args[1]) == "table" then
            title = args[1].Title or args[1][1]
            textSize = args[1].TextSize or 16
            icon = getWindIcon(args[1].Icon)
        else
            title = args[1]
            textSize = 16
        end
        
        local section = Tab:Section({
            Title = title,
            TextSize = textSize,
            Icon = icon,
            Opened = openSingleSection,
        })
        activeContainer = section
        return section
    end
    
    function Proxy:AddParagraph(el)
        local p = activeContainer:Paragraph({
            Title = el.Title,
            Desc = el.Content,
            Image = getWindIcon(el.Icon)
        })
        return {
            Raw = p,
            SetDesc = function(_, text)
                local ok = pcall(function() p:SetDesc(text) end)
                if not ok then pcall(function() p:Set(text) end) end
            end
        }
    end

    function Proxy:AddButton(el)
        return activeContainer:Button({
            Title = el.Title,
            Desc = el.Description,
            Callback = el.Callback
        })
    end

    function Proxy:AddToggle(id, el)
        local t = activeContainer:Toggle({
            Title = el.Title,
            Value = el.Default,
            Callback = el.Callback
        })
        Adapter.Options[id] = {
            Value = el.Default,
            SetValue = function(_, v) t:Set(v) end
        }
        return t
    end

    function Proxy:AddSlider(id, el)
        local step = (el.Rounding and el.Rounding > 0) and el.Rounding or 1
        local s = activeContainer:Slider({
            Title = el.Title,
            Value = {
                Min = el.Min,
                Max = el.Max,
                Default = el.Default
            },
            Step = step,
            Callback = el.Callback
        })
        Adapter.Options[id] = {
            Value = el.Default,
            SetValue = function(_, v) s:Set(v) end
        }
        return s
    end

    function Proxy:AddInput(id, el)
        local cb = el.Callback
        local function sanitizedCallback(V)
            local val = V
            if el.Numeric then
                val = V:gsub("[^%d%.%-]", "")
            end
            if Adapter.Options[id] then Adapter.Options[id].Value = val end
            if cb then cb(val) end
        end
        local i = activeContainer:Input({
            Title = el.Title,
            Value = el.Default,
            Placeholder = el.Placeholder,
            Callback = sanitizedCallback
        })
        Adapter.Options[id] = {
            Value = el.Default,
            Raw = i,
            SetValue = function(_, v) i:Set(v) end
        }
        return i
    end

    function Proxy:AddDropdown(id, el)
        local cb = el.Callback
        local function callback(v)
            if Adapter.Options[id] then Adapter.Options[id].Value = v end
            if cb then cb(v) end
        end
        local d = activeContainer:Dropdown({
            Title = el.Title,
            Values = el.Values,
            Value = el.Default,
            Multi = el.Multi,
            Callback = callback
        })
        Adapter.Options[id] = {
            Value = el.Default,
            Raw = d,
            SetValues = function(_, v) d:Refresh(v) end,
            SetValue = function(_, v) d:Set(v) end
        }
        return d
    end

    self.Tabs[config.Title] = Proxy
    return Proxy
end

function Adapter:GetContext()
    return {
        WindUI = WindUI,
        Window = self.Window,
        Options = self.Options
    }
end

function Adapter:OnFinished()
end

Engine.LoadAndBuild(Adapter)
