local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Loader = {}

local function notify(title, text)
    local module = getgenv().NexsNotifications
    if module and module.Notify then
        module.Notify(title, text, 3)
    end
end

local function resolveAsset(serverPath)
    local baseUrl = getgenv().NEXS_BASE_URL or "https://raw.githubusercontent.com/7yd7/Hub4V/Menu"
    if baseUrl:sub(-1) == "/" then baseUrl = baseUrl:sub(1, -2) end
    
    local localFolder = "7yd7Hub/Assets/" .. (serverPath:match("^(.-)/[^/]+$") or "")
    local localPath = "7yd7Hub/Assets/" .. serverPath
    local fullUrl = baseUrl .. "/Assets/" .. serverPath

    if isfile and isfile(localPath) and typeof(getcustomasset) == "function" then
        local s, asset = pcall(function() return getcustomasset(localPath) end)
        if s and asset then return asset end
    end

    local pkg = getgenv().NEXS_PACKAGE
    local b64 = getgenv().NEXS_B64DECODE and pkg and pkg["Assets/" .. serverPath]
    if b64 then
        pcall(function()
            if makefolder then
                local parts = localFolder:split("/")
                local current = ""
                for _, part in ipairs(parts) do
                    if part ~= "" then
                        current = current == "" and part or current .. "/" .. part
                        if not isfolder(current) then makefolder(current) end
                    end
                end
            end
        end)
        local okD, data = pcall(getgenv().NEXS_B64DECODE, b64)
        if okD and data then
            pcall(function() if writefile then writefile(localPath, data) end end)
            if typeof(getcustomasset) == "function" then
                local s, asset = pcall(function() return getcustomasset(localPath) end)
                if s and asset then return asset end
            end
        end
    end

    pcall(function()
        if makefolder then
            local parts = localFolder:split("/")
            local current = ""
            for _, part in ipairs(parts) do
                if part ~= "" then
                    current = current == "" and part or current .. "/" .. part
                    if not isfolder(current) then makefolder(current) end
                end
            end
        end
    end)

    local success, content = pcall(function() return game:HttpGet(fullUrl) end)
    if success and content and #content > 100 and content:sub(1, 1) ~= "<" then
        pcall(function() if writefile then writefile(localPath, content) end end)
        if typeof(getcustomasset) == "function" then
            local s, asset = pcall(function() return getcustomasset(localPath) end)
            if s and asset then
                return asset
            end
        end
    end
    return nil
end

local EXPLOIT_LIST = {
    "Codex", "Cosmic", "Delta", "Madium", "Opiumware", 
    "Potassium", "Real", "Ronin", "Seliware", "SirHurt", 
    "Solara", "Velocity", "Volcano", "Volt", "Wave", "Xeno"
}

function Loader.Create(config)
    local config = config or {}
    local uiList = config.UIs or {}
    local onSelect = config.OnSelect or function() end

    -- Color Palettes exactly matching https://7yd7.pages.dev/
    local Themes = {
        Dark = {
            BgBody = Color3.fromRGB(8, 8, 10),
            BgCard = Color3.fromRGB(17, 17, 21),
            BgCardElev = Color3.fromRGB(24, 26, 36),
            Border = Color3.fromRGB(38, 42, 56),
            BorderSubtle = Color3.fromRGB(26, 28, 38),
            TextPrimary = Color3.fromRGB(243, 243, 245),
            TextSecondary = Color3.fromRGB(148, 148, 161),
            TextMuted = Color3.fromRGB(92, 92, 102),
            Accent = Color3.fromRGB(167, 139, 250),
            AccentEmerald = Color3.fromRGB(52, 211, 153),
            AccentRed = Color3.fromRGB(239, 68, 68),
            CopyBg = Color3.fromRGB(14, 15, 20),
            CopyBorder = Color3.fromRGB(38, 42, 56),
            HeaderBg = Color3.fromRGB(8, 8, 10),
            HeaderTransparency = 0.25,
            CardInfoBg = Color3.fromRGB(14, 14, 18),
            ModalBg = Color3.fromRGB(11, 11, 15),
            CodeColor = Color3.fromRGB(226, 232, 240),
            GitHubBg = Color3.fromRGB(32, 14, 18),
            GitHubStroke = Color3.fromRGB(239, 68, 68),
            GitHubText = Color3.fromRGB(245, 245, 248),
            LogoColor = Color3.fromRGB(255, 255, 255),
            BtnHoverBg = Color3.fromRGB(38, 42, 56),
            CloseHoverBg = Color3.fromRGB(60, 20, 24),
            CloseHoverColor = Color3.fromRGB(239, 68, 68),
            CardHoverTitleColor = Color3.fromRGB(255, 255, 255),
        },
        Light = {
            BgBody = Color3.fromRGB(245, 245, 248),
            BgCard = Color3.fromRGB(255, 255, 255),
            BgCardElev = Color3.fromRGB(238, 238, 243),
            Border = Color3.fromRGB(220, 220, 232),
            BorderSubtle = Color3.fromRGB(232, 232, 240),
            TextPrimary = Color3.fromRGB(15, 15, 18),
            TextSecondary = Color3.fromRGB(101, 101, 115),
            TextMuted = Color3.fromRGB(146, 146, 159),
            Accent = Color3.fromRGB(124, 58, 237),
            AccentEmerald = Color3.fromRGB(16, 185, 129),
            AccentRed = Color3.fromRGB(220, 38, 38),
            CopyBg = Color3.fromRGB(242, 242, 246),
            CopyBorder = Color3.fromRGB(220, 220, 232),
            HeaderBg = Color3.fromRGB(250, 250, 253),
            HeaderTransparency = 0.15,
            CardInfoBg = Color3.fromRGB(248, 248, 252),
            ModalBg = Color3.fromRGB(255, 255, 255),
            CodeColor = Color3.fromRGB(15, 15, 18),
            GitHubBg = Color3.fromRGB(254, 242, 242),
            GitHubStroke = Color3.fromRGB(239, 68, 68),
            GitHubText = Color3.fromRGB(220, 38, 38),
            LogoColor = Color3.fromRGB(15, 15, 18),
            BtnHoverBg = Color3.fromRGB(225, 225, 235),
            CloseHoverBg = Color3.fromRGB(254, 226, 226),
            CloseHoverColor = Color3.fromRGB(220, 38, 38),
            CardHoverTitleColor = Color3.fromRGB(124, 58, 237),
        }
    }

    local currentTheme = "Dark"
    local function getC()
        return Themes[currentTheme]
    end

    local Screen = Instance.new("ScreenGui")
    Screen.Name = "7yd7_Loader"
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Screen.ResetOnSpawn = false
    Screen.IgnoreGuiInset = true
    Screen.DisplayOrder = 16
    local parentOk, parentErr = pcall(function()
        Screen.Parent = CoreGui
    end)
    if not parentOk then
        Screen.Parent = (gethui and gethui()) or CoreGui
    end

    -- Main Container Window
    local Main = Instance.new("CanvasGroup")
    Main.Name = "Main"
    Main.Parent = Screen
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = getC().BgBody
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0.92, 0, 0.88, 0)
    Main.GroupTransparency = 1

    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MaxSize = Vector2.new(860, 560)
    SizeConstraint.MinSize = Vector2.new(320, 360)
    SizeConstraint.Parent = Main

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = getC().Border
    MainStroke.Thickness = 1.2
    MainStroke.Transparency = 1
    MainStroke.Parent = Main

    -- Background Ambient Glows & Floating Icons
    local BgContainer = Instance.new("Frame")
    BgContainer.Name = "BgContainer"
    BgContainer.Parent = Main
    BgContainer.BackgroundTransparency = 1
    BgContainer.Size = UDim2.new(1, 0, 1, 0)
    BgContainer.ZIndex = 1

    local function createGlowBlob(color, startPos, sizeOffset)
        local glow = Instance.new("Frame")
        glow.Name = "GlowBlob"
        glow.Parent = BgContainer
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundColor3 = color
        glow.BackgroundTransparency = 0.94
        glow.BorderSizePixel = 0
        glow.Position = startPos
        glow.Size = UDim2.fromOffset(sizeOffset, sizeOffset)
        glow.ZIndex = 1

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = glow

        local grad = Instance.new("UIGradient")
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.6, 0.94),
            NumberSequenceKeypoint.new(1, 1)
        })
        grad.Parent = glow

        return glow
    end

    local Glow1 = createGlowBlob(Color3.fromRGB(167, 139, 250), UDim2.new(0.2, 0, 0.1, 0), 380)
    local Glow2 = createGlowBlob(Color3.fromRGB(52, 211, 153), UDim2.new(0.85, 0, 0.9, 0), 420)

    task.spawn(function()
        while Screen.Parent do
            TweenService:Create(Glow1, TweenInfo.new(20, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0.3, 0, 0.22, 0),
                Size = UDim2.fromOffset(420, 420)
            }):Play()
            TweenService:Create(Glow2, TweenInfo.new(24, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0.75, 0, 0.78, 0),
                Size = UDim2.fromOffset(390, 390)
            }):Play()
            task.wait(22)
            if not Screen.Parent then break end
            TweenService:Create(Glow1, TweenInfo.new(20, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0.18, 0, 0.08, 0),
                Size = UDim2.fromOffset(360, 360)
            }):Play()
            TweenService:Create(Glow2, TweenInfo.new(24, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0.88, 0, 0.92, 0),
                Size = UDim2.fromOffset(440, 440)
            }):Play()
            task.wait(22)
        end
    end)

    -- Floating Executor Logos
    local ExecutorsContainer = Instance.new("Frame")
    ExecutorsContainer.Name = "ExecutorsBg"
    ExecutorsContainer.Parent = BgContainer
    ExecutorsContainer.BackgroundTransparency = 1
    ExecutorsContainer.Size = UDim2.new(1, 0, 1, 0)
    ExecutorsContainer.ZIndex = 1

    local function spawnFloatingExploits()
        for _, exploitName in ipairs(EXPLOIT_LIST) do
            local icon = Instance.new("ImageLabel")
            icon.Name = "Exploit_" .. exploitName
            icon.Parent = ExecutorsContainer
            icon.BackgroundTransparency = 1
            icon.Size = UDim2.fromOffset(math.random(36, 52), math.random(36, 52))
            icon.Position = UDim2.new(math.random(6, 94) / 100, 0, math.random(8, 92) / 100, 0)
            icon.ImageTransparency = 0.86
            icon.ImageColor3 = Color3.fromRGB(200, 190, 240)
            icon.ZIndex = 1

            local iconCorner = Instance.new("UICorner")
            iconCorner.CornerRadius = UDim.new(1, 0)
            iconCorner.Parent = icon

            task.spawn(function()
                local asset = resolveAsset("Exploits/" .. exploitName .. ".png")
                if asset and icon.Parent then
                    icon.Image = asset
                end
            end)

            task.spawn(function()
                while icon.Parent and Screen.Parent do
                    local targetX = math.clamp(icon.Position.X.Scale + (math.random(-20, 20) / 100), 0.05, 0.95)
                    local targetY = math.clamp(icon.Position.Y.Scale + (math.random(-20, 20) / 100), 0.08, 0.92)
                    local dur = math.random(26, 42)
                    local targetRot = math.random(-90, 90)
                    
                    local tw = TweenService:Create(icon, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = UDim2.new(targetX, 0, targetY, 0),
                        Rotation = targetRot
                    })
                    tw:Play()
                    tw.Completed:Wait()
                end
            end)
        end
    end
    task.spawn(spawnFloatingExploits)

    -- Window Dragging Logic
    local dragging = false
    local dragInput, dragStart, startPos

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Parent = Main
    Content.BackgroundTransparency = 1
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.ZIndex = 2

    -- APP HEADER
    local AppHeader = Instance.new("CanvasGroup")
    AppHeader.Name = "AppHeader"
    AppHeader.Parent = Content
    AppHeader.BackgroundColor3 = getC().HeaderBg
    AppHeader.BackgroundTransparency = getC().HeaderTransparency
    AppHeader.BorderSizePixel = 0
    AppHeader.Position = UDim2.new(0, 0, 0, 0)
    AppHeader.Size = UDim2.new(1, 0, 0, 56)
    AppHeader.ZIndex = 20

    local HeaderBottomBorder = Instance.new("Frame")
    HeaderBottomBorder.Name = "BottomBorder"
    HeaderBottomBorder.Parent = AppHeader
    HeaderBottomBorder.BackgroundColor3 = getC().BorderSubtle
    HeaderBottomBorder.BorderSizePixel = 0
    HeaderBottomBorder.Position = UDim2.new(0, 0, 1, -1)
    HeaderBottomBorder.Size = UDim2.new(1, 0, 0, 1)

    AppHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    AppHeader.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- HEADER LEFT (Logo - dynamically changes color to black in light theme)
    local HeaderLeft = Instance.new("Frame")
    HeaderLeft.Name = "HeaderLeft"
    HeaderLeft.Parent = AppHeader
    HeaderLeft.BackgroundTransparency = 1
    HeaderLeft.Position = UDim2.new(0, 18, 0, 0)
    HeaderLeft.Size = UDim2.new(0, 120, 1, 0)

    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Parent = HeaderLeft
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.BackgroundTransparency = 1
    Logo.Position = UDim2.new(0, 0, 0.5, 0)
    Logo.Size = UDim2.fromOffset(34, 34)
    Logo.Image = "rbxassetid://18898582662"
    Logo.ImageColor3 = getC().LogoColor
    Logo.ScaleType = Enum.ScaleType.Fit

    task.spawn(function()
        local asset = resolveAsset("icon/I-7yd7.png")
        if asset and Logo.Parent then 
            Logo.Image = asset 
            Logo.ImageColor3 = getC().LogoColor
        end
    end)

    -- HEADER CENTER (GitHub Navigation Tab)
    local HeaderNav = Instance.new("Frame")
    HeaderNav.Name = "HeaderNav"
    HeaderNav.Parent = AppHeader
    HeaderNav.AnchorPoint = Vector2.new(0.5, 0.5)
    HeaderNav.BackgroundTransparency = 1
    HeaderNav.Position = UDim2.new(0.5, 0, 0.5, 0)
    HeaderNav.Size = UDim2.new(0, 115, 0, 34)

    local GitHubTab = Instance.new("TextButton")
    GitHubTab.Name = "GitHubTab"
    GitHubTab.Parent = HeaderNav
    GitHubTab.AnchorPoint = Vector2.new(0.5, 0.5)
    GitHubTab.Position = UDim2.new(0.5, 0, 0.5, 0)
    GitHubTab.BackgroundColor3 = getC().GitHubBg
    GitHubTab.BackgroundTransparency = 0.2
    GitHubTab.Size = UDim2.new(1, 0, 1, 0)
    GitHubTab.AutoButtonColor = false
    GitHubTab.Text = ""

    local GitHubScale = Instance.new("UIScale")
    GitHubScale.Scale = 1.0
    GitHubScale.Parent = GitHubTab

    local GitHubCorner = Instance.new("UICorner")
    GitHubCorner.CornerRadius = UDim.new(0, 10)
    GitHubCorner.Parent = GitHubTab

    local GitHubGradient = Instance.new("UIGradient")
    GitHubGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(239, 68, 68)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 12, 16))
    })
    GitHubGradient.Rotation = 135
    GitHubGradient.Parent = GitHubTab

    local GitHubStroke = Instance.new("UIStroke")
    GitHubStroke.Color = getC().GitHubStroke
    GitHubStroke.Transparency = 0.55
    GitHubStroke.Thickness = 1
    GitHubStroke.Parent = GitHubTab

    local GitHubContent = Instance.new("Frame")
    GitHubContent.Name = "Content"
    GitHubContent.Parent = GitHubTab
    GitHubContent.BackgroundTransparency = 1
    GitHubContent.Size = UDim2.new(1, 0, 1, 0)

    local GitHubLayout = Instance.new("UIListLayout")
    GitHubLayout.Parent = GitHubContent
    GitHubLayout.FillDirection = Enum.FillDirection.Horizontal
    GitHubLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    GitHubLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    GitHubLayout.Padding = UDim.new(0, 7)

    local GitHubIcon = Instance.new("ImageLabel")
    GitHubIcon.Name = "Icon"
    GitHubIcon.Parent = GitHubContent
    GitHubIcon.BackgroundTransparency = 1
    GitHubIcon.Size = UDim2.fromOffset(16, 16)
    GitHubIcon.Image = "rbxassetid://10709791437"
    GitHubIcon.ImageColor3 = Color3.fromRGB(239, 68, 68)

    task.spawn(function()
        local asset = resolveAsset("icon/I-github.png")
        if asset and GitHubIcon.Parent then 
            GitHubIcon.Image = asset
            GitHubIcon.ImageColor3 = Color3.fromRGB(239, 68, 68)
        end
    end)

    local GitHubText = Instance.new("TextLabel")
    GitHubText.Name = "Title"
    GitHubText.Parent = GitHubContent
    GitHubText.BackgroundTransparency = 1
    GitHubText.Size = UDim2.new(0, 52, 0, 20)
    GitHubText.Font = Enum.Font.GothamMedium
    GitHubText.Text = "GitHub"
    GitHubText.TextColor3 = getC().GitHubText
    GitHubText.TextSize = 13
    GitHubText.TextXAlignment = Enum.TextXAlignment.Left

    GitHubTab.MouseEnter:Connect(function()
        TweenService:Create(GitHubScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.06}):Play()
        TweenService:Create(GitHubTab, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency = 0}):Play()
        TweenService:Create(GitHubStroke, TweenInfo.new(0.25), {Transparency = 0.15}):Play()
    end)

    GitHubTab.MouseLeave:Connect(function()
        TweenService:Create(GitHubScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
        TweenService:Create(GitHubTab, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(GitHubStroke, TweenInfo.new(0.25), {Transparency = 0.55}):Play()
    end)

    GitHubTab.MouseButton1Down:Connect(function()
        TweenService:Create(GitHubScale, TweenInfo.new(0.15), {Scale = 0.95}):Play()
    end)

    GitHubTab.MouseButton1Up:Connect(function()
        TweenService:Create(GitHubScale, TweenInfo.new(0.15), {Scale = 1.06}):Play()
    end)

    GitHubTab.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://github.com/7yd7/Hub4V")
        end
        notify("GitHub", "Link copied to clipboard!")
        local orig = GitHubText.Text
        GitHubText.Text = "Copied!"
        task.wait(1.2)
        if GitHubText.Parent then GitHubText.Text = orig end
    end)

    -- HEADER RIGHT (Ordered from left to right: [Discord] -> [Theme] -> [X at far right corner])
    local HeaderRight = Instance.new("Frame")
    HeaderRight.Name = "HeaderRight"
    HeaderRight.Parent = AppHeader
    HeaderRight.AnchorPoint = Vector2.new(1, 0.5)
    HeaderRight.BackgroundTransparency = 1
    HeaderRight.Position = UDim2.new(1, -16, 0.5, 0)
    HeaderRight.Size = UDim2.new(0, 130, 0, 34)

    local HeaderRightLayout = Instance.new("UIListLayout")
    HeaderRightLayout.Parent = HeaderRight
    HeaderRightLayout.FillDirection = Enum.FillDirection.Horizontal
    HeaderRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    HeaderRightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    HeaderRightLayout.Padding = UDim.new(0, 10)
    HeaderRightLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- 1. Discord Slot & Button (Left in HeaderRight)
    local DiscordSlot = Instance.new("Frame")
    DiscordSlot.Name = "DiscordSlot"
    DiscordSlot.Parent = HeaderRight
    DiscordSlot.BackgroundTransparency = 1
    DiscordSlot.Size = UDim2.fromOffset(32, 32)
    DiscordSlot.LayoutOrder = 1

    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Name = "DiscordBtn"
    DiscordBtn.Parent = DiscordSlot
    DiscordBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    DiscordBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
    DiscordBtn.BackgroundColor3 = getC().BgCardElev
    DiscordBtn.Size = UDim2.fromOffset(32, 32)
    DiscordBtn.AutoButtonColor = false
    DiscordBtn.Text = ""

    local DiscordScale = Instance.new("UIScale")
    DiscordScale.Scale = 1.0
    DiscordScale.Parent = DiscordBtn

    local DiscordCorner = Instance.new("UICorner")
    DiscordCorner.CornerRadius = UDim.new(1, 0)
    DiscordCorner.Parent = DiscordBtn

    local DiscordStroke = Instance.new("UIStroke")
    DiscordStroke.Color = getC().BorderSubtle
    DiscordStroke.Thickness = 1
    DiscordStroke.Parent = DiscordBtn

    local DiscordIcon = Instance.new("ImageLabel")
    DiscordIcon.Name = "Icon"
    DiscordIcon.Parent = DiscordBtn
    DiscordIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    DiscordIcon.BackgroundTransparency = 1
    DiscordIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    DiscordIcon.Size = UDim2.fromOffset(17, 17)
    DiscordIcon.Image = "rbxassetid://10709791437"
    DiscordIcon.ImageColor3 = getC().TextSecondary

    task.spawn(function()
        local asset = resolveAsset("icon/I-discord.png")
        if asset and DiscordIcon.Parent then DiscordIcon.Image = asset end
    end)

    DiscordBtn.MouseEnter:Connect(function()
        local c = getC()
        TweenService:Create(DiscordScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.08}):Play()
        TweenService:Create(DiscordBtn, TweenInfo.new(0.2), {BackgroundColor3 = c.BtnHoverBg}):Play()
        TweenService:Create(DiscordIcon, TweenInfo.new(0.2), {ImageColor3 = c.TextPrimary}):Play()
    end)

    DiscordBtn.MouseLeave:Connect(function()
        local c = getC()
        TweenService:Create(DiscordScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
        TweenService:Create(DiscordBtn, TweenInfo.new(0.2), {BackgroundColor3 = c.BgCardElev}):Play()
        TweenService:Create(DiscordIcon, TweenInfo.new(0.2), {ImageColor3 = c.TextSecondary}):Play()
    end)

    DiscordBtn.MouseButton1Down:Connect(function()
        TweenService:Create(DiscordScale, TweenInfo.new(0.15), {Scale = 0.94}):Play()
    end)

    DiscordBtn.MouseButton1Up:Connect(function()
        TweenService:Create(DiscordScale, TweenInfo.new(0.15), {Scale = 1.08}):Play()
    end)

    DiscordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/kRfzv2kV7X")
        end
        notify("Discord", "Link copied to clipboard!")
    end)

    -- 2. Theme Toggle Slot & Button (Middle in HeaderRight)
    local ThemeSlot = Instance.new("Frame")
    ThemeSlot.Name = "ThemeSlot"
    ThemeSlot.Parent = HeaderRight
    ThemeSlot.BackgroundTransparency = 1
    ThemeSlot.Size = UDim2.fromOffset(32, 32)
    ThemeSlot.LayoutOrder = 2

    local ThemeToggle = Instance.new("TextButton")
    ThemeToggle.Name = "ThemeToggle"
    ThemeToggle.Parent = ThemeSlot
    ThemeToggle.AnchorPoint = Vector2.new(0.5, 0.5)
    ThemeToggle.Position = UDim2.new(0.5, 0, 0.5, 0)
    ThemeToggle.BackgroundColor3 = getC().BgCardElev
    ThemeToggle.Size = UDim2.fromOffset(32, 32)
    ThemeToggle.AutoButtonColor = false
    ThemeToggle.Text = ""

    local ThemeScale = Instance.new("UIScale")
    ThemeScale.Scale = 1.0
    ThemeScale.Parent = ThemeToggle

    local ThemeCorner = Instance.new("UICorner")
    ThemeCorner.CornerRadius = UDim.new(1, 0)
    ThemeCorner.Parent = ThemeToggle

    local ThemeStroke = Instance.new("UIStroke")
    ThemeStroke.Color = getC().BorderSubtle
    ThemeStroke.Thickness = 1
    ThemeStroke.Parent = ThemeToggle

    local ThemeIcon = Instance.new("ImageLabel")
    ThemeIcon.Name = "Icon"
    ThemeIcon.Parent = ThemeToggle
    ThemeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ThemeIcon.BackgroundTransparency = 1
    ThemeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ThemeIcon.Size = UDim2.fromOffset(16, 16)
    ThemeIcon.Image = "rbxassetid://10709791437"
    ThemeIcon.ImageColor3 = getC().TextSecondary

    local function updateThemeIcon()
        task.spawn(function()
            local iconName = currentTheme == "Dark" and "icon/I-sun.png" or "icon/I-moon.png"
            local asset = resolveAsset(iconName)
            if asset and ThemeIcon.Parent then ThemeIcon.Image = asset end
        end)
    end
    updateThemeIcon()

    ThemeToggle.MouseEnter:Connect(function()
        local c = getC()
        TweenService:Create(ThemeScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.08}):Play()
        TweenService:Create(ThemeToggle, TweenInfo.new(0.2), {BackgroundColor3 = c.BtnHoverBg}):Play()
        TweenService:Create(ThemeIcon, TweenInfo.new(0.2), {ImageColor3 = c.TextPrimary}):Play()
    end)

    ThemeToggle.MouseLeave:Connect(function()
        local c = getC()
        TweenService:Create(ThemeScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
        TweenService:Create(ThemeToggle, TweenInfo.new(0.2), {BackgroundColor3 = c.BgCardElev}):Play()
        TweenService:Create(ThemeIcon, TweenInfo.new(0.2), {ImageColor3 = c.TextSecondary}):Play()
    end)

    ThemeToggle.MouseButton1Down:Connect(function()
        TweenService:Create(ThemeScale, TweenInfo.new(0.15), {Scale = 0.94}):Play()
    end)

    ThemeToggle.MouseButton1Up:Connect(function()
        TweenService:Create(ThemeScale, TweenInfo.new(0.15), {Scale = 1.08}):Play()
    end)

    -- 3. Close Button Slot & Button (LayoutOrder = 3 -> Far right corner!)
    local CloseSlot = Instance.new("Frame")
    CloseSlot.Name = "CloseSlot"
    CloseSlot.Parent = HeaderRight
    CloseSlot.BackgroundTransparency = 1
    CloseSlot.Size = UDim2.fromOffset(32, 32)
    CloseSlot.LayoutOrder = 3

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Parent = CloseSlot
    CloseBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
    CloseBtn.BackgroundColor3 = getC().BgCardElev
    CloseBtn.Size = UDim2.fromOffset(32, 32)
    CloseBtn.AutoButtonColor = false
    CloseBtn.Text = ""

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    local CloseStroke = Instance.new("UIStroke")
    CloseStroke.Color = getC().BorderSubtle
    CloseStroke.Thickness = 1
    CloseStroke.Parent = CloseBtn

    local CloseIcon = Instance.new("ImageLabel")
    CloseIcon.Name = "Icon"
    CloseIcon.Parent = CloseBtn
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CloseIcon.Size = UDim2.fromOffset(15, 15)
    CloseIcon.Image = "rbxassetid://10709791437"
    CloseIcon.ImageColor3 = getC().TextSecondary

    task.spawn(function()
        local asset = resolveAsset("icon/I-x.png")
        if asset and CloseIcon.Parent then 
            CloseIcon.Image = asset
        else
            CloseBtn.Text = "X"
            CloseBtn.TextColor3 = getC().TextSecondary
            CloseBtn.Font = Enum.Font.GothamBold
            CloseBtn.TextSize = 12
        end
    end)

    CloseBtn.MouseEnter:Connect(function()
        local c = getC()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = c.CloseHoverBg}):Play()
        TweenService:Create(CloseStroke, TweenInfo.new(0.2), {Color = c.CloseHoverColor}):Play()
        TweenService:Create(CloseIcon, TweenInfo.new(0.2), {ImageColor3 = c.CloseHoverColor}):Play()
    end)

    CloseBtn.MouseLeave:Connect(function()
        local c = getC()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = c.BgCardElev}):Play()
        TweenService:Create(CloseStroke, TweenInfo.new(0.2), {Color = c.BorderSubtle}):Play()
        TweenService:Create(CloseIcon, TweenInfo.new(0.2), {ImageColor3 = c.TextSecondary}):Play()
    end)

    -- BODY SCROLLING CONTAINER
    local BodyScroll = Instance.new("ScrollingFrame")
    BodyScroll.Name = "BodyScroll"
    BodyScroll.Parent = Content
    BodyScroll.BackgroundTransparency = 1
    BodyScroll.BorderSizePixel = 0
    BodyScroll.Position = UDim2.new(0, 0, 0, 0)
    BodyScroll.Size = UDim2.new(1, 0, 1, 0)
    BodyScroll.ScrollBarThickness = 4
    BodyScroll.ScrollBarImageColor3 = getC().Border
    BodyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    BodyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    BodyScroll.ClipsDescendants = true
    BodyScroll.ZIndex = 5

    local BodyPadding = Instance.new("UIPadding")
    BodyPadding.Parent = BodyScroll
    BodyPadding.PaddingLeft = UDim.new(0, 24)
    BodyPadding.PaddingRight = UDim.new(0, 24)
    BodyPadding.PaddingTop = UDim.new(0, 72)
    BodyPadding.PaddingBottom = UDim.new(0, 32)

    local BodyLayout = Instance.new("UIListLayout")
    BodyLayout.Parent = BodyScroll
    BodyLayout.FillDirection = Enum.FillDirection.Vertical
    BodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BodyLayout.Padding = UDim.new(0, 18)

    local headerHidden = false
    BodyScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local scrollY = BodyScroll.CanvasPosition.Y
        if scrollY > 36 and not headerHidden then
            headerHidden = true
            TweenService:Create(AppHeader, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, -60),
                GroupTransparency = 1
            }):Play()
        elseif scrollY <= 36 and headerHidden then
            headerHidden = false
            TweenService:Create(AppHeader, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
                GroupTransparency = 0
            }):Play()
        end
    end)

    -- 1. SEARCH BAR
    local SearchContainer = Instance.new("Frame")
    SearchContainer.Name = "SearchContainer"
    SearchContainer.Parent = BodyScroll
    SearchContainer.BackgroundTransparency = 1
    SearchContainer.Size = UDim2.new(1, 0, 0, 46)
    SearchContainer.LayoutOrder = 1

    local SearchBox = Instance.new("Frame")
    SearchBox.Name = "SearchBox"
    SearchBox.Parent = SearchContainer
    SearchBox.AnchorPoint = Vector2.new(0.5, 0.5)
    SearchBox.BackgroundColor3 = getC().CopyBg
    SearchBox.Position = UDim2.new(0.5, 0, 0.5, 0)
    SearchBox.Size = UDim2.new(1, 0, 1, 0)

    local SearchBoxConstraint = Instance.new("UISizeConstraint")
    SearchBoxConstraint.MaxSize = Vector2.new(640, 46)
    SearchBoxConstraint.Parent = SearchBox

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(1, 0)
    SearchCorner.Parent = SearchBox

    local SearchStroke = Instance.new("UIStroke")
    SearchStroke.Color = getC().CopyBorder
    SearchStroke.Thickness = 1
    SearchStroke.Parent = SearchBox

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Name = "Icon"
    SearchIcon.Parent = SearchBox
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Position = UDim2.new(0, 18, 0.5, 0)
    SearchIcon.Size = UDim2.fromOffset(18, 18)
    SearchIcon.Image = "rbxassetid://10709791437"
    SearchIcon.ImageColor3 = getC().TextMuted

    task.spawn(function()
        local asset = resolveAsset("icon/I-search.png")
        if asset and SearchIcon.Parent then SearchIcon.Image = asset end
    end)

    local SearchInput = Instance.new("TextBox")
    SearchInput.Name = "Input"
    SearchInput.Parent = SearchBox
    SearchInput.BackgroundTransparency = 1
    SearchInput.Position = UDim2.new(0, 48, 0, 0)
    SearchInput.Size = UDim2.new(1, -64, 1, 0)
    SearchInput.Font = Enum.Font.Gotham
    SearchInput.PlaceholderColor3 = getC().TextMuted
    SearchInput.PlaceholderText = "Search interfaces..."
    SearchInput.Text = ""
    SearchInput.TextColor3 = getC().TextPrimary
    SearchInput.TextSize = 14.5
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false

    SearchInput.Focused:Connect(function()
        TweenService:Create(SearchStroke, TweenInfo.new(0.2), {Color = getC().Accent}):Play()
    end)

    SearchInput.FocusLost:Connect(function()
        TweenService:Create(SearchStroke, TweenInfo.new(0.2), {Color = getC().CopyBorder}):Play()
    end)

    -- 2. SCRIPT COPY FIELD (Reconstructed to 100% replicate the exact search box structure)
    local CopyContainer = Instance.new("Frame")
    CopyContainer.Name = "CopyContainer"
    CopyContainer.Parent = BodyScroll
    CopyContainer.BackgroundTransparency = 1
    CopyContainer.Size = UDim2.new(1, 0, 0, 46)
    CopyContainer.LayoutOrder = 2

    local CopyBox = Instance.new("Frame")
    CopyBox.Name = "CopyBox"
    CopyBox.Parent = CopyContainer
    CopyBox.AnchorPoint = Vector2.new(0.5, 0.5)
    CopyBox.BackgroundColor3 = getC().CopyBg
    CopyBox.Position = UDim2.new(0.5, 0, 0.5, 0)
    CopyBox.Size = UDim2.new(1, 0, 1, 0)

    local CopyBoxConstraint = Instance.new("UISizeConstraint")
    CopyBoxConstraint.MaxSize = Vector2.new(640, 46)
    CopyBoxConstraint.Parent = CopyBox

    local CopyCorner = Instance.new("UICorner")
    CopyCorner.CornerRadius = UDim.new(1, 0)
    CopyCorner.Parent = CopyBox

    local CopyStroke = Instance.new("UIStroke")
    CopyStroke.Color = getC().CopyBorder
    CopyStroke.Thickness = 1
    CopyStroke.Parent = CopyBox

    local CopyCodeText = Instance.new("TextLabel")
    CopyCodeText.Name = "Code"
    CopyCodeText.Parent = CopyBox
    CopyCodeText.AnchorPoint = Vector2.new(0.5, 0.5)
    CopyCodeText.BackgroundTransparency = 1
    CopyCodeText.Position = UDim2.new(0.5, 0, 0.5, 0)
    CopyCodeText.Size = UDim2.new(1, -40, 1, 0)
    CopyCodeText.Font = Enum.Font.RobotoMono
    CopyCodeText.Text = 'loadstring(game:HttpGet("https://7yd7.pages.dev/"))()'
    CopyCodeText.TextColor3 = getC().CodeColor
    CopyCodeText.TextSize = 14.5
    CopyCodeText.TextXAlignment = Enum.TextXAlignment.Center

    local CheckIcon = Instance.new("ImageLabel")
    CheckIcon.Name = "CheckIcon"
    CheckIcon.Parent = CopyBox
    CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CheckIcon.BackgroundTransparency = 1
    CheckIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    CheckIcon.Size = UDim2.fromOffset(24, 24)
    CheckIcon.Image = "rbxassetid://10709791437"
    CheckIcon.ImageColor3 = Color3.fromRGB(52, 211, 153)
    CheckIcon.ImageTransparency = 1

    task.spawn(function()
        local asset = resolveAsset("icon/I-check.png")
        if asset and CheckIcon.Parent then CheckIcon.Image = asset end
    end)

    local ClickCopyBtn = Instance.new("TextButton")
    ClickCopyBtn.Name = "ClickBtn"
    ClickCopyBtn.Parent = CopyBox
    ClickCopyBtn.BackgroundTransparency = 1
    ClickCopyBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickCopyBtn.Text = ""
    ClickCopyBtn.ZIndex = 5

    local isCopied = false
    ClickCopyBtn.MouseEnter:Connect(function()
        if not isCopied then
            TweenService:Create(CopyStroke, TweenInfo.new(0.2), {Color = getC().Accent}):Play()
        end
    end)

    ClickCopyBtn.MouseLeave:Connect(function()
        if not isCopied then
            TweenService:Create(CopyStroke, TweenInfo.new(0.2), {Color = getC().CopyBorder}):Play()
        end
    end)

    ClickCopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard('loadstring(game:HttpGet("https://7yd7.pages.dev/"))()')
        end
        isCopied = true

        TweenService:Create(CopyStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Color = Color3.fromRGB(52, 211, 153)}):Play()
        TweenService:Create(CopyBox, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(16, 38, 30)}):Play()
        TweenService:Create(CopyCodeText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        
        CheckIcon.Size = UDim2.fromOffset(12, 12)
        TweenService:Create(CheckIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            ImageTransparency = 0,
            Size = UDim2.fromOffset(24, 24)
        }):Play()
        
        task.wait(1.25)
        if CopyBox.Parent then
            isCopied = false
            local c = getC()
            TweenService:Create(CopyStroke, TweenInfo.new(0.3), {Color = c.CopyBorder}):Play()
            TweenService:Create(CopyBox, TweenInfo.new(0.3), {BackgroundColor3 = c.CopyBg}):Play()
            TweenService:Create(CopyCodeText, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
            TweenService:Create(CheckIcon, TweenInfo.new(0.2), {ImageTransparency = 1, Size = UDim2.fromOffset(14, 14)}):Play()
        end
    end)

    -- 3. CARDS GRID
    local GridFrame = Instance.new("Frame")
    GridFrame.Name = "GridFrame"
    GridFrame.Parent = BodyScroll
    GridFrame.BackgroundTransparency = 1
    GridFrame.Size = UDim2.new(1, 0, 0, 0)
    GridFrame.AutomaticSize = Enum.AutomaticSize.Y
    GridFrame.LayoutOrder = 3

    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.Parent = GridFrame
    GridLayout.CellPadding = UDim2.fromOffset(16, 16)
    GridLayout.CellSize = UDim2.fromOffset(245, 165)
    GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    GridLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local EmptyState = Instance.new("TextLabel")
    EmptyState.Name = "EmptyState"
    EmptyState.Parent = BodyScroll
    EmptyState.BackgroundTransparency = 1
    EmptyState.Size = UDim2.new(1, 0, 0, 60)
    EmptyState.Font = Enum.Font.Gotham
    EmptyState.Text = "No interfaces found."
    EmptyState.TextColor3 = getC().TextMuted
    EmptyState.TextSize = 14
    EmptyState.Visible = false
    EmptyState.LayoutOrder = 4

    local Camera = workspace.CurrentCamera
    local function updateResponsiveGrid()
        local vpX = Camera and Camera.ViewportSize.X or 800
        if vpX < 540 then
            GridLayout.CellSize = UDim2.new(1, -12, 0, 165)
        elseif vpX < 780 then
            GridLayout.CellSize = UDim2.fromOffset(220, 165)
        else
            GridLayout.CellSize = UDim2.fromOffset(245, 165)
        end
    end

    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveGrid)
    end
    updateResponsiveGrid()

    -- 4. DETAILS MODAL POPUP (Transparent overlay backdrop without dimming)
    local ModalOverlay = Instance.new("Frame")
    ModalOverlay.Name = "ModalOverlay"
    ModalOverlay.Parent = Screen
    ModalOverlay.BackgroundTransparency = 1
    ModalOverlay.BorderSizePixel = 0
    ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
    ModalOverlay.Visible = false
    ModalOverlay.ZIndex = 100

    local ModalContent = Instance.new("CanvasGroup")
    ModalContent.Name = "ModalContent"
    ModalContent.Parent = ModalOverlay
    ModalContent.AnchorPoint = Vector2.new(0.5, 0.5)
    ModalContent.BackgroundColor3 = getC().ModalBg
    ModalContent.Position = UDim2.new(0.5, 0, 0.5, 0)
    ModalContent.Size = UDim2.new(0.88, 0, 0.82, 0)
    ModalContent.GroupTransparency = 1

    local ModalUIScale = Instance.new("UIScale")
    ModalUIScale.Scale = 0.94
    ModalUIScale.Parent = ModalContent

    local ModalConstraint = Instance.new("UISizeConstraint")
    ModalConstraint.MaxSize = Vector2.new(560, 480)
    ModalConstraint.MinSize = Vector2.new(300, 340)
    ModalConstraint.Parent = ModalContent

    local ModalCorner = Instance.new("UICorner")
    ModalCorner.CornerRadius = UDim.new(0, 16)
    ModalCorner.Parent = ModalContent

    local ModalStroke = Instance.new("UIStroke")
    ModalStroke.Color = getC().Border
    ModalStroke.Thickness = 1.2
    ModalStroke.Transparency = 1
    ModalStroke.Parent = ModalContent

    -- Modal Header
    local ModalHeader = Instance.new("Frame")
    ModalHeader.Name = "Header"
    ModalHeader.Parent = ModalContent
    ModalHeader.BackgroundTransparency = 1
    ModalHeader.Position = UDim2.new(0, 20, 0, 14)
    ModalHeader.Size = UDim2.new(1, -40, 0, 42)

    local ModalTitleArea = Instance.new("Frame")
    ModalTitleArea.Name = "TitleArea"
    ModalTitleArea.Parent = ModalHeader
    ModalTitleArea.BackgroundTransparency = 1
    ModalTitleArea.Size = UDim2.new(1, -44, 1, 0)

    local ModalTitleList = Instance.new("UIListLayout")
    ModalTitleList.Parent = ModalTitleArea
    ModalTitleList.FillDirection = Enum.FillDirection.Horizontal
    ModalTitleList.VerticalAlignment = Enum.VerticalAlignment.Center
    ModalTitleList.Padding = UDim.new(0, 10)

    local ModalTitle = Instance.new("TextLabel")
    ModalTitle.Name = "Title"
    ModalTitle.Parent = ModalTitleArea
    ModalTitle.BackgroundTransparency = 1
    ModalTitle.Size = UDim2.new(0, 0, 1, 0)
    ModalTitle.AutomaticSize = Enum.AutomaticSize.X
    ModalTitle.Font = Enum.Font.GothamBold
    ModalTitle.Text = "Interface Name"
    ModalTitle.TextColor3 = getC().TextPrimary
    ModalTitle.TextSize = 20
    ModalTitle.TextXAlignment = Enum.TextXAlignment.Left

    local ModalBadge = Instance.new("Frame")
    ModalBadge.Name = "Badge"
    ModalBadge.Parent = ModalTitleArea
    ModalBadge.BackgroundColor3 = Color3.fromRGB(35, 24, 52)
    ModalBadge.Size = UDim2.fromOffset(96, 22)
    ModalBadge.Visible = false

    local ModalBadgeCorner = Instance.new("UICorner")
    ModalBadgeCorner.CornerRadius = UDim.new(1, 0)
    ModalBadgeCorner.Parent = ModalBadge

    local ModalBadgeStroke = Instance.new("UIStroke")
    ModalBadgeStroke.Color = getC().Accent
    ModalBadgeStroke.Thickness = 1
    ModalBadgeStroke.Parent = ModalBadge

    local ModalBadgeText = Instance.new("TextLabel")
    ModalBadgeText.Parent = ModalBadge
    ModalBadgeText.BackgroundTransparency = 1
    ModalBadgeText.Size = UDim2.new(1, 0, 1, 0)
    ModalBadgeText.Font = Enum.Font.GothamBold
    ModalBadgeText.Text = "RECOMMENDED"
    ModalBadgeText.TextColor3 = Color3.fromRGB(243, 243, 245)
    ModalBadgeText.TextSize = 8.5

    -- Modal Close Button (Top-Right)
    local ModalCloseBtn = Instance.new("TextButton")
    ModalCloseBtn.Name = "CloseBtn"
    ModalCloseBtn.Parent = ModalHeader
    ModalCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    ModalCloseBtn.BackgroundColor3 = getC().BgCardElev
    ModalCloseBtn.Position = UDim2.new(1, -4, 0.5, 0)
    ModalCloseBtn.Size = UDim2.fromOffset(32, 32)
    ModalCloseBtn.AutoButtonColor = false
    ModalCloseBtn.Text = ""

    local ModalCloseCorner = Instance.new("UICorner")
    ModalCloseCorner.CornerRadius = UDim.new(1, 0)
    ModalCloseCorner.Parent = ModalCloseBtn

    local ModalCloseStroke = Instance.new("UIStroke")
    ModalCloseStroke.Color = getC().BorderSubtle
    ModalCloseStroke.Thickness = 1
    ModalCloseStroke.Parent = ModalCloseBtn

    local ModalCloseIcon = Instance.new("ImageLabel")
    ModalCloseIcon.Name = "Icon"
    ModalCloseIcon.Parent = ModalCloseBtn
    ModalCloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ModalCloseIcon.BackgroundTransparency = 1
    ModalCloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ModalCloseIcon.Size = UDim2.fromOffset(14, 14)
    ModalCloseIcon.Image = "rbxassetid://10709791437"
    ModalCloseIcon.ImageColor3 = getC().TextSecondary

    task.spawn(function()
        local asset = resolveAsset("icon/I-x.png")
        if asset and ModalCloseIcon.Parent then ModalCloseIcon.Image = asset end
    end)

    ModalCloseBtn.MouseEnter:Connect(function()
        local c = getC()
        TweenService:Create(ModalCloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = c.CloseHoverBg}):Play()
        TweenService:Create(ModalCloseStroke, TweenInfo.new(0.2), {Color = c.CloseHoverColor}):Play()
        TweenService:Create(ModalCloseIcon, TweenInfo.new(0.2), {ImageColor3 = c.CloseHoverColor}):Play()
    end)

    ModalCloseBtn.MouseLeave:Connect(function()
        local c = getC()
        TweenService:Create(ModalCloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = c.BgCardElev}):Play()
        TweenService:Create(ModalCloseStroke, TweenInfo.new(0.2), {Color = c.BorderSubtle}):Play()
        TweenService:Create(ModalCloseIcon, TweenInfo.new(0.2), {ImageColor3 = c.TextSecondary}):Play()
    end)

    -- Modal Body Layout
    local ModalBody = Instance.new("Frame")
    ModalBody.Name = "Body"
    ModalBody.Parent = ModalContent
    ModalBody.BackgroundTransparency = 1
    ModalBody.Position = UDim2.new(0, 20, 0, 60)
    ModalBody.Size = UDim2.new(1, -40, 1, -126)

    local ModalImageWrap = Instance.new("CanvasGroup")
    ModalImageWrap.Name = "ImageWrap"
    ModalImageWrap.Parent = ModalBody
    ModalImageWrap.BackgroundTransparency = 1
    ModalImageWrap.Size = UDim2.new(1, 0, 1, 0)

    local ModalImageCorner = Instance.new("UICorner")
    ModalImageCorner.CornerRadius = UDim.new(0, 12)
    ModalImageCorner.Parent = ModalImageWrap

    local ModalImage = Instance.new("ImageLabel")
    ModalImage.Name = "Preview"
    ModalImage.Parent = ModalImageWrap
    ModalImage.BackgroundTransparency = 1
    ModalImage.Size = UDim2.new(1, 0, 1, 0)
    ModalImage.ScaleType = Enum.ScaleType.Fit
    ModalImage.Image = ""

    -- Modal Bottom Action Bar (Run Button)
    local ModalFooter = Instance.new("Frame")
    ModalFooter.Name = "Footer"
    ModalFooter.Parent = ModalContent
    ModalFooter.AnchorPoint = Vector2.new(0, 1)
    ModalFooter.BackgroundTransparency = 1
    ModalFooter.Position = UDim2.new(0, 20, 1, -16)
    ModalFooter.Size = UDim2.new(1, -40, 0, 44)

    local RunBtn = Instance.new("TextButton")
    RunBtn.Name = "RunButton"
    RunBtn.Parent = ModalFooter
    RunBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    RunBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
    RunBtn.BackgroundColor3 = getC().Accent
    RunBtn.Size = UDim2.new(1, 0, 1, 0)
    RunBtn.AutoButtonColor = false
    RunBtn.Text = ""

    local RunBtnCorner = Instance.new("UICorner")
    RunBtnCorner.CornerRadius = UDim.new(0, 12)
    RunBtnCorner.Parent = RunBtn

    local RunBtnGradient = Instance.new("UIGradient")
    RunBtnGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(167, 139, 250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(124, 58, 237))
    })
    RunBtnGradient.Rotation = 90
    RunBtnGradient.Parent = RunBtn

    local RunBtnStroke = Instance.new("UIStroke")
    RunBtnStroke.Color = Color3.fromRGB(200, 180, 255)
    RunBtnStroke.Transparency = 0.5
    RunBtnStroke.Thickness = 1
    RunBtnStroke.Parent = RunBtn

    local RunBtnContent = Instance.new("Frame")
    RunBtnContent.Name = "Content"
    RunBtnContent.Parent = RunBtn
    RunBtnContent.BackgroundTransparency = 1
    RunBtnContent.Size = UDim2.new(1, 0, 1, 0)

    local RunBtnLayout = Instance.new("UIListLayout")
    RunBtnLayout.Parent = RunBtnContent
    RunBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    RunBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    RunBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RunBtnLayout.Padding = UDim.new(0, 8)

    local RunBtnIcon = Instance.new("ImageLabel")
    RunBtnIcon.Name = "Icon"
    RunBtnIcon.Parent = RunBtnContent
    RunBtnIcon.BackgroundTransparency = 1
    RunBtnIcon.Size = UDim2.fromOffset(16, 16)
    RunBtnIcon.Image = "rbxassetid://10709791437"
    RunBtnIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)

    task.spawn(function()
        local asset = resolveAsset("icon/I-play.png")
        if asset and RunBtnIcon.Parent then RunBtnIcon.Image = asset end
    end)

    local RunBtnText = Instance.new("TextLabel")
    RunBtnText.Name = "Label"
    RunBtnText.Parent = RunBtnContent
    RunBtnText.BackgroundTransparency = 1
    RunBtnText.Size = UDim2.new(0, 0, 1, 0)
    RunBtnText.AutomaticSize = Enum.AutomaticSize.X
    RunBtnText.Font = Enum.Font.GothamBold
    RunBtnText.Text = "Run"
    RunBtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
    RunBtnText.TextSize = 15

    RunBtn.MouseEnter:Connect(function()
        TweenService:Create(RunBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 155, 255)}):Play()
        TweenService:Create(RunBtnStroke, TweenInfo.new(0.2), {Transparency = 0.1}):Play()
    end)

    RunBtn.MouseLeave:Connect(function()
        TweenService:Create(RunBtn, TweenInfo.new(0.2), {BackgroundColor3 = getC().Accent}):Play()
        TweenService:Create(RunBtnStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
    end)

    local currentModalData = nil

    local function hideModal()
        TweenService:Create(ModalStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        TweenService:Create(ModalUIScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 0.94}):Play()
        local t = TweenService:Create(ModalContent, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            GroupTransparency = 1
        })
        t:Play()
        t.Completed:Wait()
        ModalOverlay.Visible = false
    end

    local function showModal(data)
        currentModalData = data
        ModalTitle.Text = data.Name
        ModalBadge.Visible = (data.Recommended == true)

        ModalImage.Image = "rbxassetid://96248696249042"
        task.spawn(function()
            local asset = resolveAsset("UI/" .. data.Name .. ".png")
            if asset and ModalImage.Parent then
                ModalImage.Image = asset
            end
        end)

        ModalOverlay.Visible = true
        ModalContent.GroupTransparency = 1
        ModalStroke.Transparency = 1
        ModalUIScale.Scale = 0.94

        TweenService:Create(ModalContent, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            GroupTransparency = 0
        }):Play()
        TweenService:Create(ModalStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0
        }):Play()
        TweenService:Create(ModalUIScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1.0
        }):Play()
    end

    ModalCloseBtn.MouseButton1Click:Connect(hideModal)

    ModalOverlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local absPos = ModalContent.AbsolutePosition
            local absSize = ModalContent.AbsoluteSize
            if pos.X < absPos.X or pos.X > (absPos.X + absSize.X) or pos.Y < absPos.Y or pos.Y > (absPos.Y + absSize.Y) then
                hideModal()
            end
        end
    end)

    local function CloseUI()
        if ModalOverlay.Visible then
            hideModal()
        end
        TweenService:Create(MainStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()
        local t = TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            GroupTransparency = 1,
            Size = UDim2.new(0.88, 0, 0.84, 0)
        })
        t:Play()
        t.Completed:Wait()
        Main.Visible = false
    end

    RunBtn.MouseButton1Click:Connect(function()
        if currentModalData then
            local selected = currentModalData
            task.spawn(hideModal)
            CloseUI()
            onSelect(selected)
        end
    end)

    local cardInstances = {}

    -- CREATE UI CARD
    local function createCard(data, index)
        local Card = Instance.new("CanvasGroup")
        Card.Name = data.Name
        Card.Parent = GridFrame
        Card.BackgroundColor3 = getC().BgCard
        Card.BorderSizePixel = 0
        Card.LayoutOrder = index

        local CardScale = Instance.new("UIScale")
        CardScale.Scale = 1.0
        CardScale.Parent = Card

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 16)
        CardCorner.Parent = Card

        local CardStroke = Instance.new("UIStroke")
        CardStroke.Color = getC().Border
        CardStroke.Thickness = 1.2
        CardStroke.Parent = Card

        -- Thumbnail Image Wrap
        local ThumbWrap = Instance.new("Frame")
        ThumbWrap.Name = "ThumbWrap"
        ThumbWrap.Parent = Card
        ThumbWrap.BackgroundColor3 = getC().BgCardElev
        ThumbWrap.BorderSizePixel = 0
        ThumbWrap.Position = UDim2.new(0, 0, 0, 0)
        ThumbWrap.Size = UDim2.new(1, 0, 0, 120)
        ThumbWrap.ZIndex = 2

        local Thumb = Instance.new("ImageLabel")
        Thumb.Name = "Thumb"
        Thumb.Parent = ThumbWrap
        Thumb.BackgroundTransparency = 1
        Thumb.Size = UDim2.new(1, 0, 1, 0)
        Thumb.ScaleType = Enum.ScaleType.Crop
        Thumb.Image = "rbxassetid://96248696249042"

        task.spawn(function()
            local asset = resolveAsset("UI/" .. data.Name .. ".png")
            if asset and Thumb.Parent then
                Thumb.Image = asset
            end
        end)

        -- Recommended Badge
        if data.Recommended then
            local Badge = Instance.new("Frame")
            Badge.Name = "Badge"
            Badge.Parent = Card
            Badge.AnchorPoint = Vector2.new(1, 0)
            Badge.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
            Badge.BackgroundTransparency = 0.2
            Badge.Position = UDim2.new(1, -8, 0, 8)
            Badge.Size = UDim2.fromOffset(105, 22)
            Badge.ZIndex = 6

            local BadgeCorner = Instance.new("UICorner")
            BadgeCorner.CornerRadius = UDim.new(1, 0)
            BadgeCorner.Parent = Badge

            local BadgeStroke = Instance.new("UIStroke")
            BadgeStroke.Color = getC().Accent
            BadgeStroke.Thickness = 1
            BadgeStroke.Parent = Badge

            local BadgeText = Instance.new("TextLabel")
            BadgeText.Parent = Badge
            BadgeText.BackgroundTransparency = 1
            BadgeText.Size = UDim2.new(1, 0, 1, 0)
            BadgeText.Font = Enum.Font.GothamBold
            BadgeText.Text = "RECOMMENDED"
            BadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
            BadgeText.TextSize = 8.5
        end

        -- Card Bottom Info Section
        local Info = Instance.new("Frame")
        Info.Name = "Info"
        Info.Parent = Card
        Info.BackgroundColor3 = getC().CardInfoBg
        Info.BorderSizePixel = 0
        Info.Position = UDim2.new(0, 0, 1, -45)
        Info.Size = UDim2.new(1, 0, 0, 45)
        Info.ZIndex = 4

        local InfoTopLine = Instance.new("Frame")
        InfoTopLine.Parent = Info
        InfoTopLine.BackgroundColor3 = getC().BorderSubtle
        InfoTopLine.BorderSizePixel = 0
        InfoTopLine.Size = UDim2.new(1, 0, 0, 1)

        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Parent = Info
        Title.AnchorPoint = Vector2.new(0, 0.5)
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 14, 0.5, 0)
        Title.Size = UDim2.new(1, -28, 0, 22)
        Title.Font = Enum.Font.GothamBold
        Title.Text = data.Name
        Title.TextColor3 = getC().TextPrimary
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left

        -- Click overlay button
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Name = "ClickBtn"
        ClickBtn.Parent = Card
        ClickBtn.BackgroundTransparency = 1
        ClickBtn.Size = UDim2.new(1, 0, 1, 0)
        ClickBtn.Text = ""
        ClickBtn.ZIndex = 10

        ClickBtn.MouseEnter:Connect(function()
            local c = getC()
            TweenService:Create(CardScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.035}):Play()
            TweenService:Create(CardStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = c.Accent,
                Thickness = 1.6
            }):Play()
            TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = c.CardHoverTitleColor}):Play()
        end)

        ClickBtn.MouseLeave:Connect(function()
            local c = getC()
            TweenService:Create(CardScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
            TweenService:Create(CardStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = c.Border,
                Thickness = 1.2
            }):Play()
            TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = c.TextPrimary}):Play()
        end)

        ClickBtn.MouseButton1Down:Connect(function()
            TweenService:Create(CardScale, TweenInfo.new(0.15), {Scale = 0.97}):Play()
        end)

        ClickBtn.MouseButton1Up:Connect(function()
            TweenService:Create(CardScale, TweenInfo.new(0.15), {Scale = 1.035}):Play()
        end)

        ClickBtn.MouseButton1Click:Connect(function()
            showModal(data)
        end)

        table.insert(cardInstances, {
            Object = Card,
            Data = data,
            Stroke = CardStroke,
            ThumbWrap = ThumbWrap,
            Info = Info,
            InfoTopLine = InfoTopLine,
            Title = Title
        })
    end

    for i, ui in ipairs(uiList) do
        createCard(ui, i)
    end

    -- Real-time Search Filter logic
    local function filterCards()
        local query = SearchInput.Text:lower():gsub("%s+", "")
        local visibleCount = 0

        for _, item in ipairs(cardInstances) do
            local name = item.Data.Name:lower()
            local matchesSearch = query == "" or name:find(query, 1, true) ~= nil
            
            if matchesSearch then
                item.Object.Visible = true
                visibleCount = visibleCount + 1
            else
                item.Object.Visible = false
            end
        end

        EmptyState.Visible = (visibleCount == 0)
    end

    SearchInput:GetPropertyChangedSignal("Text"):Connect(filterCards)

    -- Dynamic Theme Toggle Switch
    local function applyTheme(themeName)
        currentTheme = themeName
        local c = getC()

        Main.BackgroundColor3 = c.BgBody
        MainStroke.Color = c.Border
        AppHeader.BackgroundColor3 = c.HeaderBg
        HeaderBottomBorder.BackgroundColor3 = c.BorderSubtle
        Logo.ImageColor3 = c.LogoColor
        
        SearchBox.BackgroundColor3 = c.CopyBg
        SearchStroke.Color = c.CopyBorder
        SearchInput.TextColor3 = c.TextPrimary
        SearchInput.PlaceholderColor3 = c.TextMuted
        SearchIcon.ImageColor3 = c.TextMuted

        CopyBox.BackgroundColor3 = c.CopyBg
        CopyStroke.Color = c.CopyBorder
        CopyCodeText.TextColor3 = c.CodeColor

        DiscordBtn.BackgroundColor3 = c.BgCardElev
        DiscordStroke.Color = c.BorderSubtle
        DiscordIcon.ImageColor3 = c.TextSecondary

        ThemeToggle.BackgroundColor3 = c.BgCardElev
        ThemeStroke.Color = c.BorderSubtle
        ThemeIcon.ImageColor3 = c.TextSecondary

        CloseBtn.BackgroundColor3 = c.BgCardElev
        CloseStroke.Color = c.BorderSubtle
        CloseIcon.ImageColor3 = c.TextSecondary

        GitHubTab.BackgroundColor3 = c.GitHubBg
        GitHubStroke.Color = c.GitHubStroke
        GitHubText.TextColor3 = c.GitHubText

        ModalContent.BackgroundColor3 = c.ModalBg
        ModalStroke.Color = c.Border
        ModalTitle.TextColor3 = c.TextPrimary
        ModalCloseBtn.BackgroundColor3 = c.BgCardElev
        ModalCloseStroke.Color = c.BorderSubtle
        ModalCloseIcon.ImageColor3 = c.TextSecondary
        RunBtn.BackgroundColor3 = c.Accent

        BodyScroll.ScrollBarImageColor3 = c.Border
        EmptyState.TextColor3 = c.TextMuted

        for _, item in ipairs(cardInstances) do
            item.Object.BackgroundColor3 = c.BgCard
            item.Stroke.Color = c.Border
            item.ThumbWrap.BackgroundColor3 = c.BgCardElev
            item.Info.BackgroundColor3 = c.CardInfoBg
            item.InfoTopLine.BackgroundColor3 = c.BorderSubtle
            item.Title.TextColor3 = c.TextPrimary
        end

        updateThemeIcon()
    end

    ThemeToggle.MouseButton1Click:Connect(function()
        local nextTheme = currentTheme == "Dark" and "Light" or "Dark"
        applyTheme(nextTheme)
    end)

    -- Clean Window Reveal
    local function OpenUI()
        Main.GroupTransparency = 1
        MainStroke.Transparency = 1
        Main.Size = UDim2.new(0.88, 0, 0.84, 0)
        
        TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            GroupTransparency = 0,
            Size = UDim2.new(0.92, 0, 0.88, 0)
        }):Play()
        TweenService:Create(MainStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0
        }):Play()
    end

    -- Original clean floating loading logo animation (GitHub Menu branch)
    local function ShowLoading(logicFunc)
        local Loading = Instance.new("ImageLabel")
        Loading.Name = "LoadingLogo"
        Loading.Parent = Screen
        Loading.AnchorPoint = Vector2.new(0.5, 0.5)
        Loading.BackgroundTransparency = 1
        Loading.Position = UDim2.new(0.5, 0, 0.5, 0)
        Loading.Size = UDim2.fromOffset(130, 130)
        Loading.ImageTransparency = 1
        Loading.Image = "rbxassetid://18898582662"

        task.spawn(function()
            local asset = resolveAsset("icon/I-7yd7.png")
            if asset and Loading.Parent then Loading.Image = asset end
        end)

        TweenService:Create(Loading, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { ImageTransparency = 0 }):Play()

        if logicFunc then
            task.spawn(function()
                local loadingActive = true
                task.spawn(function()
                    while loadingActive do
                        TweenService:Create(Loading, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { ImageColor3 = Color3.fromRGB(255, 220, 0) }):Play()
                        task.wait(0.6)
                        if not loadingActive then break end
                        TweenService:Create(Loading, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
                        task.wait(0.6)
                    end
                end)

                local success, err = pcall(logicFunc)
                loadingActive = false

                task.wait(0.1)

                if success then
                    TweenService:Create(Loading, TweenInfo.new(0.4), { ImageColor3 = Color3.fromRGB(0, 255, 140) }):Play()
                else
                    warn("[7yd7 Loader] Logic failed: " .. tostring(err))
                    TweenService:Create(Loading, TweenInfo.new(0.4), { ImageColor3 = Color3.fromRGB(255, 50, 50) }):Play()
                end

                task.wait(0.5)
                local fade = TweenService:Create(Loading, TweenInfo.new(0.6, Enum.EasingStyle.Quart), { ImageTransparency = 1, Size = UDim2.fromOffset(180, 180) })
                fade:Play()
                fade.Completed:Wait()
                Screen:Destroy()
            end)
        else
            task.wait(1)
            Screen:Destroy()
        end
    end

    CloseBtn.MouseButton1Click:Connect(function()
        CloseUI()
        Screen:Destroy()
    end)

    OpenUI()

    return {
        Close = CloseUI,
        Loading = ShowLoading
    }
end

return Loader