local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NOTHING/main/source.lua"))()
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
            if element and element.Value then
                element.Value(val)
            elseif element and element.Set then
                element.Set(tostring(val))
            end
        end
    }
    self.Options[tostring(id)] = tracker
    return tracker
end

function Adapter:CreateWindow(config)
    self.Window = Library.new({
        Title = config.Title,
        Description = config.SubTitle or "7yd7 Hub",
        Keybind = Enum.KeyCode.LeftControl,
        Logo = config.Logo or 'rbxassetid://18898582662',
        Size = config.Size and UDim2.fromOffset(config.Size[1], config.Size[2]) or UDim2.new(0.1, 445, 0.1, 315)
    })
    return self
end

function Adapter:AddTab(config)
    local Tab = self.Window:NewTab({
        Title = config.Title,
        Description = config.Description or "",
        Icon = config.Icon 
    })
   
    local DefaultSection = Tab:NewSection({
        Title = config.SectionTitle or "Main",
        Position = config.SectionPosition or "Left",
        Icon = Engine.GetIcon(config.SectionIcon) 
    })
    
    self.Tabs[config.Title] = DefaultSection
    
    local Proxy = { Raw = DefaultSection, CurrentSection = DefaultSection }
    
    function Proxy:AddSection(args)
        local pos = args.SectionPosition or "Left"
        local newSec = Tab:NewSection({
            Title = args.Title,
            Position = pos,
            Icon = Engine.GetIcon(args.Icon)
        })
        Proxy.CurrentSection = newSec
        return newSec
    end

    function Proxy:AddParagraph(args) 
        local title = args.Title or ""
        local content = args.Content or ""
        local fullText = (title ~= "" and title .. ": " or "") .. content
        
        local function splitByLength(text, limit)
            local lines = {}
            for i = 1, #text, limit do
                table.insert(lines, text:sub(i, i + limit - 1))
            end
            return lines
        end

        local segments = {}
        for _, line in ipairs(fullText:split("\n")) do
            if #line > 30 then
                local chunks = splitByLength(line, 30)
                for _, chunk in ipairs(chunks) do table.insert(segments, chunk) end
            else
                table.insert(segments, line)
            end
        end

        for i, segment in ipairs(segments) do
            Proxy.CurrentSection:NewTitle(segment)
        end
        return {
            SetDesc = function() end, 
            SetTitle = function() end
        }
    end
    
    function Proxy:AddButton(args) 
        local el = Proxy.CurrentSection:NewButton({
            Title = args.Title or args.Name,
            Callback = args.Callback
        })
        return Adapter:Track(args.Id or args.Title, el)
    end
    
    function Proxy:AddToggle(id, args)
        local val = args.Default or false
        local tracker
        local function callback(newVal)
            if tracker then tracker.Value = newVal end
            if args.Callback then args.Callback(newVal) end
        end
        local el = Proxy.CurrentSection:NewToggle({
            Title = args.Title,
            Default = val,
            Callback = callback
        })
        tracker = Adapter:Track(id, el, val)
        return tracker
    end
    
    function Proxy:AddSlider(id, args)
        local val = args.Default or 0
        local tracker
        local function callback(newVal)
            if tracker then tracker.Value = newVal end
            if args.Callback then args.Callback(newVal) end
        end
        local el = Proxy.CurrentSection:NewSlider({
            Title = args.Title,
            Min = args.Min or 0,
            Max = args.Max or 100,
            Default = val,
            Callback = callback
        })
        tracker = Adapter:Track(id, el, val)
        return tracker
    end
    
    function Proxy:AddInput(id, args)
        local val = args.Default or ""
        local tracker
        local function callback(newText)
            local text = newText
            if args.Numeric then
                text = newText:gsub("[^%d%.%-]", "")
            end
            if tracker then tracker.Value = text end
            if args.Callback then args.Callback(text) end
        end
        local el = Proxy.CurrentSection:NewTextbox({
            Title = args.Title,
            Default = val,
            Callback = callback
        })
        tracker = Adapter:Track(id, el, val)
        return tracker
    end
    
    function Proxy:AddDropdown(id, args)
        local val = args.Default or ""
        local tracker
        local function callback(newVal)
            if tracker then tracker.Value = newVal end
            if args.Callback then args.Callback(newVal) end
        end
        local el = Proxy.CurrentSection:NewDropdown({
            Title = args.Title,
            Data = args.Values or {},
            Default = val,
            Callback = callback
        })
        tracker = Adapter:Track(id, el, val)
        tracker.SetValue = function(_, v)
            pcall(function() el:Refresh(v) end)
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
