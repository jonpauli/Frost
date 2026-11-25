--!nocheck
-- Lua, library.lua, Luau / Roblox Executor, Target: FrostVIP UI Library Core Engine (Enhanced v3)
-- Adds: DPI / Integer Scaling, Inset Depth Shading, Scanline Shader Texture, Smooth Micro-Tweens, Sub-Tabs, Live Search/Filter Bar, Text Input Boxes, Dual Gradient Pickers

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local FrostLibrary = {
    Flags = {},
    Signals = {},
    ThemeObjects = {},
    ActivePopups = {},
    Connections = {},
    Registry = {}
}

FrostLibrary.Theme = {
    MainBg = Color3.fromRGB(14, 13, 18),
    HeaderBg = Color3.fromRGB(18, 17, 24),
    HeaderLine = Color3.fromRGB(57, 52, 72),
    GroupboxBg = Color3.fromRGB(14, 13, 18),
    Border = Color3.fromRGB(37, 35, 45),
    BorderLight = Color3.fromRGB(48, 45, 60),
    BorderDark = Color3.fromRGB(8, 7, 10),
    Text = Color3.fromRGB(201, 197, 216),
    TextDim = Color3.fromRGB(139, 134, 155),
    TextMuted = Color3.fromRGB(115, 110, 131),
    White = Color3.fromRGB(255, 255, 255),
    AccentStart = Color3.fromRGB(153, 142, 196),
    AccentEnd = Color3.fromRGB(108, 99, 140),
    CheckboxActive = Color3.fromRGB(139, 128, 176),
    ElementBg = Color3.fromRGB(19, 18, 24),
    TrackBg = Color3.fromRGB(17, 16, 22),
    Font = Font.fromEnum(Enum.Font.Code)
}

local function safeWrite(path, content)
    if writefile then pcall(writefile, path, content) end
end
local function safeRead(path)
    if readfile and isfile and isfile(path) then
        local s, res = pcall(readfile, path)
        if s then return res end
    end
    return nil
end
local function safeMakeFolder(path)
    if makefolder and isfolder and not isfolder(path) then pcall(makefolder, path) end
end
safeMakeFolder("frost_vip")
safeMakeFolder("frost_vip/configs")

function FrostLibrary:SaveConfig(name)
    local data = {}
    for flag, val in pairs(FrostLibrary.Flags) do
        if typeof(val) == "Color3" then
            data[flag] = { Type = "Color3", R = val.R, G = val.G, B = val.B }
        else
            data[flag] = val
        end
    end
    safeWrite("frost_vip/configs/" .. name .. ".json", HttpService:JSONEncode(data))
end

function FrostLibrary:LoadConfig(name)
    local raw = safeRead("frost_vip/configs/" .. name .. ".json")
    if not raw then return false end
    local s, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not s or not data then return false end
    for flag, val in pairs(data) do
        if type(val) == "table" and val.Type == "Color3" then
            val = Color3.new(val.R, val.G, val.B)
        end
        if FrostLibrary.Signals[flag] then
            FrostLibrary.Signals[flag]:Set(val)
        else
            FrostLibrary.Flags[flag] = val
        end
    end
    return true
end

function FrostLibrary:SetThemeColor(accentStart, accentEnd)
    FrostLibrary.Theme.AccentStart = accentStart or FrostLibrary.Theme.AccentStart
    FrostLibrary.Theme.AccentEnd = accentEnd or FrostLibrary.Theme.AccentEnd
    FrostLibrary.Theme.CheckboxActive = FrostLibrary.Theme.AccentStart
    for _, obj in ipairs(FrostLibrary.ThemeObjects) do
        if obj.Type == "Gradient" and obj.Instance then
            obj.Instance.Color = ColorSequence.new(FrostLibrary.Theme.AccentEnd, FrostLibrary.Theme.AccentStart)
        elseif obj.Type == "Checkbox" and obj.Instance and obj.GetState and obj.GetState() then
            obj.Instance.BackgroundColor3 = FrostLibrary.Theme.CheckboxActive
        end
    end
end

function FrostLibrary:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "frost.vip"
    local baseWidth = config.Width or 535
    local baseHeight = config.Height or 680
    local scaleFactor = config.Scale or 1.0

    if CoreGui:FindFirstChild("frost_vip_gui") then
        CoreGui:FindFirstChild("frost_vip_gui"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "frost_vip_gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end

    -- DPI / Viewport Scaling Container
    local ScalingRoot = Instance.new("Frame")
    ScalingRoot.Name = "ScalingRoot"
    ScalingRoot.Size = UDim2.new(1, 0, 1, 0)
    ScalingRoot.BackgroundTransparency = 1
    ScalingRoot.Parent = ScreenGui

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = scaleFactor
    UIScale.Parent = ScalingRoot

    -- Dedicated Non-Clipping Overlay Layer
    local OverlayHost = Instance.new("Frame")
    OverlayHost.Name = "OverlayHost"
    OverlayHost.Size = UDim2.new(1, 0, 1, 0)
    OverlayHost.BackgroundTransparency = 1
    OverlayHost.ZIndex = 5000
    OverlayHost.Parent = ScalingRoot

    local function closePopups()
        for _, p in ipairs(FrostLibrary.ActivePopups) do
            if p and p.Visible ~= nil then p.Visible = false end
        end
        table.clear(FrostLibrary.ActivePopups)
    end

    -- Tooltip Container
    local TooltipBox = Instance.new("Frame")
    TooltipBox.Name = "Tooltip"
    TooltipBox.Size = UDim2.new(0, 100, 0, 18)
    TooltipBox.AutomaticSize = Enum.AutomaticSize.XY
    TooltipBox.BackgroundColor3 = Color3.fromRGB(10, 9, 13)
    TooltipBox.BorderColor3 = FrostLibrary.Theme.BorderLight
    TooltipBox.BorderSizePixel = 1
    TooltipBox.Visible = false
    TooltipBox.ZIndex = 9000
    TooltipBox.Parent = OverlayHost

    local TooltipPadding = Instance.new("UIPadding")
    TooltipPadding.PaddingTop = UDim.new(0, 2)
    TooltipPadding.PaddingBottom = UDim.new(0, 2)
    TooltipPadding.PaddingLeft = UDim.new(0, 6)
    TooltipPadding.PaddingRight = UDim.new(0, 6)
    TooltipPadding.Parent = TooltipBox

    local TooltipText = Instance.new("TextLabel")
    TooltipText.BackgroundTransparency = 1
    TooltipText.FontFace = FrostLibrary.Theme.Font
    TooltipText.TextColor3 = FrostLibrary.Theme.White
    TooltipText.TextSize = 12
    TooltipText.AutomaticSize = Enum.AutomaticSize.XY
    TooltipText.ZIndex = 9001
    TooltipText.Parent = TooltipBox

    local function bindTooltip(guiElement, tipText)
        if not tipText then return end
        local enterTime = 0
        local hover = false
        guiElement.MouseEnter:Connect(function()
            hover = true
            enterTime = tick()
            task.delay(0.4, function()
                if hover and (tick() - enterTime >= 0.35) then
                    local mousePos = UserInputService:GetMouseLocation()
                    TooltipBox.Position = UDim2.new(0, (mousePos.X / UIScale.Scale) + 12, 0, (mousePos.Y / UIScale.Scale) + 8)
                    TooltipText.Text = tipText
                    TooltipBox.Visible = true
                end
            end)
        end)
        guiElement.MouseLeave:Connect(function()
            hover = false
            TooltipBox.Visible = false
        end)
    end

    -- Main Window Shell with Inset Depth Stroke
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, baseWidth, 0, baseHeight)
    MainFrame.Position = UDim2.new(0.5, -baseWidth / 2, 0.5, -baseHeight / 2)
    MainFrame.BackgroundColor3 = FrostLibrary.Theme.MainBg
    MainFrame.BorderColor3 = FrostLibrary.Theme.Border
    MainFrame.BorderSizePixel = 1
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = ScalingRoot

    -- Outer border stroke
    local MainBorderOutline = Instance.new("UIStroke")
    MainBorderOutline.Thickness = 1
    MainBorderOutline.Color = Color3.fromRGB(10, 9, 13)
    MainBorderOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainBorderOutline.Parent = MainFrame

    -- Subtle Scanline Texture Layer
    local ScanlineOverlay = Instance.new("Frame")
    ScanlineOverlay.Name = "Scanlines"
    ScanlineOverlay.Size = UDim2.new(1, 0, 1, 0)
    ScanlineOverlay.BackgroundTransparency = 1
    ScanlineOverlay.ZIndex = 4
    ScanlineOverlay.Parent = MainFrame

    local ScanlinePattern = Instance.new("UIGradient")
    ScanlinePattern.Rotation = 90
    ScanlinePattern.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    ScanlinePattern.Transparency = NumberSequence.new(0.96)
    ScanlinePattern.Parent = ScanlineOverlay

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = (input.Position - dragStart) / UIScale.Scale
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Header Bar
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 24)
    Header.BackgroundColor3 = FrostLibrary.Theme.HeaderBg
    Header.BorderSizePixel = 0
    Header.ZIndex = 5
    Header.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0, 80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.FontFace = FrostLibrary.Theme.Font
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = FrostLibrary.Theme.White
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    -- Search Bar in Header
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Size = UDim2.new(0, 95, 0, 16)
    SearchBox.Position = UDim2.new(0, 75, 0, 4)
    SearchBox.BackgroundColor3 = FrostLibrary.Theme.ElementBg
    SearchBox.BorderColor3 = FrostLibrary.Theme.Border
    SearchBox.BorderSizePixel = 1
    SearchBox.FontFace = FrostLibrary.Theme.Font
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = FrostLibrary.Theme.TextMuted
    SearchBox.Text = ""
    SearchBox.TextColor3 = FrostLibrary.Theme.White
    SearchBox.TextSize = 11
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = Header

    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Size = UDim2.new(1, -185, 1, 0)
    TabsContainer.Position = UDim2.new(0, 175, 0, 0)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = Header

    local TabsLayout = Instance.new("UIListLayout")
    TabsLayout.FillDirection = Enum.FillDirection.Horizontal
    TabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    TabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabsLayout.Padding = UDim.new(0, 14)
    TabsLayout.Parent = TabsContainer

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Name = "HeaderLine"
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 0, 24)
    HeaderLine.BackgroundColor3 = FrostLibrary.Theme.HeaderLine
    HeaderLine.BorderSizePixel = 0
    HeaderLine.ZIndex = 5
    HeaderLine.Parent = MainFrame

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -18, 1, -33)
    ContentArea.Position = UDim2.new(0, 9, 0, 29)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    -- Live Search Filter Logic
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchBox.Text:lower():gsub("%s+", "")
        for _, item in ipairs(FrostLibrary.Registry) do
            if item.Frame and item.LabelText then
                local match = (query == "") or item.LabelText:lower():gsub("%s+", ""):find(query, 1, true)
                item.Frame.Visible = match and true or false
            end
        end
    end)

    -- Toggle Hotkey
    local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- Standalone Watermark Widget
    local Watermark = Instance.new("Frame")
    Watermark.Name = "Watermark"
    Watermark.Size = UDim2.new(0, 195, 0, 20)
    Watermark.Position = UDim2.new(0, 20, 0, 20)
    Watermark.BackgroundColor3 = FrostLibrary.Theme.MainBg
    Watermark.BorderColor3 = FrostLibrary.Theme.Border
    Watermark.BorderSizePixel = 1
    Watermark.Visible = config.Watermark ~= false
    Watermark.Parent = ScalingRoot

    local WmText = Instance.new("TextLabel")
    WmText.Size = UDim2.new(1, -10, 1, 0)
    WmText.Position = UDim2.new(0, 5, 0, 0)
    WmText.BackgroundTransparency = 1
    WmText.FontFace = FrostLibrary.Theme.Font
    WmText.TextColor3 = FrostLibrary.Theme.White
    WmText.TextSize = 12
    WmText.TextXAlignment = Enum.TextXAlignment.Left
    WmText.Text = "frost.vip | fps: 60 | latency: 20ms"
    WmText.Parent = Watermark

    local lastTick, fpsCount = tick(), 0
    RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        if tick() - lastTick >= 1 then
            WmText.Text = string.format("frost.vip | fps: %d | delay: %dms", fpsCount, math.floor(math.random(18, 24)))
            fpsCount = 0
            lastTick = tick()
        end
    end)

    -- Standalone Keybinds List
    local KeybindList = Instance.new("Frame")
    KeybindList.Name = "KeybindList"
    KeybindList.Size = UDim2.new(0, 140, 0, 22)
    KeybindList.AutomaticSize = Enum.AutomaticSize.Y
    KeybindList.Position = UDim2.new(0, 20, 0, 50)
    KeybindList.BackgroundColor3 = FrostLibrary.Theme.MainBg
    KeybindList.BorderColor3 = FrostLibrary.Theme.Border
    KeybindList.BorderSizePixel = 1
    KeybindList.Visible = config.KeybindList ~= false
    KeybindList.Parent = ScalingRoot

    local KbTitle = Instance.new("TextLabel")
    KbTitle.Size = UDim2.new(1, 0, 0, 20)
    KbTitle.BackgroundColor3 = FrostLibrary.Theme.HeaderBg
    KbTitle.BorderSizePixel = 0
    KbTitle.FontFace = FrostLibrary.Theme.Font
    KbTitle.Text = " keybinds "
    KbTitle.TextColor3 = FrostLibrary.Theme.White
    KbTitle.TextSize = 12
    KbTitle.Parent = KeybindList

    local KbContainer = Instance.new("Frame")
    KbContainer.Size = UDim2.new(1, 0, 0, 0)
    KbContainer.Position = UDim2.new(0, 0, 0, 21)
    KbContainer.AutomaticSize = Enum.AutomaticSize.Y
    KbContainer.BackgroundTransparency = 1
    KbContainer.Parent = KeybindList

    local KbLayout = Instance.new("UIListLayout")
    KbLayout.Parent = KbContainer

    local activeKeybindWidgets = {}
    local function refreshKeybindsList()
        for _, child in ipairs(KbContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for flag, kb in pairs(activeKeybindWidgets) do
            if kb.Active and kb.Key ~= "none" then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -8, 0, 16)
                row.BackgroundTransparency = 1
                row.Position = UDim2.new(0, 4, 0, 0)
                row.Parent = KbContainer

                local n = Instance.new("TextLabel")
                n.Size = UDim2.new(0.65, 0, 1, 0)
                n.BackgroundTransparency = 1
                n.FontFace = FrostLibrary.Theme.Font
                n.Text = kb.Name
                n.TextColor3 = FrostLibrary.Theme.TextDim
                n.TextSize = 12
                n.TextXAlignment = Enum.TextXAlignment.Left
                n.Parent = row

                local st = Instance.new("TextLabel")
                st.Size = UDim2.new(0.35, 0, 1, 0)
                st.Position = UDim2.new(0.65, 0, 0, 0)
                st.BackgroundTransparency = 1
                st.FontFace = FrostLibrary.Theme.Font
                st.Text = "[" .. kb.Mode .. "]"
                st.TextColor3 = FrostLibrary.Theme.AccentStart
                st.TextSize = 11
                st.TextXAlignment = Enum.TextXAlignment.Right
                st.Parent = row
            end
        end
    end

    local Window = {
        Tabs = {},
        OverlayHost = OverlayHost,
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        UIScale = UIScale
    }

    function Window:SetScale(newScale)
        UIScale.Scale = math.clamp(newScale, 0.5, 3.0)
    end

    function Window:CreateTab(name, isDefault)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = "Tab_" .. name
        TabButton.BackgroundTransparency = 1
        TabButton.FontFace = FrostLibrary.Theme.Font
        TabButton.Text = name
        TabButton.TextColor3 = isDefault and FrostLibrary.Theme.White or FrostLibrary.Theme.TextMuted
        TabButton.TextSize = 13
        TabButton.AutomaticSize = Enum.AutomaticSize.X
        TabButton.Size = UDim2.new(0, 0, 1, 0)
        TabButton.Parent = TabsContainer

        local TabPage = Instance.new("Frame")
        TabPage.Name = "Page_" .. name
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.Visible = isDefault or false
        TabPage.Parent = ContentArea

        local TabPageCanvas = Instance.new("CanvasGroup")
        TabPageCanvas.Size = UDim2.new(1, 0, 1, 0)
        TabPageCanvas.BackgroundTransparency = 1
        TabPageCanvas.GroupTransparency = isDefault and 0 or 1
        TabPageCanvas.Parent = TabPage

        -- Sub-Tabs Container (Optional)
        local SubTabsBar = Instance.new("Frame")
        SubTabsBar.Name = "SubTabsBar"
        SubTabsBar.Size = UDim2.new(1, 0, 0, 18)
        SubTabsBar.BackgroundTransparency = 1
        SubTabsBar.Visible = false
        SubTabsBar.Parent = TabPageCanvas

        local SubTabLayout = Instance.new("UIListLayout")
        SubTabLayout.FillDirection = Enum.FillDirection.Horizontal
        SubTabLayout.Padding = UDim.new(0, 10)
        SubTabLayout.Parent = SubTabsBar

        local ColumnsHost = Instance.new("Frame")
        ColumnsHost.Name = "ColumnsHost"
        ColumnsHost.Size = UDim2.new(1, 0, 1, 0)
        ColumnsHost.BackgroundTransparency = 1
        ColumnsHost.Parent = TabPageCanvas

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.FillDirection = Enum.FillDirection.Horizontal
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = ColumnsHost

        local LeftColumn = Instance.new("ScrollingFrame")
        LeftColumn.Name = "LeftCol"
        LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
        LeftColumn.BackgroundTransparency = 1
        LeftColumn.BorderSizePixel = 0
        LeftColumn.ScrollBarThickness = 0
        LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftColumn.Parent = ColumnsHost

        local LeftList = Instance.new("UIListLayout")
        LeftList.Padding = UDim.new(0, 8)
        LeftList.SortOrder = Enum.SortOrder.LayoutOrder
        LeftList.Parent = LeftColumn

        local RightColumn = Instance.new("ScrollingFrame")
        RightColumn.Name = "RightCol"
        RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
        RightColumn.BackgroundTransparency = 1
        RightColumn.BorderSizePixel = 0
        RightColumn.ScrollBarThickness = 0
        RightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
        RightColumn.Parent = ColumnsHost

        local RightList = Instance.new("UIListLayout")
        RightList.Padding = UDim.new(0, 8)
        RightList.SortOrder = Enum.SortOrder.LayoutOrder
        RightList.Parent = RightColumn

        TabButton.MouseButton1Click:Connect(function()
            closePopups()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.TextColor3 = FrostLibrary.Theme.TextMuted
                t.Canvas.GroupTransparency = 1
            end
            TabPage.Visible = true
            TabButton.TextColor3 = FrostLibrary.Theme.White
            TweenService:Create(TabPageCanvas, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
        end)

        local tabObj = {
            Button = TabButton,
            Page = TabPage,
            Canvas = TabPageCanvas,
            Left = LeftColumn,
            Right = RightColumn,
            SubTabsBar = SubTabsBar,
            ColumnsHost = ColumnsHost,
            SubTabs = {}
        }
        Window.Tabs[name] = tabObj

        function tabObj:CreateSubTab(subName, subDefault)
            tabObj.SubTabsBar.Visible = true
            tabObj.ColumnsHost.Size = UDim2.new(1, 0, 1, -22)
            tabObj.ColumnsHost.Position = UDim2.new(0, 0, 0, 22)

            local SubBtn = Instance.new("TextButton")
            SubBtn.Name = "SubTab_" .. subName
            SubBtn.BackgroundTransparency = 1
            SubBtn.FontFace = FrostLibrary.Theme.Font
            SubBtn.Text = "[" .. subName .. "]"
            SubBtn.TextColor3 = subDefault and FrostLibrary.Theme.White or FrostLibrary.Theme.TextDim
            SubBtn.TextSize = 12
            SubBtn.AutomaticSize = Enum.AutomaticSize.X
            SubBtn.Size = UDim2.new(0, 0, 1, 0)
            SubBtn.Parent = tabObj.SubTabsBar

            local SubContent = Instance.new("Frame")
            SubContent.Name = "SubContent_" .. subName
            SubContent.Size = UDim2.new(1, 0, 1, 0)
            SubContent.BackgroundTransparency = 1
            SubContent.Visible = subDefault or false
            SubContent.Parent = tabObj.ColumnsHost

            local SubLayout = Instance.new("UIListLayout")
            SubLayout.FillDirection = Enum.FillDirection.Horizontal
            SubLayout.Padding = UDim.new(0, 8)
            SubLayout.Parent = SubContent

            local SLeft = Instance.new("ScrollingFrame")
            SLeft.Size = UDim2.new(0.5, -4, 1, 0)
            SLeft.BackgroundTransparency = 1
            SLeft.BorderSizePixel = 0
            SLeft.ScrollBarThickness = 0
            SLeft.AutomaticCanvasSize = Enum.AutomaticSize.Y
            SLeft.Parent = SubContent

            local SLeftList = Instance.new("UIListLayout")
            SLeftList.Padding = UDim.new(0, 8)
            SLeftList.SortOrder = Enum.SortOrder.LayoutOrder
            SLeftList.Parent = SLeft

            local SRight = Instance.new("ScrollingFrame")
            SRight.Size = UDim2.new(0.5, -4, 1, 0)
            SRight.BackgroundTransparency = 1
            SRight.BorderSizePixel = 0
            SRight.ScrollBarThickness = 0
            SRight.AutomaticCanvasSize = Enum.AutomaticSize.Y
            SRight.Parent = SubContent

            local SRightList = Instance.new("UIListLayout")
            SRightList.Padding = UDim.new(0, 8)
            SRightList.SortOrder = Enum.SortOrder.LayoutOrder
            SRightList.Parent = SRight

            SubBtn.MouseButton1Click:Connect(function()
                for _, s in pairs(tabObj.SubTabs) do
                    s.Frame.Visible = false
                    s.Button.TextColor3 = FrostLibrary.Theme.TextDim
                end
                SubContent.Visible = true
                SubBtn.TextColor3 = FrostLibrary.Theme.White
            end)

            local subObj = {
                Button = SubBtn,
                Frame = SubContent,
                Left = SLeft,
                Right = SRight
            }
            tabObj.SubTabs[subName] = subObj

            function subObj:CreateGroupbox(colSide, gTitle)
                return tabObj:CreateGroupbox(colSide, gTitle, (colSide == "Right") and SRight or SLeft)
            end

            return subObj
        end

        function tabObj:CreateGroupbox(columnSide, title, customTarget)
            local targetCol = customTarget or ((columnSide == "Right") and RightColumn or LeftColumn)
            local Box = Instance.new("Frame")
            Box.Name = "Groupbox_" .. (title or "Plain")
            Box.Size = UDim2.new(1, 0, 0, 0)
            Box.AutomaticSize = Enum.AutomaticSize.Y
            Box.BackgroundColor3 = FrostLibrary.Theme.GroupboxBg
            Box.BorderColor3 = FrostLibrary.Theme.Border
            Box.BorderSizePixel = 1
            Box.Parent = targetCol

            -- Inset Bevel Stroke
            local InsetStroke = Instance.new("UIStroke")
            InsetStroke.Thickness = 1
            InsetStroke.Color = FrostLibrary.Theme.BorderDark
            InsetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            InsetStroke.Parent = Box

            local BoxPadding = Instance.new("UIPadding")
            BoxPadding.PaddingTop = UDim.new(0, title and 10 or 6)
            BoxPadding.PaddingBottom = UDim.new(0, 6)
            BoxPadding.PaddingLeft = UDim.new(0, 7)
            BoxPadding.PaddingRight = UDim.new(0, 7)
            BoxPadding.Parent = Box

            local BoxList = Instance.new("UIListLayout")
            BoxList.Padding = UDim.new(0, 5)
            BoxList.SortOrder = Enum.SortOrder.LayoutOrder
            BoxList.Parent = Box

            if title then
                local TitleTag = Instance.new("TextLabel")
                TitleTag.Name = "BoxTitle"
                TitleTag.Size = UDim2.new(0, 0, 0, 10)
                TitleTag.AutomaticSize = Enum.AutomaticSize.X
                TitleTag.Position = UDim2.new(0, 4, 0, -5)
                TitleTag.BackgroundColor3 = FrostLibrary.Theme.MainBg
                TitleTag.BorderSizePixel = 0
                TitleTag.FontFace = FrostLibrary.Theme.Font
                TitleTag.Text = " " .. title .. " "
                TitleTag.TextColor3 = FrostLibrary.Theme.White
                TitleTag.TextSize = 13
                TitleTag.Parent = Box
            end

            local Group = { Frame = Box }

            -- Text Input Box
            function Group:AddTextInput(labelText, placeholder, defaultVal, callback, cfg)
                cfg = cfg or {}
                local flag = cfg.Flag or labelText
                local tip = cfg.Tooltip

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(1, 0, 0, labelText and 35 or 20)
                Frame.BackgroundTransparency = 1
                Frame.Parent = Box

                local offset = 0
                if labelText then
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0, 13)
                    Label.BackgroundTransparency = 1
                    Label.FontFace = FrostLibrary.Theme.Font
                    Label.Text = labelText
                    Label.TextColor3 = FrostLibrary.Theme.TextDim
                    Label.TextSize = 13
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Frame
                    offset = 15
                    bindTooltip(Label, tip)
                end

                local InputBox = Instance.new("TextBox")
                InputBox.Size = UDim2.new(1, 0, 0, 20)
                InputBox.Position = UDim2.new(0, 0, 0, offset)
                InputBox.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                InputBox.BorderColor3 = FrostLibrary.Theme.Border
                InputBox.BorderSizePixel = 1
                InputBox.FontFace = FrostLibrary.Theme.Font
                InputBox.PlaceholderText = placeholder or ""
                InputBox.PlaceholderColor3 = FrostLibrary.Theme.TextMuted
                InputBox.Text = defaultVal or ""
                InputBox.TextColor3 = FrostLibrary.Theme.White
                InputBox.TextSize = 12
                InputBox.ClearTextOnFocus = false
                InputBox.Parent = Frame
                bindTooltip(InputBox, tip)

                FrostLibrary.Flags[flag] = defaultVal or ""
                table.insert(FrostLibrary.Registry, { Frame = Frame, LabelText = labelText or flag })

                InputBox.FocusLost:Connect(function()
                    FrostLibrary.Flags[flag] = InputBox.Text
                    if callback then callback(InputBox.Text) end
                end)

                FrostLibrary.Signals[flag] = {
                    Set = function(_, val)
                        InputBox.Text = tostring(val)
                        FrostLibrary.Flags[flag] = tostring(val)
                        if callback then callback(tostring(val)) end
                    end
                }
            end

            -- Dual Color Gradient Picker
            function Group:AddGradientPicker(labelText, defaultStart, defaultEnd, callback, cfg)
                cfg = cfg or {}
                local flag = cfg.Flag or labelText
                local tip = cfg.Tooltip

                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 16)
                Row.BackgroundTransparency = 1
                Row.Parent = Box

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(0, 130, 1, 0)
                Label.BackgroundTransparency = 1
                Label.FontFace = FrostLibrary.Theme.Font
                Label.Text = labelText
                Label.TextColor3 = FrostLibrary.Theme.Text
                Label.TextSize = 13
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Row
                bindTooltip(Label, tip)

                local RightHost = Instance.new("Frame")
                RightHost.Size = UDim2.new(0, 52, 1, 0)
                RightHost.Position = UDim2.new(1, -52, 0, 0)
                RightHost.BackgroundTransparency = 1
                RightHost.Parent = Row

                local RightLayout = Instance.new("UIListLayout")
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                RightLayout.Padding = UDim.new(0, 3)
                RightLayout.Parent = RightHost

                local startColor = defaultStart or Color3.fromRGB(255, 255, 255)
                local endColor = defaultEnd or Color3.fromRGB(153, 142, 196)

                FrostLibrary.Flags[flag .. "_Start"] = startColor
                FrostLibrary.Flags[flag .. "_End"] = endColor

                local function spawnMiniPicker(chipBtn, currentColor, isStart)
                    local PickerBox = Instance.new("Frame")
                    PickerBox.Size = UDim2.new(0, 140, 0, 105)
                    PickerBox.BackgroundColor3 = FrostLibrary.Theme.MainBg
                    PickerBox.BorderColor3 = FrostLibrary.Theme.BorderLight
                    PickerBox.BorderSizePixel = 1
                    PickerBox.Visible = false
                    PickerBox.ZIndex = 6000
                    PickerBox.Parent = OverlayHost

                    local SatValArea = Instance.new("TextButton")
                    SatValArea.Size = UDim2.new(1, -12, 0, 65)
                    SatValArea.Position = UDim2.new(0, 6, 0, 6)
                    SatValArea.BackgroundColor3 = currentColor
                    SatValArea.BorderSizePixel = 0
                    SatValArea.Text = ""
                    SatValArea.AutoButtonColor = false
                    SatValArea.ZIndex = 6001
                    SatValArea.Parent = PickerBox

                    local HueBar = Instance.new("TextButton")
                    HueBar.Size = UDim2.new(1, -12, 0, 10)
                    HueBar.Position = UDim2.new(0, 6, 0, 76)
                    HueBar.BorderSizePixel = 0
                    HueBar.Text = ""
                    HueBar.AutoButtonColor = false
                    HueBar.ZIndex = 6001
                    HueBar.Parent = PickerBox

                    local HueGrad = Instance.new("UIGradient")
                    HueGrad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    })
                    HueGrad.Parent = HueBar

                    local currentHue, currentSat, currentVal = 0.7, 0.4, 0.8
                    local function update()
                        local c = Color3.fromHSV(currentHue, currentSat, currentVal)
                        chipBtn.BackgroundColor3 = c
                        SatValArea.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
                        if isStart then startColor = c else endColor = c end
                        FrostLibrary.Flags[flag .. (isStart and "_Start" or "_End")] = c
                        if callback then callback(startColor, endColor) end
                    end

                    HueBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            currentHue = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                            update()
                        end
                    end)
                    SatValArea.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            currentSat = math.clamp((input.Position.X - SatValArea.AbsolutePosition.X) / SatValArea.AbsoluteSize.X, 0, 1)
                            currentVal = 1 - math.clamp((input.Position.Y - SatValArea.AbsolutePosition.Y) / SatValArea.AbsoluteSize.Y, 0, 1)
                            update()
                        end
                    end)

                    chipBtn.MouseButton1Click:Connect(function()
                        local wasVis = PickerBox.Visible
                        closePopups()
                        if not wasVis then
                            local chipPos = chipBtn.AbsolutePosition / UIScale.Scale
                            PickerBox.Position = UDim2.new(0, chipPos.X - 110, 0, chipPos.Y + 12)
                            PickerBox.Visible = true
                            table.insert(FrostLibrary.ActivePopups, PickerBox)
                        end
                    end)
                end

                local Chip1 = Instance.new("TextButton")
                Chip1.Size = UDim2.new(0, 22, 0, 9)
                Chip1.BackgroundColor3 = startColor
                Chip1.BorderColor3 = FrostLibrary.Theme.BorderLight
                Chip1.BorderSizePixel = 1
                Chip1.Text = ""
                Chip1.AutoButtonColor = false
                Chip1.Parent = RightHost
                spawnMiniPicker(Chip1, startColor, true)

                local Chip2 = Instance.new("TextButton")
                Chip2.Size = UDim2.new(0, 22, 0, 9)
                Chip2.BackgroundColor3 = endColor
                Chip2.BorderColor3 = FrostLibrary.Theme.BorderLight
                Chip2.BorderSizePixel = 1
                Chip2.Text = ""
                Chip2.AutoButtonColor = false
                Chip2.Parent = RightHost
                spawnMiniPicker(Chip2, endColor, false)

                table.insert(FrostLibrary.Registry, { Frame = Row, LabelText = labelText })
            end

            -- Dropdown with Tween Expansion
            function Group:AddDropdown(labelText, options, defaultIndex, callback, cfg)
                cfg = cfg or {}
                local flag = cfg.Flag or (labelText or "Dropdown_" .. tostring(#Box:GetChildren()))
                local isMulti = cfg.Multi or false
                local tip = cfg.Tooltip

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(1, 0, 0, labelText and 35 or 20)
                Frame.BackgroundTransparency = 1
                Frame.Parent = Box

                local offset = 0
                if labelText then
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0, 13)
                    Label.BackgroundTransparency = 1
                    Label.FontFace = FrostLibrary.Theme.Font
                    Label.Text = labelText
                    Label.TextColor3 = FrostLibrary.Theme.TextDim
                    Label.TextSize = 13
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Frame
                    offset = 15
                    bindTooltip(Label, tip)
                end

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, 0, 0, 20)
                Button.Position = UDim2.new(0, 0, 0, offset)
                Button.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                Button.BorderColor3 = FrostLibrary.Theme.Border
                Button.BorderSizePixel = 1
                Button.FontFace = FrostLibrary.Theme.Font
                Button.Text = "  "
                Button.TextColor3 = FrostLibrary.Theme.Text
                Button.TextSize = 13
                Button.TextXAlignment = Enum.TextXAlignment.Left
                Button.Parent = Frame
                bindTooltip(Button, tip)

                local Arrow = Instance.new("TextLabel")
                Arrow.Size = UDim2.new(0, 15, 1, 0)
                Arrow.Position = UDim2.new(1, -15, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.FontFace = FrostLibrary.Theme.Font
                Arrow.Text = "▼"
                Arrow.TextColor3 = FrostLibrary.Theme.TextMuted
                Arrow.TextSize = 9
                Arrow.Parent = Button

                local DropList = Instance.new("Frame")
                DropList.Name = "DropList_" .. flag
                DropList.Size = UDim2.new(0, 100, 0, #options * 18)
                DropList.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                DropList.BorderColor3 = FrostLibrary.Theme.BorderLight
                DropList.BorderSizePixel = 1
                DropList.Visible = false
                DropList.ZIndex = 5100
                DropList.ClipsDescendants = true
                DropList.Parent = OverlayHost

                local DropLayout = Instance.new("UIListLayout")
                DropLayout.Parent = DropList

                local selectedValues = {}
                if isMulti then
                    if type(defaultIndex) == "table" then
                        for _, v in ipairs(defaultIndex) do selectedValues[v] = true end
                    end
                else
                    selectedValues = options[defaultIndex or 1] or ""
                end

                local function refreshButtonText()
                    if isMulti then
                        local list = {}
                        for k, v in pairs(selectedValues) do if v then table.insert(list, k) end end
                        Button.Text = "  " .. (#list > 0 and table.concat(list, ", ") or "None")
                        FrostLibrary.Flags[flag] = selectedValues
                    else
                        Button.Text = "  " .. tostring(selectedValues)
                        FrostLibrary.Flags[flag] = selectedValues
                    end
                end
                refreshButtonText()

                for _, opt in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 18)
                    OptBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                    OptBtn.BorderSizePixel = 0
                    OptBtn.FontFace = FrostLibrary.Theme.Font
                    OptBtn.Text = "  " .. opt
                    OptBtn.TextColor3 = FrostLibrary.Theme.TextDim
                    OptBtn.TextSize = 13
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.ZIndex = 5101
                    OptBtn.Parent = DropList

                    OptBtn.MouseButton1Click:Connect(function()
                        if isMulti then
                            selectedValues[opt] = not selectedValues[opt]
                            OptBtn.TextColor3 = selectedValues[opt] and FrostLibrary.Theme.White or FrostLibrary.Theme.TextDim
                            refreshButtonText()
                            if callback then callback(selectedValues) end
                        else
                            selectedValues = opt
                            refreshButtonText()
                            DropList.Visible = false
                            if callback then callback(selectedValues) end
                        end
                    end)
                end

                Button.MouseButton1Click:Connect(function()
                    local wasVis = DropList.Visible
                    closePopups()
                    if not wasVis then
                        local bPos = Button.AbsolutePosition / UIScale.Scale
                        local bSize = Button.AbsoluteSize / UIScale.Scale
                        local targetH = #options * 18
                        DropList.Size = UDim2.new(0, bSize.X, 0, 0)
                        DropList.Position = UDim2.new(0, bPos.X, 0, bPos.Y + bSize.Y + 1)
                        DropList.Visible = true
                        TweenService:Create(DropList, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, bSize.X, 0, targetH)
                        }):Play()
                        table.insert(FrostLibrary.ActivePopups, DropList)
                    end
                end)

                table.insert(FrostLibrary.Registry, { Frame = Frame, LabelText = labelText or flag })

                FrostLibrary.Signals[flag] = {
                    Set = function(_, val)
                        selectedValues = val
                        refreshButtonText()
                        if callback then callback(selectedValues) end
                    end
                }
            end

            -- Stepper
            function Group:AddStepper(labelText, options, defaultIndex, callback, cfg)
                cfg = cfg or {}
                local flag = cfg.Flag or labelText
                local tip = cfg.Tooltip

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(1, 0, 0, labelText and 35 or 19)
                Frame.BackgroundTransparency = 1
                Frame.Parent = Box

                local offset = 0
                if labelText then
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0, 13)
                    Label.BackgroundTransparency = 1
                    Label.FontFace = FrostLibrary.Theme.Font
                    Label.Text = labelText
                    Label.TextColor3 = FrostLibrary.Theme.TextDim
                    Label.TextSize = 13
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Frame
                    offset = 15
                    bindTooltip(Label, tip)
                end

                local StepperFrame = Instance.new("Frame")
                StepperFrame.Size = UDim2.new(1, 0, 0, 19)
                StepperFrame.Position = UDim2.new(0, 0, 0, offset)
                StepperFrame.BackgroundColor3 = FrostLibrary.Theme.TrackBg
                StepperFrame.BorderColor3 = FrostLibrary.Theme.Border
                StepperFrame.BorderSizePixel = 1
                StepperFrame.Parent = Frame
                bindTooltip(StepperFrame, tip)

                local MinusBtn = Instance.new("TextButton")
                MinusBtn.Size = UDim2.new(0, 16, 1, 0)
                MinusBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                MinusBtn.BorderColor3 = FrostLibrary.Theme.Border
                MinusBtn.BorderSizePixel = 1
                MinusBtn.FontFace = FrostLibrary.Theme.Font
                MinusBtn.Text = "-"
                MinusBtn.TextColor3 = FrostLibrary.Theme.TextMuted
                MinusBtn.TextSize = 13
                MinusBtn.Parent = StepperFrame

                local PlusBtn = Instance.new("TextButton")
                PlusBtn.Size = UDim2.new(0, 16, 1, 0)
                PlusBtn.Position = UDim2.new(1, -16, 0, 0)
                PlusBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                PlusBtn.BorderColor3 = FrostLibrary.Theme.Border
                PlusBtn.BorderSizePixel = 1
                PlusBtn.FontFace = FrostLibrary.Theme.Font
                PlusBtn.Text = "+"
                PlusBtn.TextColor3 = FrostLibrary.Theme.TextMuted
                PlusBtn.TextSize = 13
                PlusBtn.Parent = StepperFrame

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(1, -32, 1, 0)
                ValueLabel.Position = UDim2.new(0, 16, 0, 0)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.FontFace = FrostLibrary.Theme.Font
                ValueLabel.Text = tostring(options[defaultIndex or 1])
                ValueLabel.TextColor3 = FrostLibrary.Theme.White
                ValueLabel.TextSize = 13
                ValueLabel.Parent = StepperFrame

                local cur = defaultIndex or 1
                FrostLibrary.Flags[flag] = options[cur]

                local function setVal(idx)
                    cur = math.clamp(idx, 1, #options)
                    local val = options[cur]
                    ValueLabel.Text = tostring(val)
                    FrostLibrary.Flags[flag] = val
                    if callback then callback(val) end
                end

                MinusBtn.MouseButton1Click:Connect(function() setVal(cur - 1) end)
                PlusBtn.MouseButton1Click:Connect(function() setVal(cur + 1) end)

                table.insert(FrostLibrary.Registry, { Frame = Frame, LabelText = labelText })

                FrostLibrary.Signals[flag] = {
                    Set = function(_, val)
                        for i, opt in ipairs(options) do
                            if opt == val then setVal(i) break end
                        end
                    end
                }
            end

            -- Slider with Smooth Fill Interpolation
            function Group:AddSlider(labelText, min, max, defaultVal, suffix, step, callback, cfg)
                cfg = cfg or {}
                local flag = cfg.Flag or labelText
                local tip = cfg.Tooltip

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(1, 0, 0, 35)
                Frame.BackgroundTransparency = 1
                Frame.Parent = Box

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 13)
                Label.BackgroundTransparency = 1
                Label.FontFace = FrostLibrary.Theme.Font
                Label.Text = labelText
                Label.TextColor3 = FrostLibrary.Theme.TextDim
                Label.TextSize = 13
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Frame
                bindTooltip(Label, tip)

                local StepperFrame = Instance.new("Frame")
                StepperFrame.Size = UDim2.new(1, 0, 0, 19)
                StepperFrame.Position = UDim2.new(0, 0, 0, 15)
                StepperFrame.BackgroundColor3 = FrostLibrary.Theme.TrackBg
                StepperFrame.BorderColor3 = FrostLibrary.Theme.Border
                StepperFrame.BorderSizePixel = 1
                StepperFrame.Parent = Frame

                local MinusBtn = Instance.new("TextButton")
                MinusBtn.Size = UDim2.new(0, 16, 1, 0)
                MinusBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                MinusBtn.BorderColor3 = FrostLibrary.Theme.Border
                MinusBtn.BorderSizePixel = 1
                MinusBtn.FontFace = FrostLibrary.Theme.Font
                MinusBtn.Text = "-"
                MinusBtn.TextColor3 = FrostLibrary.Theme.TextMuted
                MinusBtn.TextSize = 13
                MinusBtn.Parent = StepperFrame

                local PlusBtn = Instance.new("TextButton")
                PlusBtn.Size = UDim2.new(0, 16, 1, 0)
                PlusBtn.Position = UDim2.new(1, -16, 0, 0)
                PlusBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                PlusBtn.BorderColor3 = FrostLibrary.Theme.Border
                PlusBtn.BorderSizePixel = 1
                PlusBtn.FontFace = FrostLibrary.Theme.Font
                PlusBtn.Text = "+"
                PlusBtn.TextColor3 = FrostLibrary.Theme.TextMuted
                PlusBtn.TextSize = 13
                PlusBtn.Parent = StepperFrame

                local TrackArea = Instance.new("TextButton")
                TrackArea.Size = UDim2.new(1, -32, 1, 0)
                TrackArea.Position = UDim2.new(0, 16, 0, 0)
                TrackArea.BackgroundColor3 = FrostLibrary.Theme.TrackBg
                TrackArea.BorderSizePixel = 0
                TrackArea.Text = ""
                TrackArea.AutoButtonColor = false
                TrackArea.Parent = StepperFrame

                local Fill = Instance.new("Frame")
                local pct = math.clamp((defaultVal - min) / (max - min), 0, 1)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Fill.BackgroundColor3 = FrostLibrary.Theme.AccentStart
                Fill.BorderSizePixel = 0
                Fill.Parent = TrackArea

                local FillGrad = Instance.new("UIGradient")
                FillGrad.Color = ColorSequence.new(FrostLibrary.Theme.AccentEnd, FrostLibrary.Theme.AccentStart)
                FillGrad.Parent = Fill

                table.insert(FrostLibrary.ThemeObjects, { Type = "Gradient", Instance = FillGrad })

                local ValLabel = Instance.new("TextLabel")
                ValLabel.Size = UDim2.new(1, 0, 1, 0)
                ValLabel.BackgroundTransparency = 1
                ValLabel.FontFace = FrostLibrary.Theme.Font
                ValLabel.Text = tostring(defaultVal) .. (suffix or "")
                ValLabel.TextColor3 = FrostLibrary.Theme.White
                ValLabel.TextSize = 13
                ValLabel.ZIndex = 3
                ValLabel.Parent = TrackArea

                local val = defaultVal
                FrostLibrary.Flags[flag] = val

                local function update(newVal)
                    val = math.clamp(math.round(newVal / (step or 1)) * (step or 1), min, max)
                    local p = math.clamp((val - min) / (max - min), 0, 1)
                    TweenService:Create(Fill, TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(p, 0, 1, 0)
                    }):Play()
                    ValLabel.Text = tostring(val) .. (suffix or "")
                    FrostLibrary.Flags[flag] = val
                    if callback then callback(val) end
                end

                MinusBtn.MouseButton1Click:Connect(function() update(val - (step or 1)) end)
                PlusBtn.MouseButton1Click:Connect(function() update(val + (step or 1)) end)

                local sliding = false
                TrackArea.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        local p = math.clamp((input.Position.X - TrackArea.AbsolutePosition.X) / TrackArea.AbsoluteSize.X, 0, 1)
                        update(min + (max - min) * p)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local p = math.clamp((input.Position.X - TrackArea.AbsolutePosition.X) / TrackArea.AbsoluteSize.X, 0, 1)
                        update(min + (max - min) * p)
                    end
                end)

                table.insert(FrostLibrary.Registry, { Frame = Frame, LabelText = labelText })

                FrostLibrary.Signals[flag] = {
                    Set = function(_, v) update(v) end
                }
            end

            -- Toggle with Animated State Switch
            function Group:AddToggle(labelText, defaultVal, callback, extras)
                extras = extras or {}
                local flag = extras.Flag or labelText
                local tip = extras.Tooltip

                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 16)
                Row.BackgroundTransparency = 1
                Row.Parent = Box

                local BoxBtn = Instance.new("TextButton")
                BoxBtn.Size = UDim2.new(0, 12, 0, 12)
                BoxBtn.Position = UDim2.new(0, 0, 0, 2)
                BoxBtn.BackgroundColor3 = defaultVal and FrostLibrary.Theme.CheckboxActive or FrostLibrary.Theme.ElementBg
                BoxBtn.BorderColor3 = FrostLibrary.Theme.Border
                BoxBtn.BorderSizePixel = 1
                BoxBtn.Text = ""
                BoxBtn.AutoButtonColor = false
                BoxBtn.Parent = Row

                local CheckMark = Instance.new("TextLabel")
                CheckMark.Size = UDim2.new(1, 0, 1, 0)
                CheckMark.BackgroundTransparency = 1
                CheckMark.FontFace = FrostLibrary.Theme.Font
                CheckMark.Text = defaultVal and "✓" or ""
                CheckMark.TextColor3 = FrostLibrary.Theme.White
                CheckMark.TextSize = 11
                CheckMark.Parent = BoxBtn

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(0, 150, 1, 0)
                Label.Position = UDim2.new(0, 18, 0, 0)
                Label.BackgroundTransparency = 1
                Label.FontFace = FrostLibrary.Theme.Font
                Label.Text = labelText
                Label.TextColor3 = FrostLibrary.Theme.Text
                Label.TextSize = 13
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Row
                bindTooltip(Label, tip)

                local state = defaultVal or false
                FrostLibrary.Flags[flag] = state

                local function setToggle(val)
                    state = val
                    local targetColor = state and FrostLibrary.Theme.CheckboxActive or FrostLibrary.Theme.ElementBg
                    TweenService:Create(BoxBtn, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = targetColor
                    }):Play()
                    CheckMark.Text = state and "✓" or ""
                    FrostLibrary.Flags[flag] = state
                    if callback then callback(state) end
                end

                BoxBtn.MouseButton1Click:Connect(function() setToggle(not state) end)

                table.insert(FrostLibrary.ThemeObjects, {
                    Type = "Checkbox",
                    Instance = BoxBtn,
                    GetState = function() return state end
                })

                table.insert(FrostLibrary.Registry, { Frame = Row, LabelText = labelText })
                FrostLibrary.Signals[flag] = { Set = function(_, v) setToggle(v) end }

                -- Extras: Gear, Color Chips, Keybind Modes
                if extras then
                    local RightHost = Instance.new("Frame")
                    RightHost.Size = UDim2.new(0, 80, 1, 0)
                    RightHost.Position = UDim2.new(1, -80, 0, 0)
                    RightHost.BackgroundTransparency = 1
                    RightHost.Parent = Row

                    local RightLayout = Instance.new("UIListLayout")
                    RightLayout.FillDirection = Enum.FillDirection.Horizontal
                    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                    RightLayout.Padding = UDim.new(0, 3)
                    RightLayout.Parent = RightHost

                    if extras.Gear then
                        local GearBtn = Instance.new("TextButton")
                        GearBtn.Size = UDim2.new(0, 14, 0, 14)
                        GearBtn.BackgroundTransparency = 1
                        GearBtn.FontFace = FrostLibrary.Theme.Font
                        GearBtn.Text = "⚙"
                        GearBtn.TextColor3 = FrostLibrary.Theme.TextMuted
                        GearBtn.TextSize = 13
                        GearBtn.Parent = RightHost
                    end

                    -- Interactive Colorpicker with DPI-aware absolute position
                    if extras.ColorChips then
                        for chipIdx, colorVal in ipairs(extras.ColorChips) do
                            local chipFlag = flag .. "_Color" .. tostring(chipIdx)
                            FrostLibrary.Flags[chipFlag] = colorVal

                            local Chip = Instance.new("TextButton")
                            Chip.Size = UDim2.new(0, 22, 0, 9)
                            Chip.BackgroundColor3 = colorVal
                            Chip.BorderColor3 = FrostLibrary.Theme.BorderLight
                            Chip.BorderSizePixel = 1
                            Chip.Text = ""
                            Chip.AutoButtonColor = false
                            Chip.Parent = RightHost

                            local PickerBox = Instance.new("Frame")
                            PickerBox.Size = UDim2.new(0, 140, 0, 110)
                            PickerBox.BackgroundColor3 = FrostLibrary.Theme.MainBg
                            PickerBox.BorderColor3 = FrostLibrary.Theme.BorderLight
                            PickerBox.BorderSizePixel = 1
                            PickerBox.Visible = false
                            PickerBox.ZIndex = 6000
                            PickerBox.Parent = OverlayHost

                            local SatValArea = Instance.new("TextButton")
                            SatValArea.Size = UDim2.new(1, -12, 0, 70)
                            SatValArea.Position = UDim2.new(0, 6, 0, 6)
                            SatValArea.BackgroundColor3 = colorVal
                            SatValArea.BorderSizePixel = 0
                            SatValArea.Text = ""
                            SatValArea.AutoButtonColor = false
                            SatValArea.ZIndex = 6001
                            SatValArea.Parent = PickerBox

                            local HueBar = Instance.new("TextButton")
                            HueBar.Size = UDim2.new(1, -12, 0, 10)
                            HueBar.Position = UDim2.new(0, 6, 0, 80)
                            HueBar.BorderSizePixel = 0
                            HueBar.Text = ""
                            HueBar.AutoButtonColor = false
                            HueBar.ZIndex = 6001
                            HueBar.Parent = PickerBox

                            local HueGrad = Instance.new("UIGradient")
                            HueGrad.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                                ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 255, 0)),
                                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 255, 0)),
                                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
                                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                            })
                            HueGrad.Parent = HueBar

                            local currentHue, currentSat, currentVal = 0.7, 0.4, 0.8
                            local function updateColor()
                                local c = Color3.fromHSV(currentHue, currentSat, currentVal)
                                Chip.BackgroundColor3 = c
                                SatValArea.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
                                FrostLibrary.Flags[chipFlag] = c
                            end

                            HueBar.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    currentHue = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                                    updateColor()
                                end
                            end)

                            SatValArea.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    currentSat = math.clamp((input.Position.X - SatValArea.AbsolutePosition.X) / SatValArea.AbsoluteSize.X, 0, 1)
                                    currentVal = 1 - math.clamp((input.Position.Y - SatValArea.AbsolutePosition.Y) / SatValArea.AbsoluteSize.Y, 0, 1)
                                    updateColor()
                                end
                            end)

                            Chip.MouseButton1Click:Connect(function()
                                local wasVis = PickerBox.Visible
                                closePopups()
                                if not wasVis then
                                    local chipPos = Chip.AbsolutePosition / UIScale.Scale
                                    PickerBox.Position = UDim2.new(0, chipPos.X - 110, 0, chipPos.Y + 12)
                                    PickerBox.Visible = true
                                    table.insert(FrostLibrary.ActivePopups, PickerBox)
                                end
                            end)
                        end
                    end

                    -- Keybind with Right-Click Context Menu
                    if extras.Keybind then
                        local keyFlag = flag .. "_Key"
                        local modeFlag = flag .. "_KeyMode"
                        local currentKey = extras.Keybind:lower()
                        local currentMode = "Toggle"

                        FrostLibrary.Flags[keyFlag] = currentKey
                        FrostLibrary.Flags[modeFlag] = currentMode

                        local KeyBtn = Instance.new("TextButton")
                        KeyBtn.Size = UDim2.new(0, 36, 0, 15)
                        KeyBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                        KeyBtn.BorderColor3 = FrostLibrary.Theme.Border
                        KeyBtn.BorderSizePixel = 1
                        KeyBtn.FontFace = FrostLibrary.Theme.Font
                        KeyBtn.Text = currentKey
                        KeyBtn.TextColor3 = FrostLibrary.Theme.TextDim
                        KeyBtn.TextSize = 12
                        KeyBtn.Parent = RightHost

                        local ContextMenu = Instance.new("Frame")
                        ContextMenu.Size = UDim2.new(0, 60, 0, 48)
                        ContextMenu.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                        ContextMenu.BorderColor3 = FrostLibrary.Theme.BorderLight
                        ContextMenu.BorderSizePixel = 1
                        ContextMenu.Visible = false
                        ContextMenu.ZIndex = 7000
                        ContextMenu.Parent = OverlayHost

                        local CtxLayout = Instance.new("UIListLayout")
                        CtxLayout.Parent = ContextMenu

                        for _, m in ipairs({"Always", "Hold", "Toggle"}) do
                            local MBtn = Instance.new("TextButton")
                            MBtn.Size = UDim2.new(1, 0, 0, 16)
                            MBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                            MBtn.BorderSizePixel = 0
                            MBtn.FontFace = FrostLibrary.Theme.Font
                            MBtn.Text = m
                            MBtn.TextColor3 = (m == currentMode) and FrostLibrary.Theme.White or FrostLibrary.Theme.TextDim
                            MBtn.TextSize = 11
                            MBtn.ZIndex = 7001
                            MBtn.Parent = ContextMenu

                            MBtn.MouseButton1Click:Connect(function()
                                currentMode = m
                                FrostLibrary.Flags[modeFlag] = m
                                ContextMenu.Visible = false
                                if activeKeybindWidgets[flag] then
                                    activeKeybindWidgets[flag].Mode = m
                                    refreshKeybindsList()
                                end
                            end)
                        end

                        KeyBtn.MouseButton2Click:Connect(function()
                            local wasVis = ContextMenu.Visible
                            closePopups()
                            if not wasVis then
                                local kbPos = KeyBtn.AbsolutePosition / UIScale.Scale
                                ContextMenu.Position = UDim2.new(0, kbPos.X - 20, 0, kbPos.Y + 16)
                                ContextMenu.Visible = true
                                table.insert(FrostLibrary.ActivePopups, ContextMenu)
                            end
                        end)

                        local listening = false
                        KeyBtn.MouseButton1Click:Connect(function()
                            listening = true
                            KeyBtn.Text = "..."
                            local conn
                            conn = UserInputService.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.Keyboard then
                                    currentKey = input.KeyCode.Name:lower()
                                    KeyBtn.Text = currentKey
                                    FrostLibrary.Flags[keyFlag] = currentKey
                                    listening = false
                                    conn:Disconnect()
                                    if activeKeybindWidgets[flag] then
                                        activeKeybindWidgets[flag].Key = currentKey
                                        refreshKeybindsList()
                                    end
                                end
                            end)
                        end)

                        activeKeybindWidgets[flag] = {
                            Name = labelText,
                            Key = currentKey,
                            Mode = currentMode,
                            Active = state
                        }

                        UserInputService.InputBegan:Connect(function(input, processed)
                            if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
                                if input.KeyCode.Name:lower() == currentKey then
                                    if currentMode == "Toggle" then
                                        setToggle(not state)
                                    elseif currentMode == "Hold" or currentMode == "Always" then
                                        setToggle(true)
                                    end
                                    if activeKeybindWidgets[flag] then
                                        activeKeybindWidgets[flag].Active = state
                                        refreshKeybindsList()
                                    end
                                end
                            end
                        end)

                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                if input.KeyCode.Name:lower() == currentKey and currentMode == "Hold" then
                                    setToggle(false)
                                    if activeKeybindWidgets[flag] then
                                        activeKeybindWidgets[flag].Active = false
                                        refreshKeybindsList()
                                    end
                                end
                            end
                        end)
                    end
                end
            end

            return Group
        end

        return tabObj
    end

    return Window
end

return FrostLibrary
