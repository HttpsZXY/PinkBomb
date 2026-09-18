local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local Me = Players.LocalPlayer
while not Me do task.wait() Me = Players.LocalPlayer end

local FONT = Enum.Font.Code
local ACCENT = Color3.fromRGB(255, 15, 123)
local BG = Color3.fromRGB(16, 16, 20)
local CARD = Color3.fromRGB(24, 24, 30)
local TXT = Color3.fromRGB(235, 235, 240)
local DISCORD = "https://discord.gg/y3cHAw6Bb4"
local GH_ICON = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/Bomb.png"

local function w(...)
	local a = { "[Pink Bomb]", ... }
	pcall(function()
		warn(table.unpack(a))
	end)
end

local function getPG()
	local pg = Me:FindFirstChildOfClass("PlayerGui")
	if pg then return pg end
	local ok, r = pcall(function() return Me:WaitForChild("PlayerGui", 8) end)
	return ok and r or nil
end

local pg = getPG()
if not pg then w("NO PlayerGui - inject after spawn") return end
pcall(function() local o = pg:FindFirstChild("PinkBombFarm") if o then o:Destroy() end end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "PinkBombFarm"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 100
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = pg

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 440)
Main.Position = UDim2.new(0.5, -160, 0.5, -220)
Main.BackgroundColor3 = BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke")
stroke.Color = ACCENT stroke.Thickness = 2 stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 0, 26)
Title.Position = UDim2.new(0, 10, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "PINK BOMB // BRING"
Title.TextColor3 = ACCENT
Title.Font = FONT
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 26, 0, 26)
Close.Position = UDim2.new(1, -32, 0, 6)
Close.BackgroundColor3 = CARD
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 100, 100)
Close.Font = FONT
Close.TextSize = 13
Close.Parent = Main
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
Close.MouseButton1Click:Connect(function()
	pcall(function() _G.PinkBombRunning = false end)
	Gui:Destroy()
end)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 20)
Status.Position = UDim2.new(0, 8, 0, 34)
Status.BackgroundTransparency = 1
Status.Text = "Idle"
Status.TextColor3 = Color3.fromRGB(180, 180, 190)
Status.Font = FONT
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -12, 0, 28)
TabBar.Position = UDim2.new(0, 6, 0, 56)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local pages = {}
local function makePage()
	local s = Instance.new("ScrollingFrame")
	s.Size = UDim2.new(1, -12, 1, -92)
	s.Position = UDim2.new(0, 6, 0, 88)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 3
	s.Visible = false
	s.CanvasSize = UDim2.new(0, 0, 0, 400)
	s.Parent = Main
	return s
end
local PageFarm = makePage()
local PageLogs = makePage()
local PageFeed = makePage()
local PageCfg = makePage()
PageFarm.Visible = true

local function selectTab(name)
	PageFarm.Visible = name == "farm"
	PageLogs.Visible = name == "logs"
	PageFeed.Visible = name == "feed"
	PageCfg.Visible = name == "cfg"
end

local function makeTab(text, x, name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 72, 1, 0)
	b.Position = UDim2.new(0, x, 0, 0)
	b.BackgroundColor3 = CARD
	b.Text = text
	b.TextColor3 = TXT
	b.Font = FONT
	b.TextSize = 11
	b.Parent = TabBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(function() selectTab(name) end)
	return b
end
makeTab("Farm", 0, "farm")
makeTab("Logs", 76, "logs")
makeTab("Feed", 152, "feed")
makeTab("Cfg", 228, "cfg")

w("UI online parent=", pg.Name)

local CharState = {}
local function refreshChar(c)
	c = c or Me.Character
	CharState.Character = c
	CharState.Humanoid = c and c:FindFirstChildOfClass("Humanoid")
	CharState.Root = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end
refreshChar(Me.Character)
Me.CharacterAdded:Connect(function(c) task.wait(0.12) refreshChar(c) end)
Me.CharacterRemoving:Connect(function() CharState.Character, CharState.Humanoid, CharState.Root = nil, nil, nil end)

local function Char()
	local c = Me.Character
	if c ~= CharState.Character then refreshChar(c) end
	return CharState.Character
end
local function Hum()
	local c = Char()
	if not c then return nil end
	if not CharState.Humanoid or CharState.Humanoid.Parent ~= c then
		CharState.Humanoid = c:FindFirstChildOfClass("Humanoid")
	end
	return CharState.Humanoid
end
local function Root()
	local c = Char()
	if not c then return nil end
	if not CharState.Root or CharState.Root.Parent ~= c then
		CharState.Root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
	end
	return CharState.Root
end
local function Hearts()
	local c = Char()
	return c and (tonumber(c:GetAttribute("hearts")) or 0) or 0
end
local function Alive()
	local c = Char()
	if not c or not Root() then return false end
	local h = Hum()
	if h and h.Health <= 0 and Hearts() <= 0 then return false end
	if Me:GetAttribute("IsDead") == true and Hearts() <= 0 then return false end
	return true
end

local remCache = {}
local function Remote(name)
	if remCache[name] and remCache[name].Parent then return remCache[name] end
	local r = RS:FindFirstChild(name)
	if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction") or r:IsA("BindableEvent") or r:IsA("BindableFunction")) then
		remCache[name] = r
		return r
	end
end

local function FireAny(inst, ...)
	if not inst then return end
	local args = { ... }
	pcall(function()
		if inst:IsA("RemoteEvent") then
			inst:FireServer(table.unpack(args))
		elseif inst:IsA("BindableEvent") then
			inst:Fire(table.unpack(args))
		elseif inst:IsA("RemoteFunction") then
			inst:InvokeServer(table.unpack(args))
		elseif inst:IsA("BindableFunction") then
			inst:Invoke(table.unpack(args))
		end
	end)
end

local function Part(o)
	if not o then return end
	if o:IsA("BasePart") then return o end
	if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart") or o:FindFirstChildWhichIsA("BasePart", true) end
	return o:FindFirstChildWhichIsA("BasePart", true)
end

local function SoftTP(pos)
	local r = Root()
	if not r or not pos then return false end
	pcall(function()
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		r.CFrame = CFrame.new(pos)
	end)
	return true
end

local S = {
	mode = "Bring", running = false, safeDist = 38, wallCheck = true, camLock = true,
	farmDelay = 0.4, taskWait = 0.08, godOn = false, godArmed = true, chased = false,
	pauseFarm = false, antiDebuff = true, blockAlerts = true, stamina = true, skipBusy = true,
	antiAfk = true, autoBestCard = true, autoRejoin = false, anonymous = true, webhookUrl = "",
	floors = 0, lastFloor = 0, status = "Idle", timerStart = 0, timerActive = false,
	loadGrace = 0, coreySideDone = 0, _bossPauseAt = nil, _whSent = {},
}
local FloorLogs = {}
local currentSnap = { cryptids = {}, items = {}, machines = {}, t0 = 0, floor = nil }
local COREY_SIDE_MAX = 3
local ExitPart
local requeue = {}

local function IsDone(o)
	if not o then return true end
	local a = o:GetAttribute("Activated") or o:GetAttribute("Done") or o:GetAttribute("Completed")
	if a == true or a == 1 then return true end
	local prog = tonumber(o:GetAttribute("Progress") or o:GetAttribute("HowMuch"))
	if prog and prog >= 100 then return true end
	return false
end

local function machineRoot(o)
	local cur = o
	while cur and cur.Parent and cur.Parent ~= Workspace do
		if cur:IsA("Model") then return cur end
		cur = cur.Parent
	end
	return o
end

local function GetMachines()
	local out, seen = {}, {}
	local function push(tag, typeName, o)
		local root = machineRoot(o) or o
		if not root or seen[root] then return end
		seen[root] = true
		local p = Part(root)
		local pos = p and p.Position
		local look = p and p.CFrame.LookVector
		table.insert(out, {
			Instance = root, Tagged = o, Type = typeName, Tag = tag,
			Done = IsDone(root) or IsDone(o), Position = pos,
			Front = pos and look and (pos + look * 4 + Vector3.new(0, 2, 0)) or pos,
			Name = root.Name,
		})
	end
	pcall(function()
		for _, o in ipairs(CS:GetTagged("ArcadeMachine")) do push("ArcadeMachine", "Arcade", o) end
		for _, o in ipairs(CS:GetTagged("StorageMachine")) do push("StorageMachine", "Storage", o) end
		for _, o in ipairs(CS:GetTagged("CoreyMachine")) do push("CoreyMachine", "Corey", o) end
	end)
	local hasA, hasS, hasC = false, false, false
	for _, m in ipairs(out) do
		if m.Type == "Arcade" then hasA = true
		elseif m.Type == "Storage" then hasS = true
		elseif m.Type == "Corey" then hasC = true end
	end
	if not (hasA and hasS and hasC) then
		local function walk(node, depth)
			if depth > 5 or not node then return end
			for _, c in ipairs(node:GetChildren()) do
				if c:IsA("Model") then
					local low = string.lower(c.Name)
					if not hasC and low:find("corey", 1, true) and low:find("machine", 1, true) then push("CoreyMachine", "Corey", c)
					elseif not hasA and (low:find("arcade", 1, true) or low:find("arcane", 1, true)) then push("ArcadeMachine", "Arcade", c)
					elseif not hasS and low:find("storage", 1, true) then push("StorageMachine", "Storage", c) end
					walk(c, depth + 1)
				end
			end
		end
		walk(Workspace, 0)
	end
	return out
end

local function FireComplete(tag, machine)
	if not machine then return end
	if tag == "ArcadeMachine" or tag == "Arcade" then
		FireAny(Remote("ArcadeMachineUse"), machine, "complete")
		FireAny(Remote("ArcadeMachineUse"), machine)
		FireAny(Remote("ArcadeForceComplete"), machine)
		FireAny(Remote("ArcadeForceComplete"), machine, true)
		FireAny(Remote("ArcadeForceComplete"))
	elseif tag == "CoreyMachine" or tag == "Corey" then
		FireAny(Remote("StorageMachineUse"), machine, "complete")
		FireAny(Remote("StorageMachineUse"), machine)
		FireAny(Remote("CoreyTreeComplete"), machine)
		FireAny(Remote("CoreyTreeComplete"))
		FireAny(Remote("ArcadeForceComplete"), machine)
		FireAny(Remote("ArcadeForceComplete"))
	else
		FireAny(Remote("StorageMachineUse"), machine, "complete")
		FireAny(Remote("StorageMachineUse"), machine)
		FireAny(Remote("ArcadeForceComplete"), machine)
		FireAny(Remote("ArcadeForceComplete"))
	end
end

local function FirePrompt(obj)
	if not obj then return end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			pcall(function()
				d.MaxActivationDistance = 50
				d.RequiresLineOfSight = false
				d.Enabled = true
				if fireproximityprompt then
					fireproximityprompt(d)
					pcall(function() fireproximityprompt(d, true) end)
				else
					d:InputHoldBegin()
					task.wait(math.max(0.03, (d.HoldDuration or 0.1) * 0.35))
					d:InputHoldEnd()
				end
			end)
		end
	end
end

local function ForceRelease()
	FireAny(Remote("ForceReleaseAll"))
	FireAny(Remote("ForceReleaseAll"), true)
	FireAny(Remote("ForceReleaseAll"), Me)
end

local function InCoreyZone()
	local cm = RS:FindFirstChild("CurrentMap")
	if cm and cm:IsA("ValueBase") and string.lower(tostring(cm.Value)):find("corey", 1, true) then return true end
	local pgui = Me:FindFirstChild("PlayerGui")
	if pgui then
		for _, n in ipairs({ "Corey", "BossIntro", "CoreyTablet" }) do
			local cg = pgui:FindFirstChild(n)
			if cg and cg:IsA("ScreenGui") and cg.Enabled then return true end
		end
	end
	local ok, tagged = pcall(function() return CS:GetTagged("CoreyMachine") end)
	if ok and tagged then
		for _, o in ipairs(tagged) do
			if o and o.Parent then return true end
		end
	end
	return false
end

local function IsLoading()
	local pgui = Me:FindFirstChild("PlayerGui")
	if not pgui then return true end
	for _, g in ipairs(pgui:GetChildren()) do
		if g:IsA("ScreenGui") and g.Enabled then
			local n = string.lower(g.Name)
			if n:find("load", 1, true) or g.Name == "Loading" then return true end
		end
	end
	return false
end

local function InIntermission()
	local inter = RS:FindFirstChild("Intermission")
	if inter and inter:IsA("NumberValue") and inter.Value > 0 then return true end
	local hs = RS:FindFirstChild("HazardState")
	if hs and tostring(hs.Value) == "Intermission" then return true end
	local gs = RS:FindFirstChild("Gamestate")
	if gs and tostring(gs.Value) == "Intermission" then return true end
	return false
end

local function MapReady()
	if IsLoading() or InIntermission() then return false end
	if not Root() or not Alive() then return false end
	for _, m in ipairs(GetMachines()) do
		if m.Instance and m.Instance.Parent then return true end
	end
	return false
end

local function ReadFloor()
	local area = RS:FindFirstChild("Area")
	if area and area:IsA("ValueBase") then
		local n = tonumber(area.Value) or tonumber(tostring(area.Value):match("%d+"))
		if n and n > 0 then return n end
	end
	local rn = RS:FindFirstChild("RoundNumber")
	if rn and rn:IsA("NumberValue") and rn.Value > 0 then return rn.Value end
	return S.lastFloor
end

local function SafeSpot()
	local map = Workspace:FindFirstChild("IntermissionMapYes")
	if map then
		for _, n in ipairs({ "SpawnLocation", "Spawn", "Safeteleporter" }) do
			local p = map:FindFirstChild(n)
			if p then local bp = Part(p) if bp then return bp.Position + Vector3.new(0, 3, 0) end end
		end
	end
	local wr = Workspace:FindFirstChild("WaitingForNextAreaRoom")
	if wr then
		local s = wr:FindFirstChild("Safeteleporter")
		if s then local bp = Part(s) if bp then return bp.Position + Vector3.new(0, 3, 0) end end
	end
end

local function GoSafe()
	local root = Root()
	local wr = Workspace:FindFirstChild("WaitingForNextAreaRoom")
	if root and wr then
		local ground = wr:FindFirstChild("Ground")
		if ground and ground:IsA("BasePart") and (root.Position - ground.Position).Magnitude < 150 then
			return false
		end
	end
	local inter = RS:FindFirstChild("Intermission")
	if inter and inter:IsA("NumberValue") and inter.Value > 0 then return false end
	local p = SafeSpot()
	if p then SoftTP(p) return true end
	return false
end

local function CryptidNear(pos, dist)
	if not pos then return false end
	local function isCryptid(m)
		local n = string.lower(m.Name)
		if n:find("cryptid", 1, true) or n:find("entity", 1, true) or n:find("snuggle", 1, true)
			or n:find("triplet", 1, true) or n:find("freddie", 1, true) or n:find("grinwell", 1, true) then
			return true
		end
		return CS:HasTag(m, "Cryptid") or CS:HasTag(m, "Entity")
	end
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") and m ~= Char() and isCryptid(m) then
			local p = Part(m)
			if p and (p.Position - pos).Magnitude <= dist then return true end
		end
	end
	return false
end

pcall(function()
	local r = Remote("RoundEnderReady")
	if r and r:IsA("RemoteEvent") then
		r.OnClientEvent:Connect(function(part)
			if typeof(part) == "Instance" then
				local t = part:FindFirstChild("TouchInterest", true) or part:FindFirstChildWhichIsA("TouchTransmitter", true)
				ExitPart = (t and t.Parent and t.Parent:IsA("BasePart") and t.Parent) or Part(part) or part
			end
		end)
	end
end)

local function FindExit()
	if ExitPart and ExitPart.Parent then return ExitPart end
	for _, name in ipairs({ "RoundEnder", "Exit", "Escape" }) do
		local o = Workspace:FindFirstChild(name, true)
		if o then
			local t = o:FindFirstChild("TouchInterest", true) or o:FindFirstChildWhichIsA("TouchTransmitter", true)
			if t and t.Parent and t.Parent:IsA("BasePart") then return t.Parent end
		end
	end
end

local function GoExit()
	local e = FindExit()
	if not e then return false end
	SoftTP(e.Position + Vector3.new(0, 3, 0))
	task.wait(0.05)
	SoftTP(e.Position + Vector3.new(0, 1, 0))
	return true
end

local function displayName()
	if S.anonymous then return "Anonymous" end
	local nick = Me.DisplayName
	if nick and nick ~= "" then return nick end
	return Me.Name or "Player"
end

local function fmtTime(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

local function sendWebhook(content)
	if not S.webhookUrl or S.webhookUrl == "" then return false end
	local body = HttpService:JSONEncode({
		username = "Pink Bomb Farm",
		avatar_url = GH_ICON,
		content = content,
	})
	return pcall(function()
		if request then
			request({ Url = S.webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		elseif http_request then
			http_request({ Url = S.webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		elseif syn and syn.request then
			syn.request({ Url = S.webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		else
			HttpService:PostAsync(S.webhookUrl, body)
		end
	end)
end

local function formatFloorEmbed(entry)
	return table.concat({
		"**" .. displayName() .. "** floor info:",
		string.format("Floor: **%s** | Time: **%s** | Mode: **%s**", tostring(entry.floor), fmtTime(entry.time), entry.mode or S.mode),
		"Cryptids: " .. (entry.cryptids ~= "" and entry.cryptids or "-"),
		"Items: " .. (entry.items ~= "" and entry.items or "-"),
		"Machines: " .. (entry.machines ~= "" and entry.machines or "-"),
	}, "\n")
end

local function collectNames(patterns)
	local names, seen = {}, {}
	for _, m in ipairs(Workspace:GetDescendants()) do
		if m:IsA("Model") then
			local low = string.lower(m.Name)
			for _, p in ipairs(patterns) do
				if low:find(p, 1, true) and not seen[m.Name] then
					seen[m.Name] = true
					table.insert(names, m.Name)
					break
				end
			end
		end
	end
	return names
end

local function scanFloorSnap(forceFloor)
	local cryptids = collectNames({ "cryptid", "snuggle", "triplet", "grinwell", "freddie", "entity" })
	local items = collectNames({ "item", "remnant", "pickup", "loot" })
	local machines = {}
	for _, m in ipairs(GetMachines()) do
		table.insert(machines, (m.Type or "?") .. ":" .. (m.Name or "?"))
	end
	if #cryptids > 0 then currentSnap.cryptids = cryptids end
	if #items > 0 then currentSnap.items = items end
	if #machines > 0 then currentSnap.machines = machines end
	if currentSnap.t0 == 0 then currentSnap.t0 = os.clock() end
	currentSnap.floor = forceFloor or ReadFloor() or currentSnap.floor
end

local function commitFloorLog()
	local floor = currentSnap.floor or ReadFloor() or S.lastFloor or 0
	local elapsed = currentSnap.t0 > 0 and math.floor(os.clock() - currentSnap.t0) or 0
	local entry = {
		floor = floor,
		cryptids = table.concat(currentSnap.cryptids or {}, ", "),
		items = table.concat(currentSnap.items or {}, ", "),
		machines = table.concat(currentSnap.machines or {}, ", "),
		time = elapsed,
		mode = S.mode,
	}
	if entry.cryptids == "" then entry.cryptids = "-" end
	if entry.items == "" then entry.items = "-" end
	if entry.machines == "" then entry.machines = "-" end
	local replaced = false
	for i, e in ipairs(FloorLogs) do
		if e.floor == floor then
			if entry.cryptids == "-" and e.cryptids ~= "-" then entry.cryptids = e.cryptids end
			if entry.items == "-" and e.items ~= "-" then entry.items = e.items end
			if entry.machines == "-" and e.machines ~= "-" then entry.machines = e.machines end
			FloorLogs[i] = entry
			replaced = true
			break
		end
	end
	if not replaced then table.insert(FloorLogs, entry) end
	if S.webhookUrl and S.webhookUrl ~= "" then
		S._whSent = S._whSent or {}
		local key = tostring(entry.floor)
		if not S._whSent[key] then
			S._whSent[key] = true
			task.spawn(function() sendWebhook(formatFloorEmbed(entry)) end)
		end
	end
	currentSnap = { cryptids = {}, items = {}, machines = {}, t0 = 0, floor = nil }
end

local function connectAny(inst, fn)
	if not inst then return end
	pcall(function()
		if inst:IsA("RemoteEvent") then inst.OnClientEvent:Connect(fn)
		elseif inst:IsA("BindableEvent") then inst.Event:Connect(fn) end
	end)
end

pcall(function()
	connectAny(Remote("ArcadeMachineInterrupt"), function(m) if m then requeue[m] = "ArcadeMachine" end end)
	connectAny(Remote("StorageMachineInterrupt"), function(m) if m then requeue[m] = "StorageMachine" end end)
	connectAny(Remote("CryptidAlertEvent"), function()
		S.chased = true
		task.delay(3.5, function() S.chased = false end)
	end)
	connectAny(Remote("BossIntroEvent"), function()
		S.pauseFarm = true
		S._bossPauseAt = os.clock()
		task.delay(11, function()
			if S.pauseFarm then S.pauseFarm = false S._bossPauseAt = nil end
		end)
	end)
	connectAny(Remote("BossIntroFinished"), function()
		S.pauseFarm = false
		S._bossPauseAt = nil
	end)
	for _, n in ipairs({ "CoreyEndEvent", "CoreyStartEvent", "CoreyChallengeEvent", "CoreyEscapeEvent", "RoundEnderReady", "CoreyTreeComplete" }) do
		connectAny(Remote(n), function()
			S.pauseFarm = false
			S._bossPauseAt = nil
			if n == "CoreyEndEvent" or n == "CoreyEscapeEvent" then S.coreySideDone = 0 end
		end)
	end
end)

pcall(function()
	Me.Idled:Connect(function()
		if not S.antiAfk then return end
		pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
	end)
end)

local function processRequeue()
	for inst, tag in pairs(requeue) do
		if inst and inst.Parent and not IsDone(inst) then
			FirePrompt(inst)
			FireComplete(tag, inst)
			ForceRelease()
		end
		requeue[inst] = nil
	end
end

local function voteBestCard()
	if not S.autoBestCard or not InIntermission() then return end
	local rem = Remote("CardVoteEvent")
	if not rem then return end
	local hp = Hearts()
	local order = {}
	if hp <= 2 then
		for _, c in ipairs({ "HeartPlus", "heartplus", "Heart+", "Hearts", "Heal" }) do table.insert(order, c) end
	end
	for _, c in ipairs({ "TaskLess", "taskless", "Taskless", "Strength", "Vitality", "Lazy", "Stamina", "StaminaBoost", "Endurance", "1", "2", "3" }) do
		table.insert(order, c)
	end
	for _, card in ipairs(order) do
		FireAny(rem, card)
		task.wait(0.03)
	end
end

local function completeMachine(m)
	if not m or not m.Instance then return false end
	local obj = m.Instance
	local tag = m.Tag
	local target = m.Tagged or obj
	for _ = 1, 6 do
		FireComplete(tag, target)
		FireComplete(tag, obj)
		FirePrompt(obj)
		FirePrompt(target)
		task.wait(0.05)
		if IsDone(obj) or IsDone(m.Tagged) then return true end
	end
	ForceRelease()
	task.wait(0.06)
	for _ = 1, 4 do
		FirePrompt(obj)
		FireComplete(tag, target)
		FireComplete(tag, obj)
		task.wait(0.08 + S.taskWait)
		if IsDone(obj) or IsDone(m.Tagged) then return true end
	end
	ForceRelease()
	FireComplete(tag, target)
	FireComplete(tag, obj)
	FirePrompt(obj)
	task.wait(0.1)
	return IsDone(obj) or IsDone(m.Tagged)
end

local function tryGodMode()
	if not S.godArmed or Hearts() ~= 1 or S.godOn then return end
	S.godOn = true
	pcall(function() local h = Hum() if h then h.Health = 0 end end)
	task.wait(0.28)
	pcall(function() Me:LoadCharacter() end)
	task.wait(0.35)
	for _, n in ipairs({ "MorphComplete", "MorphRendered", "MorphsDone" }) do
		local r = RS:FindFirstChild(n)
		if r then pcall(function() r:Destroy() end) end
	end
	task.wait(0.15)
	refreshChar(Me.Character)
end

local function onFloorChange(newFloor)
	if S.lastFloor and S.lastFloor > 0 and newFloor ~= S.lastFloor then
		commitFloorLog()
		if newFloor > S.lastFloor then
			S.floors = S.floors + (newFloor - S.lastFloor)
		end
	end
	S.lastFloor = newFloor
	S.godOn = false
	S.pauseFarm = false
	S._bossPauseAt = nil
	S.coreySideDone = 0
	S.loadGrace = os.clock() + 4.5
	if newFloor <= 1 then S._whSent = {} end
	task.delay(0.8, function() scanFloorSnap(newFloor) end)
	task.delay(2.2, function() scanFloorSnap(newFloor) end)
	task.delay(5, function() scanFloorSnap(newFloor) end)
	task.delay(8, function() scanFloorSnap(newFloor) end)
end

local function syncFloor()
	local f = ReadFloor()
	if f and f ~= S.lastFloor then onFloorChange(f) end
end

local function pickMachine()
	local machines = GetMachines()
	local corey = InCoreyZone()
	if not corey then
		S.coreySideDone = 0
		local best, bestDist
		local root = Root()
		local rp = root and root.Position
		for _, m in ipairs(machines) do
			if not m.Done and (S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist)) then
				if not rp or not m.Position then return m end
				local d = (m.Position - rp).Magnitude
				if not bestDist or d < bestDist then best, bestDist = m, d end
			end
		end
		return best
	end
	if (S.coreySideDone or 0) < COREY_SIDE_MAX then
		for _, m in ipairs(machines) do
			if not m.Done and (m.Type == "Storage" or m.Type == "Arcade") then
				if S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist) then return m end
			end
		end
	end
	for _, m in ipairs(machines) do
		if not m.Done and m.Type == "Corey" then
			if S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist) then return m end
		end
	end
	for _, m in ipairs(machines) do
		if not m.Done and (m.Type == "Storage" or m.Type == "Arcade") then
			if S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist) then return m end
		end
	end
end

local function forceBring(obj, dest)
	if not obj or not dest then return end
	local root = machineRoot(obj) or obj
	pcall(function()
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.AssemblyLinearVelocity = Vector3.zero
			end
		end
		local target = Vector3.new(dest.X, dest.Y + 3.5, dest.Z + 5)
		if root:IsA("Model") then
			root:PivotTo(CFrame.new(target))
		else
			local p = Part(root)
			if p then p.CFrame = CFrame.new(target) end
		end
	end)
end

local function doMachine(target)
	if not target or not target.Front then return end
	S.status = (InCoreyZone() and "Corey " or "") .. (target.Type or "Machine")
	local corey = InCoreyZone()
	if S.mode == "Bring" and not corey then
		local safe = SafeSpot()
		if safe then
			SoftTP(safe)
			task.wait(0.08)
			forceBring(target.Instance, safe)
			task.wait(0.08)
			forceBring(target.Instance, safe)
			SoftTP(safe + Vector3.new(0, 2, 2.5))
		else
			SoftTP(target.Front)
		end
	else
		SoftTP(target.Front)
		task.wait(0.04)
		SoftTP(target.Front + Vector3.new(0, 1, 0))
	end
	task.wait(0.08 + S.taskWait)
	if S.camLock and target.Position then
		pcall(function()
			local cam = Workspace.CurrentCamera
			if cam then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, target.Position) end
		end)
	end
	local ok = completeMachine(target)
	if not ok then
		ForceRelease()
		FirePrompt(target.Instance)
		FireComplete(target.Tag, target.Tagged or target.Instance)
		task.wait(0.1)
		ok = IsDone(target.Instance) or IsDone(target.Tagged)
	end
	if ok and corey and (target.Type == "Arcade" or target.Type == "Storage") then
		S.coreySideDone = (S.coreySideDone or 0) + 1
	end
end

local function antiDebuffTick()
	if not S.antiDebuff then return end
	for _, n in ipairs({ "Banana", "Butter", "Puddle", "FreddiePuddle" }) do
		local o = Workspace:FindFirstChild(n)
		if o then
			for _, d in ipairs(o:GetDescendants()) do
				if d.Name == "TouchInterest" or d:IsA("TouchTransmitter") then
					pcall(function() d:Destroy() end)
				end
			end
		end
	end
end

local function staminaTick()
	if not S.stamina then return end
	FireAny(Remote("StaminaBoostEvent"))
	local c = Char()
	if c then
		pcall(function()
			c:SetAttribute("Stamina", 100)
			c:SetAttribute("stamina", 100)
			c:SetAttribute("MaxStamina", 100)
		end)
	end
	local h = Hum()
	if h then pcall(function() h:SetAttribute("Stamina", 100) end) end
end

local function busyTick()
	if not S.skipBusy then return end
	local c = Char()
	if c then
		pcall(function()
			c:SetAttribute("busysorry", 0)
			c:SetAttribute("Busy", false)
			c:SetAttribute("busy", false)
		end)
	end
end

local function blockAlertsTick()
	if not S.blockAlerts then return end
	for _, n in ipairs({ "TripletAlert", "SnugglesAlert" }) do
		local r = RS:FindFirstChild(n)
		if r then pcall(function() r:Destroy() end) end
	end
end

local function farmOnce()
	if not Alive() then
		S.status = "Dead"
		if S.autoRejoin then
			pcall(function() TeleportService:Teleport(game.PlaceId, Me) end)
		end
		return
	end
	if S.pauseFarm then
		local age = S._bossPauseAt and (os.clock() - S._bossPauseAt) or 99
		if age > 10 or (not IsLoading() and MapReady() and age > 4) then
			S.pauseFarm = false
			S._bossPauseAt = nil
		else
			S.status = "Boss Intro"
			return
		end
	end
	if IsLoading() then S.status = "Loading" GoSafe() return end
	if InIntermission() then S.status = "Intermission" voteBestCard() return end
	if S.loadGrace > 0 and os.clock() < S.loadGrace then S.status = "Loading Map" GoSafe() return end
	if not MapReady() then
		S.status = "Loading Map"
		S.loadGrace = os.clock() + 2
		GoSafe()
		return
	end

	syncFloor()
	if currentSnap.t0 == 0 then scanFloorSnap() end
	tryGodMode()
	processRequeue()
	antiDebuffTick()
	staminaTick()
	busyTick()
	blockAlertsTick()

	local root = Root()
	if not root then return end
	if (S.chased or CryptidNear(root.Position, S.safeDist)) and not S.godOn then
		S.status = "Fleeing"
		GoSafe()
		task.wait(0.6)
		return
	end

	local target = pickMachine()
	if target then
		doMachine(target)
		return
	end

	local pending = 0
	for _, m in ipairs(GetMachines()) do
		if not m.Done then pending = pending + 1 end
	end
	if pending == 0 then
		S.status = "Exit"
		if GoExit() then
			syncFloor()
			task.wait(1.2)
		else
			S.status = "Waiting Exit"
		end
	else
		S.status = "Waiting Safe"
		if not S.godOn then GoSafe() end
	end
end

local function setStatus()
	local floor = S.lastFloor
	if not floor or floor <= 0 then floor = ReadFloor() end
	local live = ReadFloor()
	if live and live > 0 then
		if live ~= S.lastFloor then syncFloor() end
		floor = live
	end
	local runT = S.timerActive and S.timerStart > 0 and (os.clock() - S.timerStart) or 0
	Status.Text = string.format("%s | Floors:%s Floor:%s HP:%s God:%s %s",
		tostring(S.status), tostring(S.floors), tostring(floor or "-"),
		tostring(Hearts()), S.godOn and "ON" or "off", fmtTime(runT))
end

local function toast(title, msg)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 240, 0, 48)
	f.Position = UDim2.new(1, -250, 1, 10)
	f.BackgroundColor3 = CARD
	f.Parent = Gui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -10, 0, 16)
	t.Position = UDim2.new(0, 6, 0, 4)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = ACCENT
	t.Font = FONT
	t.TextSize = 12
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = f
	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(1, -10, 0, 18)
	b.Position = UDim2.new(0, 6, 0, 22)
	b.BackgroundTransparency = 1
	b.Text = msg
	b.TextColor3 = TXT
	b.Font = FONT
	b.TextSize = 11
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = f
	TweenService:Create(f, TweenInfo.new(0.25), { Position = UDim2.new(1, -250, 1, -58) }):Play()
	task.delay(2.2, function() pcall(function() f:Destroy() end) end)
end

local function addToggle(parent, y, text, default, cb)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 30)
	row.Position = UDim2.new(0, 0, 0, y)
	row.BackgroundColor3 = CARD
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -44, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = TXT
	lbl.Font = FONT
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	local ind = Instance.new("Frame")
	ind.Size = UDim2.new(0, 12, 0, 12)
	ind.Position = UDim2.new(1, -24, 0.5, -6)
	ind.BackgroundColor3 = default and Color3.fromRGB(60, 255, 100) or Color3.fromRGB(255, 60, 60)
	ind.Parent = row
	Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
	local state = default
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = row
	btn.MouseButton1Click:Connect(function()
		state = not state
		ind.BackgroundColor3 = state and Color3.fromRGB(60, 255, 100) or Color3.fromRGB(255, 60, 60)
		cb(state)
	end)
	return y + 34
end

local function addBtn(parent, y, text, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, 32)
	b.Position = UDim2.new(0, 0, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(20, 20, 20)
	b.Font = FONT
	b.TextSize = 12
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(cb)
	return y + 36
end

local function addInput(parent, y, ph, cb)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -4, 0, 30)
	box.Position = UDim2.new(0, 0, 0, y)
	box.BackgroundColor3 = CARD
	box.Text = ""
	box.PlaceholderText = ph
	box.TextColor3 = TXT
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
	box.Font = FONT
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.Parent = parent
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	box.FocusLost:Connect(function() cb(box.Text) end)
	return y + 34
end

local function addLabel(parent, y, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -4, 0, 20)
	l.Position = UDim2.new(0, 0, 0, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = ACCENT
	l.Font = FONT
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return y + 22
end

local y = 0
y = addLabel(PageFarm, y, "Core")
y = addBtn(PageFarm, y, "Mode: Bring (tap to switch)", function()
	S.mode = S.mode == "Bring" and "Normal" or "Bring"
	Title.Text = "PINK BOMB // " .. string.upper(S.mode)
	toast("Mode", S.mode)
end)
y = addToggle(PageFarm, y, "Enable Auto-Farm", false, function(v)
	S.running = v
	_G.PinkBombRunning = v
	if v then
		if not S.timerActive then S.timerStart = os.clock() S.timerActive = true end
		S.loadGrace = os.clock() + 2
		scanFloorSnap()
		toast("Farm", S.mode .. " ON")
		task.spawn(function()
			while S.running and Gui.Parent do
				local ok, err = pcall(farmOnce)
				if not ok then
					w("farmOnce error:", err)
					S.status = "ERR"
				end
				setStatus()
				task.wait(S.farmDelay)
			end
			S.status = "Idle"
			setStatus()
		end)
		task.spawn(function()
			while S.running and Gui.Parent do
				local ok, err = pcall(function()
					if S.stamina then staminaTick() end
					if S.skipBusy then busyTick() end
					if S.antiDebuff then antiDebuffTick() end
					if S.blockAlerts then blockAlertsTick() end
				end)
				if not ok then w("support error:", err) end
				task.wait(0.2)
			end
		end)
	else
		toast("Farm", "OFF")
	end
end)
y = addToggle(PageFarm, y, "Auto Best Card", true, function(v) S.autoBestCard = v end)
y = addToggle(PageFarm, y, "God Mode @ 1 Heart", true, function(v) S.godArmed = v end)
y = addToggle(PageFarm, y, "Wall Check Cryptid", true, function(v) S.wallCheck = v end)
y = addToggle(PageFarm, y, "Camera Lock", true, function(v) S.camLock = v end)
y = addLabel(PageFarm, y, "Support")
y = addToggle(PageFarm, y, "Max Stamina", true, function(v) S.stamina = v end)
y = addToggle(PageFarm, y, "Skip Busy Lock", true, function(v) S.skipBusy = v end)
y = addToggle(PageFarm, y, "Anti-Debuff", true, function(v) S.antiDebuff = v end)
y = addToggle(PageFarm, y, "Entity Immunity", true, function(v) S.blockAlerts = v end)
y = addToggle(PageFarm, y, "Anti AFK", true, function(v) S.antiAfk = v end)
y = addToggle(PageFarm, y, "Auto Rejoin on Death", false, function(v) S.autoRejoin = v end)
PageFarm.CanvasSize = UDim2.new(0, 0, 0, y + 16)

local LogDetail = Instance.new("TextLabel")
LogDetail.Size = UDim2.new(1, -4, 0, 100)
LogDetail.Position = UDim2.new(0, 0, 0, 0)
LogDetail.BackgroundColor3 = CARD
LogDetail.TextColor3 = TXT
LogDetail.Font = FONT
LogDetail.TextSize = 11
LogDetail.TextXAlignment = Enum.TextXAlignment.Left
LogDetail.TextYAlignment = Enum.TextYAlignment.Top
LogDetail.TextWrapped = true
LogDetail.Text = "Floor logs appear here after each floor."
LogDetail.Parent = PageLogs
Instance.new("UICorner", LogDetail).CornerRadius = UDim.new(0, 6)
local logPad = Instance.new("UIPadding")
logPad.PaddingLeft = UDim.new(0, 6)
logPad.PaddingTop = UDim.new(0, 6)
logPad.Parent = LogDetail

local logButtons = {}
local function refreshLogUI()
	for _, b in ipairs(logButtons) do pcall(function() b:Destroy() end) end
	logButtons = {}
	local ly = 108
	for i = #FloorLogs, 1, -1 do
		local e = FloorLogs[i]
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 28)
		btn.Position = UDim2.new(0, 0, 0, ly)
		btn.BackgroundColor3 = CARD
		btn.Text = "Floor " .. tostring(e.floor) .. "  " .. fmtTime(e.time)
		btn.TextColor3 = TXT
		btn.Font = FONT
		btn.TextSize = 11
		btn.Parent = PageLogs
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			LogDetail.Text = formatFloorEmbed(e)
		end)
		table.insert(logButtons, btn)
		ly = ly + 32
	end
	PageLogs.CanvasSize = UDim2.new(0, 0, 0, ly + 16)
end

local fy = 0
fy = addLabel(PageFeed, fy, "Discord")
fy = addBtn(PageFeed, fy, "Join Discord (copy invite)", function()
	pcall(function() if setclipboard then setclipboard(DISCORD) end end)
	toast("Discord", "Invite copied")
end)
fy = addLabel(PageFeed, fy, "Webhook")
fy = addToggle(PageFeed, fy, "Anonymous name in logs", true, function(v) S.anonymous = v end)
fy = addInput(PageFeed, fy, "Paste Discord Webhook URL", function(t)
	S.webhookUrl = tostring(t or ""):gsub("%s+", "")
	toast("Webhook", S.webhookUrl ~= "" and "Saved - auto each floor" or "Cleared")
end)
fy = addBtn(PageFeed, fy, "Test Webhook", function()
	if S.webhookUrl == "" then toast("Webhook", "Paste URL first") return end
	local ok = sendWebhook("**" .. displayName() .. "** connected Pink Bomb farm.")
	toast("Webhook", ok and "Sent" or "Failed - check URL/HTTP")
end)
PageFeed.CanvasSize = UDim2.new(0, 0, 0, fy + 16)

local cy = 0
cy = addLabel(PageCfg, cy, "Info")
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -4, 0, 90)
info.Position = UDim2.new(0, 0, 0, cy)
info.BackgroundColor3 = CARD
info.Text = "Loading blocks farm.\nCorey: max 3 Arcade/Storage then Corey only.\nWebhook auto-sends each floor.\nDelta: use GitHub loadstring if paste fails."
info.TextColor3 = Color3.fromRGB(180, 180, 190)
info.Font = FONT
info.TextSize = 11
info.TextWrapped = true
info.Parent = PageCfg
Instance.new("UICorner", info).CornerRadius = UDim.new(0, 6)
cy = cy + 98
cy = addLabel(PageCfg, cy, "Speed")
cy = addToggle(PageCfg, cy, "Faster farm delay (0.35)", false, function(v)
	S.farmDelay = v and 0.35 or 0.45
end)
PageCfg.CanvasSize = UDim2.new(0, 0, 0, cy + 16)

pcall(function()
	local rn = RS:FindFirstChild("RoundNumber")
	if rn and rn:IsA("NumberValue") then
		rn:GetPropertyChangedSignal("Value"):Connect(syncFloor)
	end
	local area = RS:FindFirstChild("Area")
	if area and area:IsA("ValueBase") then
		area:GetPropertyChangedSignal("Value"):Connect(function()
			syncFloor()
			S.loadGrace = os.clock() + 4
		end)
	end
	local cm = RS:FindFirstChild("CurrentMap")
	if cm and cm:IsA("ValueBase") then
		cm:GetPropertyChangedSignal("Value"):Connect(function()
			S.loadGrace = os.clock() + 4
			S.coreySideDone = 0
		end)
	end
end)

task.spawn(function()
	while Gui.Parent do
		setStatus()
		if PageLogs.Visible then refreshLogUI() end
		task.wait(0.45)
	end
end)

toast("Pink Bomb", "UI ready")
w("FULL UI READY mode=", S.mode)
