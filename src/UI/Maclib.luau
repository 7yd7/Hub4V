local Engine = loadstring(game:HttpGet(getgenv().NEXS_BASE_URL .. "/src/Core/Engine.luau"))()

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

if not MacLib then
    warn("[7yd7 Hub] Failed to load MacLib library.")
    return
end

local Adapter = {
    Options = {},
    Tabs = {}
}

local firstTab

function Adapter:CreateWindow(config)
    self.Window = MacLib:Window({
        Title = config.Title,
        Subtitle = config.SubTitle or "7yd7 Hub",
        Size = UDim2.fromOffset(868, 650),
        DragStyle = 1,
        DisabledWindowControls = {},
        ShowUserInfo = true,
        Keybind = Enum.KeyCode.RightControl,
        AcrylicBlur = config.Acrylic ~= false,
    })
    self.TabGroup = self.Window:TabGroup()
    return self
end

function Adapter:AddTab(config)
    local icon = config.Icon or "rbxassetid://18821914323"
    if typeof(icon) == "string" and not icon:find("rbxassetid://") then
        icon = Engine.GetIcon(icon) or "rbxassetid://18821914323"
    end

    local Tab = self.TabGroup:Tab({
        Name = config.Title or "Tab",
        Image = icon
    })

    if not firstTab then
        firstTab = Tab
    end

    local activeSection
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

    function Proxy:AddSection(args)
        local side = resolveSectionPosition(args)
        activeSection = Tab:Section({
            Side = side
        })
        if args.Title and args.Title ~= "" then
            activeSection:Header({ Text = args.Title, Name = args.Title })
        end
        return Proxy
    end

    function Proxy:AddParagraph(el)
        if not activeSection then
            self:AddSection({ SectionPosition = "Left" })
        end
        local p = activeSection:Paragraph({
            Header = el.Title or "",
            Body = el.Content or ""
        })
        return p
    end

    function Proxy:AddButton(el)
        if not activeSection then
            self:AddSection({ SectionPosition = "Left" })
        end
        local btn = activeSection:Button({
            Name = el.Title or "Button",
            Callback = el.Callback
        })
        return btn
    end

    function Proxy:AddToggle(id, el)
        if not activeSection then
            self:AddSection({ SectionPosition = "Left" })
        end
        local toggle = activeSection:Toggle({
            Name = el.Title or "Toggle",
            Default = el.Default or false,
            Callback = el.Callback
        })
        Adapter.Options[id] = {
            SetValue = function(_, v)
                if toggle.UpdateState then toggle:UpdateState(v) end
            end,
            Raw = toggle
        }
        return toggle
    end

    function Proxy:AddSlider(id, el)
        if not activeSection then
            self:AddSection({ SectionPosition = "Left" })
        end
        local slider = activeSection:Slider({
            Name = el.Title or "Slider",
            Minimum = el.Min or 0,
            Maximum = el.Max or 100,
            Default = el.Default or 0,
            Callback = el.Callback
        })
        Adapter.Options[id] = {
            SetValue = function(_, v)
                if slider.UpdateValue then slider:UpdateValue(v) end
            end,
            Raw = slider
        }
        return slider
    end

    function Proxy:AddInput(id, el)
        if not activeSection then
            self:AddSection({ SectionPosition = "Left" })
        end
        local input = activeSection:Input({
            Name = el.Title or "Input",
            Placeholder = el.Placeholder or "Type here...",
            Default = el.Default or "",
            AcceptedCharacters = el.Numeric and "Numeric" or "All",
            Callback = el.Callback
        })

        Adapter.Options[id] = {
            Value = el.Default or "",
            SetValue = function(_, v)
                if input and input.UpdateText then input:UpdateText(v) end
            end,
            Raw = input
        }
        return input
    end

    function Proxy:AddDropdown(id, el)
        if not activeSection then
            self:AddSection({ SectionPosition = "Left" })
        end
        
        local initialDefault = el.Default
        if type(initialDefault) == "string" and el.Values then
            for i, val in ipairs(el.Values) do
                if val == initialDefault then
                    initialDefault = i
                    break
                end
            end
        end

        local dropdown = activeSection:Dropdown({
            Name = el.Title or "Dropdown",
            Multi = el.Multi or false,
            Options = el.Values or {},
            Default = initialDefault,
            Search = true,
            Callback = el.Callback
        })

        Adapter.Options[id] = {
            Value = el.Default,
            SetValues = function(_, v)
                if dropdown.ClearOptions and dropdown.InsertOptions then
                    dropdown:ClearOptions()
                    dropdown:InsertOptions(v)
                end
            end,
            SetValue = function(_, v)
                if dropdown.UpdateSelection then dropdown:UpdateSelection(v) end
            end,
            Raw = dropdown
        }
        return dropdown
    end

    self.Tabs[config.Title] = Proxy
    return Proxy
end

function Adapter:GetContext()
    return {
        MacLib = MacLib,
        Options = self.Options,
        Window = self.Window
    }
end

function Adapter:OnFinished()
    if firstTab and firstTab.Select then
        pcall(function() firstTab:Select() end)
    end
end

Engine.LoadAndBuild(Adapter)
