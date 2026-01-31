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
                task.delay(10, function() pcall(function() if delfile then delfile(localPath) end end) end)
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

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Screen
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0.9, 0, 0.9, 0)
    Main.ClipsDescendants = true
    Main.BackgroundTransparency = 1

    local MaxSize = Instance.new("UISizeConstraint")
    MaxSize.MaxSize = Vector2.new(800, 550)
    MaxSize.Parent = Main

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(35, 35, 35)
    Stroke.Thickness = 1.2
    Stroke.Transparency = 1
    Stroke.Parent = Main

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Parent = Main
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.ClipsDescendants = true
    Container.ZIndex = 2

    local Content = Instance.new("CanvasGroup")
    Content.Name = "Content"
    Content.Parent = Container
    Content.BackgroundTransparency = 1
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.GroupTransparency = 1

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Parent = Content
    Header.BackgroundTransparency = 1
    Header.Size = UDim2.new(1, 0, 0, 60)

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Header
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 25, 0, 0)
    Title.Size = UDim2.new(0.5, 0, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = config.Rights or "7yd7 Hub v4"
    Title.TextColor3 = Color3.fromRGB(240, 240, 240)
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Parent = Header
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(1, -50, 0.5, -15)
    CloseBtn.Size = UDim2.fromOffset(30, 30)
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 20

    local Grid = Instance.new("ScrollingFrame")
    Grid.Name = "Grid"
    Grid.Parent = Content
    Grid.BackgroundTransparency = 1
    Grid.BorderSizePixel = 0
    Grid.Position = UDim2.new(0, 25, 0, 70)
    Grid.Size = UDim2.new(1, -50, 1, -110)
    Grid.ScrollBarThickness = 2
    Grid.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    Grid.CanvasSize = UDim2.new(0, 0, 0, 0)
    Grid.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local Layout = Instance.new("UIGridLayout")
    Layout.Parent = Grid
    Layout.CellPadding = UDim2.fromOffset(20, 20)
    Layout.CellSize = UDim2.fromOffset(230, 160) 
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function createCard(data)
        local Card = Instance.new("ImageButton") 
        Card.Name = data.Name
        Card.Parent = Grid
        Card.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        Card.BorderSizePixel = 0
        Card.ClipsDescendants = true
        Card.AutoButtonColor = false
        Card.Image = "rbxassetid://18898582662" 

        task.spawn(function()
            local asset = resolveAsset("UI/" .. data.Name .. ".png")
            if asset then Card.Image = asset end
        end)

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 10)
        CardCorner.Parent = Card

        local CardStroke = Instance.new("UIStroke")
        CardStroke.Color = Color3.fromRGB(40, 40, 40)
        CardStroke.Thickness = 1.2
        CardStroke.Parent = Card

        local Overlay = Instance.new("Frame")
        Overlay.Name = "Overlay"
        Overlay.Parent = Card
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 0.4
        Overlay.BorderSizePixel = 0
        Overlay.Position = UDim2.new(0, 0, 1, -40)
        Overlay.Size = UDim2.new(1, 0, 0, 40)

        local CardTitle = Instance.new("TextLabel")
        CardTitle.Name = "Title"
        CardTitle.Parent = Overlay
        CardTitle.BackgroundTransparency = 1
        CardTitle.Size = UDim2.new(1, 0, 1, 0)
        CardTitle.Font = Enum.Font.GothamSemibold
        CardTitle.Text = data.Name
        CardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        CardTitle.TextSize = 15

        if data.Recommended then
            local Badge = Instance.new("Frame")
            Badge.Name = "Badge"
            Badge.Parent = Card
            Badge.AnchorPoint = Vector2.new(0.5, 0)
            Badge.BackgroundColor3 = Color3.fromRGB(114, 28, 255)
            Badge.Position = UDim2.new(0.5, 0, 0, 10)
            Badge.Size = UDim2.fromOffset(110, 24)
            Badge.ZIndex = 5

            local BC = Instance.new("UICorner")
            BC.CornerRadius = UDim.new(0, 6)
            BC.Parent = Badge

            local BT = Instance.new("TextLabel")
            BT.Parent = Badge
            BT.BackgroundTransparency = 1
            BT.Size = UDim2.new(1, 0, 1, 0)
            BT.Font = Enum.Font.GothamBold
            BT.Text = "RECOMMENDED"
            BT.TextColor3 = Color3.fromRGB(255, 255, 255)
            BT.TextSize = 9
        end

        Card.MouseEnter:Connect(function()
            TweenService:Create(Card, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(200, 200, 200)}):Play()
            TweenService:Create(CardStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(120, 50, 255)}):Play()
            TweenService:Create(Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.2}):Play()
        end)
        Card.MouseLeave:Connect(function()
            TweenService:Create(Card, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            TweenService:Create(CardStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(40, 40, 40)}):Play()
            TweenService:Create(Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
        end)
        Card.MouseButton1Click:Connect(function() onSelect(data) end)
    end

    for _, ui in ipairs(uiList) do createCard(ui) end

    local function OpenUI()
        Main.Size = UDim2.fromOffset(400, 300)
        TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.new(0.9, 0, 0.9, 0)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.6), {Transparency = 0}):Play()
        task.wait(0.5)
        TweenService:Create(Content, TweenInfo.new(0.4), {GroupTransparency = 0}):Play()
    end

    local function CloseUI()
        TweenService:Create(Content, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
        task.wait(0.3)
        local t = TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1})
        t:Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        t.Completed:Wait()
        Main.Visible = false
    end

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
                        TweenService:Create(Loading, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(255, 230, 0)}):Play()
                        task.wait(0.8)
                        if not loadingActive then break end
                        TweenService:Create(Loading, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(150, 130, 0)}):Play()
                        task.wait(0.8)
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
            task.wait(1) Screen:Destroy()
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
