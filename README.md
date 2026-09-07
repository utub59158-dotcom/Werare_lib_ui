# WerareMods UI

A Roblox Luau GUI library with the original dark visual direction and a green accent.

## Included

- Animated tabs, buttons, toggles and sliders
- Dropdowns, checkboxes and keybinds
- HSV/SV + hue color picker with HEX preview
- Theme API
- Notifications
- Manual UI scale
- Automatic responsive scaling
- Desktop sidebar layout
- Touch/mobile top-tab layout
- Mouse + touch dragging
- Mouse + touch resizing
- Optional custom `Parent` for the `ScreenGui`
- Cleanup through Maid/Destroy
- No dependency on executor-only APIs

## Usage

The library remains a normal Luau module and can also be executed as a single source chunk by environments that support source execution. It does not require an executor-specific API to render the UI.

### ModuleScript

```lua
local UI = require(path.to.WerareMods_UI)

local Window = UI:CreateWindow({
    Title = "@WerareMods",
    Size = UDim2.fromOffset(760, 510),
    AutoScale = true,
})

local Main = Window:AddTab("Main", "M")
local Section = Main:AddSection("General")

Section:AddToggle("Enabled", false, function(value)
    print(value)
end)

Section:AddSlider("Speed", 50, 0, 100, 1, function(value)
    print(value)
end)
```

## Responsive behavior

`AutoScale = true` is the default. Desktop keeps the familiar left sidebar. Touch/small-screen devices automatically switch the tab rail to the top and use larger touch targets. Portrait/landscape viewport changes are handled automatically.

To take manual control:

```lua
Window:SetScale(0.9)
Window:SetAutoScale(false)
```

You can query the active layout with:

```lua
print(Window:IsMobileLayout())
```

## Custom parent

If your environment provides a valid `GuiObject`/`LayerCollector` parent, you can pass it without changing the library:

```lua
local Window = UI:CreateWindow({
    Parent = someGuiParent,
})
```

The library itself does not call executor-specific functions such as `gethui`, `cloneref`, `setthreadidentity`, etc.

## Files

- `WerareMods_UI.lua` — library
- `Demo.client.lua` — example
- `README.md` — documentation
