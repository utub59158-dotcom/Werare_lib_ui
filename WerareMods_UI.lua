--[[
    WerareMods UI Library
    Roblox Luau / ModuleScript
    ------------------------------------------------------------
    Visual direction:
      - Dark charcoal UI matching the supplied reference
      - GREEN accent instead of the reference pink
      - Soft rounded corners
      - Animated tabs, buttons, toggles, sliders and color pickers
      - Built-in UI scale control
      - Color picker with SV square + hue strip
      - No game-specific/exploit functionality: this is a presentation/UI library
    ------------------------------------------------------------
    Basic usage:
        local UI = require(path.to.WerareMods_UI)
        local Window = UI:CreateWindow({
            Title = "@WerareMods",
            Size = UDim2.fromOffset(760, 510),
        })

        local Main = Window:AddTab("Main", "M")
        local Section = Main:AddSection("General")
        Section:AddToggle("Example", false, function(value)
            print("Example:", value)
        end)
        Section:AddSlider("Speed", 50, 0, 100, 1, function(value)
            print("Speed:", value)
        end)
        Section:AddButton("Press me", function()
            print("clicked")
        end)
        Section:AddColorPicker("ESP Color", Color3.fromRGB(120, 214, 139), function(color)
            print(color)
        end)
]]

local WerareMods = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Runtime helpers: the library stays renderer-only and does not depend on a
-- particular loader/environment. A custom GUI parent can be supplied through
-- CreateWindow({ Parent = someGuiParent }).
local function GetViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1280, 720)
end

local function IsTouchLayout()
    local viewport = GetViewport()
    return UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled or viewport.X < 760)
end

local function GetResponsiveScale()
    local viewport = GetViewport()
    local shortest = math.min(viewport.X, viewport.Y)

    if shortest <= 360 then
        return 0.72
    elseif shortest <= 430 then
        return 0.82
    elseif viewport.X <= 760 then
        return 0.90
    end

    return 1
end

local function GetGuiParent(customParent)
    if typeof(customParent) == "Instance" and customParent:IsDescendantOf(game) then
        return customParent
    end

    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            return playerGui
        end

        return LocalPlayer:WaitForChild("PlayerGui")
    end

    return nil
end

local Theme = {
    Background = Color3.fromRGB(12, 11, 15),
    Background2 = Color3.fromRGB(17, 16, 21),
    Panel = Color3.fromRGB(20, 19, 24),
    Panel2 = Color3.fromRGB(24, 23, 29),
    Panel3 = Color3.fromRGB(29, 28, 35),
    Stroke = Color3.fromRGB(45, 43, 52),
    StrokeSoft = Color3.fromRGB(35, 34, 41),
    Text = Color3.fromRGB(235, 233, 239),
    TextMuted = Color3.fromRGB(154, 151, 160),
    TextDim = Color3.fromRGB(104, 101, 110),
    Accent = Color3.fromRGB(120, 214, 139),
    AccentDark = Color3.fromRGB(74, 146, 91),
    AccentSoft = Color3.fromRGB(52, 89, 61),
    Danger = Color3.fromRGB(226, 91, 91),
    Warning = Color3.fromRGB(224, 177, 87),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local Fonts = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Semibold = Enum.Font.GothamSemibold,
}

local Easing = {
    Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local function Tween(object, info, properties)
    if not object or object.Parent == nil then
        return
    end

    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function New(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function Corner(parent, radius)
    local corner = New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })

    return corner
end

local function Stroke(parent, color, thickness, transparency)
    local stroke = New("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })

    return stroke
end

local function Padding(parent, left, top, right, bottom)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent,
    })
end

local function List(parent, padding, direction)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = parent,
    })
end

local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function Round(number, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(number * power + 0.5) / power
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function ColorLerp(a, b, t)
    return Color3.new(
        Lerp(a.R, b.R, t),
        Lerp(a.G, b.G, t),
        Lerp(a.B, b.B, t)
    )
end

local function GetTextSize(text, size, font, bounds)
    local ok, result = pcall(function()
        return game:GetService("TextService"):GetTextSize(
            text,
            size,
            font,
            bounds or Vector2.new(1000, 1000)
        )
    end)

    if ok then
        return result
    end

    return Vector2.new(0, 0)
end

local function Disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function SafeCallback(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end

    task.spawn(function(...)
        local ok, errorMessage = pcall(callback, ...)
        if not ok then
            warn("[WerareMods UI] Callback error:", errorMessage)
        end
    end, ...)
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _connections = {},
    }, Signal)
end

function Signal:Connect(callback)
    local connection = {
        Connected = true,
    }

    function connection:Disconnect()
        self.Connected = false
    end

    table.insert(self._connections, {
        Connection = connection,
        Callback = callback,
    })

    return connection
end

function Signal:Fire(...)
    for _, item in ipairs(self._connections) do
        if item.Connection.Connected then
            SafeCallback(item.Callback, ...)
        end
    end
end

function Signal:Destroy()
    table.clear(self._connections)
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({
        _tasks = {},
    }, Maid)
end

function Maid:Give(taskObject)
    table.insert(self._tasks, taskObject)
    return taskObject
end

function Maid:Cleanup()
    for index = #self._tasks, 1, -1 do
        local taskObject = self._tasks[index]
        self._tasks[index] = nil

        local kind = typeof(taskObject)

        if kind == "RBXScriptConnection" then
            Disconnect(taskObject)
        elseif kind == "Instance" then
            pcall(function()
                taskObject:Destroy()
            end)
        elseif kind == "function" then
            pcall(taskObject)
        elseif type(taskObject) == "table" then
            if typeof(taskObject.Destroy) == "function" then
                pcall(function()
                    taskObject:Destroy()
                end)
            elseif typeof(taskObject.Cleanup) == "function" then
                pcall(function()
                    taskObject:Cleanup()
                end)
            end
        end
    end
end

function Maid:Destroy()
    self:Cleanup()
    table.clear(self)
end

local BaseObject = {}
BaseObject.__index = BaseObject

function BaseObject:_track(item)
    self._maid:Give(item)
    return item
end

function BaseObject:_connect(signal, callback)
    local connection = signal:Connect(callback)
    self:_track(connection)
    return connection
end

function BaseObject:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    if self._maid then
        self._maid:Cleanup()
    end
end

local Window = setmetatable({}, BaseObject)
Window.__index = Window

local Tab = setmetatable({}, BaseObject)
Tab.__index = Tab

local Section = setmetatable({}, BaseObject)
Section.__index = Section

local Control = setmetatable({}, BaseObject)
Control.__index = Control

local function MakeText(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 13,
        Font = font or Fonts.Regular,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = parent,
    })
end

local function MakeButton(parent, text)
    local button = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = text or "",
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Fonts.Medium,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = parent,
    })

    Corner(button, 7)
    Stroke(button, Theme.StrokeSoft, 1, 0.15)

    return button
end

local function BindHover(button, normal, hover, press)
    local down = false

    button.MouseEnter:Connect(function()
        Tween(button, Easing.Fast, {
            BackgroundColor3 = hover,
        })
    end)

    button.MouseLeave:Connect(function()
        down = false
        Tween(button, Easing.Fast, {
            BackgroundColor3 = normal,
        })
    end)

    button.MouseButton1Down:Connect(function()
        down = true
        Tween(button, Easing.Fast, {
            BackgroundColor3 = press,
        })
    end)

    button.MouseButton1Up:Connect(function()
        if down then
            Tween(button, Easing.Fast, {
                BackgroundColor3 = hover,
            })
        end
    end)
end

local function MakeIconCircle(parent, text)
    local holder = New("Frame", {
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(28, 28),
        Parent = parent,
    })

    Corner(holder, 8)

    local label = New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        Font = Fonts.Bold,
        Size = UDim2.fromScale(1, 1),
        Parent = holder,
    })

    return holder, label
end

function WerareMods:SetTheme(overrides)
    for key, value in pairs(overrides or {}) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end

    for _, window in ipairs(self._windows) do
        if window and not window._destroyed then
            window:_refreshTheme()
        end
    end
end

function WerareMods:GetTheme()
    local copy = {}

    for key, value in pairs(Theme) do
        copy[key] = value
    end

    return copy
end

function WerareMods:CreateWindow(options)
    options = options or {}

    local window = setmetatable({
        _maid = Maid.new(),
        _tabs = {},
        _controls = {},
        _scale = options.Scale or 1,
        _autoScale = options.AutoScale ~= false,
        _mobileLayout = false,
        _customParent = options.Parent,
        _title = options.Title or "@WerareMods",
        _size = options.Size or UDim2.fromOffset(760, 510),
        _baseSize = options.Size or UDim2.fromOffset(760, 510),
        _visible = true,
        _destroyed = false,
    }, Window)

    table.insert(self._windows, window)
    window:_build()

    return window
end

function Window:_build()
    local guiParent = GetGuiParent(self._customParent)
    assert(guiParent, "WerareMods UI: unable to resolve a GUI parent")

    self._gui = self:_track(New("ScreenGui", {
        Name = "WerareMods_UI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = guiParent,
    }))

    self._root = self:_track(New("Frame", {
        Name = "Root",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = self._gui,
    }))

    self._scaleObject = self:_track(New("UIScale", {
        Scale = self._scale,
        Parent = self._root,
    }))

    self._shadow = self:_track(New("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Theme.Black,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 4, 0.5, 5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = self._size,
        Parent = self._root,
    }))

    Corner(self._shadow, 11)

    self._window = self:_track(New("Frame", {
        Name = "Window",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = self._size,
        Parent = self._root,
        ClipsDescendants = true,
    }))

    Corner(self._window, 10)
    self._windowStroke = Stroke(self._window, Theme.Stroke, 1, 0.05)

    self._header = self:_track(New("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.Background2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 54),
        Parent = self._window,
    }))

    self._headerGradient = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Background2),
            ColorSequenceKeypoint.new(1, Theme.Panel),
        }),
        Rotation = 0,
        Parent = self._header,
    })

    self._title = MakeText(self._header, self._title, 13, Theme.Text, Fonts.Semibold)
    self._title.Position = UDim2.fromOffset(18, 8)
    self._title.Size = UDim2.new(1, -150, 0, 18)

    self._subtitle = MakeText(
        self._header,
        "interface library",
        10,
        Theme.TextDim,
        Fonts.Regular
    )
    self._subtitle.Position = UDim2.fromOffset(18, 26)
    self._subtitle.Size = UDim2.new(1, -150, 0, 15)

    self._close = New("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Theme.TextMuted,
        TextSize = 21,
        Font = Fonts.Regular,
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(1, -44, 0, 8),
        Parent = self._header,
    })

    self._minimize = New("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = Theme.TextMuted,
        TextSize = 18,
        Font = Fonts.Regular,
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(1, -82, 0, 8),
        Parent = self._header,
    })

    self:_track(self._close.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end))

    self:_track(self._minimize.MouseButton1Click:Connect(function()
        self:ToggleMinimized()
    end))

    BindHover(self._close, Theme.Background2, Theme.Panel3, Theme.Panel2)
    BindHover(self._minimize, Theme.Background2, Theme.Panel3, Theme.Panel2)

    self._sidebar = self:_track(New("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(0, 126, 1, -54),
        Parent = self._window,
    }))

    self._sidebarStroke = Stroke(self._sidebar, Theme.StrokeSoft, 1, 0.35)

    self._tabList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.65,
        Position = UDim2.fromOffset(8, 12),
        Size = UDim2.new(1, -16, 1, -24),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = self._sidebar,
    })

    List(self._tabList, 5)

    self._content = self:_track(New("Frame", {
        Name = "Content",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(126, 54),
        Size = UDim2.new(1, -126, 1, -54),
        Parent = self._window,
        ClipsDescendants = true,
    }))

    self._contentHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, -32, 1, -28),
        Parent = self._content,
    })

    self._toastHolder = self:_track(New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(300, 260),
        Parent = self._root,
    }))

    local toastLayout = List(self._toastHolder, 8)
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    self._dragHandle = self._header
    self:_enableDragging()
    self:_setupWindowResize()
    self:_setupGlobalInput()
    self:_setupResponsive()
    self:_refreshTheme()
end

function Window:_setupResponsive()
    local function apply()
        if self._destroyed or not self._window then
            return
        end

        local viewport = GetViewport()
        local mobile = IsTouchLayout()
        self._mobileLayout = mobile

        local minWidth = mobile and 320 or 560
        local minHeight = mobile and 280 or 380
        local maxWidth = math.max(minWidth, viewport.X - (mobile and 16 or 40))
        local maxHeight = math.max(minHeight, viewport.Y - (mobile and 16 or 40))

        local desiredWidth = self._baseSize.X.Offset
        local desiredHeight = self._baseSize.Y.Offset

        if mobile then
            desiredWidth = math.min(desiredWidth, maxWidth)
            desiredHeight = math.min(desiredHeight, maxHeight)
        else
            desiredWidth = math.min(desiredWidth, maxWidth)
            desiredHeight = math.min(desiredHeight, maxHeight)
        end

        desiredWidth = math.max(minWidth, desiredWidth)
        desiredHeight = math.max(minHeight, desiredHeight)

        if self._minimized then
            desiredHeight = 54
        end

        self._window.Size = UDim2.fromOffset(desiredWidth, desiredHeight)
        self._shadow.Size = self._window.Size

        if self._autoScale then
            local manualScale = tonumber(self._manualScale)
            local targetScale = manualScale or GetResponsiveScale()
            self._scale = targetScale
            self._scaleObject.Scale = targetScale
        end

        if mobile then
            -- Compact, touch-friendly top tab rail. The controls themselves
            -- remain unchanged; only the surrounding layout adapts.
            self._sidebar.Position = UDim2.fromOffset(0, 54)
            self._sidebar.Size = UDim2.new(1, 0, 0, 46)

            self._tabList.Position = UDim2.fromOffset(8, 6)
            self._tabList.Size = UDim2.new(1, -16, 1, -12)
            self._tabList.ScrollingDirection = Enum.ScrollingDirection.X
            self._tabList.AutomaticCanvasSize = Enum.AutomaticSize.X

            local tabLayout = self._tabList:FindFirstChildOfClass("UIListLayout")
            if tabLayout then
                tabLayout.FillDirection = Enum.FillDirection.Horizontal
                tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            end

            for _, tab in ipairs(self._tabs) do
                if tab._button then
                    tab._button.Size = UDim2.fromOffset(118, 34)
                    tab._active.Position = UDim2.new(0.5, 0, 1, -2)
                    tab._active.AnchorPoint = Vector2.new(0.5, 1)
                    tab._active.Size = tab._selected and UDim2.fromOffset(42, 2) or UDim2.fromOffset(0, 2)
                end
            end

            self._content.Position = UDim2.fromOffset(0, 100)
            self._content.Size = UDim2.new(1, 0, 1, -100)
            self._contentHolder.Position = UDim2.fromOffset(10, 10)
            self._contentHolder.Size = UDim2.new(1, -20, 1, -20)

            self._toastHolder.Position = UDim2.new(1, -10, 1, -10)
            self._toastHolder.Size = UDim2.fromOffset(math.min(320, desiredWidth - 20), 240)

            if self._resizeGrip then
                self._resizeGrip.Size = UDim2.fromOffset(28, 28)
            end
        else
            self._sidebar.Position = UDim2.fromOffset(0, 54)
            self._sidebar.Size = UDim2.new(0, 126, 1, -54)

            self._tabList.Position = UDim2.fromOffset(8, 12)
            self._tabList.Size = UDim2.new(1, -16, 1, -24)
            self._tabList.ScrollingDirection = Enum.ScrollingDirection.Y
            self._tabList.AutomaticCanvasSize = Enum.AutomaticSize.Y

            local tabLayout = self._tabList:FindFirstChildOfClass("UIListLayout")
            if tabLayout then
                tabLayout.FillDirection = Enum.FillDirection.Vertical
                tabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            end

            for _, tab in ipairs(self._tabs) do
                if tab._button then
                    tab._button.Size = UDim2.new(1, 0, 0, 37)
                    tab._active.Position = UDim2.new(0, 0, 0.5, 0)
                    tab._active.AnchorPoint = Vector2.new(0, 0.5)
                    tab._active.Size = tab._selected and UDim2.fromOffset(2, 24) or UDim2.fromOffset(2, 0)
                end
            end

            self._content.Position = UDim2.fromOffset(126, 54)
            self._content.Size = UDim2.new(1, -126, 1, -54)
            self._contentHolder.Position = UDim2.fromOffset(16, 14)
            self._contentHolder.Size = UDim2.new(1, -32, 1, -28)

            self._toastHolder.Position = UDim2.new(1, -16, 1, -16)
            self._toastHolder.Size = UDim2.fromOffset(300, 260)

            if self._resizeGrip then
                self._resizeGrip.Size = UDim2.fromOffset(20, 20)
            end
        end
    end

    self:_track(UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(apply))
    self:_track(UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(apply))

    local camera = workspace.CurrentCamera
    if camera then
        self:_track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply))
    end

    task.defer(apply)
end

function Window:_enableDragging()
    local dragging = false
    local dragStart
    local startPosition

    self:_track(self._dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = self._window.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    self:_track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        self._window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )

        self._shadow.Position = UDim2.new(
            self._window.Position.X.Scale,
            self._window.Position.X.Offset + 4,
            self._window.Position.Y.Scale,
            self._window.Position.Y.Offset + 5
        )
    end))
end

function Window:_setupWindowResize()
    local grip = self:_track(New("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromOffset(20, 20),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Parent = self._window,
        ZIndex = 50,
    }))

    self._resizeGrip = grip

    local resizing = false
    local startSize
    local startMouse

    self:_track(grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            resizing = true
            startSize = self._window.AbsoluteSize
            startMouse = input.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end))

    self:_track(UserInputService.InputChanged:Connect(function(input)
        if not resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - startMouse
        local width = Clamp(startSize.X + delta.X, 560, 1100)
        local height = Clamp(startSize.Y + delta.Y, 380, 760)

        self._window.Size = UDim2.fromOffset(width, height)
        self._baseSize = self._window.Size
        self._shadow.Size = self._window.Size
    end))
end

function Window:_setupGlobalInput()
    self:_track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == (WerareMods.Config and WerareMods.Config.ToggleKey or Enum.KeyCode.RightShift) then
            self:ToggleVisible()
        end
    end))
end

function Window:_refreshTheme()
    if self._destroyed then
        return
    end

    if self._window then
        self._window.BackgroundColor3 = Theme.Background
    end

    if self._header then
        self._header.BackgroundColor3 = Theme.Background2
    end

    if self._headerGradient then
        self._headerGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Background2),
            ColorSequenceKeypoint.new(1, Theme.Panel),
        })
    end

    if self._sidebar then
        self._sidebar.BackgroundColor3 = Theme.Panel
    end

    if self._content then
        self._content.BackgroundColor3 = Theme.Background
    end

    if self._windowStroke then
        self._windowStroke.Color = Theme.Stroke
    end

    if self._title then
        self._title.TextColor3 = Theme.Text
    end

    if self._subtitle then
        self._subtitle.TextColor3 = Theme.TextDim
    end

    if self._tabList then
        self._tabList.ScrollBarImageColor3 = Theme.Accent
    end

    for _, tab in ipairs(self._tabs) do
        tab:_refreshTheme()
    end

    for _, control in ipairs(self._controls) do
        if control._refreshTheme then
            control:_refreshTheme()
        end
    end
end

function Window:SetScale(scale)
    scale = Clamp(tonumber(scale) or 1, 0.65, 1.35)
    self._manualScale = scale
    self._scale = scale

    Tween(self._scaleObject, Easing.Smooth, {
        Scale = scale,
    })
end

function Window:SetAutoScale(enabled)
    self._autoScale = enabled ~= false
    if self._autoScale then
        self._manualScale = nil
        local target = GetResponsiveScale()
        self._scale = target
        Tween(self._scaleObject, Easing.Smooth, { Scale = target })
    end
end

function Window:IsMobileLayout()
    return self._mobileLayout == true
end

function Window:GetScale()
    return self._scale
end

function Window:SetVisible(visible)
    visible = visible == true

    if visible == self._visible then
        return
    end

    self._visible = visible

    if visible then
        self._root.Visible = true
        self._window.Position = UDim2.new(0.5, 0, 0.5, 12)
        self._window.BackgroundTransparency = 1
        Tween(self._window, Easing.Smooth, {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0,
        })
        Tween(self._shadow, Easing.Smooth, {
            BackgroundTransparency = 0.55,
        })
    else
        Tween(self._window, Easing.Normal, {
            Position = UDim2.new(0.5, 0, 0.5, 10),
            BackgroundTransparency = 1,
        })
        Tween(self._shadow, Easing.Normal, {
            BackgroundTransparency = 1,
        })

        task.delay(0.22, function()
            if not self._visible and self._root then
                self._root.Visible = false
            end
        end)
    end
end

function Window:ToggleVisible()
    self:SetVisible(not self._visible)
end

function Window:ToggleMinimized()
    self._minimized = not self._minimized

    if self._minimized then
        Tween(self._window, Easing.Smooth, {
            Size = UDim2.fromOffset(self._window.AbsoluteSize.X, 54),
        })
        Tween(self._shadow, Easing.Smooth, {
            Size = UDim2.fromOffset(self._window.AbsoluteSize.X, 54),
        })
    else
        Tween(self._window, Easing.Smooth, {
            Size = self._size,
        })
        Tween(self._shadow, Easing.Smooth, {
            Size = self._size,
        })
    end
end

function Window:AddTab(name, icon)
    local tab = setmetatable({
        _maid = Maid.new(),
        _window = self,
        _name = name or "Tab",
        _icon = icon or "•",
        _sections = {},
        _controls = {},
        _selected = false,
        _destroyed = false,
    }, Tab)

    table.insert(self._tabs, tab)
    tab:_build(#self._tabs)

    if #self._tabs == 1 then
        tab:Select()
    end

    return tab
end

function Window:AddTabFromConfig(config)
    config = config or {}

    return self:AddTab(config.Name or "Tab", config.Icon or "•")
end

function Window:Notify(options)
    options = options or {}

    local title = options.Title or "WerareMods"
    local text = options.Text or ""
    local duration = tonumber(options.Duration) or 3
    local accent = options.Color or Theme.Accent

    local toast = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(290, 62),
        BackgroundTransparency = 1,
        Parent = self._toastHolder,
    })

    Corner(toast, 8)
    Stroke(toast, Theme.Stroke, 1, 0.1)

    local bar = New("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(3, 62),
        Parent = toast,
    })

    Corner(bar, 3)

    local titleLabel = MakeText(toast, title, 12, Theme.Text, Fonts.Semibold)
    titleLabel.Position = UDim2.fromOffset(14, 7)
    titleLabel.Size = UDim2.new(1, -24, 0, 18)
    titleLabel.TextTransparency = 1

    local body = MakeText(toast, text, 10, Theme.TextMuted, Fonts.Regular)
    body.Position = UDim2.fromOffset(14, 27)
    body.Size = UDim2.new(1, -24, 0, 27)
    body.TextWrapped = true
    body.TextTransparency = 1

    toast.Position = UDim2.new(1, 25, 0, 0)

    Tween(toast, Easing.Spring, {
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 0,
    })

    Tween(titleLabel, Easing.Fast, {
        TextTransparency = 0,
    })

    Tween(body, Easing.Fast, {
        TextTransparency = 0,
    })

    task.delay(duration, function()
        if not toast.Parent then
            return
        end

        Tween(toast, Easing.Normal, {
            Position = UDim2.new(1, 25, 0, 0),
            BackgroundTransparency = 1,
        })

        Tween(titleLabel, Easing.Fast, {
            TextTransparency = 1,
        })

        Tween(body, Easing.Fast, {
            TextTransparency = 1,
        })

        task.delay(0.25, function()
            if toast then
                toast:Destroy()
            end
        end)
    end)

    return toast
end

function Tab:_build(index)
    self._button = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 37),
        Text = "",
        LayoutOrder = index,
        Parent = self._window._tabList,
    })

    Corner(self._button, 7)

    self._active = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 0),
        Parent = self._button,
    })

    Corner(self._active, 2)

    self._iconLabel = MakeText(
        self._button,
        self._icon,
        11,
        Theme.TextMuted,
        Fonts.Bold
    )
    self._iconLabel.Position = UDim2.fromOffset(9, 5)
    self._iconLabel.Size = UDim2.fromOffset(22, 27)
    self._iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    self._nameLabel = MakeText(
        self._button,
        self._name,
        11,
        Theme.TextMuted,
        Fonts.Medium
    )
    self._nameLabel.Position = UDim2.fromOffset(36, 5)
    self._nameLabel.Size = UDim2.new(1, -42, 0, 27)

    self._page = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.7,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self._window._contentHolder,
    })

    Padding(self._page, 0, 0, 2, 0)
    List(self._page, 10)

    self:_track(self._button.MouseButton1Click:Connect(function()
        self:Select()
    end))

    self._button.MouseEnter:Connect(function()
        if not self._selected then
            Tween(self._button, Easing.Fast, {
                BackgroundColor3 = Theme.Panel2,
            })
            Tween(self._iconLabel, Easing.Fast, {
                TextColor3 = Theme.Text,
            })
        end
    end)

    self._button.MouseLeave:Connect(function()
        if not self._selected then
            Tween(self._button, Easing.Fast, {
                BackgroundColor3 = Theme.Panel,
            })
            Tween(self._iconLabel, Easing.Fast, {
                TextColor3 = Theme.TextMuted,
            })
        end
    end)
end

function Tab:_refreshTheme()
    if not self._button then
        return
    end

    if self._selected then
        self._button.BackgroundColor3 = Theme.Panel2
        self._iconLabel.TextColor3 = Theme.Accent
        self._nameLabel.TextColor3 = Theme.Text
        self._active.BackgroundColor3 = Theme.Accent
        self._page.ScrollBarImageColor3 = Theme.Accent
    else
        self._button.BackgroundColor3 = Theme.Panel
        self._iconLabel.TextColor3 = Theme.TextMuted
        self._nameLabel.TextColor3 = Theme.TextMuted
        self._active.BackgroundColor3 = Theme.Accent
        self._page.ScrollBarImageColor3 = Theme.Accent
    end
end

function Tab:Select()
    if self._destroyed then
        return
    end

    for _, tab in ipairs(self._window._tabs) do
        if tab ~= self then
            tab._selected = false
            tab._page.Visible = false

            Tween(tab._button, Easing.Normal, {
                BackgroundColor3 = Theme.Panel,
            })

            Tween(tab._iconLabel, Easing.Normal, {
                TextColor3 = Theme.TextMuted,
            })

            Tween(tab._nameLabel, Easing.Normal, {
                TextColor3 = Theme.TextMuted,
            })

            Tween(tab._active, Easing.Smooth, {
                Size = UDim2.fromOffset(2, 0),
            })
        end
    end

    self._selected = true
    self._page.Visible = true
    self._page.Position = UDim2.fromOffset(8, 0)

    Tween(self._button, Easing.Normal, {
        BackgroundColor3 = Theme.Panel2,
    })

    Tween(self._iconLabel, Easing.Normal, {
        TextColor3 = Theme.Accent,
    })

    Tween(self._nameLabel, Easing.Normal, {
        TextColor3 = Theme.Text,
    })

    Tween(self._active, Easing.Spring, {
        Size = UDim2.fromOffset(2, 24),
    })

    Tween(self._page, Easing.Smooth, {
        Position = UDim2.fromOffset(0, 0),
    })
end

function Tab:AddSection(name)
    local section = setmetatable({
        _maid = Maid.new(),
        _tab = self,
        _name = name or "Section",
        _controls = {},
        _destroyed = false,
    }, Section)

    table.insert(self._sections, section)
    section:_build()

    return section
end

function Tab:AddLeftSection(name)
    return self:AddSection(name)
end

function Tab:AddRightSection(name)
    return self:AddSection(name)
end

function Tab:AddParagraph(title, text)
    local holder = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -4, 0, 0),
        Parent = self._page,
    })

    Corner(holder, 8)
    Stroke(holder, Theme.StrokeSoft, 1, 0.25)
    Padding(holder, 12, 10, 12, 10)

    local titleLabel = MakeText(holder, title or "Info", 12, Theme.Text, Fonts.Semibold)
    titleLabel.Size = UDim2.new(1, 0, 0, 19)

    local body = MakeText(holder, text or "", 11, Theme.TextMuted, Fonts.Regular)
    body.Position = UDim2.fromOffset(0, 22)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top

    return {
        Frame = holder,
        Title = titleLabel,
        Text = body,
        Destroy = function()
            holder:Destroy()
        end,
    }
end

function Tab:AddSpacer(height)
    local spacer = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 8),
        Parent = self._page,
    })

    return spacer
end

function Section:_build()
    self._frame = New("Frame", {
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -4, 0, 0),
        Parent = self._tab._page,
    })

    Corner(self._frame, 8)
    Stroke(self._frame, Theme.StrokeSoft, 1, 0.2)
    Padding(self._frame, 10, 10, 10, 10)

    self._header = MakeText(
        self._frame,
        self._name,
        11,
        Theme.TextMuted,
        Fonts.Semibold
    )
    self._header.Size = UDim2.new(1, 0, 0, 18)

    self._container = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self._frame,
    })

    List(self._container, 7)
end

function Section:_register(control)
    table.insert(self._controls, control)
    table.insert(self._tab._controls, control)
    table.insert(self._tab._window._controls, control)
    return control
end

function Section:AddLabel(text)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "", 11, Theme.TextMuted, Fonts.Regular)
    label.Size = UDim2.fromScale(1, 1)

    return self:_register({
        Frame = holder,
        Label = label,
        Destroy = function()
            holder:Destroy()
        end,
        _refreshTheme = function()
            label.TextColor3 = Theme.TextMuted
        end,
    })
end

function Section:AddButton(text, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = self._container,
    })

    local button = MakeButton(holder, text or "Button")

    BindHover(
        button,
        Theme.Panel3,
        ColorLerp(Theme.Panel3, Theme.Accent, 0.12),
        ColorLerp(Theme.Panel3, Theme.Accent, 0.20)
    )

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _button = button,
        _callback = callback,
        _destroyed = false,
    }, Control)

    control.Activated = Signal.new()
    control:_track(button.MouseButton1Click:Connect(function()
        control.Activated:Fire()
        SafeCallback(callback)
    end))

    control._refreshTheme = function()
        BindHover(
            button,
            Theme.Panel3,
            ColorLerp(Theme.Panel3, Theme.Accent, 0.12),
            ColorLerp(Theme.Panel3, Theme.Accent, 0.20)
        )
        button.TextColor3 = Theme.Text
    end

    return self:_register(control)
end

function Section:AddToggle(text, default, callback)
    local value = default == true

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Toggle", 11, Theme.Text, Fonts.Medium)
    label.Size = UDim2.new(1, -58, 1, 0)

    local track = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 20),
        Parent = holder,
    })

    Corner(track, 10)
    Stroke(track, Theme.Stroke, 1, 0.2)

    local knob = New("Frame", {
        BackgroundColor3 = Theme.TextMuted,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Parent = track,
    })

    Corner(knob, 7)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _label = label,
        _trackButton = track,
        _knob = knob,
        _value = value,
        _callback = callback,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:SetValue(nextValue, silent)
        nextValue = nextValue == true

        if self._value == nextValue and not silent then
            self:_animate()
            return
        end

        self._value = nextValue
        self:_animate()

        if not silent then
            self.Changed:Fire(nextValue)
            SafeCallback(self._callback, nextValue)
        end
    end

    function control:GetValue()
        return self._value
    end

    function control:Toggle()
        self:SetValue(not self._value)
    end

    function control:_animate()
        local targetX = self._value and 29 or 11
        local targetColor = self._value and Theme.Accent or Theme.TextMuted
        local trackColor = self._value
            and ColorLerp(Theme.Panel3, Theme.Accent, 0.30)
            or Theme.Panel3

        Tween(self._knob, Easing.Spring, {
            Position = UDim2.new(0, targetX, 0.5, 0),
            BackgroundColor3 = targetColor,
        })

        Tween(self._trackButton, Easing.Normal, {
            BackgroundColor3 = trackColor,
        })
    end

    control:_track(track.MouseButton1Click:Connect(function()
        control:Toggle()
    end))

    control._refreshTheme = function()
        control:_animate()
        label.TextColor3 = Theme.Text
    end

    control:_animate()

    return self:_register(control)
end

function Section:AddCheckbox(text, default, callback)
    local value = default == true

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = self._container,
    })

    local button = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Parent = holder,
    })

    Corner(button, 5)
    Stroke(button, Theme.Stroke, 1, 0.15)

    local check = MakeText(button, "✓", 12, Theme.White, Fonts.Bold)
    check.Size = UDim2.fromScale(1, 1)
    check.TextXAlignment = Enum.TextXAlignment.Center
    check.TextTransparency = value and 0 or 1

    local label = MakeText(holder, text or "Checkbox", 11, Theme.Text, Fonts.Medium)
    label.Position = UDim2.fromOffset(28, 0)
    label.Size = UDim2.new(1, -28, 1, 0)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _button = button,
        _check = check,
        _label = label,
        _value = value,
        _callback = callback,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:SetValue(nextValue, silent)
        self._value = nextValue == true

        Tween(self._button, Easing.Fast, {
            BackgroundColor3 = self._value and Theme.Accent or Theme.Panel3,
        })

        Tween(self._check, Easing.Fast, {
            TextTransparency = self._value and 0 or 1,
        })

        if not silent then
            self.Changed:Fire(self._value)
            SafeCallback(self._callback, self._value)
        end
    end

    function control:GetValue()
        return self._value
    end

    control:_track(button.MouseButton1Click:Connect(function()
        control:SetValue(not control._value)
    end))

    control._refreshTheme = function()
        control:SetValue(control._value, true)
        label.TextColor3 = Theme.Text
    end

    control:SetValue(value, true)

    return self:_register(control)
end

function Section:AddSlider(text, default, minimum, maximum, step, callback)
    minimum = tonumber(minimum) or 0
    maximum = tonumber(maximum) or 100
    step = tonumber(step) or 1
    default = Clamp(tonumber(default) or minimum, minimum, maximum)

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Slider", 11, Theme.Text, Fonts.Medium)
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.new(1, -70, 0, 20)

    local valueLabel = MakeText(holder, "", 10, Theme.TextMuted, Fonts.Medium)
    valueLabel.Position = UDim2.new(1, -65, 0, 0)
    valueLabel.Size = UDim2.fromOffset(65, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = "",
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 7),
        Parent = holder,
    })

    Corner(track, 4)

    local fill = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    })

    Corner(fill, 4)

    local knob = New("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(13, 13),
        Parent = track,
    })

    Corner(knob, 7)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _label = label,
        _valueLabel = valueLabel,
        _track = track,
        _fill = fill,
        _knob = knob,
        _value = default,
        _minimum = minimum,
        _maximum = maximum,
        _step = step,
        _callback = callback,
        _dragging = false,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:_format(value)
        if self._step < 1 then
            local decimals = math.ceil(-math.log10(self._step))
            return string.format("%." .. tostring(decimals) .. "f", value)
        end

        return tostring(math.floor(value + 0.5))
    end

    function control:SetValue(nextValue, silent)
        nextValue = tonumber(nextValue) or self._minimum
        nextValue = Clamp(nextValue, self._minimum, self._maximum)

        local steps = math.round((nextValue - self._minimum) / self._step)
        nextValue = self._minimum + steps * self._step
        nextValue = Clamp(nextValue, self._minimum, self._maximum)

        self._value = nextValue

        local alpha = 0
        if self._maximum ~= self._minimum then
            alpha = (nextValue - self._minimum) / (self._maximum - self._minimum)
        end

        valueLabel.Text = self:_format(nextValue)

        Tween(fill, Easing.Fast, {
            Size = UDim2.fromScale(alpha, 1),
        })

        Tween(knob, Easing.Fast, {
            Position = UDim2.new(alpha, 0, 0.5, 0),
        })

        if not silent then
            self.Changed:Fire(nextValue)
            SafeCallback(self._callback, nextValue)
        end
    end

    function control:GetValue()
        return self._value
    end

    function control:_setFromInput(inputX)
        local left = track.AbsolutePosition.X
        local width = track.AbsoluteSize.X
        local alpha = Clamp((inputX - left) / math.max(width, 1), 0, 1)

        self:SetValue(
            self._minimum + (self._maximum - self._minimum) * alpha
        )
    end

    control:_track(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            control._dragging = true
            control:_setFromInput(input.Position.X)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    control._dragging = false
                end
            end)
        end
    end))

    control:_track(UserInputService.InputChanged:Connect(function(input)
        if not control._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            control:_setFromInput(input.Position.X)
        end
    end))

    control._refreshTheme = function()
        label.TextColor3 = Theme.Text
        valueLabel.TextColor3 = Theme.TextMuted
        fill.BackgroundColor3 = Theme.Accent
        control:SetValue(control._value, true)
    end

    control:SetValue(default, true)

    return self:_register(control)
end

function Section:AddDropdown(text, options, default, callback)
    options = options or {}
    local current = default or options[1]

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Dropdown", 11, Theme.Text, Fonts.Medium)
    label.Size = UDim2.new(0.5, 0, 1, 0)

    local button = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(150, 30),
        Parent = holder,
    })

    Corner(button, 7)
    Stroke(button, Theme.StrokeSoft, 1, 0.2)

    local selected = MakeText(button, tostring(current or "Select"), 10, Theme.TextMuted, Fonts.Medium)
    selected.Position = UDim2.fromOffset(10, 0)
    selected.Size = UDim2.new(1, -28, 1, 0)

    local arrow = MakeText(button, "⌄", 13, Theme.TextMuted, Fonts.Bold)
    arrow.Position = UDim2.new(1, -23, 0, 0)
    arrow.Size = UDim2.fromOffset(18, 30)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local popup = New("Frame", {
        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 1, 5),
        Size = UDim2.fromOffset(150, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = holder,
    })

    Corner(popup, 7)
    Stroke(popup, Theme.Stroke, 1, 0.05)

    local optionList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = popup,
    })

    Padding(optionList, 5, 5, 5, 5)
    List(optionList, 3)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _label = label,
        _button = button,
        _selected = selected,
        _arrow = arrow,
        _popup = popup,
        _options = options,
        _value = current,
        _callback = callback,
        _open = false,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:SetValue(nextValue, silent)
        self._value = nextValue
        selected.Text = tostring(nextValue)

        if not silent then
            self.Changed:Fire(nextValue)
            SafeCallback(self._callback, nextValue)
        end
    end

    function control:GetValue()
        return self._value
    end

    function control:SetOpen(open)
        open = open == true

        if open == self._open then
            return
        end

        self._open = open

        if open then
            popup.Visible = true
            popup.Size = UDim2.fromOffset(150, 0)

            local height = math.min(#options * 31 + 10, 185)

            Tween(popup, Easing.Smooth, {
                Size = UDim2.fromOffset(150, height),
            })

            Tween(arrow, Easing.Fast, {
                Rotation = 180,
                TextColor3 = Theme.Accent,
            })
        else
            Tween(popup, Easing.Normal, {
                Size = UDim2.fromOffset(150, 0),
            })

            Tween(arrow, Easing.Fast, {
                Rotation = 0,
                TextColor3 = Theme.TextMuted,
            })

            task.delay(0.20, function()
                if not self._open and popup then
                    popup.Visible = false
                end
            end)
        end
    end

    for _, option in ipairs(options) do
        local optionButton = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Panel2,
            BorderSizePixel = 0,
            Text = tostring(option),
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            Font = Fonts.Medium,
            Size = UDim2.new(1, 0, 0, 28),
            ZIndex = 101,
            Parent = optionList,
        })

        Corner(optionButton, 5)

        optionButton.MouseEnter:Connect(function()
            Tween(optionButton, Easing.Fast, {
                BackgroundColor3 = Theme.Panel3,
                TextColor3 = Theme.Text,
            })
        end)

        optionButton.MouseLeave:Connect(function()
            Tween(optionButton, Easing.Fast, {
                BackgroundColor3 = Theme.Panel2,
                TextColor3 = Theme.TextMuted,
            })
        end)

        control:_track(optionButton.MouseButton1Click:Connect(function()
            control:SetValue(option)
            control:SetOpen(false)
        end))
    end

    control:_track(button.MouseButton1Click:Connect(function()
        control:SetOpen(not control._open)
    end))

    control._refreshTheme = function()
        label.TextColor3 = Theme.Text
        selected.TextColor3 = Theme.TextMuted
        control:SetOpen(false)
    end

    return self:_register(control)
end

function Section:AddKeybind(text, default, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Keybind", 11, Theme.Text, Fonts.Medium)
    label.Size = UDim2.new(1, -95, 1, 0)

    local button = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = default and default.Name or "None",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        Font = Fonts.Medium,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(90, 28),
        Parent = holder,
    })

    Corner(button, 6)
    Stroke(button, Theme.StrokeSoft, 1, 0.2)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _label = label,
        _button = button,
        _key = default,
        _callback = callback,
        _listening = false,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:SetKey(key)
        self._key = key
        button.Text = key and key.Name or "None"
        self.Changed:Fire(key)
        SafeCallback(self._callback, key)
    end

    function control:GetKey()
        return self._key
    end

    control:_track(button.MouseButton1Click:Connect(function()
        control._listening = true
        button.Text = "Press key..."
        Tween(button, Easing.Fast, {
            BackgroundColor3 = ColorLerp(Theme.Panel3, Theme.Accent, 0.20),
            TextColor3 = Theme.Text,
        })
    end))

    control:_track(UserInputService.InputBegan:Connect(function(input, processed)
        if not control._listening or processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            control._listening = false
            control:SetKey(input.KeyCode)
        end
    end))

    control._refreshTheme = function()
        label.TextColor3 = Theme.Text
        button.TextColor3 = Theme.TextMuted
        button.BackgroundColor3 = Theme.Panel3
    end

    return self:_register(control)
end

local function HSVToColor(h, s, v)
    return Color3.fromHSV(h, s, v)
end

local function MakeColorPicker(parent, initialColor)
    local currentColor = initialColor or Theme.Accent
    local h, s, v = currentColor:ToHSV()

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = parent,
    })

    local swatchButton = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(46, 24),
        Parent = holder,
    })

    Corner(swatchButton, 6)
    Stroke(swatchButton, Theme.Stroke, 1, 0.1)

    local popup = New("Frame", {
        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 1, 7),
        Size = UDim2.fromOffset(235, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 200,
        Parent = holder,
    })

    Corner(popup, 9)
    Stroke(popup, Theme.Stroke, 1, 0.05)
    Padding(popup, 10, 10, 10, 10)

    local title = MakeText(
        popup,
        "Color",
        10,
        Theme.TextMuted,
        Fonts.Semibold
    )
    title.Size = UDim2.new(1, 0, 0, 17)

    local picker = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 25),
        Size = UDim2.new(1, -20, 0, 130),
        ZIndex = 201,
        Parent = popup,
    })

    Corner(picker, 6)
    picker.ClipsDescendants = true

    local saturation = New("ImageLabel", {
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        Image = "rbxassetid://4155801252",
        ScaleType = Enum.ScaleType.Stretch,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 202,
        Parent = picker,
    })

    Corner(saturation, 6)

    local satOverlay = New("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 203,
        Parent = picker,
    })

    local whiteGradient = New("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = satOverlay,
    })

    local blackOverlay = New("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 204,
        Parent = picker,
    })

    local valueGradient = New("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = blackOverlay,
    })

    local cursor = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(10, 10),
        ZIndex = 205,
        Parent = picker,
    })

    Corner(cursor, 5)
    Stroke(cursor, Color3.new(0, 0, 0), 1, 0)

    local hue = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 163),
        Size = UDim2.new(1, -20, 0, 12),
        ZIndex = 201,
        Parent = popup,
    })

    Corner(hue, 6)

    local hueGradient = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(1 / 6, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(2 / 6, 1, 1)),
            ColorSequenceKeypoint.new(0.50, Color3.fromHSV(3 / 6, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(4 / 6, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(5 / 6, 1, 1)),
            ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
        }),
        Parent = hue,
    })

    local hueCursor = New("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.fromOffset(5, 18),
        ZIndex = 202,
        Parent = hue,
    })

    Corner(hueCursor, 3)

    local preview = New("Frame", {
        BackgroundColor3 = currentColor,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 190),
        Size = UDim2.new(1, -20, 0, 32),
        ZIndex = 201,
        Parent = popup,
    })

    Corner(preview, 6)

    local hex = MakeText(
        preview,
        "#FFFFFF",
        10,
        Theme.White,
        Fonts.Semibold
    )
    hex.Position = UDim2.fromOffset(10, 0)
    hex.Size = UDim2.new(1, -20, 1, 0)
    hex.TextXAlignment = Enum.TextXAlignment.Center
    hex.ZIndex = 202

    local open = false
    local draggingSV = false
    local draggingHue = false

    local function updateColor()
        currentColor = HSVToColor(h, s, v)
        swatchButton.BackgroundColor3 = currentColor
        preview.BackgroundColor3 = currentColor
        saturation.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)

        local r = math.floor(currentColor.R * 255 + 0.5)
        local g = math.floor(currentColor.G * 255 + 0.5)
        local b = math.floor(currentColor.B * 255 + 0.5)

        hex.Text = string.format("#%02X%02X%02X", r, g, b)
    end

    local function setSV(position)
        local absolute = picker.AbsolutePosition
        local size = picker.AbsoluteSize

        s = Clamp((position.X - absolute.X) / math.max(size.X, 1), 0, 1)
        v = Clamp(1 - (position.Y - absolute.Y) / math.max(size.Y, 1), 0, 1)

        updateColor()
    end

    local function setHue(position)
        local absolute = hue.AbsolutePosition
        local size = hue.AbsoluteSize

        h = Clamp((position.X - absolute.X) / math.max(size.X, 1), 0, 1)

        updateColor()
    end

    swatchButton.MouseButton1Click:Connect(function()
        open = not open

        if open then
            popup.Visible = true
            popup.Size = UDim2.fromOffset(235, 0)

            Tween(popup, Easing.Smooth, {
                Size = UDim2.fromOffset(235, 235),
            })
        else
            Tween(popup, Easing.Normal, {
                Size = UDim2.fromOffset(235, 0),
            })

            task.delay(0.20, function()
                if not open then
                    popup.Visible = false
                end
            end)
        end
    end)

    picker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingSV = true
            setSV(input.Position)
        end
    end)

    hue.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingHue = true
            setHue(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if draggingSV then
            setSV(input.Position)
        elseif draggingHue then
            setHue(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingSV = false
            draggingHue = false
        end
    end)

    updateColor()

    return {
        Holder = holder,
        Button = swatchButton,
        Popup = popup,
        GetColor = function()
            return currentColor
        end,
        SetColor = function(color)
            currentColor = color
            h, s, v = color:ToHSV()
            updateColor()
        end,
    }
end

function Section:AddColorPicker(text, default, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Color", 11, Theme.Text, Fonts.Medium)
    label.Size = UDim2.new(1, -55, 1, 0)

    local picker = MakeColorPicker(holder, default or Theme.Accent)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _label = label,
        _picker = picker,
        _callback = callback,
        _color = default or Theme.Accent,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:SetColor(color, silent)
        self._color = color
        picker.SetColor(color)

        if not silent then
            self.Changed:Fire(color)
            SafeCallback(self._callback, color)
        end
    end

    function control:GetColor()
        return self._color
    end

    self:_register(control)

    local originalGetColor = picker.GetColor

    task.spawn(function()
        while not control._destroyed and holder.Parent do
            local newColor = originalGetColor()

            if newColor ~= control._color then
                control._color = newColor
                control.Changed:Fire(newColor)
                SafeCallback(control._callback, newColor)
            end

            task.wait(0.04)
        end
    end)

    control._refreshTheme = function()
        label.TextColor3 = Theme.Text
    end

    return control
end

function Section:AddMultiToggle(text, options, defaults, callback)
    options = options or {}
    defaults = defaults or {}

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Options", 11, Theme.TextMuted, Fonts.Semibold)
    label.Size = UDim2.new(1, 0, 0, 20)

    local buttonsHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 25),
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = holder,
    })

    local layout = List(buttonsHolder, 5, Enum.FillDirection.Horizontal)
    layout.Wraps = true

    local values = {}

    for _, option in ipairs(options) do
        values[option] = defaults[option] == true

        local button = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = values[option]
                and ColorLerp(Theme.Panel3, Theme.Accent, 0.25)
                or Theme.Panel3,
            BorderSizePixel = 0,
            Text = tostring(option),
            TextColor3 = values[option] and Theme.Text or Theme.TextMuted,
            TextSize = 10,
            Font = Fonts.Medium,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(50, 27),
            Parent = buttonsHolder,
        })

        Corner(button, 6)
        Padding(button, 10, 0, 10, 0)

        button.MouseButton1Click:Connect(function()
            values[option] = not values[option]

            Tween(button, Easing.Fast, {
                BackgroundColor3 = values[option]
                    and ColorLerp(Theme.Panel3, Theme.Accent, 0.25)
                    or Theme.Panel3,
                TextColor3 = values[option] and Theme.Text or Theme.TextMuted,
            })

            SafeCallback(callback, values)
        end)
    end

    return self:_register({
        Frame = holder,
        GetValues = function()
            local copy = {}
            for key, value in pairs(values) do
                copy[key] = value
            end
            return copy
        end,
        SetValue = function(_, option, value)
            if values[option] ~= nil then
                values[option] = value == true
            end
        end,
        Destroy = function()
            holder:Destroy()
        end,
        _refreshTheme = function()
            label.TextColor3 = Theme.TextMuted
        end,
    })
end

function Section:AddSeparator()
    local separator = New("Frame", {
        BackgroundColor3 = Theme.StrokeSoft,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self._container,
    })

    return separator
end

function Section:AddSearch(text, placeholder, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = self._container,
    })

    local box = New("TextBox", {
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = placeholder or "Search...",
        PlaceholderColor3 = Theme.TextDim,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Fonts.Regular,
        Size = UDim2.fromScale(1, 1),
        Parent = holder,
    })

    Corner(box, 7)
    Stroke(box, Theme.StrokeSoft, 1, 0.2)
    Padding(box, 10, 0, 10, 0)

    local control = {
        Frame = holder,
        TextBox = box,
        GetText = function()
            return box.Text
        end,
        SetText = function(_, value)
            box.Text = value or ""
        end,
        Destroy = function()
            holder:Destroy()
        end,
        _refreshTheme = function()
            box.TextColor3 = Theme.Text
            box.PlaceholderColor3 = Theme.TextDim
        end,
    }

    box.FocusLost:Connect(function()
        SafeCallback(callback, box.Text)
    end)

    return self:_register(control)
end

function Section:AddProgress(text, value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 100

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Progress", 11, Theme.TextMuted, Fonts.Medium)
    label.Size = UDim2.new(1, -50, 0, 18)

    local percentage = MakeText(holder, "0%", 10, Theme.TextDim, Fonts.Medium)
    percentage.Position = UDim2.new(1, -45, 0, 0)
    percentage.Size = UDim2.fromOffset(45, 18)
    percentage.TextXAlignment = Enum.TextXAlignment.Right

    local track = New("Frame", {
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 6),
        Parent = holder,
    })

    Corner(track, 3)

    local fill = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    })

    Corner(fill, 3)

    local control = {
        Frame = holder,
        SetValue = function(_, nextValue)
            value = Clamp(tonumber(nextValue) or 0, 0, maximum)
            local alpha = maximum == 0 and 0 or value / maximum

            Tween(fill, Easing.Smooth, {
                Size = UDim2.fromScale(alpha, 1),
            })

            percentage.Text = string.format("%d%%", math.floor(alpha * 100 + 0.5))
        end,
        GetValue = function()
            return value
        end,
        Destroy = function()
            holder:Destroy()
        end,
        _refreshTheme = function()
            label.TextColor3 = Theme.TextMuted
            fill.BackgroundColor3 = Theme.Accent
        end,
    }

    control:SetValue(value)

    return self:_register(control)
end

function Section:AddSliderWithInput(text, default, minimum, maximum, step, callback)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 72),
        Parent = self._container,
    })

    local label = MakeText(holder, text or "Value", 11, Theme.Text, Fonts.Medium)
    label.Size = UDim2.new(1, -75, 0, 20)

    local input = New("TextBox", {
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = tostring(default or minimum),
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Fonts.Medium,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(65, 22),
        Parent = holder,
    })

    Corner(input, 5)
    Stroke(input, Theme.StrokeSoft, 1, 0.2)

    local sliderHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 29),
        Size = UDim2.new(1, 0, 0, 34),
        Parent = holder,
    })

    local track = New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel3,
        BorderSizePixel = 0,
        Text = "",
        Position = UDim2.fromOffset(0, 13),
        Size = UDim2.new(1, 0, 0, 7),
        Parent = sliderHolder,
    })

    Corner(track, 4)

    local fill = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    })

    Corner(fill, 4)

    local knob = New("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(),
        Size = UDim2.fromOffset(13, 13),
        Parent = track,
    })

    Corner(knob, 7)

    local control = setmetatable({
        _maid = Maid.new(),
        _frame = holder,
        _label = label,
        _input = input,
        _track = track,
        _fill = fill,
        _knob = knob,
        _value = default or minimum,
        _minimum = minimum,
        _maximum = maximum,
        _step = step or 1,
        _callback = callback,
        _dragging = false,
        _destroyed = false,
    }, Control)

    control.Changed = Signal.new()

    function control:SetValue(nextValue, silent)
        nextValue = Clamp(tonumber(nextValue) or self._minimum, self._minimum, self._maximum)

        local steps = math.round((nextValue - self._minimum) / self._step)
        nextValue = Clamp(self._minimum + steps * self._step, self._minimum, self._maximum)

        self._value = nextValue
        input.Text = tostring(nextValue)

        local alpha = (nextValue - self._minimum)
            / math.max(self._maximum - self._minimum, 0.0001)

        Tween(fill, Easing.Fast, {
            Size = UDim2.fromScale(alpha, 1),
        })

        Tween(knob, Easing.Fast, {
            Position = UDim2.new(alpha, 0, 0.5, 0),
        })

        if not silent then
            self.Changed:Fire(nextValue)
            SafeCallback(self._callback, nextValue)
        end
    end

    function control:GetValue()
        return self._value
    end

    function control:_fromX(x)
        local left = track.AbsolutePosition.X
        local width = math.max(track.AbsoluteSize.X, 1)
        local alpha = Clamp((x - left) / width, 0, 1)

        self:SetValue(
            self._minimum + (self._maximum - self._minimum) * alpha
        )
    end

    control:_track(track.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then

            self._dragging = true
            self:_fromX(inputObject.Position.X)
        end
    end))

    control:_track(UserInputService.InputChanged:Connect(function(inputObject)
        if not self._dragging then
            return
        end

        if inputObject.UserInputType == Enum.UserInputType.MouseMovement
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            self:_fromX(inputObject.Position.X)
        end
    end))

    control:_track(UserInputService.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            self._dragging = false
        end
    end))

    control:_track(input.FocusLost:Connect(function()
        self:SetValue(tonumber(input.Text) or self._value)
    end))

    control._refreshTheme = function()
        label.TextColor3 = Theme.Text
        input.TextColor3 = Theme.Text
        fill.BackgroundColor3 = Theme.Accent
        control:SetValue(control._value, true)
    end

    control:SetValue(default or minimum, true)

    return self:_register(control)
end

function Control:SetText(text)
    if self._button then
        self._button.Text = text
    end
end

function Control:SetCallback(callback)
    self._callback = callback
end

function Control:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    if self._maid then
        self._maid:Cleanup()
    end

    if self._frame then
        self._frame:Destroy()
    end
end

function Tab:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    if self._maid then
        self._maid:Cleanup()
    end

    if self._button then
        self._button:Destroy()
    end

    if self._page then
        self._page:Destroy()
    end

    for index, tab in ipairs(self._window._tabs) do
        if tab == self then
            table.remove(self._window._tabs, index)
            break
        end
    end
end

function Section:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, control in ipairs(self._controls) do
        if control.Destroy then
            control:Destroy()
        end
    end

    if self._maid then
        self._maid:Cleanup()
    end

    if self._frame then
        self._frame:Destroy()
    end
end

function Window:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    for _, tab in ipairs(self._tabs) do
        if tab.Destroy then
            tab:Destroy()
        end
    end

    if self._maid then
        self._maid:Cleanup()
    end

    if self._gui then
        self._gui:Destroy()
    end

    for index, window in ipairs(WerareMods._windows) do
        if window == self then
            table.remove(WerareMods._windows, index)
            break
        end
    end
end

function Window:GetSelectedTab()
    for _, tab in ipairs(self._tabs) do
        if tab._selected then
            return tab
        end
    end

    return nil
end

function Window:SetTitle(title)
    self._title.Text = tostring(title or "")
end

function Window:SetSubtitle(subtitle)
    self._subtitle.Text = tostring(subtitle or "")
end

function Window:SetSize(size)
    if typeof(size) ~= "UDim2" then
        return
    end

    self._size = size

    if not self._minimized then
        Tween(self._window, Easing.Smooth, {
            Size = size,
        })

        Tween(self._shadow, Easing.Smooth, {
            Size = size,
        })
    end
end

function Window:GetSize()
    return self._size
end

function Window:SetPosition(position)
    if typeof(position) ~= "UDim2" then
        return
    end

    self._window.Position = position
    self._shadow.Position = UDim2.new(
        position.X.Scale,
        position.X.Offset + 4,
        position.Y.Scale,
        position.Y.Offset + 5
    )
end

function Window:GetPosition()
    return self._window.Position
end

function Window:Focus()
    self._gui.DisplayOrder = 999
end

function Window:Open()
    self:SetVisible(true)
end

function Window:Close()
    self:SetVisible(false)
end

function Window:IsVisible()
    return self._visible
end

function Window:AddScaleControl(section)
    local control = section:AddSlider(
        "Interface size",
        self:GetScale() * 100,
        65,
        135,
        1,
        function(value)
            self:SetScale(value / 100)
        end
    )

    return control
end

function WerareMods:CreatePresetWindow(title)
    local window = self:CreateWindow({
        Title = title or "@WerareMods",
        Size = UDim2.fromOffset(760, 510),
        Scale = 0.95,
    })

    local main = window:AddTab("Main", "M")
    local visuals = window:AddTab("Visuals", "V")
    local settings = window:AddTab("Settings", "S")

    local general = main:AddSection("General")
    general:AddButton("Example button", function()
        window:Notify({
            Title = "WerareMods",
            Text = "Button pressed.",
        })
    end)

    general:AddToggle("Example toggle", false, function(value)
        window:Notify({
            Title = "Toggle",
            Text = value and "Enabled" or "Disabled",
            Duration = 1.5,
        })
    end)

    general:AddSlider("Example slider", 50, 0, 100, 1, function(value)
        print("Slider:", value)
    end)

    local visualSection = visuals:AddSection("Colors")
    visualSection:AddColorPicker(
        "Accent",
        Theme.Accent,
        function(color)
            WerareMods:SetTheme({
                Accent = color,
            })
        end
    )

    local scaleSection = settings:AddSection("Interface")
    window:AddScaleControl(scaleSection)

    settings:AddKeybind("Toggle UI", Enum.KeyCode.RightShift, function(key)
        print("New UI key:", key)
    end)

    return window
end

WerareMods.Theme = Theme
WerareMods.Fonts = Fonts
WerareMods.Signal = Signal
WerareMods.Maid = Maid
WerareMods._windows = {}

WerareMods.Config = {
    Name = "WerareMods",
    Brand = "@WerareMods",
    Accent = Theme.Accent,
    ToggleKey = Enum.KeyCode.RightShift,
    MinScale = 0.65,
    MaxScale = 1.35,
    AutoScale = true,
    MobileMinWidth = 320,
    MobileMinHeight = 280,
}

function WerareMods:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return
    end

    Theme.Accent = color
    self:SetTheme({
        Accent = color,
    })
end

function WerareMods:GetAccent()
    return Theme.Accent
end

function WerareMods:SetAccentFromRGB(r, g, b)
    self:SetAccent(Color3.fromRGB(
        Clamp(tonumber(r) or 0, 0, 255),
        Clamp(tonumber(g) or 0, 0, 255),
        Clamp(tonumber(b) or 0, 0, 255)
    ))
end

function WerareMods:SetAccentFromHex(hex)
    if type(hex) ~= "string" then
        return false
    end

    hex = hex:gsub("#", "")

    if #hex ~= 6 then
        return false
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    if not r or not g or not b then
        return false
    end

    self:SetAccent(Color3.fromRGB(r, g, b))
    return true
end

function WerareMods:DestroyAll()
    for index = #self._windows, 1, -1 do
        local window = self._windows[index]

        if window and window.Destroy then
            window:Destroy()
        end
    end

    table.clear(self._windows)
end

return WerareMods
