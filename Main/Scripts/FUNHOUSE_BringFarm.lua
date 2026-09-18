local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local UIS = game:GetService("UserInputService")

local Me = Players.LocalPlayer
while not Me do task.wait() Me = Players.LocalPlayer end

local FONT = Enum.Font.Code
local ACCENT = Color3.fromRGB(255, 15, 123)
local BG = Color3.fromRGB(16, 16, 20)
local CARD = Color3.fromRGB(24, 24, 30)
local TXT = Color3.fromRGB(235, 235, 240)
local DISCORD = "https://discord.gg/y3cHAw6Bb4"
local GH_ICON = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/Bomb.png"
local GH_BG = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/51%20sin%20t%C3%ADtulo_20260916173714.png"
local assetCache = {}
local function loadAsset(url, name)
	if assetCache[url] then return assetCache[url] end
	local data
	pcall(function()
		if request then
			local r = request({ Url = url, Method = "GET" })
			data = r.Body or r.body
		elseif game.HttpGet then
			data = game:HttpGet(url)
		end
	end)
	if type(data) ~= "string" or #data < 64 then
		assetCache[url] = url
		return url
	end
	local fname = "PinkBomb_" .. (name or "img") .. ".png"
	pcall(function() if writefile then writefile(fname, data) end end)
	local asset = url
	pcall(function()
		if getcustomasset then asset = getcustomasset(fname)
		elseif getsynasset then asset = getsynasset(fname)
		elseif syn and syn.getcustomasset then asset = syn.getcustomasset(fname) end
	end)
	assetCache[url] = asset
	return asset
end

local function w(...) end

local connections = {}
local function connect(signal, callback)
	local c = signal:Connect(callback)
	table.insert(connections, c)
	return c
end
local function connectAny(inst, callback)
	if not inst then return end
	pcall(function()
		if inst:IsA("RemoteEvent") then connect(inst.OnClientEvent, callback)
		elseif inst:IsA("BindableEvent") then connect(inst.Event, callback) end
	end)
end

local Gui
local function cleanup()
	pcall(function()
		_G.PinkBombRunning = false
	end)
	for i = #connections, 1, -1 do
		pcall(function() connections[i]:Disconnect() end)
		connections[i] = nil
	end
	if Gui then pcall(function() Gui:Destroy() end) Gui = nil end
end

local function getPG()
	local pg = Me:FindFirstChildOfClass("PlayerGui")
	if pg then return pg end
	local ok, r = pcall(function() return Me:WaitForChild("PlayerGui", 8) end)
	return ok and r or nil
end

local pg = getPG()
if not pg then w("NO PlayerGui - inject after spawn") return end
pcall(function()
	local o = pg:FindFirstChild("PinkBombFarm")
	if o then o:Destroy() end
end)

Gui = Instance.new("ScreenGui")
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

local bgImg = Instance.new("ImageLabel")
bgImg.Size = UDim2.new(1, 0, 1, 0)
bgImg.BackgroundTransparency = 1
bgImg.ImageTransparency = 0.88
bgImg.ScaleType = Enum.ScaleType.Crop
bgImg.ZIndex = 0
bgImg.Parent = Main
Instance.new("UICorner", bgImg).CornerRadius = UDim.new(0, 10)

local iconImg = Instance.new("ImageLabel")
iconImg.Size = UDim2.new(0, 22, 0, 22)
iconImg.Position = UDim2.new(0, 8, 0, 8)
iconImg.BackgroundTransparency = 1
iconImg.ZIndex = 2
iconImg.Parent = Main

task.spawn(function()
	local a = loadAsset(GH_BG, "bg")
	local b = loadAsset(GH_ICON, "icon")
	pcall(function() bgImg.Image = a end)
	pcall(function() iconImg.Image = b end)
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 0, 26)
Title.Position = UDim2.new(0, 34, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "PINK BOMB // BRING"
Title.TextColor3 = ACCENT
Title.Font = FONT
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -62, 0, 6)
MinBtn.BackgroundColor3 = CARD
MinBtn.Text = "-"
MinBtn.TextColor3 = TXT
MinBtn.Font = FONT
MinBtn.TextSize = 16
MinBtn.Parent = Main
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

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
	cleanup()
end)

local minimized = false
local fullSize = Main.Size
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		TabBar.Visible = false
		PageFarm.Visible = false
		PageLogs.Visible = false
		PageFeed.Visible = false
		Status.Visible = false
		Main.Size = UDim2.new(0, 200, 0, 40)
		MinBtn.Text = "+"
	else
		Main.Size = fullSize
		TabBar.Visible = true
		Status.Visible = true
		PageFarm.Visible = true
		PageLogs.Visible = false
		PageFeed.Visible = false
		MinBtn.Text = "-"
	end
end)

do
	local dragging = false
	local dragStart, startPos
	local function beginDrag(input)
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
	local function updateDrag(input)
		if not dragging then return end
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
	Main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)
	Main.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
end

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
PageFarm.Visible = true

local function selectTab(name)
	PageFarm.Visible = name == "farm"
	PageLogs.Visible = name == "logs"
	PageFeed.Visible = name == "feed"
end

local function makeTab(text, x, name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 96, 1, 0)
	b.Position = UDim2.new(0, x, 0, 0)
	b.BackgroundColor3 = CARD
	b.Text = text
	b.TextColor3 = TXT
	b.Font = FONT
	b.TextSize = 11
	b.Parent = TabBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(function() selectTab(name) end)
end
makeTab("Farm", 0, "farm")
makeTab("Logs", 100, "logs")
makeTab("Feed", 200, "feed")


local CharState = {}
local function refreshChar(c)
	c = c or Me.Character
	CharState.Character = c
	CharState.Humanoid = c and c:FindFirstChildOfClass("Humanoid")
	CharState.Root = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end
refreshChar(Me.Character)
connect(Me.CharacterAdded, function(c) task.wait(0.12) refreshChar(c) end)
connect(Me.CharacterRemoving, function()
	CharState.Character, CharState.Humanoid, CharState.Root = nil, nil, nil
end)

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
	if c then
		for _, k in ipairs({ "hearts", "Hearts", "Heart", "heart", "Lives", "lives" }) do
			local v = tonumber(c:GetAttribute(k))
			if v ~= nil then return v end
		end
		local h = c:FindFirstChild("Hearts") or c:FindFirstChild("hearts")
		if h and h:IsA("ValueBase") then
			local v = tonumber(h.Value)
			if v ~= nil then return v end
		end
	end
	for _, k in ipairs({ "hearts", "Hearts", "Heart" }) do
		local v = tonumber(Me:GetAttribute(k))
		if v ~= nil then return v end
	end
	return 0
end
local function Alive()
	local c = Char()
	if not c then return false end
	local r = Root()
	if not r then return false end
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
	if not inst then return false, "missing" end
	local args = { ... }
	local ok, err = pcall(function()
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
	return ok, err
end

local function Part(o)
	if not o then return end
	if o:IsA("BasePart") then return o end
	if o:IsA("Model") then
		return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart") or o:FindFirstChildWhichIsA("BasePart", true)
	end
	return o:FindFirstChildWhichIsA("BasePart", true)
end

local function SoftTP(pos)
	local r = Root()
	if not r or not pos then return false end
	if (r.Position - pos).Magnitude < 4 then
		return true
	end
	local ok = pcall(function()
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		r.CFrame = CFrame.new(pos)
	end)
	return ok
end

local S = {
	mode = "Bring", running = false, safeDist = 38, wallCheck = true, camLock = true,
	farmDelay = 0.42, taskWait = 0.08, godOn = false, godArmed = true, chased = false,
	pauseFarm = false, antiDebuff = true, blockAlerts = true, stamina = true, skipBusy = true,
	antiAfk = true, autoBestCard = true, autoBlood = true, autoRejoin = false, anonymous = true, webhookUrl = "",
	floors = 0, lastFloor = 0, status = "Idle", timerStart = 0, timerActive = false,
	loadGrace = 0, coreySideDone = 0, _bossPauseAt = nil, _whSent = {},
	_stuckKey = nil, _stuckTries = 0, deaths = 0, godUses = 0, mapStartSent = {},
}
local FloorLogs = {}
local currentSnap = { cryptids = {}, items = {}, machines = {}, t0 = 0, floor = nil }
local COREY_SIDE_MAX = 1
local ExitPart
local requeue = {}
local logsDirty = true

local function IsDone(o)
	if not o then return true end
	local a = o:GetAttribute("Activated") or o:GetAttribute("Done") or o:GetAttribute("Completed")
	if a == true or a == 1 then return true end
	local prog = tonumber(o:GetAttribute("Progress") or o:GetAttribute("HowMuch"))
	return prog ~= nil and prog >= 100
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
		FireAny(Remote("ArcadeForceComplete"))
	elseif tag == "CoreyMachine" or tag == "Corey" then
		FireAny(Remote("CoreyTreeComplete"), machine)
		FireAny(Remote("CoreyTreeComplete"), machine, true)
		FireAny(Remote("CoreyTreeComplete"))
		FireAny(Remote("StorageMachineUse"), machine, "complete")
		FireAny(Remote("StorageMachineUse"), machine)
		FireAny(Remote("ArcadeForceComplete"), machine)
		FireAny(Remote("ArcadeForceComplete"))
		FireAny(Remote("ArcadeMachineUse"), machine, "complete")
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
				local oldDist = d.MaxActivationDistance
				local oldLos = d.RequiresLineOfSight
				local oldEn = d.Enabled
				d.MaxActivationDistance = math.max(oldDist, 40)
				d.RequiresLineOfSight = false
				d.Enabled = true
				if fireproximityprompt then
					fireproximityprompt(d)
				else
					local hold = d.HoldDuration or 0
					d:InputHoldBegin()
					task.wait(math.max(0.05, hold > 0 and hold or 0.1))
					d:InputHoldEnd()
				end
				task.defer(function()
					pcall(function()
						d.MaxActivationDistance = oldDist
						d.RequiresLineOfSight = oldLos
						d.Enabled = oldEn
					end)
				end)
			end)
		end
	end
end

local function ForceRelease()
	FireAny(Remote("ForceReleaseAll"))
end

local function InCoreyZone()
	local cm = RS:FindFirstChild("CurrentMap")
	if cm and cm:IsA("ValueBase") then
		local v = string.lower(tostring(cm.Value))
		if v:find("corey", 1, true) then return true end
	end
	local area = RS:FindFirstChild("Area")
	if area and area:IsA("ValueBase") then
		local v = string.lower(tostring(area.Value))
		if v:find("corey", 1, true) then return true end
	end
	local pgui = Me:FindFirstChild("PlayerGui")
	if pgui then
		for _, n in ipairs({ "Corey", "BossIntro", "CoreyTablet", "HELLOTHERE", "REVEAL" }) do
			local cg = pgui:FindFirstChild(n, true)
			if cg then
				if cg:IsA("ScreenGui") and cg.Enabled then return true end
				if cg:IsA("Frame") and cg.Visible then return true end
			end
		end
	end
	local ok, tagged = pcall(function() return CS:GetTagged("CoreyMachine") end)
	if ok and tagged then
		for _, o in ipairs(tagged) do
			if o and o.Parent and not IsDone(o) then return true end
		end
	end
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") then
			local low = string.lower(m.Name)
			if low:find("corey", 1, true) and low:find("machine", 1, true) and not IsDone(m) then
				return true
			end
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

local function IsTutorial()
	local cm = RS:FindFirstChild("CurrentMap")
	if cm and cm:IsA("ValueBase") then
		local v = string.lower(tostring(cm.Value))
		if v:find("tutorial", 1, true) then return true end
	end
	return false
end

local function InIntermission()
	if IsTutorial() then return false end
	local inter = RS:FindFirstChild("Intermission")
	if inter and inter:IsA("ValueBase") then
		local v = tonumber(inter.Value)
		if v and v > 0 then return true end
	end
	local gs = RS:FindFirstChild("Gamestate")
	if gs and tostring(gs.Value) == "Intermission" then return true end
	return false
end


local function TasksRemaining()
	local pgui = Me:FindFirstChild("PlayerGui")
	if not pgui then return nil end
	local function dig(node, depth)
		if depth > 8 or not node then return end
		for _, c in ipairs(node:GetChildren()) do
			if c:IsA("TextLabel") then
				local n = string.lower(c.Name)
				if n:find("taskleft", 1, true) or n:find("taskcount", 1, true) or n == "taskleft" then
					local num = tonumber((c.Text or ""):match("%d+"))
					if num then return num end
				end
			end
			local r = dig(c, depth + 1)
			if r then return r end
		end
	end
	local ig = pgui:FindFirstChild("InGame")
	if ig then
		local r = dig(ig, 0)
		if r then return r end
	end
	return dig(pgui, 0)
end

local function PendingMachines(machines)
	local n = 0
	for _, m in ipairs(machines or GetMachines()) do
		if not m.Done then n = n + 1 end
	end
	return n
end

local function ReadFloor()
	local area = RS:FindFirstChild("Area")
	if area and area:IsA("ValueBase") then
		local n = tonumber(area.Value) or tonumber(tostring(area.Value):match("%d+"))
		if n and n > 0 then return n end
	end
	local rn = RS:FindFirstChild("RoundNumber")
	if rn and rn:IsA("ValueBase") then
		local n = tonumber(rn.Value)
		if n and n > 0 then return n end
	end
	return S.lastFloor
end

local function MapReady(machines)
	if IsLoading() or InIntermission() then return false end
	if not Alive() then return false end
	machines = machines or GetMachines()
	for _, m in ipairs(machines) do
		if m.Instance and m.Instance.Parent then return true end
	end
	return false
end

local function LobbySafeSpot()
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

local function SafeSpot()
	return LobbySafeSpot()
end

local function BringSpot()
	local r = Root()
	if r then return r.Position + Vector3.new(0, 1, 0) end
end

local function NearPos(a, b, dist)
	if not a or not b then return false end
	return (a - b).Magnitude <= (dist or 18)
end

local function GoSafe(reason)
	local root = Root()
	if not root then return false end
	local inFloor = not IsLoading() and not InIntermission() and not IsTutorial()
	local machines = nil
	pcall(function() machines = GetMachines() end)
	local hasMachines = false
	if machines then
		for _, m in ipairs(machines) do
			if m.Instance and m.Instance.Parent then hasMachines = true break end
		end
	end
	if inFloor and hasMachines and reason ~= "lobby" then
		return false
	end
	local p = LobbySafeSpot()
	if not p then return false end
	if NearPos(root.Position, p, 20) then
		return false
	end
	return SoftTP(p)
end

local function StepAwayFromCryptid()
	local root = Root()
	if not root then return end
	local rp = root.Position
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") and m ~= Char() then
			local n = string.lower(m.Name)
			if n:find("cryptid", 1, true) or n:find("snuggle", 1, true) or n:find("triplet", 1, true)
				or CS:HasTag(m, "Cryptid") or CS:HasTag(m, "Entity") then
				local p = Part(m)
				if p and (p.Position - rp).Magnitude < S.safeDist then
					local dir = (rp - p.Position)
					if dir.Magnitude > 0.1 then
						dir = dir.Unit
						SoftTP(rp + dir * 12 + Vector3.new(0, 2, 0))
					end
					return
				end
			end
		end
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function CryptidNear(pos, dist)
	if not pos then return false end
	local function isCryptid(m)
		if not m or not m:IsA("Model") or m == Char() then return false end
		local n = string.lower(m.Name)
		if n:find("cryptid", 1, true) or n:find("entity", 1, true) or n:find("snuggle", 1, true)
			or n:find("triplet", 1, true) or n:find("freddie", 1, true) or n:find("grinwell", 1, true) then
			return true
		end
		return CS:HasTag(m, "Cryptid") or CS:HasTag(m, "Entity")
	end
	local candidates = {}
	pcall(function()
		for _, t in ipairs({ "Cryptid", "Entity" }) do
			for _, o in ipairs(CS:GetTagged(t)) do table.insert(candidates, o) end
		end
	end)
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") then table.insert(candidates, m) end
	end
	local root = Root()
	rayParams.FilterDescendantsInstances = root and { Char() } or {}
	for _, m in ipairs(candidates) do
		if isCryptid(m) then
			local p = Part(m)
			if p and (p.Position - pos).Magnitude <= dist then
				if not S.wallCheck or not root then return true end
				local dir = p.Position - root.Position
				local hit = Workspace:Raycast(root.Position + Vector3.new(0, 2, 0), dir, rayParams)
				if not hit or hit.Instance:IsDescendantOf(m) then return true end
			end
		end
	end
	return false
end

pcall(function()
	local r = Remote("RoundEnderReady")
	if r and r:IsA("RemoteEvent") then
		connect(r.OnClientEvent, function(part)
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
	return SoftTP(e.Position + Vector3.new(0, 1, 0))
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

local function emptyLabel(kind, val)
	if val and val ~= "" and val ~= "-" then return val end
	return "There are no " .. kind
end

local function formatFloorEmbed(entry)
	local name = displayName()
	return table.concat({
		name,
		string.format("Time: %s | God-Mode: %s | Death: %s", fmtTime(entry.time or 0), tostring(entry.god or S.godUses or 0), tostring(entry.deaths or S.deaths or 0)),
		"Cryptid's: " .. emptyLabel("cryptids", entry.cryptids),
		"Item's: " .. emptyLabel("Item's", entry.items),
	}, "\n")
end

local function sendMapStartWebhook(force)
	if not S.webhookUrl or S.webhookUrl == "" then return false end
	local floor = ReadFloor() or S.lastFloor or 0
	local key = "start_" .. tostring(floor)
	S.mapStartSent = S.mapStartSent or {}
	if not force and S.mapStartSent[key] then return false end
	S.mapStartSent[key] = true
	scanFloorSnap(floor)
	local entry = {
		floor = floor,
		cryptids = table.concat(currentSnap.cryptids or {}, ", "),
		items = table.concat(currentSnap.items or {}, ", "),
		time = currentSnap.t0 > 0 and math.floor(os.clock() - currentSnap.t0) or 0,
		god = S.godUses or 0,
		deaths = S.deaths or 0,
	}
	task.spawn(function()
		local ok = sendWebhook(formatFloorEmbed(entry))
		if not ok then
			S.mapStartSent[key] = nil
		end
	end)
	return true
end

local function sendMachinesRemainingWebhook(left)
	if not S.webhookUrl or S.webhookUrl == "" then return end
	if InCoreyZone() then return end
	task.spawn(function()
		sendWebhook("Machines remaining: " .. tostring(math.max(0, tonumber(left) or 0)))
	end)
end

local function collectNames(patterns, deep)
	local names, seen = {}, {}
	local function consider(m)
		if not m or seen[m.Name] then return end
		if not (m:IsA("Model") or m:IsA("Folder") or m:IsA("BasePart")) then return end
		local low = string.lower(m.Name)
		for _, p in ipairs(patterns) do
			if low:find(p, 1, true) then
				seen[m.Name] = true
				table.insert(names, m.Name)
				return
			end
		end
	end
	pcall(function()
		for _, tag in ipairs({ "Cryptid", "Entity", "Item", "Pickup", "Remnant" }) do
			for _, o in ipairs(CS:GetTagged(tag)) do consider(o) end
		end
	end)
	for _, m in ipairs(Workspace:GetChildren()) do
		consider(m)
		if deep and (m:IsA("Folder") or m:IsA("Model")) then
			pcall(function()
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("Model") then consider(d) end
				end
			end)
		end
	end
	return names
end

local function scanFloorSnap(forceFloor)
	local cryptids = collectNames({ "cryptid", "snuggle", "triplet", "grinwell", "freddie", "entity", "polly", "chaser" }, true)
	local items = collectNames({ "item", "remnant", "pickup", "loot", "token", "key", "battery", "flashlight" }, true)
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
		god = S.godUses or 0,
		deaths = S.deaths or 0,
	}
	if entry.cryptids == "" or entry.cryptids == "-" then entry.cryptids = "There are no cryptids" end
	if entry.items == "" or entry.items == "-" then entry.items = "There are no Item's" end
	if entry.machines == "" or entry.machines == "-" then entry.machines = "There are no machines" end
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
	logsDirty = true
	entry.god = S.godUses or 0
	entry.deaths = S.deaths or 0
	currentSnap = { cryptids = {}, items = {}, machines = {}, t0 = 0, floor = nil }
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
	connect(Me.Idled, function()
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
	local pick
	if hp <= 2 then
		pick = "HeartPlus"
	else
		pick = "TaskLess"
	end
	FireAny(rem, pick)
	task.wait(0.05)
	if pick == "HeartPlus" then
		FireAny(rem, "Hearts")
	else
		FireAny(rem, "taskless")
		FireAny(rem, "Strength")
	end
end

local function bloodDonateTick()
	if not S.autoBlood then return end
	if Hearts() < 2 then return end
	FireAny(Remote("BloodDonationEvent"))
	FireAny(Remote("BloodDonationEvent"), true)
	FireAny(Remote("BloodDonationEvent"), 1)
	pcall(function()
		local pgui = Me:FindFirstChild("PlayerGui")
		if not pgui then return end
		for _, d in ipairs(pgui:GetDescendants()) do
			if d:IsA("TextButton") and (d.Name == "DONATE" or string.lower(d.Text or "") == "donate") then
				pcall(function()
					firesignal(d.MouseButton1Click)
				end)
				pcall(function()
					for _, conn in pairs(getconnections(d.MouseButton1Click)) do
						conn:Fire()
					end
				end)
			end
		end
	end)
end

local function completeMachine(m)
	if not m or not m.Instance then return false end
	local obj = m.Instance
	local tag = m.Tag
	local target = m.Tagged or obj
	local isCorey = (m.Type == "Corey") or (tag == "CoreyMachine") or InCoreyZone()
	local key = tostring(obj)
	if S._stuckKey == key then
		S._stuckTries = (S._stuckTries or 0) + 1
	else
		S._stuckKey = key
		S._stuckTries = 1
	end
	local tries = isCorey and 8 or 5
	for i = 1, tries do
		local pos = m.Front or m.Position
		if pos and isCorey then
			SoftTP(pos)
			task.wait(0.04)
			SoftTP(pos + Vector3.new(0, 1.5, 0))
		end
		FireComplete(tag, target)
		FireComplete(tag, obj)
		FirePrompt(obj)
		FirePrompt(target)
		if isCorey then
			FireAny(Remote("CoreyTreeComplete"), target)
			FireAny(Remote("CoreyTreeComplete"), obj)
			FireAny(Remote("CoreyTreeComplete"))
			ForceRelease()
		end
		if i % 2 == 0 then ForceRelease() end
		task.wait(0.07 + S.taskWait)
		if IsDone(obj) or IsDone(m.Tagged) then
			S._stuckKey = nil
			S._stuckTries = 0
			return true
		end
	end
	ForceRelease()
	FireComplete(tag, target)
	FirePrompt(obj)
	task.wait(0.1)
	local done = IsDone(obj) or IsDone(m.Tagged)
	if done then
		S._stuckKey = nil
		S._stuckTries = 0
	end
	return done
end

local function tryGodMode()
	if not S.godArmed or S.godOn then return end
	local hp = Hearts()
	if hp ~= 1 then return end
	S.godOn = true
	S.godUses = (S.godUses or 0) + 1
	S.status = "God Mode"
	pcall(function()
		local h = Hum()
		if h then
			h.Health = 0
			h:TakeDamage(h.MaxHealth + 100)
		end
	end)
	task.wait(0.25)
	pcall(function() Me:LoadCharacter() end)
	task.wait(0.45)
	refreshChar(Me.Character)
	pcall(function()
		local c = Char()
		if not c then return end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
				pcall(function() d:Destroy() end)
			end
		end
	end)
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
	S._stuckKey = nil
	S._stuckTries = 0
	if newFloor <= 1 then S._whSent = {} S.mapStartSent = {} end
	task.delay(0.5, function() scanFloorSnap(newFloor) end)
	task.delay(1.5, function() scanFloorSnap(newFloor) sendMapStartWebhook() end)
	task.delay(3.5, function() scanFloorSnap(newFloor) sendMapStartWebhook() end)
	task.delay(6, function() scanFloorSnap(newFloor) end)
	task.delay(9, function() scanFloorSnap(newFloor) end)
end

local function syncFloor()
	local f = ReadFloor()
	if f and f ~= S.lastFloor then onFloorChange(f) end
end

local function pickMachine(machines)
	machines = machines or GetMachines()
	local corey = InCoreyZone()
	if not corey then
		S.coreySideDone = 0
		local best, bestDist, fallback, fallbackDist
		local root = Root()
		local rp = root and root.Position
		for _, m in ipairs(machines) do
			if not m.Done then
				local pos = m.Front or m.Position
				local d = (rp and m.Position) and (m.Position - rp).Magnitude or 0
				if not fallbackDist or d < fallbackDist then
					fallback, fallbackDist = m, d
				end
				if S.godOn or not CryptidNear(pos, S.safeDist * 0.7) then
					if not bestDist or d < bestDist then best, bestDist = m, d end
				end
			end
		end
		return best or fallback
	end
	local forceCorey = (S.coreySideDone or 0) >= COREY_SIDE_MAX or (S._stuckTries or 0) >= 7
	if not forceCorey then
		for _, m in ipairs(machines) do
			if not m.Done and (m.Type == "Storage" or m.Type == "Arcade") then
				if S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist) then return m end
			end
		end
	end
	for _, m in ipairs(machines) do
		if not m.Done and m.Type == "Corey" then
			if S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist) then
				if forceCorey then S._stuckTries = 0 S._stuckKey = nil end
				return m
			end
		end
	end
	if not forceCorey then
		for _, m in ipairs(machines) do
			if not m.Done and (m.Type == "Storage" or m.Type == "Arcade") then
				if S.godOn or not CryptidNear(m.Front or m.Position, S.safeDist) then return m end
			end
		end
	end
end

local function forceBring(obj, dest)
	if not obj or not dest then return false end
	local root = machineRoot(obj) or obj
	local ok = pcall(function()
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.AssemblyLinearVelocity = Vector3.zero
				d.AssemblyAngularVelocity = Vector3.zero
			end
		end
		local target = Vector3.new(dest.X, dest.Y + 2.5, dest.Z + 4)
		local cf = CFrame.new(target)
		if root:IsA("Model") then
			pcall(function() root:PivotTo(cf) end)
			local pp = root.PrimaryPart or Part(root)
			if pp then
				local offset = root:GetPivot().Position - pp.Position
				pp.CFrame = cf
				for _, d in ipairs(root:GetDescendants()) do
					if d:IsA("BasePart") and d ~= pp then
						d.CFrame = cf * CFrame.new(d.Position - pp.Position)
					end
				end
			end
		else
			local p = Part(root)
			if p then p.CFrame = cf end
		end
	end)
	return ok
end

local function doMachine(target)
	if not target or not (target.Front or target.Position) then return end
	local corey = InCoreyZone()
	S.status = (corey and "Corey " or "") .. (target.Type or "Machine")
	local useBring = (S.mode == "Bring") and (not corey)
	if useBring then
		local r = Root()
		local spot = r and (r.Position + Vector3.new(0, 1, 0)) or target.Front
		for _ = 1, 5 do
			forceBring(target.Instance, spot)
			task.wait(0.04)
		end
	else
		local dest = target.Front or target.Position
		if dest then
			SoftTP(dest)
			task.wait(0.05)
			SoftTP(dest + Vector3.new(0, 1.2, 0))
			task.wait(0.04)
			if corey then
				SoftTP(dest)
				task.wait(0.05)
			end
		end
	end
	task.wait(0.05 + S.taskWait)
	if useBring then
		local r = Root()
		local spot = r and (r.Position + Vector3.new(0, 1, 0))
		if spot then
			for _ = 1, 3 do forceBring(target.Instance, spot) end
		end
	end
	if S.camLock then
		pcall(function()
			local cam = Workspace.CurrentCamera
			local look = target.Position or (Root() and Root().Position)
			if cam and look then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, look) end
		end)
	end
	local ok
	if useBring then
		local spot = BringSpot()
		for _ = 1, 2 do
			if spot then forceBring(target.Instance, spot) end
			ok = completeMachine(target)
			if ok then break end
			if spot then forceBring(target.Instance, spot) end
			task.wait(0.08)
		end
	else
		ok = completeMachine(target)
		if not ok and corey then
			local dest = target.Front or target.Position
			if dest then SoftTP(dest) end
			ForceRelease()
			ok = completeMachine(target)
		end
	end
	if ok then
		if corey and (target.Type == "Arcade" or target.Type == "Storage") then
			S.coreySideDone = (S.coreySideDone or 0) + 1
		end
		if not corey then
			local left = TasksRemaining()
			if left == nil then
				left = 0
				for _, m in ipairs(GetMachines()) do if not m.Done then left = left + 1 end end
			end
			sendMachinesRemainingWebhook(left)
		end
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
		end)
	end
end

local function busyTick()
	if not S.skipBusy then return end
	local c = Char()
	if c then
		pcall(function()
			c:SetAttribute("busysorry", 0)
			c:SetAttribute("Busy", false)
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
		S.deaths = (S.deaths or 0) + 1
		if S.autoRejoin then
			pcall(function() TeleportService:Teleport(game.PlaceId, Me) end)
		end
		return
	end
	if S.pauseFarm then
		local age = S._bossPauseAt and (os.clock() - S._bossPauseAt) or 99
		if age > 10 or (not IsLoading() and age > 4) then
			S.pauseFarm = false
			S._bossPauseAt = nil
		else
			S.status = "Boss Intro"
			return
		end
	end
	if IsLoading() then
		S.status = "Loading"
		GoSafe("lobby")
		return
	end
	if InIntermission() then
		S.status = "Intermission"
		voteBestCard()
		bloodDonateTick()
		return
	end
	if S.loadGrace > 0 and os.clock() < S.loadGrace then
		S.status = "Loading Map"
		return
	end

	local machines = GetMachines()
	if not MapReady(machines) then
		S.status = "Loading Map"
		S.loadGrace = os.clock() + 1.5
		return
	end

	syncFloor()
	if currentSnap.t0 == 0 then scanFloorSnap() end
	tryGodMode()
	processRequeue()

	local root = Root()
	if not root then return end

	if S.chased and not S.godOn then
		S.status = "Fleeing"
		StepAwayFromCryptid()
		task.wait(0.35)
		S.chased = false
	end

	local target = pickMachine(machines)
	if target then
		doMachine(target)
		return
	end

	local pending = 0
	for _, m in ipairs(machines) do
		if not m.Done then pending = pending + 1 end
	end
	if pending == 0 then
		S.status = "Exit"
		if GoExit() then
			syncFloor()
			task.wait(1.1)
		else
			S.status = "Waiting Exit"
		end
	else
		S.status = "Retry Machines"
		local any
		for _, m in ipairs(machines) do
			if not m.Done then
				any = m
				break
			end
		end
		if any then
			doMachine(any)
		end
	end
end

local function setStatus()
	local floor = S.lastFloor
	if not floor or floor <= 0 then floor = ReadFloor() end
	local live = ReadFloor()
	if live and live > 0 then floor = live end
	local runT = S.timerActive and S.timerStart > 0 and (os.clock() - S.timerStart) or 0
	Status.Text = string.format("%s | Floor:%s HP:%s God:%s %s",
		tostring(S.status), tostring(floor or "-"),
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
local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1, -4, 0, 48)
desc.Position = UDim2.new(0, 0, 0, y)
desc.BackgroundColor3 = CARD
desc.TextColor3 = Color3.fromRGB(180, 180, 190)
desc.Font = FONT
desc.TextSize = 10
desc.TextWrapped = true
desc.TextXAlignment = Enum.TextXAlignment.Left
desc.TextYAlignment = Enum.TextYAlignment.Top
desc.Text = "Auto-farm might not work well if you have more than 150-200 ms, so we recommend using it when your ms is lower"
desc.Parent = PageFarm
Instance.new("UICorner", desc).CornerRadius = UDim.new(0, 6)
local dp = Instance.new("UIPadding")
dp.PaddingLeft = UDim.new(0, 6)
dp.PaddingTop = UDim.new(0, 4)
dp.PaddingRight = UDim.new(0, 4)
dp.Parent = desc
y = y + 52
y = addToggle(PageFarm, y, "Enable Auto-Farm", false, function(v)
	S.running = v
	_G.PinkBombRunning = v
	if v then
		if not S.timerActive then S.timerStart = os.clock() S.timerActive = true end
		S.loadGrace = os.clock() + 2
		scanFloorSnap()
		task.delay(1, function() sendMapStartWebhook() end)
		task.delay(4, function() sendMapStartWebhook() end)
		toast("Farm", S.mode .. " ON")
		task.spawn(function()
			while S.running and Gui and Gui.Parent do
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
			while S.running and Gui and Gui.Parent do
				local ok, err = pcall(function()
					if S.stamina then staminaTick() end
					if S.skipBusy then busyTick() end
					if S.antiDebuff then antiDebuffTick() end
					if S.blockAlerts then blockAlertsTick() end
					if S.autoBlood then bloodDonateTick() end
					if S.godArmed and not S.godOn and Hearts() == 1 then tryGodMode() end
				end)
				if not ok then w("support error:", err) end
				task.wait(0.25)
			end
		end)
	else
		toast("Farm", "OFF")
	end
end)
y = addToggle(PageFarm, y, "Auto Best Card", true, function(v) S.autoBestCard = v end)
y = addToggle(PageFarm, y, "Auto Donate Blood", true, function(v) S.autoBlood = v end)
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
LogDetail.Text = "Logs: name / Time | God | Death / Cryptids / Items"
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
	if S.webhookUrl ~= "" then
		S.mapStartSent = {}
		task.delay(0.3, function() sendMapStartWebhook(true) end)
		toast("Webhook", "Saved - auto send ON")
	else
		toast("Webhook", "Cleared")
	end
end)
fy = addBtn(PageFeed, fy, "Test Webhook", function()
	if S.webhookUrl == "" then toast("Webhook", "Paste URL first") return end
	local ok = sendWebhook("**" .. displayName() .. "** connected Pink Bomb farm.")
	toast("Webhook", ok and "Sent" or "Failed - check URL/HTTP")
end)
PageFeed.CanvasSize = UDim2.new(0, 0, 0, fy + 16)

pcall(function()
	local rn = RS:FindFirstChild("RoundNumber")
	if rn and rn:IsA("ValueBase") then
		connect(rn:GetPropertyChangedSignal("Value"), syncFloor)
	end
	local area = RS:FindFirstChild("Area")
	if area and area:IsA("ValueBase") then
		connect(area:GetPropertyChangedSignal("Value"), function()
			syncFloor()
			S.loadGrace = os.clock() + 4
		end)
	end
	local cm = RS:FindFirstChild("CurrentMap")
	if cm and cm:IsA("ValueBase") then
		connect(cm:GetPropertyChangedSignal("Value"), function()
			S.loadGrace = os.clock() + 4
			S.coreySideDone = 0
		end)
	end
end)

task.spawn(function()
	while Gui and Gui.Parent do
		setStatus()
		if PageLogs.Visible and logsDirty then
			refreshLogUI()
			logsDirty = false
		end
		syncFloor()
		task.wait(0.5)
	end
end)

toast("Pink Bomb", "UI ready")
