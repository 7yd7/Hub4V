local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Loader = {}

local function resolveAsset(serverPath)
    local baseUrl = getgenv().NEXS_BASE_URL or ""
    if baseUrl:sub(-1) == "/" then baseUrl = baseUrl:sub(1, -2) end
    
    local fileName = serverPath:match("([^/]+)$")
    local localFolder = "7yd7Hub/Assets/" .. serverPath:match("^(.-)/[^/]+$")
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
                    current = current == "" and part or current .. "/" .. part
                    if not isfolder(current) then makefolder(current) end
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
                current = current == "" and part or current .. "/" .. part
                if not isfolder(current) then makefolder(current) end
            end
        end
    end)

    local success, content = pcall(function() return game:HttpGet(fullUrl) end)
    if success and content and #content > 500 and content:sub(1, 1) ~= "<" then
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

function Loader.Create(config)
    local config = config or {}
    local uiList = config.UIs or {}
    local onSelect = config.OnSelect or function() end

    local Screen = Instance.new("ScreenGui")
    Screen.Name = "7yd7_Loader"
    Screen.Parent = (gethui and gethui()) or CoreGui
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Window Frame (Responsive across PC, Tablet & Mobile)
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Screen
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0.9, 0, 0.85, 0)
    Main.ClipsDescendants = true
    Main.BackgroundTransparency = 1

    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MaxSize = Vector2.new(760, 460)
    SizeConstraint.MinSize = Vector2.new(300, 260)
    SizeConstraint.Parent = Main

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(44, 48, 64)
    Stroke.Thickness = 1.4
    Stroke.Transparency = 1
    Stroke.Parent = Main

    -- Neutral Ambient Background Gradient
    local AmbientGradient = Instance.new("UIGradient")
    AmbientGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 23, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 14, 19))
    })
    AmbientGradient.Rotation = 45
    AmbientGradient.Parent = Main

    -- Dragging Logic for title header
    local dragging = false
    local dragInput, dragStart, startPos

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Parent = Main
    Content.BackgroundTransparency = 1
    Content.Size = UDim2.new(1, 0, 1, 0)

    -- Header Frame
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Parent = Content
    Header.BackgroundTransparency = 1
    Header.Size = UDim2.new(1, 0, 0, 70)

    Header.InputBegan:Connect(function(input)
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

    Header.InputChanged:Connect(function(input)
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

    -- Brand Icon / Logo
    local BrandIcon = Instance.new("ImageLabel")
    BrandIcon.Name = "BrandIcon"
    BrandIcon.Parent = Header
    BrandIcon.BackgroundTransparency = 1
    BrandIcon.Position = UDim2.new(0, 16, 0.5, -19)
    BrandIcon.Size = UDim2.fromOffset(38, 38)
    BrandIcon.Image = "rbxassetid://18898582662"

    task.spawn(function()
        local asset = resolveAsset("icon/I-7yd7.png")
        if asset then BrandIcon.Image = asset end
    end)

    local BrandIconCorner = Instance.new("UICorner")
    BrandIconCorner.CornerRadius = UDim.new(0, 8)
    BrandIconCorner.Parent = BrandIcon

    -- Title Label
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Header
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 62, 0, 16)
    Title.Size = UDim2.new(0.5, 0, 0, 22)
    Title.Font = Enum.Font.GothamBold
    Title.Text = config.Rights or "7yd7 Hub"
    Title.TextColor3 = Color3.fromRGB(250, 250, 255)
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Version Badge (Dark Slate)
    local VerBadge = Instance.new("Frame")
    VerBadge.Name = "VerBadge"
    VerBadge.Parent = Header
    VerBadge.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
    VerBadge.Position = UDim2.new(0, 62 + Title.TextBounds.X + 8, 0, 18)
    VerBadge.Size = UDim2.fromOffset(42, 18)

    local VerBadgeCorner = Instance.new("UICorner")
    VerBadgeCorner.CornerRadius = UDim.new(0, 5)
    VerBadgeCorner.Parent = VerBadge

    local VerBadgeStroke = Instance.new("UIStroke")
    VerBadgeStroke.Color = Color3.fromRGB(58, 65, 85)
    VerBadgeStroke.Thickness = 1
    VerBadgeStroke.Parent = VerBadge

    local VerText = Instance.new("TextLabel")
    VerText.Parent = VerBadge
    VerText.BackgroundTransparency = 1
    VerText.Size = UDim2.new(1, 0, 1, 0)
    VerText.Font = Enum.Font.GothamBold
    VerText.Text = "v4.0"
    VerText.TextColor3 = Color3.fromRGB(200, 210, 230)
    VerText.TextSize = 10

    -- Subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Parent = Header
    Subtitle.BackgroundTransparency = 1
    Subtitle.Position = UDim2.new(0, 62, 0, 40)
    Subtitle.Size = UDim2.new(0.65, 0, 0, 16)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Text = "Select your preferred interface framework"
    Subtitle.TextColor3 = Color3.fromRGB(145, 150, 170)
    Subtitle.TextSize = 11.5
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Clean Neutral Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Parent = Header
    CloseBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.Size = UDim2.fromOffset(30, 30)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(165, 170, 190)
    CloseBtn.TextSize = 13
    CloseBtn.AutoButtonColor = false

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 7)
    CloseCorner.Parent = CloseBtn

    local CloseStroke = Instance.new("UIStroke")
    CloseStroke.Color = Color3.fromRGB(42, 46, 60)
    CloseStroke.Thickness = 1
    CloseStroke.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(36, 40, 54), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(CloseStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(70, 78, 98)}):Play()
    end)

    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 26, 36), TextColor3 = Color3.fromRGB(165, 170, 190)}):Play()
        TweenService:Create(CloseStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(42, 46, 60)}):Play()
    end)

    -- Divider Line
    local Divider = Instance.new("Frame")
    Divider.Name = "Divider"
    Divider.Parent = Content
    Divider.BackgroundColor3 = Color3.fromRGB(34, 38, 50)
    Divider.BorderSizePixel = 0
    Divider.Position = UDim2.new(0, 16, 0, 70)
    Divider.Size = UDim2.new(1, -32, 0, 1)

    -- Grid Scrolling Frame (Calculated Width to perfectly fit cards across screen sizes)
    local Grid = Instance.new("ScrollingFrame")
    Grid.Name = "Grid"
    Grid.Parent = Content
    Grid.BackgroundTransparency = 1
    Grid.BorderSizePixel = 0
    Grid.Position = UDim2.new(0, 16, 0, 80)
    Grid.Size = UDim2.new(1, -32, 1, -90)
    Grid.ScrollBarThickness = 3
    Grid.ScrollBarImageColor3 = Color3.fromRGB(70, 75, 95)
    Grid.CanvasSize = UDim2.new(0, 0, 0, 0)
    Grid.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local GridPadding = Instance.new("UIPadding")
    GridPadding.Parent = Grid
    GridPadding.PaddingBottom = UDim.new(0, 30)
    GridPadding.PaddingTop = UDim.new(0, 4)
    GridPadding.PaddingLeft = UDim.new(0, 4)
    GridPadding.PaddingRight = UDim.new(0, 4)

    local Layout = Instance.new("UIGridLayout")
    Layout.Parent = Grid
    Layout.CellPadding = UDim2.fromOffset(14, 14)
    Layout.CellSize = UDim2.fromOffset(222, 150)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Dynamic Device Responsiveness Listener
    local Camera = workspace.CurrentCamera
    local function updateResponsiveGrid()
        local viewportX = Camera and Camera.ViewportSize.X or 800
        if viewportX < 500 then
            -- Mobile Phone: 1 full-width card per row
            Layout.CellSize = UDim2.new(1, -10, 0, 140)
        elseif viewportX < 740 then
            -- Small Tablet: 2 cards per row
            Layout.CellSize = UDim2.fromOffset(200, 145)
        else
            -- PC / Large Screen: 3 cards per row
            Layout.CellSize = UDim2.fromOffset(222, 150)
        end
    end

    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveGrid)
    end
    updateResponsiveGrid()

    local function createCard(data)
        local Card = Instance.new("ImageButton")
        Card.Name = data.Name
        Card.Parent = Grid
        Card.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
        Card.BorderSizePixel = 0
        Card.ClipsDescendants = true
        Card.AutoButtonColor = false
        Card.Image = "rbxassetid://96248696249042"
        Card.ScaleType = Enum.ScaleType.Crop

        task.spawn(function()
            local asset = resolveAsset("UI/" .. data.Name .. ".png")
            if asset then Card.Image = asset end
        end)

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 10)
        CardCorner.Parent = Card

        local CardStroke = Instance.new("UIStroke")
        CardStroke.Color = Color3.fromRGB(42, 46, 62)
        CardStroke.Thickness = 1.2
        CardStroke.Parent = Card

        -- Bottom Dark Contrast Gradient Overlay
        local Overlay = Instance.new("Frame")
        Overlay.Name = "Overlay"
        Overlay.Parent = Card
        Overlay.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
        Overlay.BackgroundTransparency = 0.1
        Overlay.BorderSizePixel = 0
        Overlay.Position = UDim2.new(0, 0, 1, -50)
        Overlay.Size = UDim2.new(1, 0, 0, 50)

        local OverlayGradient = Instance.new("UIGradient")
        OverlayGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 11, 15)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 28))
        })
        OverlayGradient.Parent = Overlay

        local OverlayTopLine = Instance.new("Frame")
        OverlayTopLine.Parent = Overlay
        OverlayTopLine.BackgroundColor3 = Color3.fromRGB(50, 55, 75)
        OverlayTopLine.BackgroundTransparency = 0.5
        OverlayTopLine.BorderSizePixel = 0
        OverlayTopLine.Size = UDim2.new(1, 0, 0, 1)

        local CardTitle = Instance.new("TextLabel")
        CardTitle.Name = "Title"
        CardTitle.Parent = Overlay
        CardTitle.BackgroundTransparency = 1
        CardTitle.Position = UDim2.new(0, 12, 0, 8)
        CardTitle.Size = UDim2.new(1, -24, 0, 18)
        CardTitle.Font = Enum.Font.GothamBold
        CardTitle.Text = data.Name
        CardTitle.TextColor3 = Color3.fromRGB(250, 250, 255)
        CardTitle.TextSize = 14
        CardTitle.TextXAlignment = Enum.TextXAlignment.Left

        local CardDesc = Instance.new("TextLabel")
        CardDesc.Name = "Desc"
        CardDesc.Parent = Overlay
        CardDesc.BackgroundTransparency = 1
        CardDesc.Position = UDim2.new(0, 12, 0, 27)
        CardDesc.Size = UDim2.new(1, -24, 0, 15)
        CardDesc.Font = Enum.Font.Gotham
        CardDesc.Text = data.Description or "Click to launch interface"
        CardDesc.TextColor3 = Color3.fromRGB(145, 150, 170)
        CardDesc.TextSize = 11
        CardDesc.TextXAlignment = Enum.TextXAlignment.Left

        -- Centered Recommended Badge
        if data.Recommended then
            local Badge = Instance.new("Frame")
            Badge.Name = "Badge"
            Badge.Parent = Card
            Badge.AnchorPoint = Vector2.new(0.5, 0)
            Badge.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
            Badge.Position = UDim2.new(0.5, 0, 0, 8)
            Badge.Size = UDim2.fromOffset(118, 22)
            Badge.ZIndex = 5

            local BC = Instance.new("UICorner")
            BC.CornerRadius = UDim.new(0, 5)
            BC.Parent = Badge

            local BS = Instance.new("UIStroke")
            BS.Color = Color3.fromRGB(65, 75, 100)
            BS.Thickness = 1
            BS.Parent = Badge

            local BT = Instance.new("TextLabel")
            BT.Parent = Badge
            BT.BackgroundTransparency = 1
            BT.Size = UDim2.new(1, 0, 1, 0)
            BT.Font = Enum.Font.GothamBold
            BT.Text = "RECOMMENDED"
            BT.TextColor3 = Color3.fromRGB(235, 240, 255)
            BT.TextSize = 9.5
        end

        Card.MouseEnter:Connect(function()
            TweenService:Create(CardStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = Color3.fromRGB(85, 95, 120)}):Play()
            TweenService:Create(OverlayTopLine, TweenInfo.new(0.25), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(90, 100, 125)}):Play()
            TweenService:Create(CardTitle, TweenInfo.new(0.25), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)

        Card.MouseLeave:Connect(function()
            TweenService:Create(CardStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = Color3.fromRGB(42, 46, 62)}):Play()
            TweenService:Create(OverlayTopLine, TweenInfo.new(0.25), {BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(50, 55, 75)}):Play()
            TweenService:Create(CardTitle, TweenInfo.new(0.25), {TextColor3 = Color3.fromRGB(250, 250, 255)}):Play()
        end)

        Card.MouseButton1Click:Connect(function()
            onSelect(data)
        end)
    end

    for _, ui in ipairs(uiList) do createCard(ui) end

    local function OpenUI()
        Main.Size = UDim2.new(0.4, 0, 0.4, 0)
        Main.BackgroundTransparency = 1
        TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.new(0.9, 0, 0.85, 0)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.45), {Transparency = 0}):Play()
    end

    -- Refined Two-Stage Closing Animation
    local function CloseUI()
        for _, child in ipairs(Content:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Transparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
            end
        end

        task.wait(0.22)

        local t = TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0.7, 0, 0, 0),
            BackgroundTransparency = 1
        })
        TweenService:Create(Stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Transparency = 1}):Play()
        t:Play()
        t.Completed:Wait()
        Main.Visible = false
    end

    -- Original Clean Floating Loading Logo Animation
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
            if asset then Loading.Image = asset end
        end)

        TweenService:Create(Loading, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
        
        if logicFunc then
            task.spawn(function()
                local loadingActive = true
                task.spawn(function()
                    while loadingActive do
                        TweenService:Create(Loading, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(255, 220, 0)}):Play()
                        task.wait(0.6)
                        if not loadingActive then break end
                        TweenService:Create(Loading, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                        task.wait(0.6)
                    end
                end)

                local success, err = pcall(logicFunc)
                loadingActive = false

                task.wait(0.1)

                if success then
                    TweenService:Create(Loading, TweenInfo.new(0.4), {ImageColor3 = Color3.fromRGB(0, 255, 140)}):Play()
                else
                    warn("[7yd7 Loader] Logic failed: " .. tostring(err))
                    TweenService:Create(Loading, TweenInfo.new(0.4), {ImageColor3 = Color3.fromRGB(255, 50, 50)}):Play()
                end
                
                task.wait(0.5)
                local fade = TweenService:Create(Loading, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {ImageTransparency = 1, Size = UDim2.fromOffset(180, 180)})
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
