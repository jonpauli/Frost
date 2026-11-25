--!nocheck
-- Lua, library.lua, Luau / Roblox Executor, Target: FrostVIP UI Library Core Engine

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local FrostLibrary = {}
FrostLibrary.Theme = {
    MainBg = Color3.fromRGB(14, 13, 18),
    HeaderBg = Color3.fromRGB(18, 17, 24),
    HeaderLine = Color3.fromRGB(57, 52, 72),
    GroupboxBg = Color3.fromRGB(14, 13, 18),
    Border = Color3.fromRGB(37, 35, 45),
    BorderLight = Color3.fromRGB(48, 45, 60),
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

function FrostLibrary:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "frost.vip"
    local size = config.Size or UDim2.new(0, 535, 0, 680)

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

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = size
    MainFrame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    MainFrame.BackgroundColor3 = FrostLibrary.Theme.MainBg
    MainFrame.BorderColor3 = FrostLibrary.Theme.Border
    MainFrame.BorderSizePixel = 1
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = ScreenGui

    local MainBorderOutline = Instance.new("UIStroke")
    MainBorderOutline.Thickness = 1
    MainBorderOutline.Color = Color3.fromRGB(10, 9, 13)
    MainBorderOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainBorderOutline.Parent = MainFrame

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 24)
    Header.BackgroundColor3 = FrostLibrary.Theme.HeaderBg
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0, 100, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.FontFace = FrostLibrary.Theme.Font
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = FrostLibrary.Theme.White
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Size = UDim2.new(1, -120, 1, 0)
    TabsContainer.Position = UDim2.new(0, 110, 0, 0)
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
    HeaderLine.Parent = MainFrame

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -18, 1, -33)
    ContentArea.Position = UDim2.new(0, 9, 0, 29)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    -- Keybind toggle visibility
    local toggleKey = config.ToggleKey or Enum.KeyCode.Insert
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    local Window = {
        Tabs = {},
        TabsContainer = TabsContainer,
        ContentArea = ContentArea,
        ScreenGui = ScreenGui,
        MainFrame = MainFrame
    }

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

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.FillDirection = Enum.FillDirection.Horizontal
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = TabPage

        local LeftColumn = Instance.new("ScrollingFrame")
        LeftColumn.Name = "LeftCol"
        LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
        LeftColumn.BackgroundTransparency = 1
        LeftColumn.BorderSizePixel = 0
        LeftColumn.ScrollBarThickness = 0
        LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftColumn.Parent = TabPage

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
        RightColumn.Parent = TabPage

        local RightList = Instance.new("UIListLayout")
        RightList.Padding = UDim.new(0, 8)
        RightList.SortOrder = Enum.SortOrder.LayoutOrder
        RightList.Parent = RightColumn

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.TextColor3 = FrostLibrary.Theme.TextMuted
            end
            TabPage.Visible = true
            TabButton.TextColor3 = FrostLibrary.Theme.White
        end)

        local tabObj = {
            Button = TabButton,
            Page = TabPage,
            Left = LeftColumn,
            Right = RightColumn
        }
        Window.Tabs[name] = tabObj

        function tabObj:CreateGroupbox(columnSide, title)
            local targetCol = (columnSide == "Right") and RightColumn or LeftColumn
            local Box = Instance.new("Frame")
            Box.Name = "Groupbox_" .. (title or "Plain")
            Box.Size = UDim2.new(1, 0, 0, 0)
            Box.AutomaticSize = Enum.AutomaticSize.Y
            Box.BackgroundColor3 = FrostLibrary.Theme.GroupboxBg
            Box.BorderColor3 = FrostLibrary.Theme.Border
            Box.BorderSizePixel = 1
            Box.Parent = targetCol

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

            function Group:AddDropdown(labelText, options, defaultIndex, callback)
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
                end

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, 0, 0, 20)
                Button.Position = UDim2.new(0, 0, 0, offset)
                Button.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                Button.BorderColor3 = FrostLibrary.Theme.Border
                Button.BorderSizePixel = 1
                Button.FontFace = FrostLibrary.Theme.Font
                Button.Text = "  " .. (options[defaultIndex or 1] or "")
                Button.TextColor3 = FrostLibrary.Theme.Text
                Button.TextSize = 13
                Button.TextXAlignment = Enum.TextXAlignment.Left
                Button.Parent = Frame

                local Arrow = Instance.new("TextLabel")
                Arrow.Size = UDim2.new(0, 15, 1, 0)
                Arrow.Position = UDim2.new(1, -15, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.FontFace = FrostLibrary.Theme.Font
                Arrow.Text = "▼"
                Arrow.TextColor3 = FrostLibrary.Theme.TextMuted
                Arrow.TextSize = 9
                Arrow.Parent = Button

                local List = Instance.new("Frame")
                List.Size = UDim2.new(1, 0, 0, #options * 18)
                List.Position = UDim2.new(0, 0, 1, 1)
                List.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                List.BorderColor3 = FrostLibrary.Theme.BorderLight
                List.BorderSizePixel = 1
                List.Visible = false
                List.ZIndex = 100
                List.Parent = Button

                local DropLayout = Instance.new("UIListLayout")
                DropLayout.Parent = List

                for idx, opt in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 18)
                    OptBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                    OptBtn.BorderSizePixel = 0
                    OptBtn.FontFace = FrostLibrary.Theme.Font
                    OptBtn.Text = "  " .. opt
                    OptBtn.TextColor3 = (idx == defaultIndex) and FrostLibrary.Theme.White or FrostLibrary.Theme.TextDim
                    OptBtn.TextSize = 13
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.ZIndex = 101
                    OptBtn.Parent = List

                    OptBtn.MouseButton1Click:Connect(function()
                        Button.Text = "  " .. opt
                        List.Visible = false
                        if callback then callback(opt) end
                    end)
                end

                Button.MouseButton1Click:Connect(function()
                    List.Visible = not List.Visible
                end)
            end

            function Group:AddStepper(labelText, options, defaultIndex, callback)
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
                end

                local StepperFrame = Instance.new("Frame")
                StepperFrame.Size = UDim2.new(1, 0, 0, 19)
                StepperFrame.Position = UDim2.new(0, 0, 0, offset)
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
                MinusBtn.MouseButton1Click:Connect(function()
                    cur = math.max(1, cur - 1)
                    ValueLabel.Text = tostring(options[cur])
                    if callback then callback(options[cur]) end
                end)

                PlusBtn.MouseButton1Click:Connect(function()
                    cur = math.min(#options, cur + 1)
                    ValueLabel.Text = tostring(options[cur])
                    if callback then callback(options[cur]) end
                end)
            end

            function Group:AddSlider(labelText, min, max, defaultVal, suffix, step, callback)
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
                local function update(newVal)
                    val = math.clamp(math.round(newVal / (step or 1)) * (step or 1), min, max)
                    local p = math.clamp((val - min) / (max - min), 0, 1)
                    Fill.Size = UDim2.new(p, 0, 1, 0)
                    ValLabel.Text = tostring(val) .. (suffix or "")
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
            end

            function Group:AddToggle(labelText, defaultVal, callback, extras)
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

                local state = defaultVal or false
                local function setToggle(val)
                    state = val
                    BoxBtn.BackgroundColor3 = state and FrostLibrary.Theme.CheckboxActive or FrostLibrary.Theme.ElementBg
                    CheckMark.Text = state and "✓" or ""
                    if callback then callback(state) end
                end

                BoxBtn.MouseButton1Click:Connect(function() setToggle(not state) end)

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

                    if extras.ColorChips then
                        for _, color in ipairs(extras.ColorChips) do
                            local Chip = Instance.new("TextButton")
                            Chip.Size = UDim2.new(0, 22, 0, 9)
                            Chip.BackgroundColor3 = color
                            Chip.BorderColor3 = FrostLibrary.Theme.BorderLight
                            Chip.BorderSizePixel = 1
                            Chip.Text = ""
                            Chip.AutoButtonColor = false
                            Chip.Parent = RightHost
                        end
                    end

                    if extras.Keybind then
                        local KeyBtn = Instance.new("TextButton")
                        KeyBtn.Size = UDim2.new(0, 36, 0, 15)
                        KeyBtn.BackgroundColor3 = FrostLibrary.Theme.ElementBg
                        KeyBtn.BorderColor3 = FrostLibrary.Theme.Border
                        KeyBtn.BorderSizePixel = 1
                        KeyBtn.FontFace = FrostLibrary.Theme.Font
                        KeyBtn.Text = extras.Keybind
                        KeyBtn.TextColor3 = FrostLibrary.Theme.TextDim
                        KeyBtn.TextSize = 12
                        KeyBtn.Parent = RightHost

                        local listening = false
                        KeyBtn.MouseButton1Click:Connect(function()
                            listening = true
                            KeyBtn.Text = "..."
                            local conn
                            conn = UserInputService.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.Keyboard then
                                    local key = input.KeyCode.Name:lower()
                                    KeyBtn.Text = key
                                    listening = false
                                    conn:Disconnect()
                                end
                            end)
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
