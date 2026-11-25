--!nocheck
-- Lua, main.lua, Luau / Roblox Executor, Target: Consumer Script for frost.vip UI Library (Enhanced v3)

local LibraryURL = "https://raw.githubusercontent.com/<USERNAME>/<REPO>/main/library.lua"

local FrostLibrary
local success, result = pcall(function()
    return loadstring(game:HttpGet(LibraryURL))()
end)

if not success or not result then
    FrostLibrary = loadfile("library.lua")()
else
    FrostLibrary = result
end

-- Initialize Window with DPI scale, scanline shader, and search bar
local Window = FrostLibrary:CreateWindow({
    Title = "frost.vip",
    Width = 535,
    Height = 680,
    Scale = 1.0,
    ToggleKey = Enum.KeyCode.Insert,
    Watermark = true,
    KeybindList = true
})

-- Create Primary Tabs
local CombatTab   = Window:CreateTab("Combat", true)
local VisualsTab  = Window:CreateTab("Visuals", false)
local MiscTab     = Window:CreateTab("Misc", false)
local SkinsTab    = Window:CreateTab("Skins", false)
local SettingsTab = Window:CreateTab("settings", false)

-- ============================================================
-- TAB 1: COMBAT (1:1 Screenshot Structure)
-- ============================================================

-- Left Column - Main Combat Box
local MainCombatBox = CombatTab:CreateGroupbox("Left", nil)

MainCombatBox:AddDropdown(nil, {"Mouse", "Memory", "Silent"}, 1, function(selected)
    print("Device mode:", selected)
end, { Flag = "DeviceMode", Tooltip = "Target acquisition input method" })

MainCombatBox:AddDropdown("Hitscan priority", {"Closest to crosshair", "Lowest health", "Most lethal", "Nearest distance"}, 1, function(selected)
    print("Hitscan priority:", selected)
end, { Flag = "HitscanPriority", Tooltip = "Priority filter for target selection" })

MainCombatBox:AddDropdown("Checks", {"Visible check", "Smoke check", "Flash check"}, {1}, function(selected)
    print("Active Checks:", selected)
end, { Flag = "HitscanChecks", Multi = true, Tooltip = "Multi-selection visibility sanity checks" })

MainCombatBox:AddStepper("Aim size", {"-180°", "-90°", "-10°", "0°", "10°", "90°", "180°"}, 3, function(val)
    print("Aim size:", val)
end, { Flag = "AimSize", Tooltip = "Maximum angular target FOV" })

MainCombatBox:AddSlider("Aim smoothness X", 0, 1, 0.7, "", 0.05, function(val)
    print("Aim smoothness X:", val)
end, { Flag = "AimSmoothnessX", Tooltip = "Horizontal mouse lerp smoothing factor" })

MainCombatBox:AddSlider("Aim smoothness Y", 0, 1, 0.7, "", 0.05, function(val)
    print("Aim smoothness Y:", val)
end, { Flag = "AimSmoothnessY", Tooltip = "Vertical mouse lerp smoothing factor" })

MainCombatBox:AddStepper("Multipoint", {"Auto", "Low", "Medium", "High", "Extreme"}, 1, function(val)
    print("Multipoint:", val)
end, { Flag = "Multipoint", Tooltip = "Hitbox point subdivision intensity" })

MainCombatBox:AddToggle("FOV", false, function(state)
    print("FOV:", state)
end, { Flag = "DrawFOV", Tooltip = "Render crosshair field of view circle", ColorChips = { Color3.fromRGB(255, 255, 255) } })

MainCombatBox:AddToggle("Auto fire", false, function(state)
    print("Auto fire:", state)
end, { Flag = "AutoFire", Tooltip = "Automatically discharge weapon on target confirmation", Keybind = "none" })

MainCombatBox:AddStepper("Min damage", {"Off", "10", "20", "30", "40", "50", "60", "70", "80", "90", "100"}, 1, function(val)
    print("Min damage:", val)
end, { Flag = "MinDamage", Tooltip = "Minimum calculated damage before engagement" })

MainCombatBox:AddToggle("Override min damage", false, function(state)
    print("Override min damage:", state)
end, { Flag = "OverrideMinDamage", Tooltip = "Temporarily override damage threshold", Keybind = "none" })

MainCombatBox:AddStepper("Override damage", {"1", "5", "10", "20", "50", "100"}, 1, function(val)
    print("Override damage:", val)
end, { Flag = "OverrideDamageVal", Tooltip = "Fallback penetration threshold" })

MainCombatBox:AddToggle("Self extrapolation", false, function(state)
    print("Self extrapolation:", state)
end, { Flag = "SelfExtrapolation", Tooltip = "Predict local velocity compensation" })

MainCombatBox:AddToggle("Origin scan", false, function(state)
    print("Origin scan:", state)
end, { Flag = "OriginScan", Tooltip = "Trace trajectories from barrel muzzle offset" })

-- Left Column - Visual Group Box
local VisualBox = CombatTab:CreateGroupbox("Left", "Visual")

VisualBox:AddToggle("Snapline", false, function(state)
    print("Snapline:", state)
end, { Flag = "Snapline", Tooltip = "Render vector trace to locked target", ColorChips = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(153, 142, 196) } })

VisualBox:AddToggle("Visualize hitpart", false, function(state)
    print("Visualize hitpart:", state)
end, { Flag = "VisualizeHitpart", Tooltip = "Render 3D bone orientation at target point", ColorChips = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Hitlogs", false, function(state)
    print("Hitlogs:", state)
end, { Flag = "Hitlogs", Gear = true, Tooltip = "Log bullet trace and register events", ColorChips = { Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Bullet impact", false, function(state)
    print("Bullet impact:", state)
end, { Flag = "BulletImpact", Tooltip = "Spawn client hit confirmation markers", ColorChips = { Color3.fromRGB(68, 110, 189), Color3.fromRGB(185, 61, 72) } })

VisualBox:AddToggle("Hit Screen Effect", false, function(state)
    print("Hit Screen Effect:", state)
end, { Flag = "HitScreenEffect", Tooltip = "Vignette flash upon lethal hit registration", ColorChips = { Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Hitmarker", false, function(state)
    print("Hitmarker:", state)
end, { Flag = "Hitmarker", Gear = true, Tooltip = "Dynamic audio/visual crosshair tic", ColorChips = { Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Hit damage", false, function(state)
    print("Hit damage:", state)
end, { Flag = "HitDamage", Gear = true, Tooltip = "World floating combat text", ColorChips = { Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Crosshair marker", false, function(state)
    print("Crosshair marker:", state)
end, { Flag = "CrosshairMarker", Gear = true, Tooltip = "Center screen reticle overlay", ColorChips = { Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Hit effect", false, function(state)
    print("Hit effect:", state)
end, { Flag = "HitEffect", Gear = true, Tooltip = "Spark particle emitter at hit location", ColorChips = { Color3.fromRGB(255, 255, 255) } })

VisualBox:AddToggle("Kill effect", false, function(state)
    print("Kill effect:", state)
end, { Flag = "KillEffect", Gear = true, Tooltip = "Elimination feedback visual effect", ColorChips = { Color3.fromRGB(255, 255, 255) } })

-- Right Column - Gun modification
local GunModBox = CombatTab:CreateGroupbox("Right", "Gun modification")

local gunMods = {
    {"Instant Reload", "Bypass reload cycle animation delay"},
    {"Auto reload", "Trigger magazine reload on empty clip"},
    {"Instant Revolver", "Eliminate hammer cock timing delay"},
    {"No Sway", "Zero viewport gun model idle sway"},
    {"Recoil Control", "Compensate procedural weapon recoil pattern"},
    {"No Spread", "Zero bullet cone expansion spread"},
    {"Always Auto", "Enable continuous automatic fire trigger"},
    {"Fire rate", "Override weapon cyclical RPM limit"},
    {"No shoot animation", "Suppress local weapon recoil animation kick"},
    {"Persistent Inspect", "Lock weapon inspection sequence loop"}
}

for _, mod in ipairs(gunMods) do
    GunModBox:AddToggle(mod[1], false, function(state)
        print(mod[1] .. ":", state)
    end, { Flag = mod[1]:gsub("%s+", ""), Tooltip = mod[2] })
end

-- Right Column - Other
local OtherBox = CombatTab:CreateGroupbox("Right", "Other")

OtherBox:AddToggle("Trigger bot", false, function(state)
    print("Trigger bot:", state)
end, { Flag = "Triggerbot", Tooltip = "Discharge weapon immediately when crosshair enters enemy", Keybind = "none" })

OtherBox:AddToggle("Knife bot", false, function(state)
    print("Knife bot:", state)
end, { Flag = "Knifebot", Tooltip = "Automatic lethal backstab melee range execution" })

OtherBox:AddToggle("Zeus bot", false, function(state)
    print("Zeus bot:", state)
end, { Flag = "Zeusbot", Tooltip = "Automatic taser discharge within lethal perimeter" })

-- Right Column - Anti aim
local AntiAimBox = CombatTab:CreateGroupbox("Right", "Anti aim")

AntiAimBox:AddToggle("Anti aim", false, function(state)
    print("Anti aim:", state)
end, { Flag = "AntiAimEnabled", Tooltip = "Manipulate outbound third-person desync angles", Keybind = "b" })

AntiAimBox:AddDropdown("Edit state", {"Global", "Standing", "Moving", "Air", "Crouch"}, 1, function(selected)
    print("Edit state:", selected)
end, { Flag = "AntiAimEditState", Tooltip = "Motion state conditioning context" })

AntiAimBox:AddDropdown("Mode", {"Jitter", "Static", "Spin", "Random"}, 1, function(selected)
    print("Mode:", selected)
end, { Flag = "AntiAimMode", Tooltip = "Angular offset rotation algorithm" })

AntiAimBox:AddStepper("Pitch", {"=90°", "89°", "0°", "-89°", "-90°"}, 1, function(val)
    print("Pitch:", val)
end, { Flag = "AntiAimPitch", Tooltip = "Vertical viewing angle offset" })

AntiAimBox:AddSlider("Range", 0, 180, 90, "°", 1, function(val)
    print("Range:", val)
end, { Flag = "AntiAimRange", Tooltip = "Jitter excursion angle bounds" })

AntiAimBox:AddSlider("Speed", 0, 100, 10, "", 1, function(val)
    print("Speed:", val)
end, { Flag = "AntiAimSpeed", Tooltip = "Tick rate angular transition velocity" })

AntiAimBox:AddStepper("Yaw", {"-180°", "-90°", "0°", "90°", "180°"}, 3, function(val)
    print("Yaw:", val)
end, { Flag = "AntiAimYaw", Tooltip = "Base yaw deflection angle" })

AntiAimBox:AddToggle("At target", false, function(state)
    print("At target:", state)
end, { Flag = "AntiAimAtTarget", Tooltip = "Align desync base angle opposite closest adversary" })

AntiAimBox:AddToggle("Manual left", false, function(state)
    print("Manual left:", state)
end, { Flag = "ManualLeft", Tooltip = "Snap fake angle 90 degrees left", Keybind = "z" })

AntiAimBox:AddToggle("Manual right", false, function(state)
    print("Manual right:", state)
end, { Flag = "ManualRight", Tooltip = "Snap fake angle 90 degrees right", Keybind = "c" })

AntiAimBox:AddToggle("Manual forward", false, function(state)
    print("Manual forward:", state)
end, { Flag = "ManualForward", Tooltip = "Snap fake angle 0 degrees forward", Keybind = "x" })

-- ============================================================
-- TAB 2: VISUALS (Demonstrating Sub-Tabs & Dual Gradient Pickers)
-- ============================================================
local PlayersSub = VisualsTab:CreateSubTab("Players", true)
local WorldSub   = VisualsTab:CreateSubTab("World", false)

local EspBox = PlayersSub:CreateGroupbox("Left", "Enemy ESP")
EspBox:AddToggle("Bounding Box", false, nil, { Flag = "EspBox", Tooltip = "2D axis-aligned bounding box" })
EspBox:AddGradientPicker("Box Outline Gradient", Color3.fromRGB(255, 255, 255), Color3.fromRGB(153, 142, 196), nil, { Flag = "BoxGradient" })
EspBox:AddToggle("Health Bar", false, nil, { Flag = "EspHealth", Tooltip = "Vertical dynamic damage bar" })
EspBox:AddToggle("Player Name", false, nil, { Flag = "EspName" })
EspBox:AddTextInput("Filter Name", "Enter name...", "", nil, { Flag = "EspFilterName", Tooltip = "Exclude specific usernames" })

local WorldBox = WorldSub:CreateGroupbox("Left", "Atmosphere")
WorldBox:AddGradientPicker("Skybox Color", Color3.fromRGB(20, 20, 30), Color3.fromRGB(60, 50, 80), nil, { Flag = "SkyboxGradient" })
WorldBox:AddSlider("Nightmode Density", 0, 100, 40, "%", 1, nil, { Flag = "NightmodeDensity" })

-- ============================================================
-- TAB 3: SETTINGS (Config System, Themes & DPI Scaling)
-- ============================================================
local ConfigBox = SettingsTab:CreateGroupbox("Left", "Configuration")

ConfigBox:AddDropdown("Select Config", {"default", "legit", "rage", "scout"}, 1, function(cfgName)
    print("Selected config:", cfgName)
end, { Flag = "SelectedConfig" })

ConfigBox:AddTextInput("Config Name", "new_config", "", nil, { Flag = "CustomConfigName", Tooltip = "Name for new config file" })

ConfigBox:AddToggle("Save Active Config", false, function(s)
    if s then
        local cfg = FrostLibrary.Flags["CustomConfigName"]
        if not cfg or cfg == "" then cfg = FrostLibrary.Flags["SelectedConfig"] or "default" end
        FrostLibrary:SaveConfig(cfg)
        print("Config saved:", cfg)
    end
end, { Tooltip = "Serialize all flags to executor workspace storage" })

ConfigBox:AddToggle("Load Active Config", false, function(s)
    if s then
        local cfg = FrostLibrary.Flags["SelectedConfig"] or "default"
        FrostLibrary:LoadConfig(cfg)
        print("Config loaded:", cfg)
    end
end, { Tooltip = "Restore saved flags from disk" })

local UiCustomBox = SettingsTab:CreateGroupbox("Right", "Interface Customization")

UiCustomBox:AddDropdown("Theme Preset", {"Frost (Default)", "Skeet Green", "Neverlose Cyan", "Onetap Orange"}, 1, function(theme)
    if theme == "Frost (Default)" then
        FrostLibrary:SetThemeColor(Color3.fromRGB(153, 142, 196), Color3.fromRGB(108, 99, 140))
    elseif theme == "Skeet Green" then
        FrostLibrary:SetThemeColor(Color3.fromRGB(168, 219, 90), Color3.fromRGB(106, 153, 40))
    elseif theme == "Neverlose Cyan" then
        FrostLibrary:SetThemeColor(Color3.fromRGB(80, 200, 255), Color3.fromRGB(30, 110, 170))
    elseif theme == "Onetap Orange" then
        FrostLibrary:SetThemeColor(Color3.fromRGB(255, 160, 60), Color3.fromRGB(180, 90, 20))
    end
end, { Tooltip = "Live pipeline accent re-theming" })

UiCustomBox:AddStepper("DPI / Scale Factor", {"0.8x", "1.0x", "1.25x", "1.5x", "2.0x"}, 2, function(val)
    local s = tonumber((val:gsub("x", ""))) or 1.0
    Window:SetScale(s)
end, { Flag = "UiScaleFactor", Tooltip = "Adjust integer UI raster scale" })
