--[[
    WerareMods UI - Demo
    Put this LocalScript next to the ModuleScript and update the require path.
]]

local UI = require(script.Parent.WerareMods_UI)

local Window = UI:CreateWindow({
    Title = "@WerareMods",
    Size = UDim2.fromOffset(760, 510),
    Scale = 0.95,
})

local Main = Window:AddTab("Main", "M")
local Visuals = Window:AddTab("Visuals", "V")
local Settings = Window:AddTab("Settings", "S")

local General = Main:AddSection("General")

General:AddButton("Open notification", function()
    Window:Notify({
        Title = "WerareMods",
        Text = "Everything is working.",
    })
end)

General:AddToggle("Enabled", true, function(value)
    print("Enabled:", value)
end)

General:AddCheckbox("Show details", false, function(value)
    print("Show details:", value)
end)

General:AddSlider("Amount", 50, 0, 100, 1, function(value)
    print("Amount:", value)
end)

General:AddSliderWithInput("Power", 25, 0, 100, 1, function(value)
    print("Power:", value)
end)

General:AddDropdown(
    "Mode",
    {"Default", "Compact", "Detailed"},
    "Default",
    function(value)
        print("Mode:", value)
    end
)

local VisualSection = Visuals:AddSection("Appearance")

VisualSection:AddColorPicker(
    "ESP Color",
    Color3.fromRGB(120, 214, 139),
    function(color)
        print("Selected color:", color)
    end
)

VisualSection:AddMultiToggle(
    "Display",
    {"Names", "Boxes", "Distance", "Health"},
    {
        Names = true,
        Boxes = true,
        Distance = false,
        Health = true,
    },
    function(values)
        print("Display changed")
    end
)

VisualSection:AddProgress("Loading", 72, 100)

local Interface = Settings:AddSection("Interface")
Window:AddScaleControl(Interface)

Settings:AddKeybind(
    "Toggle UI",
    Enum.KeyCode.RightShift,
    function(key)
        print("Toggle key:", key)
    end
)

Settings:AddSearch(
    "Search",
    "Search controls...",
    function(text)
        print("Search:", text)
    end
)

Settings:AddParagraph(
    "About",
    "Dark WerareMods interface with animated controls, green accent and an integrated color picker."
)
