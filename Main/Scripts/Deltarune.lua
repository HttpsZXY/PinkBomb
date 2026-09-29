local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then return end

WindUI:Notify({
    Title = "Deltarune | Pink's",
    Content = "It might take a while or you might experience some lag loading, so please be patient, and if it doesn't load or something else happens, please let us know.",
    Duration = 8,
    Icon = "info",
})

local Green  = Color3.fromHex("#10C550")
local Red    = Color3.fromHex("#EF4F1D")
local Orange = Color3.fromHex("#F97316")

local PinksState = {
    TPInfinite = false,
    HPInfinite = false,
    GodMode = false,
    FreeSoulToggle = false,
    DeleteStinky = false,
    VisualHitbox = false,
    _TPAmount = 10,
    _HPAmount = 0,
    UIColor = "Dark",
}

local ConfigFolder = "DeltarunePinks/Configs"
local ConfigNameValue = "Default"
local ConfigFileList = { "Default" }

local function EnsureConfigFolder()
    pcall(function()
        if makefolder then
            makefolder("DeltarunePinks")
            makefolder(ConfigFolder)
        end
    end)
end

local function ConfigPath(name)
    return ConfigFolder .. "/" .. tostring(name or "Default") .. ".json"
end

local function EncodeConfig(data)
    local parts = {}
    for k, v in pairs(data) do
        local val
        if type(v) == "boolean" then
            val = v and "true" or "false"
        elseif type(v) == "number" then
            val = tostring(v)
        else
            val = '"' .. tostring(v):gsub('"', "") .. '"'
        end
        table.insert(parts, '"' .. tostring(k) .. '":' .. val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function DecodeConfig(str)
    local result = {}
    if type(str) ~= "string" then
        return result
    end
    for key, val in string.gmatch(str, '"([^"]+)":%s*([^,}]+)') do
        val = val:gsub("%s+", "")
        if val == "true" then
            result[key] = true
        elseif val == "false" then
            result[key] = false
        elseif tonumber(val) then
            result[key] = tonumber(val)
        else
            result[key] = val:gsub('^"', ""):gsub('"$', "")
        end
    end
    return result
end

local function RefreshConfigList()
    EnsureConfigFolder()
    local list = { "Default" }
    pcall(function()
        if listfiles then
            for _, file in pairs(listfiles(ConfigFolder)) do
                local name = tostring(file):match("([^/\\]+)%.json$")
                if name and name ~= "Default" then
                    table.insert(list, name)
                end
            end
        end
    end)
    ConfigFileList = list
    return list
end

local function SnapshotConfig()
    return {
        TPInfinite = PinksState.TPInfinite,
        HPInfinite = PinksState.HPInfinite,
        GodMode = PinksState.GodMode,
        FreeSoulToggle = PinksState.FreeSoulToggle,
        DeleteStinky = PinksState.DeleteStinky,
        VisualHitbox = PinksState.VisualHitbox,
        _TPAmount = PinksState._TPAmount or 10,
        _HPAmount = PinksState._HPAmount or 0,
        UIColor = PinksState.UIColor or "Dark",
    }
end

local ApplyConfig

local function SaveConfig(name)
    name = tostring(name or ConfigNameValue or "Default")
    if name == "" then
        name = "Default"
    end
    EnsureConfigFolder()
    local data = SnapshotConfig()
    local ok = pcall(function()
        if writefile then
            writefile(ConfigPath(name), EncodeConfig(data))
        end
    end)
    RefreshConfigList()
    return ok
end

local function LoadConfig(name)
    name = tostring(name or ConfigNameValue or "Default")
    local path = ConfigPath(name)
    local raw
    local ok = pcall(function()
        if isfile and isfile(path) and readfile then
            raw = readfile(path)
        elseif readfile then
            raw = readfile(path)
        end
    end)
    if not ok or not raw then
        return false
    end
    local data = DecodeConfig(raw)
    ApplyConfig(data)
    return true
end

local function DeleteConfig(name)
    name = tostring(name or ConfigNameValue or "Default")
    local path = ConfigPath(name)
    local ok = pcall(function()
        if isfile and isfile(path) and delfile then
            delfile(path)
        end
    end)
    RefreshConfigList()
    return ok
end

local Cache = {
    TensionBars = {},
    TensionTables = {},
    SoulTables = {},
    HPTables = {},
    BattleTables = {},
    LastScan = 0,
}

local function GetTensionMax()
    local max = 100
    pcall(function()
        local Core = ReplicatedStorage:FindFirstChild("Core")
        if not Core then return end
        local ok, Config = pcall(require, Core.Data.Config)
        if ok and Config and Config.Tension and type(Config.Tension.Max) == "number" then
            max = Config.Tension.Max
        end
    end)
    return max
end

local function GetConfig()
    local ok, cfg = pcall(function()
        return require(ReplicatedStorage.Core.Data.Config)
    end)
    return ok and cfg or nil
end

local function RescanCache(force)
    local now = os.clock()
    if not force and now - Cache.LastScan < 2 then
        return
    end
    Cache.LastScan = now

    local tensionBars = {}
    local tensionTables = {}
    local soulTables = {}
    local hpTables = {}
    local battleTables = {}

    pcall(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "table" then
                if rawget(v, "Apparent") ~= nil and rawget(v, "Current") ~= nil then
                    table.insert(tensionBars, v)
                end
                if type(rawget(v, "Tension")) == "number" and rawget(v, "TensionMax") ~= nil then
                    table.insert(tensionTables, v)
                end
                if rawget(v, "Invuln") ~= nil and rawget(v, "HP") ~= nil and rawget(v, "MaxHP") ~= nil then
                    table.insert(soulTables, v)
                end
                if rawget(v, "HP") ~= nil and rawget(v, "MaxHP") ~= nil then
                    table.insert(hpTables, v)
                end
                if typeof(v.ClearBullets) == "function" or typeof(v.Bullets) == "table" then
                    table.insert(battleTables, v)
                end
            end
        end
    end)

    Cache.TensionBars = tensionBars
    Cache.TensionTables = tensionTables
    Cache.SoulTables = soulTables
    Cache.HPTables = hpTables
    Cache.BattleTables = battleTables
end

local function ForceTP(amount)
    local max = GetTensionMax()
    local value = math.clamp(tonumber(amount) or max, 0, max)
    RescanCache(false)
    pcall(function()
        for _, v in pairs(Cache.TensionBars) do
            rawset(v, "Apparent", value)
            rawset(v, "Current", value)
        end
        for _, v in pairs(Cache.TensionTables) do
            local tmax = rawget(v, "TensionMax") or max
            rawset(v, "Tension", math.clamp(value, 0, tmax))
        end
    end)
end

local function ClearBulletsNow()
    RescanCache(false)
    pcall(function()
        for _, v in pairs(Cache.BattleTables) do
            if typeof(v.ClearBullets) == "function" then
                pcall(function()
                    v:ClearBullets()
                end)
            end
            if typeof(v.Bullets) == "table" then
                for i = #v.Bullets, 1, -1 do
                    local b = v.Bullets[i]
                    if b and typeof(b.Destroy) == "function" then
                        pcall(function()
                            b:Destroy()
                        end)
                    end
                    table.remove(v.Bullets, i)
                end
            end
        end

        for _, v in pairs(getgc(true)) do
            if typeof(v) ~= "table" then
            else
                if typeof(v.Bombs) == "table" then
                    if typeof(v.DestroyBomb) == "function" then
                        for i = #v.Bombs, 1, -1 do
                            local bomb = v.Bombs[i]
                            pcall(function()
                                v:DestroyBomb(bomb)
                            end)
                            table.remove(v.Bombs, i)
                        end
                    else
                        for i = #v.Bombs, 1, -1 do
                            local bomb = v.Bombs[i]
                            if type(bomb) == "table" then
                                if bomb.Bullet and typeof(bomb.Bullet.Destroy) == "function" then
                                    pcall(function()
                                        bomb.Bullet:Destroy()
                                    end)
                                end
                                for _, key in pairs({ "BandH", "BandV", "TeleRing", "TeleDisc", "Body", "Fuse" }) do
                                    local part = bomb[key]
                                    if part and typeof(part.Destroy) == "function" then
                                        pcall(function()
                                            part:Destroy()
                                        end)
                                    end
                                end
                            end
                            table.remove(v.Bombs, i)
                        end
                    end
                end

                if typeof(v.Explosions) == "table" then
                    for i = #v.Explosions, 1, -1 do
                        local exp = v.Explosions[i]
                        if type(exp) == "table" and exp.Bullet and typeof(exp.Bullet.Destroy) == "function" then
                            pcall(function()
                                exp.Bullet:Destroy()
                            end)
                        end
                        table.remove(v.Explosions, i)
                    end
                end
            end
        end
    end)
end

local function InstantWinNow()
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "table" then
                if type(rawget(v, "EnemyHP")) == "number" then
                    rawset(v, "EnemyHP", 0)
                end
                local enemies = rawget(v, "Enemies")
                if type(enemies) == "table" then
                    for _, enemy in pairs(enemies) do
                        if type(enemy) == "table" and rawget(enemy, "HP") ~= nil then
                            rawset(enemy, "HP", 0)
                            if rawget(enemy, "Alive") ~= nil then
                                rawset(enemy, "Alive", false)
                            end
                            if rawget(enemy, "Gone") ~= nil then
                                rawset(enemy, "Gone", true)
                            end
                        end
                    end
                end
                if typeof(v.ClearBullets) == "function" then
                    pcall(function()
                        if typeof(v.StopWaves) == "function" then
                            v:StopWaves()
                        end
                        v:ClearBullets()
                    end)
                end
                if typeof(v.EnterVictory) == "function" then
                    pcall(function()
                        v:EnterVictory()
                    end)
                elseif typeof(v.EndEnemyTurn) == "function" and rawget(v, "Roster") ~= nil then
                    pcall(function()
                        v:EndEnemyTurn()
                    end)
                end
            end
        end
    end)
end

local function SkipEnemyTurnNow()
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "table" then
                if typeof(v.StopWaves) == "function" and typeof(v.ClearBullets) == "function" then
                    pcall(function()
                        v:StopWaves()
                        v:ClearBullets()
                    end)
                end
                if typeof(v.Bullets) == "table" then
                    for i = #v.Bullets, 1, -1 do
                        local b = v.Bullets[i]
                        if b and typeof(b.Destroy) == "function" then
                            pcall(function()
                                b:Destroy()
                            end)
                        end
                        table.remove(v.Bullets, i)
                    end
                end
                if typeof(v.EndEnemyTurn) == "function" and rawget(v, "Roster") ~= nil then
                    pcall(function()
                        v:EndEnemyTurn()
                    end)
                end
            end
        end
    end)
end

local function MaxMercyNow()
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "table" then
                if type(rawget(v, "Mercy")) == "number" then
                    local max = 100
                    local def = rawget(v, "Def")
                    if type(def) == "table" and type(def.MercyMax) == "number" then
                        max = def.MercyMax
                    elseif type(rawget(v, "MercyMax")) == "number" then
                        max = v.MercyMax
                    end
                    rawset(v, "Mercy", max)
                end

                local enemyDef = rawget(v, "Enemy")
                if type(enemyDef) == "table" then
                    if type(rawget(enemyDef, "Mercy")) == "number" then
                        local max = 100
                        if type(rawget(enemyDef, "MercyMax")) == "number" then
                            max = enemyDef.MercyMax
                        end
                        rawset(enemyDef, "Mercy", max)
                    elseif type(rawget(enemyDef, "MercyMax")) == "number" then
                        rawset(enemyDef, "Mercy", enemyDef.MercyMax)
                    end
                end

                local enemies = rawget(v, "Enemies")
                if type(enemies) == "table" then
                    for _, enemy in pairs(enemies) do
                        if type(enemy) == "table" then
                            local max = 100
                            local def = rawget(enemy, "Def")
                            if type(def) == "table" and type(def.MercyMax) == "number" then
                                max = def.MercyMax
                            elseif type(rawget(enemy, "MercyMax")) == "number" then
                                max = enemy.MercyMax
                            end
                            if rawget(enemy, "Mercy") ~= nil or type(def) == "table" then
                                rawset(enemy, "Mercy", max)
                            end
                            pcall(function()
                                enemy.Mercy = max
                            end)
                        end
                    end
                end

                if typeof(v.AddMercy) == "function" then
                    local list = rawget(v, "Enemies")
                    if type(list) == "table" then
                        for _, enemy in pairs(list) do
                            if type(enemy) == "table" then
                                pcall(function()
                                    v:AddMercy(enemy, 999)
                                end)
                            end
                        end
                    end
                    if type(rawget(v, "Enemy")) == "table" then
                        pcall(function()
                            v:AddMercy(v.Enemy, 999)
                        end)
                    end
                end

                if typeof(v.RefreshUi) == "function" and (rawget(v, "Mercy") ~= nil or rawget(v, "Enemies") ~= nil) then
                    pcall(function()
                        v:RefreshUi()
                    end)
                end
            end
        end
    end)
end

local function ApplyGodMode(on)
    RescanCache(true)
    pcall(function()
        for _, v in pairs(Cache.SoulTables) do
            if on then
                rawset(v, "Invuln", 999)
                if rawget(v, "MaxHP") ~= nil then
                    rawset(v, "HP", v.MaxHP)
                end
                if rawget(v, "GrazeCount") ~= nil then
                    rawset(v, "GrazeCount", 9999)
                end
            else
                if type(rawget(v, "Invuln")) == "number" then
                    rawset(v, "Invuln", 0)
                end
            end
        end
        if on then
            for _, v in pairs(Cache.HPTables) do
                if rawget(v, "MaxHP") ~= nil then
                    rawset(v, "HP", v.MaxHP)
                end
            end
        end
    end)
end

local function ApplyFreeSoul(on)
    RescanCache(true)
    pcall(function()
        for _, v in pairs(Cache.SoulTables) do
            if on then
                if rawget(v, "Frozen") ~= nil then
                    rawset(v, "Frozen", false)
                end
                if rawget(v, "FreeRoam") ~= nil then
                    rawset(v, "FreeRoam", true)
                end
                if rawget(v, "Locked") ~= nil then
                    rawset(v, "Locked", false)
                end
            else
                if rawget(v, "FreeRoam") ~= nil then
                    rawset(v, "FreeRoam", false)
                end
                if rawget(v, "Locked") ~= nil then
                    rawset(v, "Locked", false)
                end
            end
        end
    end)
end

local function SetVisualHitboxes(on)
    pcall(function()
        local Config = GetConfig()
        if Config and Config.Debug then
            Config.Debug.ShowHitboxes = on and true or false
        end
    end)
end

ApplyConfig = function(data)
    if type(data) ~= "table" then
        return
    end

    PinksState.TPInfinite = data.TPInfinite == true
    PinksState.HPInfinite = data.HPInfinite == true
    PinksState.GodMode = data.GodMode == true
    PinksState.FreeSoulToggle = data.FreeSoulToggle == true
    PinksState.DeleteStinky = data.DeleteStinky == true
    PinksState.VisualHitbox = data.VisualHitbox == true
    PinksState._TPAmount = tonumber(data._TPAmount) or 10
    PinksState._HPAmount = tonumber(data._HPAmount) or 0
    PinksState.UIColor = data.UIColor or "Dark"

    ApplyGodMode(PinksState.GodMode)
    ApplyFreeSoul(PinksState.FreeSoulToggle)
    SetVisualHitboxes(PinksState.VisualHitbox)

    if PinksState.TPInfinite then
        ForceTP(GetTensionMax())
    end

    pcall(function()
        WindUI:SetTheme(PinksState.UIColor)
    end)

    WindUI:Notify({
        Title = "Config",
        Content = "Loaded preset toggles.",
        Duration = 3,
        Icon = "info",
    })
end

local ScanAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
    local needTP = PinksState.TPInfinite
    local needGod = PinksState.GodMode
    local needHP = PinksState.HPInfinite
    local needClear = PinksState.DeleteStinky
    local needFree = PinksState.FreeSoulToggle
    local needVisual = PinksState.VisualHitbox

    if not (needTP or needGod or needHP or needClear or needFree or needVisual) then
        return
    end

    ScanAccumulator = ScanAccumulator + dt
    if ScanAccumulator < 0.12 then
        return
    end
    ScanAccumulator = 0

    RescanCache(false)

    pcall(function()
        if needTP then
            local maxTP = GetTensionMax()
            for _, v in pairs(Cache.TensionBars) do
                rawset(v, "Apparent", maxTP)
                rawset(v, "Current", maxTP)
            end
            for _, v in pairs(Cache.TensionTables) do
                local tmax = rawget(v, "TensionMax") or maxTP
                rawset(v, "Tension", tmax)
            end
        end

        if needGod then
            for _, v in pairs(Cache.SoulTables) do
                rawset(v, "Invuln", 999)
                if rawget(v, "MaxHP") ~= nil then
                    rawset(v, "HP", v.MaxHP)
                end
                if rawget(v, "GrazeCount") ~= nil then
                    rawset(v, "GrazeCount", 9999)
                end
            end
            for _, v in pairs(Cache.HPTables) do
                if rawget(v, "MaxHP") ~= nil then
                    rawset(v, "HP", v.MaxHP)
                end
            end
        elseif needHP then
            for _, v in pairs(Cache.HPTables) do
                if rawget(v, "MaxHP") ~= nil then
                    rawset(v, "HP", v.MaxHP)
                end
            end
        end

        if needClear then
            ClearBulletsNow()
        end

        if needFree then
            for _, v in pairs(Cache.SoulTables) do
                if rawget(v, "Frozen") ~= nil then
                    rawset(v, "Frozen", false)
                end
                if rawget(v, "FreeRoam") ~= nil then
                    rawset(v, "FreeRoam", true)
                end
                if rawget(v, "Locked") ~= nil then
                    rawset(v, "Locked", false)
                end
            end
        end

        if needVisual then
            for _, v in pairs(getgc(true)) do
                if typeof(v) == "table" and rawget(v, "Harmful") == true and type(rawget(v, "Radius")) == "number" then
                    if not rawget(v, "_PinkVisScale") then
                        rawset(v, "_PinkVisScale", true)
                        rawset(v, "Radius", (v.Radius or 4) * 1.75)
                        if type(rawget(v, "Width")) == "number" then
                            rawset(v, "Width", v.Width * 1.75)
                        end
                        if type(rawget(v, "Height")) == "number" then
                            rawset(v, "Height", v.Height * 1.75)
                        end
                    end
                end
            end
        end
    end)
end)

local Window = WindUI:CreateWindow({
    Title = "Deltarune | Pink's",
    Icon = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/Bomb.png",
    Folder = "DeltarunePinks",
    Size = UDim2.fromOffset(IsMobile and 480 or 640, IsMobile and 420 or 500),
    MinSize = Vector2.new(IsMobile and 360 or 520, IsMobile and 300 or 360),
    MaxSize = Vector2.new(950, 700),
    ToggleKey = Enum.KeyCode.LeftShift,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = IsMobile and 180 or 220,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    OpenButton = {
        Title = "Pink's",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = IsMobile and 1.25 or 1.15,
    },
    User = {
        Enabled = true,
        Anonymous = true,
    },
})

pcall(function()
    Window:Tag({
        Title = "2.2.4",
        Icon = "github",
        Color = Orange,
        Border = true,
    })
end)

local MainSection     = Window:Section({ Title = "Main", Opened = true })
local FightSection    = Window:Section({ Title = "Fight", Opened = true })
local SettingsSection = Window:Section({ Title = "Settings", Opened = true })

do
    local Tab = MainSection:Tab({
        Title = "Home",
        Icon = "solar:info-circle-bold",
        IconColor = Orange,
        IconShape = "Square",
        Border = true,
        BorderColor = Orange,
    })

    Tab:Section({ Title = "About" })

    Tab:Paragraph({
        Title = "Support Executors",
        Desc = "Mobile Exploits\n[OK] Delta (deltaexploits.dev) - Main recommendation for mobile. Turn off Verify Teleports if you face rejoining bugs.\n[OK] Codex (codex.lol) - Fully operational and running the UI without issues.\n\nmacOS Exploits\n[OK] Opiumware (opiumware.today) - Top choice selected by the development team.\n[OK] Hydrogen (hydrogen.lat) - 100% stable execution with full features.\n[OK] Macsploit (raptor.fun) - Works perfectly.\n\nWindows Exploits\n[OK] Volt (voltbz.net) - Highly recommended for smooth farm performance.\n[OK] Madium (getmadium.net) - Excellent support for automation functions.\n[OK] Real (realest.gg) - Confirmed working with the entire script framework.\n[OK] Velocity (getvelocity.llc) - Fully compatible with the Script.\n[OK] Potassium (potassium.pro) - Runs the script smoothly.\n[~] Solara (getsolara.dev) - Good keyless alternative; a few premium features might fail due to missing API functions.\n[X] Xeno (xeno.onl) - Extremely unstable and poorly optimized. Skip this one completely.",
    })

    Tab:Space()

    Tab:Paragraph({
        Title = "Supported Games",
        Desc = "[OK] Funhouse\n[OK] Deltarune Fight",
    })

    Tab:Space()

    Tab:Paragraph({
        Title = "Changelog",
        Desc = "omg first realesed this script pls wait Cries",
    })

    Tab:Space()

    Tab:Paragraph({
        Title = "Developers",
        Desc = "Hs (Https), Gh (GourdyHalloway), Nc (Nexocat).",
    })
end

do
    local Tab = FightSection:Tab({
        Title = "Automatic",
        Icon = "solar:restart-bold",
        IconColor = Orange,
        IconShape = "Square",
        Border = true,
        BorderColor = Orange,
    })

    Tab:Section({ Title = "General" })

    Tab:Toggle({
        Title = "TP Infinite",
        Value = false,
        Flag = "TPInfinite",
        Callback = function(state)
            PinksState.TPInfinite = state
            if state then
                RescanCache(true)
                ForceTP(GetTensionMax())
            end
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "TP Max",
        Icon = "zap",
        Callback = function()
            RescanCache(true)
            ForceTP(GetTensionMax())
        end,
    })
    Tab:Space()
    Tab:Input({
        Title = "TP Giver",
        Placeholder = "Amount...",
        Value = "",
        Flag = "TPGiver",
        Callback = function(text)
            PinksState._TPAmount = tonumber(text) or 0
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Give TP",
        Icon = "plus",
        Callback = function()
            RescanCache(true)
            ForceTP(PinksState._TPAmount or 10)
        end,
    })

    Tab:Space()
    Tab:Divider()

    Tab:Toggle({
        Title = "HP Infinite",
        Value = false,
        Flag = "HPInfinite",
        Callback = function(state)
            PinksState.HPInfinite = state
            if state then
                RescanCache(true)
            end
        end,
    })
    Tab:Space()
    Tab:Input({
        Title = "HP Giver",
        Placeholder = "Amount...",
        Value = "",
        Flag = "HPGiver",
        Callback = function(text)
            PinksState._HPAmount = tonumber(text) or 0
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Give HP",
        Icon = "plus",
        Callback = function()
            local amount = PinksState._HPAmount or 0
            if amount <= 0 then
                return
            end
            RescanCache(true)
            pcall(function()
                for _, v in pairs(Cache.HPTables) do
                    if type(rawget(v, "HP")) == "number" and type(rawget(v, "MaxHP")) == "number" then
                        rawset(v, "HP", math.min(v.HP + amount, v.MaxHP))
                    end
                end
            end)
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Heal Party",
        Icon = "heart-pulse",
        Color = Green,
        Callback = function()
            RescanCache(true)
            pcall(function()
                for _, v in pairs(Cache.HPTables) do
                    if rawget(v, "MaxHP") ~= nil then
                        rawset(v, "HP", v.MaxHP)
                        if rawget(v, "Down") == true then
                            rawset(v, "Down", false)
                        end
                        if rawget(v, "Swooned") == true then
                            rawset(v, "Swooned", false)
                        end
                    end
                end
            end)
        end,
    })
    Tab:Space()
    Tab:Toggle({
        Title = "God-Mode",
        Value = false,
        Flag = "GodMode",
        Callback = function(state)
            PinksState.GodMode = state
            ApplyGodMode(state)
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Max Mercy",
        Icon = "heart",
        Color = Green,
        Callback = function()
            MaxMercyNow()
        end,
    })
    Tab:Space()
    Tab:Toggle({
        Title = "Free Soul",
        Value = false,
        Flag = "FreeSoul",
        Callback = function(state)
            PinksState.FreeSoulToggle = state
            ApplyFreeSoul(state)
        end,
    })

    Tab:Space()
    Tab:Divider()

    Tab:Section({ Title = "Fight" })

    Tab:Button({
        Title = "Instant Complete Fight",
        Icon = "check-circle",
        Color = Green,
        Callback = function()
            InstantWinNow()
        end,
    })
    Tab:Space()
    Tab:Toggle({
        Title = "Delete Stinky Attacks Enemy",
        Value = false,
        Flag = "DeleteStinkyAttacks",
        Callback = function(state)
            PinksState.DeleteStinky = state
            if state then
                RescanCache(true)
                ClearBulletsNow()
            end
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Skip Enemys Turn",
        Icon = "skip-forward",
        Callback = function()
            SkipEnemyTurnNow()
        end,
    })
    Tab:Space()
    Tab:Toggle({
        Title = "Visual Hitbox",
        Value = false,
        Flag = "VisualHitbox",
        Callback = function(state)
            PinksState.VisualHitbox = state
            SetVisualHitboxes(state)
        end,
    })
end

do
    local Tab = SettingsSection:Tab({
        Title = "Settings",
        Icon = "solar:settings-bold",
        IconColor = Orange,
        IconShape = "Square",
        Border = true,
        BorderColor = Orange,
    })

    Tab:Section({ Title = "Saves" })

    Tab:Input({
        Title = "Name",
        Placeholder = "Config name...",
        Value = "Default",
        Flag = "ConfigName",
        Callback = function(text)
            ConfigNameValue = text
        end,
    })
    Tab:Space()
    Tab:Dropdown({
        Title = "File",
        Values = RefreshConfigList(),
        Value = "Default",
        Flag = "ConfigFile",
        Callback = function(option)
            ConfigNameValue = option
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Save",
        Icon = "save",
        Color = Green,
        Callback = function()
            local name = ConfigNameValue
            if not name or name == "" then
                name = "Default"
            end
            if SaveConfig(name) then
                WindUI:Notify({
                    Title = "Config",
                    Content = "Saved preset: " .. name,
                    Duration = 3,
                    Icon = "check",
                })
            else
                WindUI:Notify({
                    Title = "Config",
                    Content = "Save failed (executor may not support writefile).",
                    Duration = 4,
                    Icon = "x",
                })
            end
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Load",
        Icon = "download",
        Callback = function()
            local name = ConfigNameValue
            if not name or name == "" then
                name = "Default"
            end
            if LoadConfig(name) then
                WindUI:Notify({
                    Title = "Config",
                    Content = "Loaded preset: " .. name,
                    Duration = 3,
                    Icon = "check",
                })
            else
                WindUI:Notify({
                    Title = "Config",
                    Content = "Load failed or preset not found.",
                    Duration = 4,
                    Icon = "x",
                })
            end
        end,
    })
    Tab:Space()
    Tab:Button({
        Title = "Delete",
        Icon = "trash-2",
        Color = Red,
        Callback = function()
            local name = ConfigNameValue
            if not name or name == "" or name == "Default" then
                WindUI:Notify({
                    Title = "Config",
                    Content = "Cannot delete Default / empty name.",
                    Duration = 3,
                    Icon = "x",
                })
                return
            end
            if DeleteConfig(name) then
                WindUI:Notify({
                    Title = "Config",
                    Content = "Deleted preset: " .. name,
                    Duration = 3,
                    Icon = "check",
                })
            end
        end,
    })

    Tab:Space()
    Tab:Divider()

    Tab:Section({ Title = "UI" })

    Tab:Dropdown({
        Title = "Change Color UI",
        Values = { "Dark", "Light", "Rose", "Plant", "Indigo", "Sky", "Violet", "Amber" },
        Value = "Dark",
        Flag = "UIColor",
        Callback = function(theme)
            PinksState.UIColor = theme
            pcall(function()
                WindUI:SetTheme(theme)
            end)
        end,
    })
end
