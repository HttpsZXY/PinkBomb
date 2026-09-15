

local VERSION = "2.2.0"
if not table.clear then
	function table.clear(t)
		for k in pairs(t) do t[k] = nil end
	end
end
local HUB_NAME = "Pink bomb's | FUNHOUSE"

local ASSETS = {
	Icon = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/Bomb.png",
	Error = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/Error.png",
	Notify = "https://raw.githubusercontent.com/HttpsZXY/PinkBomb/main/Assets/Notify.png",
}

local function errLog(...)
end

local function safeCall(name, fn)
	local ok, err = pcall(fn)
	return ok, err
end


local WindUI
local loadFails = {}

local function toast(msg, ok)
	pcall(function()
		if WindUI and type(WindUI.Notify) == "function" then
			WindUI:Notify({
				Title = ok and "Pink bomb's" or "Pink bomb's Error",
				Content = tostring(msg),
				Duration = ok and 2 or 6,
				Icon = ok and ASSETS.Notify or ASSETS.Error,
			})
		end
	end)
end

local function tryWind(url)
	local ok, res = pcall(function()
		local src = game:HttpGet(url)
		assert(type(src) == "string" and #src > 200, "empty")
		local fn, err = loadstring(src)
		assert(fn, tostring(err))
		local lib = fn()
		assert(type(lib) == "table" and type(lib.CreateWindow) == "function", "bad lib")
		return lib
	end)
	if ok then return res end
	table.insert(loadFails, tostring(res))
	return nil
end

WindUI = tryWind("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua")
	or tryWind("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
	or tryWind("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
	or tryWind("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua")

if not WindUI then
	toast("WindUI failed\n" .. table.concat(loadFails, "\n"), false)
	return
end

pcall(function()
	if WindUI.SetFont then
		WindUI:SetFont("rbxassetid://12187371840")
	end
end)


local cref = (type(cloneref) == "function" and cloneref) or function(x) return x end
local UIS = cref(game:GetService("UserInputService"))
local GuiService = cref(game:GetService("GuiService"))
local RS = cref(game:GetService("ReplicatedStorage"))
local CS = cref(game:GetService("CollectionService"))
local Players = cref(game:GetService("Players"))
local RunService = cref(game:GetService("RunService"))
local Workspace = cref(game:GetService("Workspace"))
local Lighting = cref(game:GetService("Lighting"))
local VirtualUser = cref(game:GetService("VirtualUser"))

local Me = Players.LocalPlayer
if not Me then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	Me = Players.LocalPlayer
end

local OnPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local OnTV = GuiService:IsTenFootInterface()
if OnPhone and WindUI.SetNotificationLower then
	pcall(function() WindUI:SetNotificationLower(true) end)
end


local Loops = {}
local Conns = {}
local ConnGroups = {}

local function Loop(key, pred, fn, waitTime)
	if Loops[key] then return end
	Loops[key] = true
	task.spawn(function()
		while Loops[key] do
			if not pred() then break end
			pcall(fn)
			if not Loops[key] then break end
			local w = waitTime
			if type(w) == "function" then
				local ok, v = pcall(w)
				w = ok and v or 0.6
			end
			task.wait(math.max(0.08, tonumber(w) or 0.6))
		end
		Loops[key] = nil
	end)
end

local function Stop(key)
	Loops[key] = nil
end

local function StopAllLoops()
	for k in pairs(Loops) do Loops[k] = nil end
end

local Managers = { Loops = {} }
Managers.Loops.Start = Loop
Managers.Loops.Stop = Stop
Managers.Loops.StopAll = StopAllLoops
Managers.Loops.IsRunning = function(key) return Loops[key] == true end
Managers.Loops.Active = function() local n = 0; for _ in pairs(Loops) do n += 1 end; return n end

local function Conn(key, connection)
	if not connection then return end
	Conns[key] = Conns[key] or {}
	table.insert(Conns[key], connection)
	return connection
end

local function DisconnectKey(key)
	local list = Conns[key]
	if not list then return end
	for _, c in ipairs(list) do
		pcall(function() c:Disconnect() end)
	end
	Conns[key] = nil
end

local function DisconnectAll()
	for k in pairs(Conns) do
		DisconnectKey(k)
	end
end


local CharState = {
	Character = nil,
	Humanoid = nil,
	Root = nil,
}

local function refreshChar(char)
	char = char or Me.Character
	CharState.Character = char
	CharState.Humanoid = char and char:FindFirstChildOfClass("Humanoid") or nil
	CharState.Root = char and char:FindFirstChild("HumanoidRootPart") or nil
	if not CharState.Root and char then
		CharState.Root = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	end
end

refreshChar(Me.Character)
Conn("core", Me.CharacterAdded:Connect(function(c)
	task.wait(0.15)
	refreshChar(c)
end))
Conn("core", Me.CharacterRemoving:Connect(function()
	CharState.Character = nil
	CharState.Humanoid = nil
	CharState.Root = nil
end))

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
		CharState.Root = c:FindFirstChild("HumanoidRootPart")
			or c:FindFirstChild("Torso")
			or c:FindFirstChild("UpperTorso")
	end
	return CharState.Root
end

local function Hearts()
	local c = Char()
	return c and (tonumber(c:GetAttribute("hearts")) or 0) or 0
end

local function Alive()
	local c = Char()
	if not c then return false end
	local h = Hum()
	if h and h.Health <= 0 and Hearts() <= 0 then return false end
	if Me:GetAttribute("IsDead") == true and Hearts() <= 0 then return false end
	
	if Root() then
		if Hearts() > 0 then return true end
		if h and h.Health > 0 then return true end
		
		return true
	end
	return false
end

local function CharName()
	local c = Char()
	if not c then return "" end
	return string.lower(tostring(c:GetAttribute("CharacterName") or ""))
end

local function IsPal(name)
	local n = CharName()
	return n:find(name, 1, true) ~= nil
end


local remCache = {}
local function Rem(name)
	if not name then return nil end
	local cached = remCache[name]
	if cached and cached.Parent then return cached end
	local function okRemote(r)
		return r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction"))
	end
	local r = RS:FindFirstChild(name)
	if okRemote(r) then
		remCache[name] = r
		return r
	end
	r = RS:FindFirstChild(name, true)
	if okRemote(r) then
		remCache[name] = r
		return r
	end
	for _, d in ipairs(RS:GetDescendants()) do
		if d.Name == name and okRemote(d) then
			remCache[name] = d
			return d
		end
	end
	return nil
end

local function RemAny(names)
	for _, n in ipairs(names) do
		local r = Rem(n)
		if r then return r, n end
	end
	return nil, nil
end

local function Part(x)
	if not x then return nil end
	if x:IsA("BasePart") then return x end
	if x:IsA("Model") then
		if x.PrimaryPart then return x.PrimaryPart end
		return x:FindFirstChild("HumanoidRootPart")
			or x:FindFirstChildWhichIsA("BasePart", true)
	end
	return x:FindFirstChildWhichIsA("BasePart", true)
end

local function IsPlayerChar(m)
	if not m then return false end
	local pl = Players:GetPlayerFromCharacter(m)
	if pl then return true end
	if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and Players:GetPlayerFromCharacter(m) then
		return true
	end
	return false
end

local function IsDone(obj)
	if not obj then return true end
	local function check(o)
		if not o then return false end
		if o:GetAttribute("Used") == true then return true end
		local a = o:GetAttribute("Activated")
		if a == 1 or a == true then return true end
		local d = o:GetAttribute("Completed") or o:GetAttribute("Done")
		if d == true or d == 1 then return true end
		local prog = tonumber(o:GetAttribute("Progress"))
		local need = tonumber(o:GetAttribute("HowMuch"))
		if prog and need and need > 0 and prog >= need then return true end
		return false
	end
	if check(obj) then return true end
	local root = obj
	pcall(function()
		local p = obj.Parent
		if p and p:IsA("Model") then root = p end
	end)
	if root ~= obj and check(root) then return true end
	return false
end

local function isSanePos(pos, maxMag)
	if typeof(pos) ~= "Vector3" then return false end
	if pos ~= pos then return false end
	local lim = maxMag or 8000
	return math.abs(pos.X) < lim and math.abs(pos.Y) < lim and math.abs(pos.Z) < lim
end

local function Ping(title, content, dur)
	pcall(function()
		if WindUI and type(WindUI.Notify) == "function" then
			WindUI:Notify({ Title = title, Content = content, Duration = dur or 3, Icon = ASSETS.Notify })
		end
	end)
end
local Notify = Ping


local MANNY_WANDER = "100596528077771"
local cryptidCache = {}
local cryptidCacheAt = 0

local function IsMabel(m)
	if not m then return false end
	local n = string.lower(m.Name)
	if n:find("mabel", 1, true) then return true end
	local cn = string.lower(tostring(m:GetAttribute("CharacterName") or ""))
	return cn:find("mabel", 1, true) ~= nil
end

local function IsPassiveManny(m)
	if not m then return false end
	local n = string.lower(m.Name)
	if not (n:find("manny", 1, true) or n:find("cryptidmanny", 1, true)) then
		return false
	end
	local awake = false
	local wander = false
	pcall(function()
		local hum = m:FindFirstChildOfClass("Humanoid")
		local anim = hum and hum:FindFirstChildOfClass("Animator")
		if not anim then return end
		for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
			local id = ""
			pcall(function()
				id = tostring(t.Animation and t.Animation.AnimationId or "")
			end)
			local low = string.lower(id)
			if low:find("awakening", 1, true) or low:find("100596") == nil and low:find("awaken", 1, true) then
				
			end
			if low:find("awakening", 1, true) then awake = true end
			if low:find(MANNY_WANDER, 1, true) or low:find("wandering", 1, true) then
				wander = true
			end
		end
	end)
	if awake then return false end
	if wander then return true end
	return false
end

local function IsCryptid(m)
	if not m or not m.Parent then return false end
	if IsPlayerChar(m) then return false end
	local n = string.lower(m.Name)
	if n == "fan" or n:find("stargil", 1, true) then return true end
	if n:find("cryptid", 1, true) then return true end
	if m:GetAttribute("IsCryptid") == true then return true end
	local cn = string.lower(tostring(m:GetAttribute("CharacterName") or ""))
	if cn:find("cryptid", 1, true) then return true end
	return false
end

local function IsThreat(m)
	if not m or IsPlayerChar(m) then return false end
	if IsMabel(m) then return false end
	if IsPassiveManny(m) then return false end
	return IsCryptid(m)
end

local function refreshCryptids(force)
	local now = os.clock()
	local cd = OnPhone and 2.0 or 1.4
	if not force and now - cryptidCacheAt < cd then return end
	cryptidCacheAt = now
	table.clear(cryptidCache)
	local seen = {}
	local function add(o)
		if not o or not o.Parent or seen[o] then return end
		if IsCryptid(o) then
			seen[o] = true
			table.insert(cryptidCache, o)
		end
	end
	pcall(function()
		for _, tag in ipairs({ "Cryptid", "Chaser", "Entity" }) do
			for _, o in ipairs(CS:GetTagged(tag)) do
				add(o)
			end
		end
	end)
	local maxDepth = OnPhone and 1 or 2
	local function walk(root, depth)
		if depth > maxDepth or not root then return end
		for _, c in ipairs(root:GetChildren()) do
			add(c)
			if c:IsA("Model") or c:IsA("Folder") then
				walk(c, depth + 1)
			end
		end
	end
	for _, o in ipairs(Workspace:GetChildren()) do
		add(o)
		walk(o, 1)
	end
end

local function CryptidNear(pos, rad, force)
	if not pos then return false end
	rad = (rad or 56) + 4
	refreshCryptids(force == true)
	local me = Char()
	if me and me:GetAttribute("Chased") == true then
		rad = rad * 1.35
	end
	local samples = {
		pos,
		pos + Vector3.new(5, 0, 0),
		pos + Vector3.new(-5, 0, 0),
		pos + Vector3.new(0, 0, 5),
		pos + Vector3.new(0, 0, -5),
		pos + Vector3.new(0, 3, 0),
	}
	for _, o in ipairs(cryptidCache) do
		if o.Parent and IsThreat(o) then
			local p = Part(o)
			if p then
				for _, s in ipairs(samples) do
					if (p.Position - s).Magnitude <= rad then
						return true, o, p.Position
					end
				end
			end
		end
	end
	return false
end


local machineFail = {} 

local function machineRoot(o)
	if not o then return nil end
	local cur, best = o, o:IsA("Model") and o or nil
	while cur and cur ~= Workspace do
		if cur:IsA("Model") then
			local low = string.lower(cur.Name)
			if low:find("arcade", 1, true) or low:find("arcane", 1, true)
				or low:find("storage", 1, true) or low:find("corey", 1, true) then
				best = cur
			end
		end
		cur = cur.Parent
	end
	return best or (o:IsA("Model") and o) or o
end

local function prettyMachineName(obj)
	local n = tostring(obj and obj.Name or "")
	local low = string.lower(n)
	if low:find("double", 1, true) and (low:find("arcane", 1, true) or low:find("arcade", 1, true)) then
		return "Double Arcane"
	end
	if low:find("arcade", 1, true) or low:find("arcane", 1, true) then return "Arcane" end
	if low:find("storage", 1, true) then return "Storage" end
	if low:find("corey", 1, true) then return "Corey" end
	return n:gsub("%d+$", "")
end

local machineScanCache = nil
local machineScanCacheAt = 0
local machineScanBusy = false

local function GetMachines()
	local now = os.clock()
	if machineScanCache and now - machineScanCacheAt < 0.9 then
		return machineScanCache
	end
	if machineScanBusy then
		return machineScanCache or {}
	end
	machineScanBusy = true

	local out = {}
	local seen = {}
	local seenPos = {}
	local function posKey(pos)
		if not pos then return nil end
		return string.format("%d_%d_%d", math.floor(pos.X / 4), math.floor(pos.Y / 4), math.floor(pos.Z / 4))
	end
	local function push(tag, typeName, o)
		local root = machineRoot(o) or o
		if not root or not root.Parent or seen[root] then return end
		local p = Part(root)
		local pos = p and p.Position
		local pk = posKey(pos)
		if pk and seenPos[pk] then return end
		seen[root] = true
		if pk then seenPos[pk] = true end
		local look = p and p.CFrame.LookVector
		table.insert(out, {
			Instance = root,
			Tagged = o,
			Type = typeName,
			Tag = tag,
			Done = IsDone(root) or IsDone(o),
			Position = pos,
			Front = pos and look and (pos + look * 4 + Vector3.new(0, 2, 0)) or pos,
		})
	end
	pcall(function()
		for _, o in ipairs(CS:GetTagged("ArcadeMachine")) do push("ArcadeMachine", "Arcade", o) end
		for _, o in ipairs(CS:GetTagged("StorageMachine")) do push("StorageMachine", "Storage", o) end
		for _, o in ipairs(CS:GetTagged("CoreyMachine")) do push("CoreyMachine", "Corey", o) end
	end)
	local hasA, hasS, hasC = false, false, false
	for _, m in ipairs(out) do
		if m.Type == "Arcade" then hasA = true end
		if m.Type == "Storage" then hasS = true end
		if m.Type == "Corey" then hasC = true end
	end
	if not (hasA and hasS and hasC) then
		local function walk(node, depth)
			if depth > 6 or not node then return end
			for _, c in ipairs(node:GetChildren()) do
				if c:IsA("Model") then
					local low = string.lower(c.Name)
					if not hasC and (low:find("coreymachine", 1, true)
						or (low:find("corey", 1, true) and low:find("machine", 1, true))) then
						push("CoreyMachine", "Corey", c)
					elseif not hasA and (low:find("arcademachine", 1, true)
						or low:find("arcanemachine", 1, true)
						or (low:find("arcane", 1, true) and not low:find("spawn", 1, true))) then
						if low:find("machine", 1, true) or low == "arcane" or low:find("arcade", 1, true) then
							push("ArcadeMachine", "Arcade", c)
						end
					elseif not hasS and low:find("storage", 1, true) then
						push("StorageMachine", "Storage", c)
					end
				end
				if c:IsA("Folder") or c:IsA("Model") then
					walk(c, depth + 1)
				end
			end
		end
		pcall(function() walk(Workspace, 0) end)
	end
	machineScanBusy = false
	machineScanCache = out
	machineScanCacheAt = os.clock()
	return out
end

local MachineManager = { CacheTime = 0.35 }
function MachineManager.Get() return GetMachines() end
function MachineManager.Clear() machineScanCache, machineScanCacheAt = nil, 0 end
Managers.Machines = MachineManager

local function markMachineFail(obj, sec)
	if obj then machineFail[obj] = os.clock() + (sec or 4) end
end

local function isMachineFailed(obj)
	local t = machineFail[obj]
	return t and os.clock() < t
end


local Settings = {
	wallCheck = true,
	safeDist = 52,
	exitCd = 2.2,
	exitY = 2.5,
	machCd = 1.6,
	pace = 1.0,
	lootCd = 1.2,
}

local lastExitTry = 0
local fleeLockUntil = 0

local function SafeTP(target, lookAt, rad)
	local r = Root()
	if not r or not r.Parent then return false end
	local pos = typeof(target) == "Vector3" and target or nil
	if typeof(target) == "Instance" then
		local p = Part(target)
		pos = p and p.Position
	end
	if not pos or not isSanePos(pos) then return false end
	rad = rad or Settings.safeDist
	if Settings.wallCheck then
		local near = CryptidNear(pos, rad, true)
		if near then
			return false
		end
	end
	local cf
	if lookAt then
		cf = CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
	else
		cf = CFrame.new(pos)
	end
	pcall(function()
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		r.CFrame = cf
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
	end)
	return true
end


local function remoteForMachineTag(tag)
	if tag == "ArcadeMachine" then
		local r = Rem("ArcadeMachineUse") or Rem("ArcadeUse") or Rem("ArcaneMachineUse")
		if r then return r end
	else
		local r = Rem("StorageMachineUse") or Rem("StorageUse") or Rem("CoreyMachineUse")
		if r then return r end
	end
	local want = tag == "ArcadeMachine" and "arcade" or "storage"
	local found
	pcall(function()
		for _, d in ipairs(RS:GetDescendants()) do
			if d:IsA("RemoteEvent") then
				local n = string.lower(d.Name)
				if n:find("use", 1, true) then
					if want == "arcade" and (n:find("arcade", 1, true) or n:find("arcane", 1, true)) then
						found = d
						break
					end
					if want == "storage" and (n:find("storage", 1, true) or n:find("corey", 1, true)) then
						found = d
						break
					end
				end
			end
		end
	end)
	return found
end

local function CompleteRemoteOnly(tag)
	local rem = remoteForMachineTag(tag)
	if not rem then return end
	local fired = {}
	local function fire(m)
		if not m or not m.Parent or fired[m] then return end
		fired[m] = true
		pcall(function() rem:FireServer(m, "complete") end)
	end
	pcall(function()
		for _, m in ipairs(CS:GetTagged(tag)) do
			fire(m)
		end
	end)
	MachineManager.Clear()
	for _, m in ipairs(GetMachines()) do
		local match = (m.Tag == tag)
			or (tag == "ArcadeMachine" and m.Type == "Arcade")
			or (tag == "StorageMachine" and m.Type == "Storage")
			or (tag == "CoreyMachine" and m.Type == "Corey")
		if match then
			fire(m.Tagged)
			fire(m.Instance)
		end
	end
end

local function FireCompleteOne(obj, tag)
	if not obj or not obj.Parent then return end
	local rem = remoteForMachineTag(tag or "StorageMachine")
	if rem then
		pcall(function() rem:FireServer(obj, "complete") end)
		local root = machineRoot(obj)
		if root and root ~= obj and root.Parent then
			pcall(function() rem:FireServer(root, "complete") end)
		end
	end
	if tag == "ArcadeMachine" then
		local af = RS:FindFirstChild("ArcadeForceComplete")
		if af and af:IsA("BindableEvent") then
			pcall(function() af:Fire(obj) end)
			pcall(function() af:Fire() end)
		end
	end
end

local function FirePrompt(obj)
	if not obj then return false end
	local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then return false end
	if type(fireproximityprompt) == "function" then
		local ok = pcall(function() fireproximityprompt(prompt) end)
		if ok then return true end
	end
	local ok = pcall(function()
		prompt.Enabled = true
		local hold = tonumber(prompt.HoldDuration) or 0
		prompt:InputHoldBegin()
		task.wait(math.clamp(hold, 0.08, 1.2))
		prompt:InputHoldEnd()
	end)
	return ok
end


local lastInvFullWarn = 0
local function warnInvFull()
	if os.clock() - lastInvFullWarn < 4 then return end
	lastInvFullWarn = os.clock()
	Ping("Inventory", "Inventory is full.", 2)
end

local function invFull()
	local c = Char()
	if not c then return false end
	local filled = 0
	for i = 1, 3 do
		local v = c:GetAttribute("Inv" .. i)
		if v and tostring(v) ~= "" then filled = filled + 1 end
	end
	return filled >= 3
end


local function isRemnantOrFlesh(o)
	if not o or not o.Parent then return false end
	local low = string.lower(o.Name or "")
	if low:find("fleshtrap", 1, true) then return false end
	if low:find("remnant", 1, true) or low:find("remmant", 1, true) or low:find("remant", 1, true) then
		return true
	end
	if low:find("flesh", 1, true) and not low:find("trap", 1, true) then
		return true
	end
	return false
end

local function collectLootTargets()
	local list = {}
	local seen = {}
	local function add(o)
		if not o or seen[o] or not isRemnantOrFlesh(o) then return end
		local p = Part(o)
		if not p or p.Transparency >= 0.95 then return end
		seen[o] = true
		table.insert(list, o)
	end
	pcall(function()
		for _, tag in ipairs({ "Spawneditem", "SpawnedItem" }) do
			for _, o in ipairs(CS:GetTagged(tag)) do
				add(o)
			end
		end
	end)
	for _, o in ipairs(Workspace:GetChildren()) do
		add(o)
	end
	return list
end


local savedExitPart = nil
local exitReady = false

pcall(function()
	local ev = RS:FindFirstChild("RoundEnderReady")
	if ev and ev:IsA("RemoteEvent") then
		Conn("exit", ev.OnClientEvent:Connect(function(part)
			if typeof(part) == "Instance" then
				savedExitPart = Part(part) or part
				exitReady = true
			end
		end))
	end
end)

local function findExitPart()
	if savedExitPart and savedExitPart.Parent then
		return savedExitPart
	end
	local function hasTouch(o)
		if not o then return false end
		if o:FindFirstChild("TouchInterest") then return true end
		local ok = false
		pcall(function()
			for _, d in ipairs(o:GetDescendants()) do
				if d:IsA("TouchTransmitter") or d.Name == "TouchInterest" then
					ok = true
					break
				end
			end
		end)
		return ok
	end
	local bestTouch, bestAny
	local function consider(c)
		local low = string.lower(c.Name)
		if not (low:find("roundender", 1, true) or low == "exit" or low:find("escape", 1, true) or low:find("ender", 1, true)) then
			return
		end
		local p = Part(c)
		if not p then return end
		if hasTouch(c) then
			bestTouch = bestTouch or p
		else
			bestAny = bestAny or p
		end
	end
	local function scan(root, depth)
		if depth > 7 or not root then return end
		for _, c in ipairs(root:GetChildren()) do
			consider(c)
			if c:IsA("Model") or c:IsA("Folder") then
				scan(c, depth + 1)
			end
		end
	end
	for _, name in ipairs({ "PartyRoom", "CaveMap", "CurrentMap", "Map" }) do
		local f = Workspace:FindFirstChild(name)
		if f then scan(f, 1) end
	end
	if not bestTouch and not bestAny then
		scan(Workspace, 1)
	end
	return bestTouch or bestAny
end

local function doExit(force)
	if not force and os.clock() - lastExitTry < Settings.exitCd then
		return false
	end
	if not force and os.clock() < fleeLockUntil then
		return false
	end
	lastExitTry = os.clock()
	local part = findExitPart()
	if not part then
		return false
	end
	local p = Part(part) or part
	if not p or not p:IsA("BasePart") then return false end
	local dest = p.Position + Vector3.new(0, Settings.exitY, 0)
	if not force and Settings.wallCheck and CryptidNear(dest, 40, true) then
		return false
	end
	if SafeTP(dest, nil, force and 1 or 40) then
		exitReady = false
		savedExitPart = p
		return true
	end
	pcall(function()
		local r = Root()
		if r then
			r.CFrame = CFrame.new(dest)
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end)
	exitReady = false
	return true
end

local function getSafePos()
	local function fromFolder(folder, names)
		if not folder then return nil end
		for _, n in ipairs(names) do
			local o = folder:FindFirstChild(n)
			if o then
				local p = Part(o)
				if p and isSanePos(p.Position, 8000) then
					return p.Position + Vector3.new(0, 3, 0)
				end
			end
		end
		for _, o in ipairs(folder:GetChildren()) do
			for _, n in ipairs(names) do
				if o.Name == n then
					local p = Part(o)
					if p and isSanePos(p.Position, 8000) then
						return p.Position + Vector3.new(0, 3, 0)
					end
				end
			end
		end
		return nil
	end
	local pos = fromFolder(Workspace:FindFirstChild("IntermissionMapYes"), { "SpawnLocation", "Spawn", "Safeteleporter" })
	if pos then return pos end
	pos = fromFolder(Workspace:FindFirstChild("WaitingForNextAreaRoom"), { "Safeteleporter", "SpawnLocation", "Spawn" })
	if pos then return pos end
	return nil
end

local function goSafe()
	if isIntermission() then
		return false
	end
	local pos = getSafePos()
	if not pos then
		return false
	end
	fleeLockUntil = os.clock() + 0.9
	local ok = SafeTP(pos, nil, 1)
	return ok
end

local function isIntermission()
	local inter = RS:FindFirstChild("Intermission")
	if inter then
		local v = inter.Value
		if type(v) == "number" and v > 0 then return true end
		if type(v) == "boolean" and v then return true end
		if type(v) == "string" then
			local ls = string.lower(v)
			if ls ~= "" and ls ~= "0" and ls ~= "false" and ls ~= "nil" then
				return true
			end
		end
	end
	local mapSv = RS:FindFirstChild("CurrentMap")
	local mapName = mapSv and string.lower(tostring(mapSv.Value or "")) or ""
	if mapName:find("tutorial", 1, true) then return false end
	if mapName:find("intermission", 1, true) or mapName:find("waiting", 1, true) then
		return true
	end
	local area = RS:FindFirstChild("Area")
	if area then
		local a = string.lower(tostring(area.Value or ""))
		if a:find("intermission", 1, true) or a:find("waiting", 1, true) then
			return true
		end
		if a:find("tutorial", 1, true) then return false end
	end
	return false
end

local function isCoreyArea()
	local mapSv = RS:FindFirstChild("CurrentMap")
	local mapName = mapSv and string.lower(tostring(mapSv.Value or "")) or ""
	local area = RS:FindFirstChild("Area")
	local a = area and string.lower(tostring(area.Value or "")) or ""
	if mapName:find("corey", 1, true) or a:find("corey", 1, true) then
		return true
	end
	local gs = RS:FindFirstChild("Gamestate")
	if gs then
		local g = string.lower(tostring(gs.Value or ""))
		if g:find("corey", 1, true) then return true end
	end
	return false
end

local FloorSession = {
	mode = nil,
	cryptids = {},
	items = {},
}

local FarmLogs = {
	keys = {},
	byKey = {},
	uiDrop = nil,
	uiPara = nil,
	uiList = nil,
	selected = nil,
	seq = 0,
}

local function prettyCryptidLogName(o)
	if not o then return nil end
	local n = tostring(o.Name or "")
	local low = string.lower(n)
	if low:find("spawn", 1, true) or low:find("spawner", 1, true) then return nil end
	if low == "fan" then return "Fan" end
	if low:find("stargil", 1, true) then return "Stargil" end
	if low:find("anton", 1, true) then return "Anton" end
	if low:find("mabel", 1, true) then return "Mabel" end
	if low:find("manny", 1, true) then return "Manny" end
	if low:find("split", 1, true) then return "Split" end
	if low:find("freddie", 1, true) then return "Freddie" end
	if low:find("dusty", 1, true) then return "Dusty" end
	if low:find("corey", 1, true) then return "Corey" end
	return n
end

local function sessionNoteCryptids()
	pcall(function()
		refreshCryptids(false)
		for _, o in ipairs(cryptidCache) do
			local name = prettyCryptidLogName(o)
			if name then FloorSession.cryptids[name] = true end
		end
	end)
end

local function sessionNoteItems()
	pcall(function()
		local function scan(node, depth)
			if depth > 5 or not node then return end
			local tagged = false
			pcall(function()
				tagged = CS:HasTag(node, "Spawneditem") or CS:HasTag(node, "SpawnedItem")
			end)
			local low = string.lower(tostring(node.Name or ""))
			if tagged then
				if not low:find("fleshtrap", 1, true) and not low:find("rotten", 1, true) then
					local label = tostring(node.Name)
					if #label > 0 then FloorSession.items[label] = true end
				end
			end
			if node:IsA("Model") or node:IsA("Folder") then
				for _, c in ipairs(node:GetChildren()) do
					scan(c, depth + 1)
				end
			end
		end
		for _, o in ipairs(Workspace:GetChildren()) do
			scan(o, 1)
		end
	end)
end

local function sessionReset(mode)
	FloorSession.mode = mode
	FloorSession.cryptids = {}
	FloorSession.items = {}
end

local function sessionKeysSorted(map)
	local list = {}
	for k in pairs(map) do table.insert(list, k) end
	table.sort(list)
	return list
end

local function commitFloorLog(_)
end

local FloorTrack = {
	passed = 0,
	startFloor = nil,
	lastFloorNum = nil,
	lastMap = "",
	exitCounted = false,
	current = nil,
}

local function readFloorNumber()
	for _, attr in ipairs({ "Floor", "floor", "CurrentFloor", "FloorNumber", "Floors" }) do
		local v = Me:GetAttribute(attr)
		if typeof(v) == "number" then return math.floor(v) end
		if typeof(v) == "string" then
			local n = tonumber(v:match("%d+"))
			if n then return n end
		end
	end
	for _, name in ipairs({ "Floor", "CurrentFloor", "FloorNumber", "Floors" }) do
		local o = RS:FindFirstChild(name)
		if o then
			if o:IsA("IntValue") or o:IsA("NumberValue") then return math.floor(o.Value) end
			if o:IsA("StringValue") then
				local n = tonumber(tostring(o.Value):match("%d+"))
				if n then return n end
			end
		end
	end
	local c = Char()
	if c then
		for _, attr in ipairs({ "Floor", "floor", "CurrentFloor" }) do
			local v = c:GetAttribute(attr)
			if typeof(v) == "number" then return math.floor(v) end
		end
	end
	return nil
end

local function onMapMaybeChanged()
	local mapSv = RS:FindFirstChild("CurrentMap")
	local mapName = mapSv and tostring(mapSv.Value or "") or ""
	if mapName ~= "" and mapName ~= FloorTrack.lastMap then
		FloorTrack.lastMap = mapName
		FloorTrack.exitCounted = false

		local cur = readFloorNumber()
		FloorTrack.current = cur

		if typeof(cur) == "number" then
			if FloorTrack.startFloor == nil then
				FloorTrack.startFloor = cur
			end
			FloorTrack.lastFloorNum = cur
		end

	end
end

local function countFloorPass()
	onMapMaybeChanged()
	if FloorTrack.exitCounted then
		return false
	end

	local cur = readFloorNumber()
	FloorTrack.exitCounted = true
	FloorTrack.current = cur

	if typeof(cur) == "number" then
		if FloorTrack.startFloor == nil then
			FloorTrack.startFloor = cur
		end

		FloorTrack.lastFloorNum = cur
		FloorTrack.passed = math.max(0, cur - FloorTrack.startFloor)
	else
		-- Only count an additional floor when the game does not expose a numeric floor.
		FloorTrack.passed = FloorTrack.passed + 1
	end

	return true
end

pcall(function()
	local mapSv = RS:FindFirstChild("CurrentMap")
	if mapSv then
		local lastPlayMap = tostring(mapSv.Value or "")
		Conn("floorMap", mapSv:GetPropertyChangedSignal("Value"):Connect(function()
			local prev = lastPlayMap
			lastPlayMap = tostring(mapSv.Value or "")
			onMapMaybeChanged()
			local wasPlay = prev ~= "" and not string.lower(prev):find("wait", 1, true) and not string.lower(prev):find("intermission", 1, true)
			if wasPlay and isIntermission() then
				if Farm.on then
					commitFloorLog("Auto-Farm")
				elseif Bring.on then
					commitFloorLog("Bring")
				end
			end
		end))
	end
end)


local Farm = {
	on = false,
	state = "IDLE",
	doMach = false,
	doExit = false,
	doSafe = false,
	doArc = true,
	doSto = true,
	doCor = true,
	doLoot = false,
	floors = 0,
	start = 0,
	status = "Idle",
	lastMach = 0,
	empty = 0,
	camLock = false,
	priorityNearest = true,
	skipIfChased = true,
	aggressiveComplete = true,
	waitSafeSec = 2,
}

local function setFarmStatus(s)
	Farm.status = s
end

local forceBring

local function itemBlacklisted(o)
	if not o then return true end
	local low = string.lower(o.Name or "")
	return low:find("fleshtrap", 1, true) and true or false
end

local function isBringItem(o)
	if not o or not o.Parent then return false end
	local low = string.lower(tostring(o.Name or ""))
	if low == "" or low:find("fleshtrap", 1, true) or low:find("rottenbanana", 1, true) then return false end
	if low:find("rotten", 1, true) and low:find("banana", 1, true) then return false end
	if low:find("banana", 1, true) or low:find("chomp", 1, true) or low:find("crazed", 1, true)
		or low:find("mystery", 1, true) or low:find("corndog", 1, true) or low:find("medkit", 1, true)
		or low:find("bandage", 1, true) or low:find("remote", 1, true) or low:find("clock", 1, true)
		or low:find("soup", 1, true) or low:find("funco", 1, true) or low:find("remnant", 1, true)
		or low:find("flesh", 1, true) then return true end
	local tagged = false
	pcall(function() tagged = CS:HasTag(o, "Spawneditem") or CS:HasTag(o, "SpawnedItem") end)
	return tagged
end

local function bringItemOnce(safe)
	if invFull() then warnInvFull() return false end
	local r = Root()
	if not r then return false end
	local best, bestD
	local seen = {}
	local function consider(o)
		if not o or seen[o] or not isBringItem(o) then return end
		seen[o] = true
		local p = Part(o)
		if not p or p.Transparency >= 0.95 then return end
		local d = (p.Position - r.Position).Magnitude
		if d <= 300 and (not bestD or d < bestD) and not CryptidNear(p.Position, 24, false) then
			best, bestD = o, d
		end
	end
	pcall(function()
		for _, tag in ipairs({ "Spawneditem", "SpawnedItem" }) do
			for _, o in ipairs(CS:GetTagged(tag)) do consider(o) end
		end
	end)
	for _, o in ipairs(Workspace:GetChildren()) do consider(o) end
	if not best then return false end
	local safePos = safe or getSafePos()
	if not safePos then return false end
	if not forceBring(best, safePos + Vector3.new(0, 2.5, 3)) then return false end
	task.wait(0.12)
	FirePrompt(best)
	task.wait(0.08)
	if best.Parent then FirePrompt(best) end
	return true
end

local function farmLootOnce()
	if not Farm.doLoot then return false end
	if invFull() then
		warnInvFull()
		return false
	end
	local r = Root()
	if not r then return false end
	local best, bestD = nil, 250
	for _, o in ipairs(collectLootTargets()) do
		if not itemBlacklisted(o) then
			local p = Part(o)
			if p and p.Transparency < 0.95 then
				local d = (p.Position - r.Position).Magnitude
				if d < bestD and not CryptidNear(p.Position, 24, false) then
					bestD = d
					best = o
				end
			end
		end
	end
	if not best then return false end
	local dest = r.Position + Vector3.new(0, 1, 0)
	pcall(function()
		if best:IsA("Model") then
			for _, d in ipairs(best:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			best:PivotTo(CFrame.new(dest))
		else
			local bp = Part(best)
			if bp then
				bp.Anchored = true
				bp.CanCollide = false
				bp.CFrame = CFrame.new(dest)
			end
		end
	end)
	task.wait(0.12)
	FirePrompt(best)
	task.wait(0.08)
	if best.Parent and best:FindFirstChildWhichIsA("ProximityPrompt", true) then
		local bp = Part(best)
		if bp then
			local origin = r.CFrame
			SafeTP(bp.Position + Vector3.new(0, 2, 0), nil, 12)
			task.wait(0.1)
			FirePrompt(best)
			pcall(function()
				r.CFrame = origin
				r.AssemblyLinearVelocity = Vector3.zero
			end)
		end
	end
	return true
end

local FarmCorey = { phase = 0, didOne = false } 

local function pickMachine()
	local r = Root()
	if not r then return nil end
	local inCorey = isCoreyArea()
	if not inCorey then
		FarmCorey.phase = 0
		FarmCorey.didOne = false
	elseif FarmCorey.phase == 0 then
		FarmCorey.phase = 1
		FarmCorey.didOne = false
	end
	local best, bestD = nil, 1e9
	for _, m in ipairs(GetMachines()) do
		if not m.Done and m.Position and not isMachineFailed(m.Instance) then
			local allow = false
			if inCorey then
				if FarmCorey.phase == 1 and not FarmCorey.didOne then
					allow = (m.Type == "Arcade" or m.Type == "Storage")
				elseif FarmCorey.phase == 2 or (FarmCorey.phase == 1 and FarmCorey.didOne) then
					allow = m.Type == "Corey"
					FarmCorey.phase = 2
				end
			else
				allow = (m.Type == "Arcade" and Farm.doArc)
					or (m.Type == "Storage" and Farm.doSto)
					or (m.Type == "Corey" and Farm.doCor)
			end
			if allow then
				local d = (m.Position - r.Position).Magnitude
				if d < bestD then
					bestD = d
					best = m
				end
			end
		end
	end
	return best
end

local function farmDoMachine()
	if os.clock() - Farm.lastMach < Settings.machCd then return false end
	local m = pickMachine()
	if not m or not m.Front then
		Farm.empty = Farm.empty + 1
		return false
	end
	if CryptidNear(m.Front, Settings.safeDist, true) then
		setFarmStatus("Waiting Safe")
		if Farm.doSafe then goSafe() end
		return false
	end
	setFarmStatus("Going Machine")
	if not SafeTP(m.Front, m.Position, Settings.safeDist) then
		markMachineFail(m.Instance, 3)
		return false
	end
	Farm.lastMach = os.clock()
	task.wait(0.15)
	if CryptidNear(Root() and Root().Position or m.Front, 36, true) then
		setFarmStatus("Fleeing")
		if Farm.doSafe then goSafe() end
		return false
	end
	setFarmStatus("Completing")
	local target = m.Tagged or m.Instance
	for _ = 1, 8 do
		if not m.Instance or not m.Instance.Parent then break end
		if IsDone(m.Instance) or IsDone(target) then break end
		FirePrompt(m.Instance)
		FireCompleteOne(target, m.Tag)
		FireCompleteOne(m.Instance, m.Tag)
		if m.Type == "Corey" then
			CompleteRemoteOnly("CoreyMachine")
		end
		task.wait(0.2)
	end
	local completed = IsDone(m.Instance) or IsDone(target)
	if completed then
		Farm.empty = 0
		if isCoreyArea() and FarmCorey.phase == 1 and (m.Type == "Arcade" or m.Type == "Storage") then
			FarmCorey.didOne = true
			FarmCorey.phase = 2
		end
	else
		markMachineFail(m.Instance, 4)
		Farm.empty = Farm.empty + 1
	end
	return completed
end

local function farmTick()
	if not Farm.on then
		Farm.state = "IDLE"
		return
	end
	if not Alive() then
		setFarmStatus("Dead")
		Farm.state = "WAIT"
		return
	end
	if isIntermission() then
		setFarmStatus("Intermission")
		Farm.state = "WAIT"
		
		if Hearts() <= 2 then
			local ev = Rem("CardVoteEvent")
			if ev then pcall(function() ev:FireServer("Heartplus") end) end
		end
		return
	end

	local r = Root()
	if r and Farm.doSafe and CryptidNear(r.Position, 34, false) then
		setFarmStatus("Fleeing")
		goSafe()
		Farm.state = "WAIT"
		return
	end

	
	if Farm.doLoot then
		Farm.state = "LOOT"
		if farmLootOnce() then
			setFarmStatus("Looting")
			return
		end
	end

	
	if Farm.doMach then
		Farm.state = "MACHINE"
		local left = 0
		for _, m in ipairs(GetMachines()) do
			if not m.Done then
				if (m.Type == "Arcade" and Farm.doArc)
					or (m.Type == "Storage" and Farm.doSto)
					or (m.Type == "Corey" and Farm.doCor) then
					left = left + 1
				end
			end
		end
		if left > 0 then
			if farmDoMachine() then return end
			setFarmStatus("Waiting Safe")
			return
		end
	end

	
	if Farm.doExit then
		Farm.state = "EXIT"
		if exitReady or Farm.empty >= 3 then
			setFarmStatus("Going Exit")
			if doExit(exitReady) then
				countFloorPass()
				Farm.floors = FloorTrack.passed
				commitFloorLog("Auto-Farm")
				Farm.empty = 0
				setFarmStatus("Exit Done")
				if isCoreyArea() then
					FarmCorey.phase = 3
				else
					FarmCorey.phase = 0
					FarmCorey.didOne = false
				end
			else
				setFarmStatus("Waiting Exit")
			end
		else
			Farm.empty = Farm.empty + 1
			setFarmStatus("Machines Done")
		end
		return
	end

	Farm.state = "CHECK"
	setFarmStatus("Idle")
end


local SplitCheer = { on = false, speed = 10 }

local function fireSplitCheer()
	if not IsPal("split") then return false end
	local c = Char()
	if not c then return false end
	local a1 = c:FindFirstChild("Skills") and (c.Skills:FindFirstChild("Ability1") or c.Skills:FindFirstChild("Skill1"))
	if not a1 then
		for _, d in ipairs(c:GetDescendants()) do
			if d.Name == "Ability1" and d:FindFirstChild("activate") then
				a1 = d
				break
			end
		end
	end
	if not a1 then return false end
	local act = a1:FindFirstChild("activate")
	if not act or not act:IsA("RemoteEvent") then return false end
	local solo = true
	local r = Root()
	if r then
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= Me and pl.Character and (pl.Character:GetAttribute("hearts") or 0) > 0 then
				local hr = pl.Character:FindFirstChild("HumanoidRootPart")
				if hr and (hr.Position - r.Position).Magnitude <= 80 then
					solo = false
					break
				end
			end
		end
	end
	return pcall(function() act:FireServer(solo) end)
end


local Bring = {
	on = false,
	tries = 10,
	coreyRoutine = true,
	pace = 1.2,
	floors = 0,
	status = "Idle",
	busy = false,
	coreyPhase = 0,
	coreyDidOne = false,
	items = false,
	pause = false,
	promptFirst = true,
	maxBringDist = 120,
	retryComplete = 6,
}

forceBring = function(obj, dest)
	if not obj or not dest then return false end
	local root = machineRoot(obj) or obj
	local ok = false
	pcall(function()
		local target = Vector3.new(dest.X, dest.Y, dest.Z)
		if root:IsA("Model") then
			local delta = target - root:GetPivot().Position
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CFrame = d.CFrame + delta
					d.AssemblyLinearVelocity = Vector3.zero
					d.AssemblyAngularVelocity = Vector3.zero
				end
			end
			root:PivotTo(CFrame.new(target))
			ok = true
		else
			local p = Part(root)
			if p then
				p.Anchored = true
				p.CanCollide = false
				p.CFrame = CFrame.new(target)
				p.AssemblyLinearVelocity = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
				ok = true
			end
		end
	end)
	return ok
end

local function completeMachineAtFront(m)
	if not m or not m.Instance or not m.Instance.Parent or IsDone(m.Instance) then
		return false
	end
	if not m.Front then return false end
	if CryptidNear(m.Front, Settings.safeDist or 42, true) then
		return false
	end
	Bring.status = "Corey TP " .. tostring(m.Type)
	if not SafeTP(m.Front, m.Position, Settings.safeDist or 42) then
		markMachineFail(m.Instance, 2.5)
		return false
	end
	task.wait(0.12)
	Bring.status = "Corey Complete " .. tostring(m.Type)
	local target = m.Tagged or m.Instance
	for _ = 1, 12 do
		if not m.Instance or not m.Instance.Parent then break end
		if IsDone(m.Instance) or IsDone(target) then
			return true
		end
		FirePrompt(m.Instance)
		FireCompleteOne(target, m.Tag)
		FireCompleteOne(m.Instance, m.Tag)
		if m.Tag == "CoreyMachine" then
			CompleteRemoteOnly("CoreyMachine")
		end
		task.wait(0.22)
	end
	return IsDone(m.Instance) or IsDone(target)
end

local function bringOneMachine(m, safe)
	if not m or not m.Instance or not m.Instance.Parent or IsDone(m.Instance) then
		return false
	end
	refreshChar(Me.Character)

	if isCoreyArea() then
		return completeMachineAtFront(m)
	end

	Bring.status = "Bring " .. tostring(m.Type)

	local safePos = safe or getSafePos()
	if not safePos then
		return false
	end

	local r = Root()
	if not r then return false end
	if (r.Position - safePos).Magnitude > 14 then
		SafeTP(safePos, nil, 1)
		task.wait(0.12)
		r = Root()
		if not r then return false end
	end

	local bringDest = safePos + Vector3.new(0, 6, 4)
	forceBring(m.Instance, bringDest)
	task.wait(0.2)

	r = Root()
	if not r or not m.Instance or not m.Instance.Parent then return false end
	local mp = Part(m.Instance)
	if mp then
		local stand = mp.Position + Vector3.new(0, 4.5, 0)
		if (stand - safePos).Magnitude > 40 then
			stand = safePos + Vector3.new(0, 5, 2)
		end
		pcall(function()
			r.CFrame = CFrame.lookAt(stand, mp.Position)
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end)
		task.wait(0.12)
	end

	Bring.status = "Complete " .. tostring(m.Type)
	for _ = 1, 10 do
		if not m.Instance or not m.Instance.Parent then break end
		if IsDone(m.Instance) then
			goSafe()
			return true
		end
		r = Root()
		if r and (r.Position - safePos).Magnitude > 22 then
			SafeTP(safePos, nil, 1)
			task.wait(0.08)
		end
		FirePrompt(m.Instance)
		FireCompleteOne(m.Tagged or m.Instance, m.Tag)
		task.wait(0.28)
	end

	local done = m.Instance and m.Instance.Parent and IsDone(m.Instance)
	goSafe()
	return done == true
end

local function pickBringMachine()
	local inCorey = isCoreyArea()
	if not inCorey then
		Bring.coreyPhase = 0
		Bring.coreyDidOne = false
	elseif Bring.coreyPhase == 0 then
		Bring.coreyPhase = 1
		Bring.coreyDidOne = false
	end
	local list = GetMachines()
	local function findType(types)
		for _, m in ipairs(list) do
			if not m.Done and not isMachineFailed(m.Instance) then
				for _, ty in ipairs(types) do
					if m.Type == ty then return m end
				end
			end
		end
		return nil
	end
	if inCorey then
		if Bring.coreyPhase == 1 and not Bring.coreyDidOne then
			local m = findType({ "Storage", "Arcade" })
			if m then return m end
			Bring.coreyPhase = 2
			Bring.coreyDidOne = true
		end
		if Bring.coreyPhase >= 2 then
			Bring.coreyPhase = 2
			return findType({ "Corey" })
		end
		return nil
	end
	
	for _, m in ipairs(list) do
		if not m.Done and not isMachineFailed(m.Instance) then
			return m
		end
	end
	return nil
end

local function bringTick()
	if Bring.busy then return end
	if not Bring.on then
		Bring.status = "Idle"
		return
	end
	if Bring.pause then
		Bring.status = "Paused"
		return
	end
	refreshChar(Me.Character)
	if not Alive() then
		Bring.status = "Dead"
		return
	end
	if isIntermission() then
		Bring.status = "Intermission"
		onMapMaybeChanged()
		return
	end
	Bring.busy = true
	local ok, err = pcall(function()
		onMapMaybeChanged()
		local safe = getSafePos()
		if not safe then
			Bring.status = "No Safe"
			return
		end
		local r = Root()
		if not r then
			Bring.status = "No Character"
			return
		end
		if (r.Position - safe).Magnitude > 18 then
			Bring.status = "Safe"
			SafeTP(safe, nil, 1)
			return
		end

			local target = pickBringMachine()
		if target then
			local done = bringOneMachine(target, safe)
			if done then
				if isCoreyArea() and Bring.coreyPhase == 1 and (target.Type == "Storage" or target.Type == "Arcade") then
					Bring.coreyDidOne = true
					Bring.coreyPhase = 2
				end
			else
				markMachineFail(target.Instance, 5)
			end
			return
		end

		
		Bring.status = "Exit"
		local exited = false
		for _ = 1, 3 do
			if doExit(true) then
				exited = true
				break
			end
			task.wait(0.35)
		end
		if exited then
			countFloorPass()
			Bring.floors = FloorTrack.passed
			commitFloorLog("Bring")
			Bring.status = "Floor Done"
			Bring.coreyPhase = 0
			Bring.coreyDidOne = false
		else
			Bring.status = "Exit Wait"
		end
	end)
	Bring.busy = false
	if not ok then errLog("Bring", err) end
end


local function godModeOneRound()
	local farmWas = Farm.on
	local bringWas = Bring.on
	Farm.on = false
	Bring.on = false
	Stop("Farm")
	Stop("Bring")
	task.spawn(function()
		local h = Hum()
		if h then
			pcall(function() h.Health = 0 end)
		end
		task.wait(0.45)
		pcall(function() Me:LoadCharacter() end)
		local newChar = nil
		pcall(function()
			newChar = Me.CharacterAdded:Wait()
		end)
		task.wait(0.35)
		refreshChar(newChar or Me.Character)
		task.wait(0.25)
		refreshChar(Me.Character)
		Ping("God Mode", "Active for this round.", 3)
		if farmWas then
			Farm.on = true
			Farm.start = os.clock()
			Farm.state = "CHECK"
			Loop("Farm", function() return Farm.on end, function()
				farmTick()
			end, function()
				return Settings.pace
			end)
		end
		if bringWas then
			Bring.on = true
			Loop("Bring", function() return Bring.on end, function()
				bringTick()
			end, function()
				return Bring.pace
			end)
		end
	end)
end


local Util = {
	fullbright = false,
	nofog = false,
	noclip = false,
	fly = false,
	flySpeed = 50,
	maxStam = false,
	noBusy = false,
	afk = false,
}

local lightSnap = nil
local fogSnap = nil
local noclipParts = {}
local flyLV, flyAtt
local flyWant = false

local function snapLighting()
	lightSnap = {
		Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
	}
end

local function applyFullbright()
	pcall(function()
		Lighting.Brightness = 1.25
		Lighting.Ambient = Color3.fromRGB(95, 95, 100)
		Lighting.OutdoorAmbient = Color3.fromRGB(90, 90, 95)
		Lighting.GlobalShadows = true
		if Lighting.ClockTime < 5 or Lighting.ClockTime > 20 then
			Lighting.ClockTime = 12.5
		end
		for _, fx in ipairs(Lighting:GetChildren()) do
			if fx:IsA("ColorCorrectionEffect") then
				if fx.Brightness < -0.2 then fx.Brightness = -0.05 end
			elseif fx:IsA("BloomEffect") then
				fx.Intensity = math.min(fx.Intensity, 0.35)
			elseif fx:IsA("DepthOfFieldEffect") then
				fx.Enabled = false
			end
		end
	end)
end

local function restoreLighting()
	if not lightSnap then return end
	for k, v in pairs(lightSnap) do
		pcall(function() Lighting[k] = v end)
	end
	Lighting.GlobalShadows = true
end

local function applyNoFog()
	pcall(function()
		Lighting.FogEnd = math.max(Lighting.FogEnd, 2200)
		Lighting.FogStart = math.min(Lighting.FogStart, 80)
		for _, fx in ipairs(Lighting:GetChildren()) do
			if fx:IsA("Atmosphere") then
				if not fogSnap then
					fogSnap = { Density = fx.Density, Haze = fx.Haze }
				end
				fx.Density = math.min(fx.Density, 0.18)
				fx.Haze = math.min(fx.Haze, 0.5)
			end
		end
	end)
end

local function restoreFog()
	if fogSnap then
		local at = Lighting:FindFirstChildOfClass("Atmosphere")
		if at then
			at.Density = fogSnap.Density
			at.Haze = fogSnap.Haze
		end
	end
	if lightSnap then
		Lighting.FogEnd = lightSnap.FogEnd
		Lighting.FogStart = lightSnap.FogStart
	end
end

local noclipCharacter, noclipRefreshAt = nil, 0

local function setNoclip(on)
	local c, h = Char(), Hum()
	if not c then return end
	if not on then
		for part, was in pairs(noclipParts) do
			if part and part.Parent then pcall(function() part.CanCollide = was end) end
		end
		table.clear(noclipParts); noclipCharacter = nil
		if h then pcall(function() h.AutoRotate = true; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
		local r = Root()
		if r then pcall(function() r.AssemblyAngularVelocity = Vector3.zero end) end
		return
	end
	local now = os.clock()
	if noclipCharacter == c and now - noclipRefreshAt < 0.12 then return end
	noclipRefreshAt = now
	if noclipCharacter ~= c then table.clear(noclipParts); noclipCharacter = c end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			if noclipParts[d] == nil then noclipParts[d] = d.CanCollide end
			if d.CanCollide then d.CanCollide = false end
		end
	end
end

local flyRebindPending = false

local function stopFly(keepWanted)
	Util.fly = false
	DisconnectKey("fly")
	if flyLV then pcall(function() flyLV:Destroy() end) flyLV = nil end
	if flyAtt then pcall(function() flyAtt:Destroy() end) flyAtt = nil end

	local r = Root()
	if r then
		pcall(function()
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	local h = Hum()
	if h then pcall(function() h.PlatformStand = false; h.AutoRotate = true; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end

	if not keepWanted then
		flyWant = false
	end
end

local function startFly()
	if flyRebindPending then return end
	flyRebindPending = true
	Util.fly = false; DisconnectKey("fly")
	if flyLV then pcall(function() flyLV:Destroy() end); flyLV = nil end
	if flyAtt then pcall(function() flyAtt:Destroy() end); flyAtt = nil end
	task.defer(function()
		flyRebindPending = false
		if not flyWant then return end
		local r, h, c = Root(), Hum(), Char()
		if not r or not h or not c or h.Health <= 0 then return end
		Util.fly = true
		pcall(function() h.AutoRotate = false; h:ChangeState(Enum.HumanoidStateType.Physics) end)
		flyAtt = Instance.new("Attachment"); flyAtt.Name = "EclipseFlyAtt"; flyAtt.Parent = r
		flyLV = Instance.new("LinearVelocity")
		flyLV.Name = "EclipseFlyLV"; flyLV.Attachment0 = flyAtt; flyLV.RelativeTo = Enum.ActuatorRelativeTo.World
		flyLV.MaxForce = math.huge; flyLV.VectorVelocity = Vector3.zero; flyLV.Parent = r
		local bindChar = c
		Conn("fly", RunService.RenderStepped:Connect(function()
			if not flyWant or not Util.fly then return end
			local cur, hum, root, cam = Char(), Hum(), Root(), Workspace.CurrentCamera
			if not cur or not hum or not root or hum.Health <= 0 or not cam then
				Util.fly = false; if flyWant then startFly() end; return
			end
			if cur ~= bindChar or not flyLV or not flyLV.Parent or not flyAtt or not flyAtt.Parent then
				Util.fly = false; if flyWant then startFly() end; return
			end
			local speed = tonumber(Util.flySpeed) or 50
			local input, look = hum.MoveDirection, cam.CFrame.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			local right = cam.CFrame.RightVector
			if flatLook.Magnitude > 0.01 then flatLook = flatLook.Unit end
			local side, forward = input:Dot(right), input:Dot(flatLook)
			local dir = flatLook * forward + right * side
			if math.abs(look.Y) > 0.05 and math.abs(forward) > 0.05 then dir = Vector3.new(dir.X, look.Y * forward, dir.Z) end
			local up = 0
			if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.ButtonR2) or UIS:IsKeyDown(Enum.KeyCode.ButtonA) then up += 1 end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.ButtonL2) then up -= 1 end
			if up ~= 0 then
				dir = Vector3.new(dir.X, up, dir.Z)
			end
			if dir.Magnitude > 1 then dir = dir.Unit end
			flyLV.VectorVelocity = dir * speed
			pcall(function() root.AssemblyAngularVelocity = Vector3.zero end)
		end))
	end)
end

local function SetFly(state)
	flyWant = state == true
	if flyWant then startFly() else stopFly(false) end
end


DisconnectKey("flyChar")
Conn("flyChar", Me.CharacterAdded:Connect(function()
	if flyWant then
		task.delay(0.25, function()
			if flyWant then startFly() end
		end)
	end
end))

local function readMaxStamina(c)
	local mx = tonumber(c:GetAttribute("MaxStamina"))
		or tonumber(c:GetAttribute("maxStamina"))
		or tonumber(c:GetAttribute("MaxStam"))
	if mx and mx > 0 then return mx end
	for _, n in ipairs({ "MaxStamina", "maxStamina", "StaminaMax" }) do
		local v = c:FindFirstChild(n, true)
		if v and v:IsA("NumberValue") and v.Value > 0 then return v.Value end
		if v and v:IsA("IntValue") and v.Value > 0 then return v.Value end
	end
	return 100
end

local function staminaTick()
	if not Util.maxStam then return end
	local c = Char()
	if not c then return end
	local maxS = readMaxStamina(c)
	pcall(function()
		c:SetAttribute("Stamina", maxS)
		c:SetAttribute("stamina", maxS)
		c:SetAttribute("Stam", maxS)
		c:SetAttribute("CurrentStamina", maxS)
	end)
	local h = Hum()
	if h then
		pcall(function()
			h:SetAttribute("Stamina", maxS)
		end)
	end
	for _, n in ipairs({ "Stamina", "stamina", "CurrentStamina", "Stam" }) do
		local v = c:FindFirstChild(n, true)
		if v then
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				v.Value = maxS
			end
		end
	end
	
end

local function busyTick()
	if not Util.noBusy then return end
	local c = Char()
	if c then
		pcall(function() c:SetAttribute("busysorry", 0) end)
	end
end


local Debuff = {
	RottenBanana = false,
	RottenBananaCrash = false,
	Butter = false,
	Puddle = false,
	FreddiePuddle = false,
}

local DebuffProcessed = setmetatable({}, { __mode = "k" })
local debuffConns = {}
local debuffWatchOn = false
local anyDebuffOn
local setDebuff

local function isDebuffEnabled(name)
	return Debuff[name] == true
end

local function removeTouchChildren(inst)
	if not inst or not inst.Parent then return end

	-- Only inspect the immediate children first; this is the common case.
	for _, child in ipairs(inst:GetChildren()) do
		if child.Name == "TouchInterest" or child:IsA("TouchTransmitter") then
			child:Destroy()
		end
	end

	-- If the target is a Model/Folder, walk only its BaseParts rather than
	-- repeatedly scanning all of Workspace.
	if inst:IsA("Model") or inst:IsA("Folder") then
		for _, child in ipairs(inst:GetDescendants()) do
			if child:IsA("BasePart") then
				for _, sub in ipairs(child:GetChildren()) do
					if sub.Name == "TouchInterest" or sub:IsA("TouchTransmitter") then
						sub:Destroy()
					end
				end
			end
		end
	end
end

local function processDebuffObject(inst)
	if not inst or not inst.Parent then return end
	local name = inst.Name
	if not isDebuffEnabled(name) then return end
	if DebuffProcessed[inst] then return end

	DebuffProcessed[inst] = true
	removeTouchChildren(inst)
end

local function processExistingDebuff(name)
	if not isDebuffEnabled(name) then return end
	local obj = Workspace:FindFirstChild(name, true)
	if obj then
		processDebuffObject(obj)
	end
end

local function disconnectDebuffWatch()
	for _, c in pairs(debuffConns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(debuffConns)
	debuffWatchOn = false
end

local function startDebuffWatch()
	if debuffWatchOn then return end
	debuffWatchOn = true

	-- Detect the actual hazard object when it spawns anywhere in Workspace.
	debuffConns.child = Workspace.DescendantAdded:Connect(function(obj)
		if not anyDebuffOn() then return end

		if Debuff[obj.Name] then
			task.defer(processDebuffObject, obj)
			return
		end

		-- If a TouchInterest is created after the hazard was processed,
		-- process only its nearest matching ancestor.
		if obj.Name == "TouchInterest" or obj:IsA("TouchTransmitter") then
			local parent = obj.Parent
			while parent and parent ~= Workspace do
				if Debuff[parent.Name] then
					DebuffProcessed[parent] = nil
					processDebuffObject(parent)
					break
				end
				parent = parent.Parent
			end
		end
	end)

	for name, enabled in pairs(Debuff) do
		if enabled then
			processExistingDebuff(name)
		end
	end
end

anyDebuffOn = function()
	return Debuff.RottenBanana or Debuff.Butter or Debuff.Puddle
end

local function stopDebuffWatch()
	disconnectDebuffWatch()
	DebuffProcessed = setmetatable({}, { __mode = "k" })
end

setDebuff = function(name, on)
	if Debuff[name] == nil then return end
	Debuff[name] = on == true

	if Debuff[name] then
		startDebuffWatch()
		processExistingDebuff(name)
	elseif not anyDebuffOn() then
		stopDebuffWatch()
	end
end

Managers.AntiDebuff = { State = Debuff, Set = setDebuff, Start = startDebuffWatch, Stop = stopDebuffWatch, IsOn = anyDebuffOn }

local TW = { on = false, speed = 3 }

local function stopTPWalk()
	TW.on = false
	DisconnectKey("tw")
end

local function twTick(_, dt)
	if not TW.on then return end
	local h = Hum()
	local c = Char()
	if not h or not c or h.Health <= 0 then return end
	local md = h.MoveDirection
	if md.Magnitude < 0.05 then return end
	local spd = tonumber(TW.speed) or 3
	if spd < 1 then spd = 1 end
	if spd > 15 then spd = 15 end
	dt = math.clamp(tonumber(dt) or 0.016, 0.008, 0.05)
	local translation = md * spd * dt * 10
	pcall(function()
		c:TranslateBy(translation)
	end)
end

local function startTPWalk()
	DisconnectKey("tw")
	if not TW.on then return end
	Conn("tw", RunService.Stepped:Connect(function(time, dt)
		twTick(time, dt)
	end))
end

Managers.Movement = { Fly = SetFly, Noclip = setNoclip, TeleportWalk = function(on)
	TW.on = on == true
	if TW.on then startTPWalk() else stopTPWalk() end
end }


local Features = {
	minigameMode = "Force Win",
	minigameOn = false,
	autoMachines = false,
	autoExit = false,
	tpMode = "Cryptid Check",
	losESP = true,
	progressESP = true,
	minigameESP = true,
	abilityBusy = false,
	bossIntroPause = true,
	pauseFarm = false,
	cryptidAlert = false,
	dodgeCryptids = false,
	dodgeRanged = false,
	machineWalk = false,
	machineNoCollide = false,
	exitWarnWatch = true,
	forceReleaseStuck = true,
	requeueOnInterrupt = true,
	hideItemAware = true,
	bulletESP = false,
	autoMini = false,
	autoCard = false,
	autoBestCard = false,
	autoUseItem = false,
	autoUseMode = "Advanced",
	itemAura = false,
	itemAuraRange = 18,
	machineAura = false,
	machineAuraRange = 22,
	itemAuraBL = {},
	machineAuraBL = {},
}


local GameHooks = {
	exitReadyFlag = false,
	roundNumber = 0,
	staminaBonus = 0,
	hazardState = "",
	bossIntro = false,
}

local function fireBindable(name)
	local ev = RS:FindFirstChild(name)
	if ev and (ev:IsA("BindableEvent") or ev:IsA("RemoteEvent")) then
		pcall(function()
			if ev:IsA("BindableEvent") then
				ev:Fire()
			end
		end)
		return true
	end
	return false
end

local function setupGameHooks()
	pcall(function()
		local rr = RS:FindFirstChild("RoundEnderReady")
		if rr and rr:IsA("RemoteEvent") then
			Conn("hook_exit", rr.OnClientEvent:Connect(function(...)
				GameHooks.exitReadyFlag = true
				local args = { ... }
				for _, a in ipairs(args) do
					if typeof(a) == "Instance" then
						local p = Part(a)
						if p then savedExitPart = p end
					end
				end
				if Features.autoExit and Alive() and not isIntermission() then
					task.defer(function() doExit(true) end)
				end
			end))
		end
	end)
	pcall(function()
		local rn = RS:FindFirstChild("RoundNumber")
		if rn then
			GameHooks.roundNumber = tonumber(rn.Value) or 0
			Conn("hook_round", rn:GetPropertyChangedSignal("Value"):Connect(function()
				GameHooks.roundNumber = tonumber(rn.Value) or GameHooks.roundNumber
			end))
		end
	end)
	pcall(function()
		local sb = RS:FindFirstChild("StaminaBonus")
		if sb then
			GameHooks.staminaBonus = tonumber(sb.Value) or 0
			Conn("hook_stam", sb:GetPropertyChangedSignal("Value"):Connect(function()
				GameHooks.staminaBonus = tonumber(sb.Value) or 0
			end))
		end
	end)
	pcall(function()
		local hs = RS:FindFirstChild("HazardState")
		if hs then
			GameHooks.hazardState = tostring(hs.Value or "")
			Conn("hook_haz", hs:GetPropertyChangedSignal("Value"):Connect(function()
				GameHooks.hazardState = tostring(hs.Value or "")
			end))
		end
	end)
	pcall(function()
		local he = RS:FindFirstChild("HazardEvent")
		if he and he:IsA("RemoteEvent") then
			Conn("hook_haze", he.OnClientEvent:Connect(function(state)
				if state ~= nil then GameHooks.hazardState = tostring(state) end
			end))
		end
	end)
	pcall(function()
		local bi = RS:FindFirstChild("BossIntroEvent")
		if bi and bi:IsA("RemoteEvent") then
			Conn("hook_boss", bi.OnClientEvent:Connect(function()
				GameHooks.bossIntro = true
				Features.pauseFarm = Features.bossIntroPause
				if type(Bring) == "table" then Bring.pause = Features.pauseFarm end
			end))
		end
		local bf = RS:FindFirstChild("BossIntroFinished")
		if bf then
			if bf:IsA("RemoteEvent") then
				Conn("hook_bossf", bf.OnClientEvent:Connect(function()
					GameHooks.bossIntro = false
					Features.pauseFarm = false
					if type(Bring) == "table" then Bring.pause = false end
				end))
			elseif bf:IsA("BindableEvent") then
				Conn("hook_bossf", bf.Event:Connect(function()
					GameHooks.bossIntro = false
					Features.pauseFarm = false
					if type(Bring) == "table" then Bring.pause = false end
				end))
			end
		end
	end)
	pcall(function()
		local ca = RS:FindFirstChild("CryptidAlertEvent")
		if ca and ca:IsA("BindableEvent") then
			Conn("hook_alert", ca.Event:Connect(function()
				Features.cryptidAlert = true
				task.delay(4, function() Features.cryptidAlert = false end)
				if Features.dodgeCryptids and not isIntermission() then
					task.defer(goSafe)
				end
			end))
		end
	end)
	pcall(function()
		local ai = RS:FindFirstChild("ArcadeMachineInterrupt")
		if ai and ai:IsA("RemoteEvent") then
			Conn("hook_intA", ai.OnClientEvent:Connect(function(machine)
				if Features.requeueOnInterrupt and machine then
					task.defer(function()
						FireCompleteOne(machine, "ArcadeMachine")
						fireBindable("ArcadeForceComplete")
					end)
				end
			end))
		end
		local si = RS:FindFirstChild("StorageMachineInterrupt")
		if si and si:IsA("RemoteEvent") then
			Conn("hook_intS", si.OnClientEvent:Connect(function(machine)
				if Features.requeueOnInterrupt and machine then
					task.defer(function()
						FireCompleteOne(machine, "StorageMachine")
					end)
				end
			end))
		end
	end)
	pcall(function()
		local mr = RS:FindFirstChild("MorphRendered")
		if mr and mr:IsA("RemoteEvent") then
			Conn("hook_morph", mr.OnClientEvent:Connect(function()
				task.defer(function()
					if Util and Util.godMode then
					end
				end)
			end))
		end
	end)
	pcall(function()
		local hide = RS:FindFirstChild("HideItemEvent")
		if hide and hide:IsA("RemoteEvent") then
			Conn("hook_hide", hide.OnClientEvent:Connect(function(item)
				if Features.hideItemAware and item and typeof(item) == "Instance" then
					pcall(function() item:SetAttribute("FH_Hidden", true) end)
				end
			end))
		end
	end)
end

task.defer(setupGameHooks)

local CamUtil = {
	fov = 70,
	minZoom = 0.5,
	maxZoom = 128,
	firstPerson = false,
	shiftLock = false,
	jumpOn = false,
	infJump = false,
	antiLag = false,
	noRender = false,
	backflip = false,
	frontflip = false,
	upsideDown = false,
}

local function applyCameraSettings()
	pcall(function()
		local cam = Workspace.CurrentCamera
		if cam then
			cam.FieldOfView = CamUtil.fov
		end
		Me.CameraMinZoomDistance = CamUtil.minZoom
		Me.CameraMaxZoomDistance = CamUtil.maxZoom
		if CamUtil.firstPerson then
			Me.CameraMode = Enum.CameraMode.LockFirstPerson
		else
			Me.CameraMode = Enum.CameraMode.Classic
		end
	end)
end

local function inMachineMinigame()
	local c = Char()
	if c then
		if c:GetAttribute("InArcade") or c:GetAttribute("InStorage") or c:GetAttribute("DoingTask") then
			return true
		end
		if c:GetAttribute("busysorry") == 1 then return true end
	end
	local pg = Me:FindFirstChildOfClass("PlayerGui")
	if not pg then return false end
	for _, n in ipairs({ "Storage", "Arcade", "Corey", "InGame" }) do
		local f = pg:FindFirstChild(n)
		if f then
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("Frame") or d:IsA("ScreenGui") then
					local nm = string.lower(d.Name)
					if (nm:find("minigame", 1, true) or nm:find("mini", 1, true)) and d.Visible then
						return true
					end
				end
			end
		end
	end
	return false
end

local function autoPlayMinigameTick()
	if not Features.autoMini then return end
	if not inMachineMinigame() then return end
	forceWinMinigames()
	fireBindable("ArcadeForceComplete")
	local pg = Me:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local function click(gui)
		if not gui or not gui.Visible then return end
		pcall(function()
			if typeof(firesignal) == "function" and gui.MouseButton1Click then
				firesignal(gui.MouseButton1Click)
			end
			if typeof(fireproximityprompt) == "function" then end
		end)
		pcall(function()
			if gui:IsA("GuiButton") then
				gui.BackgroundTransparency = gui.BackgroundTransparency
			end
		end)
	end
	for _, d in ipairs(pg:GetDescendants()) do
		if d:IsA("TextButton") or d:IsA("ImageButton") then
			local n = string.lower(d.Name .. (d.Text or ""))
			if d.Visible and d.Active and (n:find("hit", 1, true) or n:find("success", 1, true) or n:find("ok", 1, true) or n:find("claim", 1, true) or n == "e") then
				click(d)
			end
		end
	end
end

local function autoCardTick()
	if not Features.autoCard and not Features.autoBestCard then return end
	if not isIntermission() then return end
	local rem = Rem("CardVoteEvent")
	if not rem then return end
	local hearts = 3
	pcall(function()
		local c = Char()
		if c then hearts = tonumber(c:GetAttribute("hearts")) or 3 end
	end)
	local card = "TaskLess"
	if Features.autoBestCard then
		if hearts <= 2 then card = "HeartPlus" else card = "TaskLess" end
	elseif Features.autoCard then
		card = hearts <= 2 and "HeartPlus" or "TaskLess"
	end
	pcall(function() rem:FireServer(card) end)
	pcall(function() rem:FireServer("HeartPlus") end)
end

local function autoUseItemTick()
	if not Features.autoUseItem then return end
	local rem = Rem("UseInventoryItem")
	if not rem then return end
	local c = Char()
	if not c then return end
	local hearts = tonumber(c:GetAttribute("hearts")) or 3
	local poison = tonumber(c:GetAttribute("Poison")) or 0
	local blocked = c:GetAttribute("HealingBlocked")
	local mode = Features.autoUseMode or "Advanced"
	local function useSlot(slot)
		pcall(function()
			rem:FireServer(slot, Vector3.new(0, -1, 0))
		end)
	end
	if mode == "Instant" then
		for i = 1, 3 do useSlot(i) end
		return
	end
	if not blocked then
		if hearts <= 1 then useSlot(1) elseif hearts == 2 then useSlot(2) end
	end
	if poison and poison > 0 then useSlot(1) end
end

local function auraItemsTick()
	if not Features.itemAura then return end
	local r = Root()
	if not r then return end
	local range = Features.itemAuraRange or 18
	local bl = Features.itemAuraBL or {}
	for _, o in ipairs(Workspace:GetChildren()) do
		local low = string.lower(o.Name or "")
		if not bl[low] and isBringItem and isBringItem(o) then
			local p = Part(o)
			if p and (p.Position - r.Position).Magnitude <= range then
				if o:GetAttribute("FH_Hidden") then
				else
					local prompt = o:FindFirstChildWhichIsA("ProximityPrompt", true)
					if prompt then
						pcall(function()
							prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, range + 5)
							prompt.RequiresLineOfSight = false
							if fireproximityprompt then fireproximityprompt(prompt) end
						end)
					end
				end
			end
		end
	end
end

local function auraMachinesTick()
	if not Features.machineAura then return end
	local r = Root()
	if not r then return end
	local range = Features.machineAuraRange or 22
	local bl = Features.machineAuraBL or {}
	for _, tag in ipairs({ "ArcadeMachine", "StorageMachine", "CoreyMachine" }) do
		if bl[string.lower(tag)] then
		else
			pcall(function()
				for _, m in ipairs(CS:GetTagged(tag)) do
					local p = Part(m)
					if p and (p.Position - r.Position).Magnitude <= range then
						local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
						if prompt then
							prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, range + 6)
							prompt.RequiresLineOfSight = false
							if fireproximityprompt then pcall(fireproximityprompt, prompt) end
						end
						FireCompleteOne(m, tag)
					end
				end
			end)
		end
	end
end


local function stripHazardNames()
	local names = {
		"RottenBanana", "Butter", "Puddle", "FreddiePuddle", "RottenBananaCrash",
	}
	for _, n in ipairs(names) do
		if Debuff[n] or Debuff.Puddle or Debuff.RottenBanana then
			local o = Workspace:FindFirstChild(n, true)
			if o then
				for _, d in ipairs(o:GetDescendants()) do
					if d.Name == "TouchInterest" or d:IsA("TouchTransmitter") then
						pcall(function() d:Destroy() end)
					end
				end
			end
		end
	end
	pcall(function()
		for _, n in ipairs(names) do
			if Debuff[n] then
				for _, o in ipairs(Workspace:GetChildren()) do
					if o.Name == n then
						for _, d in ipairs(o:GetDescendants()) do
							if d.Name == "TouchInterest" or d:IsA("TouchTransmitter") then
								pcall(function() d:Destroy() end)
							end
						end
					end
				end
			end
		end
	end)
end

local function dodgeRangedTick()
	if not Features.dodgeRanged and not Features.bulletESP then return end
	local r = Root()
	if not r then return end
	for _, name in ipairs({ "DustyBullet", "CoreyBullet", "CoreyWarning" }) do
		local b = Workspace:FindFirstChild(name)
		if b then
			local p = Part(b)
			if p and (p.Position - r.Position).Magnitude < 40 then
				if Features.dodgeRanged then
					local away = r.Position + (r.Position - p.Position).Unit * 18
					SafeTP(away + Vector3.new(0, 2, 0), nil, 1)
				end
			end
		end
	end
end

local function machineNoCollideTick()
	if not Features.machineNoCollide then return end
	for _, tag in ipairs({ "ArcadeMachine", "StorageMachine", "CoreyMachine" }) do
		pcall(function()
			for _, m in ipairs(CS:GetTagged(tag)) do
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CanCollide = false
					end
				end
			end
		end)
	end
end

local function forceReleaseIfStuck()
	if not Features.forceReleaseStuck then return end
	local c = Char()
	if not c then return end
	local busy = c:GetAttribute("busysorry") == 1 or c:GetAttribute("InArcade") or c:GetAttribute("InStorage") or c:GetAttribute("DoingTask")
	if busy then
		fireBindable("ForceReleaseAll")
	end
end

local function watchExitWarning()
	if not Features.exitWarnWatch or not Features.autoExit then return end
	local anchor = RS:FindFirstChild("BillboardAnchor") or Workspace:FindFirstChild("BillboardAnchor")
	if not anchor then return end
	local gui = anchor:FindFirstChild("ExitWarningGui", true)
	if gui and gui:IsA("BillboardGui") and gui.Enabled ~= false then
		doExit(true)
	end
end


local function L(key)
	local en = {
		ready = "ready",
		invFull = "Inventory is full.",
		leave = "Leaving !!",
		complete = "Complete",
		incomplete = "Incomplete",
		minigame = "In minigame",
	}
	return en[key] or key
end

local function hasLOS(fromPos, toPos)
	if not fromPos or not toPos then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	local me = Char()
	if me then table.insert(filter, me) end
	params.FilterDescendantsInstances = filter
	params.IgnoreWater = true
	local dir = toPos - fromPos
	if dir.Magnitude < 1 then return true end
	local hit = Workspace:Raycast(fromPos, dir.Unit * math.min(dir.Magnitude, 400), params)
	if not hit then return true end
	return (hit.Position - toPos).Magnitude < 6
end

local function forceWinMinigames()
	local roots = {
		Me:FindFirstChild("PlayerGui"),
		game:GetService("StarterGui"),
	}
	for _, root in ipairs(roots) do
		if root then
			for _, mod in ipairs(root:GetDescendants()) do
				if mod:IsA("ModuleScript") then
					local n = string.lower(mod.Name)
					if n:find("minigame", 1, true) or n:find("mini", 1, true) then
						pcall(function()
							local m = require(mod)
							if type(m) == "table" and type(m.run) == "function" then
								m.run = function(...)
									return true
								end
							end
						end)
					end
				end
			end
		end
	end
end

local function minigameTick()
	if not Features.minigameOn then return end
	forceWinMinigames()
end

local function autoMachinesTick()
	if not Features.autoMachines then return end
	if Features.pauseFarm or GameHooks.bossIntro then return end
	if isIntermission() or not Alive() then return end
	remCache = {}
	CompleteRemoteOnly("ArcadeMachine")
	CompleteRemoteOnly("StorageMachine")
	CompleteRemoteOnly("CoreyMachine")
	local list = GetMachines()
	local r = Root()
	if not r then return end
	local best, bestD
	for _, m in ipairs(list) do
		if not m.Done and m.Front and not isMachineFailed(m.Instance) then
			if not CryptidNear(m.Front, Settings.safeDist or 42, true) then
				local d = (m.Front - r.Position).Magnitude
				if not bestD or d < bestD then best, bestD = m, d end
			end
		end
	end
	if not best then return end
	if not SafeTP(best.Front, best.Position, Settings.safeDist or 42) then
		FireCompleteOne(best.Tagged or best.Instance, best.Tag)
		FireCompleteOne(best.Instance, best.Tag)
		return
	end
	task.wait(0.1)
	for _ = 1, 4 do
		FirePrompt(best.Instance)
		FireCompleteOne(best.Tagged or best.Instance, best.Tag)
		FireCompleteOne(best.Instance, best.Tag)
		if best.Tag then CompleteRemoteOnly(best.Tag) end
		task.wait(0.12)
		if IsDone(best.Instance) then break end
	end
end

local function autoExitTick()
	if not Features.autoExit then return end
	if isIntermission() or not Alive() then return end
	doExit(true)
end

local function getPalName()
	local c = Char()
	if not c then return "" end
	return string.lower(tostring(c:GetAttribute("CharacterName") or c:GetAttribute("Pal") or ""))
end

local AbilitySupport = {
	anton = { [1] = false, [2] = true },
	manny = { [1] = false, [2] = false },
	split = { [1] = true, [2] = true },
	freddie = { [1] = false, [2] = true },
	mabel = { [1] = true, [2] = true },
}

local function fireAbility(slot)
	if Features.abilityBusy then return end
	local pal = getPalName()
	local key = pal
	for name in pairs(AbilitySupport) do
		if pal:find(name, 1, true) then key = name break end
	end
	local support = AbilitySupport[key]
	if support and support[slot] == false then
		Ping("Ability", "This ability doesn't work for this Pal", 2)
		return
	end
	Features.abilityBusy = true
	task.spawn(function()
		local c = Char()
		if not c then Features.abilityBusy = false return end
		local skills = c:FindFirstChild("Skills")
		local ab = skills and skills:FindFirstChild("Ability" .. tostring(slot))
		if ab then
			local act = ab:FindFirstChild("activate")
			if act and act:IsA("RemoteEvent") then
				pcall(function() act:FireServer() end)
			elseif act and act:IsA("BindableEvent") then
				pcall(function() act:Fire() end)
			end
		end
		local rem = Rem("SkillActivate") or Rem("AbilityActivate")
		if rem then
			pcall(function() rem:FireServer(slot) end)
		end
		task.wait(0.35)
		Features.abilityBusy = false
	end)
end

local function itemStandPos(obj)
	if not obj then return nil, nil end
	local p = nil
	if obj:IsA("Model") then
		p = obj.PrimaryPart
		if not p then
			local best, bestVol = nil, -1
			for _, d in ipairs(obj:GetDescendants()) do
				if d:IsA("BasePart") and d.Transparency < 0.95 then
					local vol = d.Size.X * d.Size.Y * d.Size.Z
					if vol > bestVol then
						bestVol = vol
						best = d
					end
				end
			end
			p = best
		end
	elseif obj:IsA("BasePart") then
		p = obj
	else
		p = Part(obj)
	end
	if not p then return nil, nil end
	local center = p.Position
	local look = p.CFrame.LookVector
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	local stand = center - look.Unit * 3.5 + Vector3.new(0, 2.5, 0)
	local r = Root()
	if r then
		local toPlayer = (r.Position - center)
		local flat = Vector3.new(toPlayer.X, 0, toPlayer.Z)
		if flat.Magnitude > 0.5 then
			stand = center + flat.Unit * 3.5 + Vector3.new(0, 2.5, 0)
		end
	end
	return stand, center
end

local function collectTeleportTargets(kind)
	local out = {}
	local usedLabels = {}
	local function uniqueLabel(base)
		base = tostring(base or "Target")
		if not usedLabels[base] then
			usedLabels[base] = 1
			return base
		end
		usedLabels[base] = usedLabels[base] + 1
		return base .. " #" .. tostring(usedLabels[base])
	end
	if kind == "Machines" then
		for _, m in ipairs(GetMachines()) do
			if m.Instance and m.Position then
				local base = prettyMachineName(m.Instance) .. (m.Done and (" (" .. L("complete") .. ")") or (" (" .. L("incomplete") .. ")"))
				local label = uniqueLabel(base)
				table.insert(out, {
					label = label,
					pos = m.Front or (m.Position + Vector3.new(0, 2, 0)),
					look = m.Position,
					inst = m.Instance,
				})
			end
		end
	else
		local seen = {}
		local function add(o)
			if not o or seen[o] or not o.Parent then return end
			local low = string.lower(tostring(o.Name or ""))
			if low:find("fleshtrap", 1, true) or low:find("rottenbanana", 1, true) then return end
			local tagged = false
			pcall(function() tagged = CS:HasTag(o, "Spawneditem") or CS:HasTag(o, "SpawnedItem") end)
			if not tagged and not isBringItem(o) then return end
			seen[o] = true
			local stand, center = itemStandPos(o)
			if stand and center then
				local base = tostring(o.Name):gsub("%d+$", "")
				if base == "" then base = "Item" end
				local label = uniqueLabel(base)
				table.insert(out, {
					label = label,
					pos = stand,
					look = center,
					inst = o,
					isItem = true,
				})
			end
		end
		pcall(function()
			for _, tag in ipairs({ "Spawneditem", "SpawnedItem" }) do
				for _, o in ipairs(CS:GetTagged(tag)) do add(o) end
			end
		end)
		for _, o in ipairs(Workspace:GetChildren()) do add(o) end
	end
	return out
end

local function doTeleportTo(entry)
	if not entry then return end
	local pos, look = entry.pos, entry.look
	if entry.isItem and entry.inst and entry.inst.Parent then
		local stand, center = itemStandPos(entry.inst)
		if stand then
			pos, look = stand, center
		end
	end
	if not pos then return end
	local rad = Features.tpMode == "Cryptid Check" and (Settings.safeDist or 42) or 1
	if Features.tpMode == "Cryptid Check" and CryptidNear(pos, rad, true) then
		Ping("Teleport", "Blocked by cryptid", 2)
		return
	end
	SafeTP(pos, look, rad)
end


local ESP = {
	on = { Cryptids = false, Storages = false, Arcanes = false, Coreys = false, Pals = false, Items = false },
	scanBusy = false,
	scanAgain = false,
	colors = {
		Cryptids = Color3.fromRGB(255, 70, 70),
		Storages = Color3.fromRGB(80, 180, 255),
		StoragesDone = Color3.fromRGB(60, 120, 180),
		Arcanes = Color3.fromRGB(180, 100, 255),
		ArcanesDone = Color3.fromRGB(120, 70, 180),
		Coreys = Color3.fromRGB(255, 180, 60),
		Pals = Color3.fromRGB(100, 255, 140),
		Items = Color3.fromRGB(255, 220, 80),
	},
	tags = {
		Progress = true, MachineName = true,
		PalName = true, PalUser = false,
		CryptidName = true, CryptidDist = true,
		ItemName = true,
		Minigame = true,
	},
	los = true,
	bl = {
		Cryptids = false,
		Items = false,
		Machines = false,
		Corey = false,
		Storage = false,
		Arcane = false,
		Anton = false,
		Freddie = false,
		Mabel = false,
		Manny = false,
		Split = false,
		Dusty = false,
		Stargil = false,
		Fan = false,
		CoreyCryptid = false,
	},
	cache = {},
	folder = nil,
	itemHooked = false,
	blItem = {},
	maxObjects = OnPhone and 22 or 48,
	maxDistance = OnPhone and 160 or 260,
	scanInterval = OnPhone and 4.2 or 2.8,
}

local function anyESP()
	for _, v in pairs(ESP.on) do
		if v then return true end
	end
	return false
end

local function isEspHidden(cat, machineType)
	if cat == "Cryptids" then
		return ESP.bl.Cryptids == true
	end
	if cat == "Items" then
		return ESP.bl.Items == true
	end
	if cat == "Pals" then return false end
	if cat == "Storages" then return ESP.bl.Machines == true or ESP.bl.Storage == true end
	if cat == "Arcanes" then return ESP.bl.Machines == true or ESP.bl.Arcane == true end
	if cat == "Coreys" then return ESP.bl.Machines == true or ESP.bl.Corey == true end
	return false
end
local function isEspHiddenMachine(typeName)
	if typeName == "Storage" then return ESP.bl.Machines == true or ESP.bl.Storage == true end
	if typeName == "Arcade" then return ESP.bl.Machines == true or ESP.bl.Arcane == true end
	if typeName == "Corey" then return ESP.bl.Machines == true or ESP.bl.Corey == true end
	return false
end
local function ensureESPFolder()
	if ESP.folder and ESP.folder.Parent then return ESP.folder end
	local pg = Me:FindFirstChildOfClass("PlayerGui") or Me:WaitForChild("PlayerGui", 5)
	if not pg then return nil end
	local f = pg:FindFirstChild("EC_ESP")
	if not f then
		f = Instance.new("Folder")
		f.Name = "EC_ESP"
		f.Parent = pg
	end
	ESP.folder = f
	return f
end

local function removeESP(inst)
	local data = ESP.cache[inst]
	if not data then return end
	pcall(function() if data.hl then data.hl:Destroy() end end)
	pcall(function() if data.bill then data.bill:Destroy() end end)
	ESP.cache[inst] = nil
end

local function clearESP()
	for inst in pairs(ESP.cache) do removeESP(inst) end
end

local function ensureHL(inst, col)
	local data = ESP.cache[inst]
	if data then
		if data.hl and data.hl.Parent then
			data.hl.FillColor = col
			data.hl.OutlineColor = col
			data.hl.Adornee = inst
			if Features.losESP or ESP.los then
				local r = Root()
				local p = Part(inst)
				local visible = true
				if r and p then
					visible = hasLOS(r.Position + Vector3.new(0, 2, 0), p.Position + Vector3.new(0, 2, 0))
				end
				data.hl.FillTransparency = visible and 0.55 or 1
				data.hl.OutlineTransparency = visible and 0.1 or 0.25
			end
		else
			local folder = ensureESPFolder()
			if folder then
				local hl = Instance.new("Highlight")
				hl.Name = "EC_HL"
				hl.Adornee = inst
				hl.FillTransparency = 0.55
				hl.OutlineTransparency = 0.1
				hl.FillColor = col
				hl.OutlineColor = col
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = folder
				data.hl = hl
			end
		end
		if data.bill and data.bill.Parent then
			data.bill.MaxDistance = ESP.maxDistance
			local p = Part(inst)
			if p then data.bill.Adornee = p end
		elseif not data.bill then
			local folder = ensureESPFolder()
			local p = Part(inst)
			if folder and p then
				local bill = Instance.new("BillboardGui")
				bill.Name = "EC_TAG"
				bill.Adornee = p
				bill.Size = UDim2.fromOffset(120, 28)
				bill.StudsOffset = Vector3.new(0, 3.2, 0)
				bill.AlwaysOnTop = true
				bill.MaxDistance = ESP.maxDistance
				bill.Parent = folder
				local lab = Instance.new("TextLabel")
				lab.Name = "T"
				lab.Size = UDim2.fromScale(1, 1)
				lab.BackgroundTransparency = 1
				lab.TextColor3 = Color3.new(1, 1, 1)
				lab.TextStrokeTransparency = 0.4
				lab.Font = Enum.Font.GothamBold
				lab.TextSize = 12
				lab.Text = ""
				lab.Parent = bill
				data.bill = bill
			end
		end
		return data
	end
	local folder = ensureESPFolder()
	if not folder then return nil end
	local hl = Instance.new("Highlight")
	hl.Name = "EC_HL"
	hl.Adornee = inst
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0.1
	hl.FillColor = col
	hl.OutlineColor = col
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = folder
	local bill
	local p = Part(inst)
	if p then
		bill = Instance.new("BillboardGui")
		bill.Name = "EC_TAG"
		bill.Adornee = p
		bill.Size = UDim2.fromOffset(120, 28)
		bill.StudsOffset = Vector3.new(0, 3.2, 0)
		bill.AlwaysOnTop = true
		bill.MaxDistance = ESP.maxDistance
		bill.Parent = folder
		local lab = Instance.new("TextLabel")
		lab.Name = "T"
		lab.Size = UDim2.fromScale(1, 1)
		lab.BackgroundTransparency = 1
		lab.TextColor3 = Color3.new(1, 1, 1)
		lab.TextStrokeTransparency = 0.4
		lab.Font = Enum.Font.GothamBold
		lab.TextSize = 12
		lab.Text = ""
		lab.Parent = bill
	end
	data = { hl = hl, bill = bill, cat = nil }
	ESP.cache[inst] = data
	return data
end

local function setTagText(data, text)
	if not data or not data.bill then return end
	local lab = data.bill:FindFirstChild("T")
	if lab then lab.Text = text or "" end
end

local function espScanWork()
	if not anyESP() then
		if next(ESP.cache) then clearESP() end
		return
	end
	local seen = {}
	local r = Root()

	local created = 0
	local function keep(inst, cat, label, col, asMachine)
		if not inst or not inst.Parent or isEspHidden(cat) then return false end
		if asMachine then
			inst = machineRoot(inst) or inst
		end
		if seen[inst] then
			local data = ESP.cache[inst]
			if data then setTagText(data, label or "") end
			return false
		end
		if r then
			local p = Part(inst)
			if p and (p.Position - r.Position).Magnitude > ESP.maxDistance then return false end
		end
		if created >= ESP.maxObjects then return false end
		seen[inst] = true
		created += 1
		local data = ensureHL(inst, col or ESP.colors[cat] or Color3.new(1, 1, 1))
		if data then
			data.cat = cat
			setTagText(data, label or "")
		end
		return true
	end

	if ESP.on.Cryptids and not ESP.bl.Cryptids then
		refreshCryptids(false)
		for _, o in ipairs(cryptidCache) do
			if o.Parent and not IsPlayerChar(o) then
				local n = o.Name
				local low = string.lower(n)
				local hide = low:find("spawn", 1, true) ~= nil
					or low:find("spawner", 1, true) ~= nil
					or low == "cryptidspawn"
					or low:find("placeholder", 1, true) ~= nil
				if low:find("anton", 1, true) and ESP.bl.Anton then hide = true end
				if low:find("freddie", 1, true) and ESP.bl.Freddie then hide = true end
				if low:find("mabel", 1, true) and ESP.bl.Mabel then hide = true end
				if low:find("manny", 1, true) and ESP.bl.Manny then hide = true end
				if low:find("split", 1, true) and ESP.bl.Split then hide = true end
				if low:find("dusty", 1, true) and ESP.bl.Dusty then hide = true end
				if low:find("stargil", 1, true) and ESP.bl.Stargil then hide = true end
				if (low == "fan" or (low:find("fan", 1, true) and #low <= 8)) and ESP.bl.Fan then hide = true end
				if low:find("corey", 1, true) and not low:find("machine", 1, true) and ESP.bl.CoreyCryptid then hide = true end
				if not hide then
					local label = n
					if low == "fan" then label = "Fan"
					elseif low:find("stargil") then label = "Stargil"
					elseif low:find("anton") then label = "Cryptid Anton"
					elseif low:find("mabel") then label = "Cryptid Mabel"
					elseif low:find("manny") then label = "Cryptid Manny"
					elseif low:find("split") then label = "Cryptid Split"
					elseif low:find("freddie") then label = "Cryptid Freddie"
					end
					if ESP.tags.CryptidDist and r then
						local p = Part(o)
						if p then
							label = label .. string.format(" · %dm", math.floor((p.Position - r.Position).Magnitude))
						end
					end
					if not ESP.tags.CryptidName then label = "" end
					keep(o, "Cryptids", label, ESP.colors.Cryptids)
				end
			end
		end
	end

	if ESP.on.Storages or ESP.on.Arcanes or ESP.on.Coreys then
		for _, m in ipairs(GetMachines()) do
			local on = (m.Type == "Storage" and ESP.on.Storages)
				or (m.Type == "Arcade" and ESP.on.Arcanes)
				or (m.Type == "Corey" and ESP.on.Coreys)
			if on and not isEspHiddenMachine(m.Type) then
				local cat = m.Type == "Storage" and "Storages" or (m.Type == "Arcade" and "Arcanes" or "Coreys")
				local col = ESP.colors[cat]
				if m.Done then
					col = ESP.colors[cat .. "Done"] or col
				end
				local parts = {}
				if ESP.tags.MachineName then table.insert(parts, prettyMachineName(m.Instance)) end
				if ESP.tags.Progress or Features.progressESP then
					local prog = tonumber(m.Instance and m.Instance:GetAttribute("Progress"))
					local need = tonumber(m.Instance and m.Instance:GetAttribute("HowMuch"))
					if prog and need and need > 0 then
						table.insert(parts, string.format("%d/%d", prog, need))
					else
						table.insert(parts, m.Done and L("complete") or L("incomplete"))
					end
				end
				if (ESP.tags.Minigame or Features.minigameESP) then
					local c = Char()
					if c then
						local inMini = c:GetAttribute("InArcade") or c:GetAttribute("InStorage") or c:GetAttribute("DoingTask")
						if inMini == true or inMini == 1 then
							table.insert(parts, L("minigame"))
						end
					end
				end
				keep(m.Instance, cat, table.concat(parts, " · "), col, true)
			end
		end
	end

	if ESP.on.Pals then
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= Me and pl.Character then
				local parts = {}
				if ESP.tags.PalName then
					table.insert(parts, tostring(pl.Character:GetAttribute("CharacterName") or pl.Name))
				end
				if ESP.tags.PalUser then table.insert(parts, pl.Name) end
				keep(pl.Character, "Pals", table.concat(parts, " · "), ESP.colors.Pals)
			end
		end
	end

	if ESP.on.Items and not ESP.bl.Items and created < ESP.maxObjects then
		local function addItem(o)
			if not o or not o.Parent or seen[o] then return end
			local n = string.lower(tostring(o.Name or ""))
			if n:find("fleshtrap", 1, true) then return end
			if ESP.blItem and next(ESP.blItem) then
				for key in pairs(ESP.blItem) do
					if key ~= "all items" and n:find(key, 1, true) then return end
				end
			end
			local tagged = false
			pcall(function() tagged = CS:HasTag(o, "Spawneditem") or CS:HasTag(o, "SpawnedItem") end)
			if not tagged then return end
			local label = ESP.tags.ItemName and tostring(o.Name):gsub("%d+$", "") or ""
			keep(o, "Items", label, ESP.colors.Items)
		end
		pcall(function()
			for _, tag in ipairs({ "Spawneditem", "SpawnedItem" }) do
				for _, o in ipairs(CS:GetTagged(tag)) do
					if created >= ESP.maxObjects then break end
					addItem(o)
				end
				if created >= ESP.maxObjects then break end
			end
		end)
	end

	
	for inst in pairs(ESP.cache) do
		if not seen[inst] or not inst.Parent then removeESP(inst) end
	end
end

local function espScan()
	if ESP.scanBusy then
		ESP.scanAgain = true
		return
	end

	ESP.scanBusy = true
	local ok, err = pcall(espScanWork)
	ESP.scanBusy = false

	if not ok then
		errLog("ESP", err)
	end

	if ESP.scanAgain and anyESP() then
		ESP.scanAgain = false
		task.delay(0.12, function()
			if anyESP() and not ESP.scanBusy then
				espScan()
			end
		end)
	else
		ESP.scanAgain = false
	end
end


local CFG_FOLDER = "PinkBombs_Funhouse_CFGS"
local AUTOLOAD_FILE = CFG_FOLDER .. "/_autoload.ec"
local function cfgPath(name)
	return CFG_FOLDER .. "/" .. tostring(name) .. ".ec"
end

local function ensureCfgFolder()
	if isfolder and not isfolder(CFG_FOLDER) then
		pcall(function() makefolder(CFG_FOLDER) end)
	end
end

local function listConfigs()
	ensureCfgFolder()
	local out = {}
	pcall(function()
		if not listfiles then return end
		for _, path in ipairs(listfiles(CFG_FOLDER)) do
			local name = tostring(path):gsub("\\", "/"):match("([^/]+)%.ec$")
			if name and name ~= "_autoload" then
				table.insert(out, name)
			end
		end
	end)
	table.sort(out)
	if #out == 0 then table.insert(out, "default") end
	return out
end

local function readAutoLoad()
	local ok, raw = pcall(function()
		return readfile(AUTOLOAD_FILE)
	end)
	if not ok or not raw or raw == "" then return false, nil end
	local name = tostring(raw):match("^%s*(.-)%s*$")
	if not name or name == "" then return false, nil end
	return true, name
end

local function serializeSettings()
	return {
		ESP = { on = ESP.on, colors = nil, bl = ESP.bl, tags = ESP.tags },
		Farm = {
			doMach = Farm.doMach, doExit = Farm.doExit, doSafe = Farm.doSafe,
			doArc = Farm.doArc, doSto = Farm.doSto, doCor = Farm.doCor, doLoot = Farm.doLoot,
		},
		Settings = Settings,
		Util = {
			flySpeed = Util.flySpeed,
		},
		Bring = {
		},
	}
end

local function applyConfig(data)
	if type(data) ~= "table" then return end
	if data.Settings then
		for k, v in pairs(data.Settings) do
			if Settings[k] ~= nil then Settings[k] = v end
		end
	end
	if data.Farm then
		for k, v in pairs(data.Farm) do
			if Farm[k] ~= nil then Farm[k] = v end
		end
	end
	if data.ESP and data.ESP.on then
		for k, v in pairs(data.ESP.on) do
			if ESP.on[k] ~= nil then ESP.on[k] = v end
		end
	end
	if data.ESP and data.ESP.bl then
		for k, v in pairs(data.ESP.bl) do if ESP.bl[k] == nil then else ESP.bl[k] = v end end
	elseif data.ESP and data.ESP.blacklist then
		for k, v in pairs(data.ESP.blacklist) do if ESP.bl[k] == nil then else ESP.bl[k] = v end end
	end
	if data.Bring then
		for k, v in pairs(data.Bring) do
			if Bring[k] == nil then else Bring[k] = v end
		end
	end
end


local okWin, Hub = pcall(function()
	return WindUI:CreateWindow({
		Title = HUB_NAME,
		Icon = "door-open",
		Author = "by .HS & .GH",
		Folder = "PinkBombsFunhouse",
		Size = OnPhone and UDim2.fromOffset(420, 580) or UDim2.fromOffset(580, 460),
		Transparent = true,
		Theme = "Dark",
		Resizable = true,
		SideBarWidth = OnPhone and 170 or 200,
		HideSearchBar = true,
		ScrollBarEnabled = true,
		KeySystem = false,
	})
end)
if not okWin or not Hub then
	okWin, Hub = pcall(function()
		return WindUI:CreateWindow({
			Title = HUB_NAME,
			Icon = "door-open",
			Folder = "PinkBombsFunhouse",
			Size = UDim2.fromOffset(560, 440),
			Theme = "Dark",
		})
	end)
end
if not okWin or not Hub then
	toast("Window failed: " .. tostring(Hub), false)
	return
end

local function Tab(title, desc, icon)
	local ok, r = pcall(function()
		return Hub:Tab({
			Title = title, Desc = desc, Icon = icon,
			IconShape = "Square", ShowTabTitle = true, Border = true,
		})
	end)
	if ok and r then return r end
	return Hub:Tab({ Title = title, Desc = desc, Icon = icon })
end

local function Sec(tab, title, desc, icon)
	if not tab then return nil end
	local ok, r = pcall(function()
		return tab:Section({
			Title = title, Desc = desc, Icon = icon,
			TextSize = OnPhone and 17 or 19, Opened = true,
		})
	end)
	if ok and r then return r end
	return tab:Section({ Title = title, Desc = desc })
end

local function Add(sec, method, data)
	if not sec then return nil end
	data = data or {}
	if method == "Slider" and type(data.Value) ~= "table" then
		data.Value = {
			Min = tonumber(data.Min) or 0,
			Max = tonumber(data.Max) or 100,
			Default = tonumber(data.Value) or 0,
		}
		data.Min, data.Max = nil, nil
		if data.Step == nil then data.Step = 1 end
	end
	local fn = sec[method]
	if type(fn) ~= "function" then return nil end
	local ok, r = pcall(function() return fn(sec, data) end)
	if not ok then end
	return r
end


safeCall("UI:Home", function()
	local t = Tab("Home", "Welcome", "solar:home-angle-broken")
	local s = Sec(t, "Home", nil, "solar:moon-stars-bold")
	Add(s, "Paragraph", {
		Title = HUB_NAME,
		Desc = "This script is primarily for Funhouse and may contain errors and bugs. If you find any, please send us a screenshot and a photo of the error/bug and we will fix it as soon as possible.",
	})
	Add(s, "Paragraph", {
		Title = "Version",
		Desc = VERSION,
	})
	Add(s, "Paragraph", {
		Title = "Developers",
		Desc = ".HS & .GH",
	})
	Add(s, "Paragraph", {
		Title = "Tester's",
		Desc = "NexoCat",
	})
end)


safeCall("UI:Visual", function()
	local t = Tab("Visual", "ESP", "solar:eye-bold")
	local s = Sec(t, "ESP", nil, "solar:eye-bold")
	for _, key in ipairs({ "Cryptids", "Storages", "Arcanes", "Coreys", "Pals", "Items" }) do
		Add(s, "Toggle", {
			Title = key .. " ESP",
			Value = false,
			Callback = function(v)
				ESP.on[key] = v
				if not anyESP() then
					Stop("ESP")
					DisconnectKey("espItems")
					DisconnectKey("espItemRemoved")
					clearESP()
				else
					Loop("ESP", anyESP, espScan, ESP.scanInterval)
					if ESP.on.Items and not ESP.itemHooked then
						ESP.itemHooked = true
						local espItemPending = false
						Conn("espItems", Workspace.DescendantAdded:Connect(function(o)
							if not ESP.on.Items or espItemPending then return end
							local tagged = false
							pcall(function() tagged = CS:HasTag(o, "Spawneditem") or CS:HasTag(o, "SpawnedItem") end)
							if not tagged then return end
							espItemPending = true
						task.delay(0.16, function()
							espItemPending = false
							if ESP.on.Items and anyESP() then
								ESP.scanAgain = true
								if not ESP.scanBusy then espScan() end
							end
						end)
						end))
						Conn("espItemRemoved", Workspace.DescendantRemoving:Connect(function(o)
							if ESP.cache[o] then removeESP(o) end
						end))
					end
				end
			end,
		})
	end
	local bl = Sec(t, "Blacklist", "ESP only", "solar:forbidden-circle-bold")
	local function selectedList(v)
		if type(v) == "table" then return v end
		if type(v) == "string" and v ~= "" then return { v } end
		return {}
	end
	local function applyCryptidBl(list)
		local set = {}
		for _, name in ipairs(selectedList(list)) do
			set[tostring(name)] = true
		end
		ESP.bl.Anton = set["Anton"] == true
		ESP.bl.Manny = set["Manny"] == true
		ESP.bl.Split = set["Split"] == true
		ESP.bl.Freddie = set["Freddie"] == true
		ESP.bl.Mabel = set["Mabel"] == true
		ESP.bl.Dusty = set["Dusty"] == true
		ESP.bl.CoreyCryptid = set["Corey"] == true
		ESP.bl.Stargil = set["Stargil"] == true
		ESP.bl.Fan = set["Fan"] == true
		ESP.bl.Cryptids = false
	end
	local function applyMachineBl(list)
		local set = {}
		for _, name in ipairs(selectedList(list)) do
			set[tostring(name)] = true
		end
		ESP.bl.Corey = set["Corey"] == true
		ESP.bl.Storage = set["Storage"] == true
		ESP.bl.Arcane = set["Arcane"] == true
		ESP.bl.Machines = ESP.bl.Corey and ESP.bl.Storage and ESP.bl.Arcane
	end
	Add(bl, "Dropdown", {
		Title = "Cryptid's",
		Values = { "Anton", "Manny", "Split", "Freddie", "Mabel", "Dusty", "Corey", "Stargil", "Fan" },
		Value = {},
		Multi = true,
		AllowNone = true,
		Callback = function(v)
			applyCryptidBl(v)
		end,
	})
	Add(bl, "Dropdown", {
		Title = "Item's",
		Values = {
			"All Items",
			"Bananas",
			"Chomp-a-Chino",
			"Crazed Marshmallows",
			"Medkit",
			"Bandage",
			"Mystery Box",
			"Corndog",
			"Firework",
			"Flesh",
			"Funco",
			"Soup",
			"Noisy Clock",
			"Guide Detector",
			"Remnant",
			"Grappling",
			"Remote",
			"Patch",
		},
		Value = {},
		Multi = true,
		AllowNone = true,
		Callback = function(v)
			ESP.blItem = {}
			local set = {}
			for _, name in ipairs(selectedList(v)) do
				set[tostring(name)] = true
				ESP.blItem[string.lower(tostring(name))] = true
			end
			ESP.bl.Items = set["All Items"] == true
		end,
	})
	Add(bl, "Dropdown", {
		Title = "Machine's",
		Values = { "Corey", "Storage", "Arcane" },
		Value = {},
		Multi = true,
		AllowNone = true,
		Callback = function(v)
			applyMachineBl(v)
		end,
	})
	local cols = Sec(t, "Tags & Colors", nil, "solar:palette-2-bold")
	Add(cols, "Toggle", {
		Title = "Cryptid Name",
		Value = ESP.tags.CryptidName == true,
		Callback = function(v) ESP.tags.CryptidName = v end,
	})
	Add(cols, "Toggle", {
		Title = "Cryptid Distance",
		Value = ESP.tags.CryptidDist == true,
		Callback = function(v) ESP.tags.CryptidDist = v end,
	})
	Add(cols, "Colorpicker", {
		Title = "Cryptids Color",
		Default = ESP.colors.Cryptids,
		Callback = function(c) ESP.colors.Cryptids = c end,
	})
	Add(cols, "Toggle", {
		Title = "Machine Name",
		Value = ESP.tags.MachineName == true,
		Callback = function(v) ESP.tags.MachineName = v end,
	})
	Add(cols, "Toggle", {
		Title = "Machine Progress",
		Value = ESP.tags.Progress == true,
		Callback = function(v) ESP.tags.Progress = v end,
	})
	Add(cols, "Colorpicker", {
		Title = "Storage Color",
		Default = ESP.colors.Storages,
		Callback = function(c) ESP.colors.Storages = c end,
	})
	Add(cols, "Colorpicker", {
		Title = "Storage Done Color",
		Default = ESP.colors.StoragesDone,
		Callback = function(c) ESP.colors.StoragesDone = c end,
	})
	Add(cols, "Colorpicker", {
		Title = "Arcane Color",
		Default = ESP.colors.Arcanes,
		Callback = function(c) ESP.colors.Arcanes = c end,
	})
	Add(cols, "Colorpicker", {
		Title = "Arcane Done Color",
		Default = ESP.colors.ArcanesDone,
		Callback = function(c) ESP.colors.ArcanesDone = c end,
	})
	Add(cols, "Colorpicker", {
		Title = "Corey Color",
		Default = ESP.colors.Coreys,
		Callback = function(c) ESP.colors.Coreys = c end,
	})
	Add(cols, "Toggle", {
		Title = "Pal Name",
		Value = ESP.tags.PalName == true,
		Callback = function(v) ESP.tags.PalName = v end,
	})
	Add(cols, "Toggle", {
		Title = "Pal Username",
		Value = ESP.tags.PalUser == true,
		Callback = function(v) ESP.tags.PalUser = v end,
	})
	Add(cols, "Colorpicker", {
		Title = "Pals Color",
		Default = ESP.colors.Pals,
		Callback = function(c) ESP.colors.Pals = c end,
	})
	Add(cols, "Toggle", {
		Title = "Item Name",
		Value = ESP.tags.ItemName == true,
		Callback = function(v) ESP.tags.ItemName = v end,
	})
	Add(cols, "Colorpicker", {
		Title = "Items Color",
		Default = ESP.colors.Items,
		Callback = function(c) ESP.colors.Items = c end,
	})
	Add(cols, "Toggle", {
		Title = "LOS Outline Mode",
		Value = true,
		Callback = function(v)
			Features.losESP = v == true
			ESP.los = v == true
		end,
	})
	Add(cols, "Toggle", {
		Title = "Progress ESP",
		Value = true,
		Callback = function(v)
			Features.progressESP = v == true
			ESP.tags.Progress = v == true
		end,
	})
	Add(cols, "Toggle", {
		Title = "Minigame ESP",
		Value = true,
		Callback = function(v)
			Features.minigameESP = v == true
			ESP.tags.Minigame = v == true
		end,
	})
end)


safeCall("UI:Automatic", function()
	local t = Tab("Automatic", "Instant systems", "solar:bolt-bold")
	local s = Sec(t, "Instant Complete", nil, "solar:bolt-bold")
	local acA, acS, acC = false, false, false
	local function runInstant(tag)
		remCache = {}
		pcall(function() MachineManager.Clear() end)
		CompleteRemoteOnly(tag)
		local rem = remoteForMachineTag(tag)
		if not rem then return end
		local fired = {}
		local function fire(m)
			if not m or not m.Parent or fired[m] then return end
			fired[m] = true
			pcall(function() rem:FireServer(m, "complete") end)
		end
		pcall(function()
			for _, m in ipairs(CS:GetTagged(tag)) do
				fire(m)
			end
		end)
		pcall(function()
			local keys = {}
			if tag == "ArcadeMachine" then
				keys = { "arcade", "arcane" }
			elseif tag == "CoreyMachine" then
				keys = { "corey" }
			else
				keys = { "storage" }
			end
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("Model") or d:IsA("BasePart") then
					local n = string.lower(d.Name)
					for _, k in ipairs(keys) do
						if n:find(k, 1, true) and not n:find("spawn", 1, true) then
							fire(d)
							break
						end
					end
				end
			end
		end)
	end
	Add(s, "Toggle", {
		Title = "Instant Complete Arcane",
		Value = false,
		Callback = function(v)
			acA = v == true
			if not v then Stop("AC_A") return end
			Loop("AC_A", function() return acA end, function()
				runInstant("ArcadeMachine")
			end, OnPhone and 0.9 or 0.55)
		end,
	})
	Add(s, "Toggle", {
		Title = "Instant Complete Storage",
		Value = false,
		Callback = function(v)
			acS = v == true
			if not v then Stop("AC_S") return end
			Loop("AC_S", function() return acS end, function()
				runInstant("StorageMachine")
			end, OnPhone and 0.85 or 0.5)
		end,
	})
	Add(s, "Toggle", {
		Title = "Instant Complete Corey",
		Value = false,
		Callback = function(v)
			acC = v == true
			if not v then Stop("AC_C") return end
			Loop("AC_C", function() return acC end, function()
				runInstant("CoreyMachine")
			end, OnPhone and 0.9 or 0.55)
		end,
	})

	local mc = Sec(t, "Machine Complete Modes", nil, "solar:gamepad-bold")
	Add(mc, "Toggle", {
		Title = "Force Win Minigame",
		Value = false,
		Callback = function(v)
			Features.minigameOn = v == true
			Features.minigameMode = "Force Win"
			if not v then Stop("MiniA") return end
			Loop("MiniA", function() return Features.minigameOn end, minigameTick, OnPhone and 0.7 or 0.4)
		end,
	})

	local auto = Sec(t, "Auto", nil, "solar:bolt-circle-bold")
	Add(auto, "Toggle", {
		Title = "Auto Machines",
		Value = false,
		Callback = function(v)
			Features.autoMachines = v == true
			if not v then Stop("AutoMach") return end
			Loop("AutoMach", function() return Features.autoMachines end, autoMachinesTick, OnPhone and 1.0 or 0.75)
		end,
	})
	Add(auto, "Toggle", {
		Title = "Auto Exit",
		Value = false,
		Callback = function(v)
			Features.autoExit = v == true
			if not v then Stop("AutoEx") return end
			Loop("AutoEx", function() return Features.autoExit end, autoExitTick, OnPhone and 1.4 or 1.0)
		end,
	})

	Add(auto, "Toggle", {
		Title = "Auto Play Mini-Games",
		Desc = "Only while in a machine minigame (PC/Mobile).",
		Value = false,
		Callback = function(v)
			Features.autoMini = v == true
			if not v then Stop("AutoMini") return end
			Loop("AutoMini", function() return Features.autoMini end, autoPlayMinigameTick, OnPhone and 0.35 or 0.22)
		end,
	})
	Add(auto, "Toggle", {
		Title = "Auto Card",
		Value = false,
		Callback = function(v)
			Features.autoCard = v == true
			if not v then Stop("AutoCard") return end
			Loop("AutoCard", function() return Features.autoCard or Features.autoBestCard end, autoCardTick, 1.2)
		end,
	})
	Add(auto, "Toggle", {
		Title = "Auto Best Card",
		Desc = "HeartPlus when low hearts, else TaskLess.",
		Value = false,
		Callback = function(v)
			Features.autoBestCard = v == true
			if not v then
				if not Features.autoCard then Stop("AutoCard") end
				return
			end
			Loop("AutoCard", function() return Features.autoCard or Features.autoBestCard end, autoCardTick, 1.2)
		end,
	})
	Add(auto, "Toggle", {
		Title = "Auto Use Item",
		Value = false,
		Callback = function(v)
			Features.autoUseItem = v == true
			if not v then Stop("AutoUse") return end
			Loop("AutoUse", function() return Features.autoUseItem end, autoUseItemTick, 0.9)
		end,
	})
	Add(auto, "Dropdown", {
		Title = "Auto Use Behavior",
		Values = { "Advanced", "Instant" },
		Value = "Advanced",
		Callback = function(v)
			Features.autoUseMode = v or "Advanced"
		end,
	})
	Add(auto, "Toggle", {
		Title = "Item Aura",
		Value = false,
		Callback = function(v)
			Features.itemAura = v == true
			if not v then Stop("ItAura") return end
			Loop("ItAura", function() return Features.itemAura end, auraItemsTick, 0.45)
		end,
	})
	Add(auto, "Toggle", {
		Title = "Machine Aura",
		Value = false,
		Callback = function(v)
			Features.machineAura = v == true
			if not v then Stop("McAura") return end
			Loop("McAura", function() return Features.machineAura end, auraMachinesTick, 0.55)
		end,
	})
	Add(auto, "Slider", {
		Title = "Item Aura Range",
		Value = 18, Min = 8, Max = 40, Step = 1,
		Callback = function(v) Features.itemAuraRange = tonumber(v) or 18 end,
	})
	Add(auto, "Slider", {
		Title = "Machine Aura Range",
		Value = 22, Min = 10, Max = 50, Step = 1,
		Callback = function(v) Features.machineAuraRange = tonumber(v) or 22 end,
	})

	local tp = Sec(t, "Teleports", nil, "solar:map-arrow-bold")
	local tpKind = "Machines"
	local tpLabels = { "None" }
	local tpMap = {}
	local function refreshTpList()
		local list = collectTeleportTargets(tpKind)
		tpMap = {}
		tpLabels = {}
		for _, e in ipairs(list) do
			table.insert(tpLabels, e.label)
			tpMap[e.label] = e
		end
		if #tpLabels == 0 then tpLabels = { "None" } end
	end
	refreshTpList()
	local selectedTp = tpLabels[1]
	local tpDrop
	tpDrop = Add(tp, "Dropdown", {
		Title = "Target List",
		Values = tpLabels,
		Value = selectedTp,
		Callback = function(v)
			if type(v) == "string" then selectedTp = v end
		end,
	})
	Add(tp, "Dropdown", {
		Title = "List Type",
		Values = { "Machines", "Items" },
		Value = "Machines",
		Callback = function(v)
			if type(v) == "string" then
				tpKind = v
				refreshTpList()
				selectedTp = tpLabels[1]
				if tpDrop and tpDrop.Refresh then pcall(function() tpDrop:Refresh(tpLabels) end) end
				if tpDrop and tpDrop.SetValues then pcall(function() tpDrop:SetValues(tpLabels) end) end
			end
		end,
	})
	Add(tp, "Dropdown", {
		Title = "Teleport Mode",
		Values = { "Normal", "Cryptid Check" },
		Value = Features.tpMode,
		Callback = function(v)
			if type(v) == "string" then Features.tpMode = v end
		end,
	})
	Add(tp, "Button", {
		Title = "Refresh List",
		Callback = function()
			refreshTpList()
			selectedTp = tpLabels[1]
			if tpDrop and tpDrop.Refresh then pcall(function() tpDrop:Refresh(tpLabels) end) end
			if tpDrop and tpDrop.SetValues then pcall(function() tpDrop:SetValues(tpLabels) end) end
			Ping("Teleport", "List refreshed", 1.5)
		end,
	})
	Add(tp, "Button", {
		Title = "Teleport",
		Callback = function()
			local entry = tpMap[selectedTp]
			if not entry then
				refreshTpList()
				entry = tpMap[selectedTp]
			end
			if entry then doTeleportTo(entry) else Ping("Teleport", "No target", 1.5) end
		end,
	})

	local ab = Sec(t, "Abilities", nil, "solar:hand-stars-bold")
	Add(ab, "Button", {
		Title = "Ability 1",
		Callback = function() fireAbility(1) end,
	})
	Add(ab, "Button", {
		Title = "Ability 2",
		Callback = function() fireAbility(2) end,
	})

	local imm = Sec(t, "Immunity", nil, "solar:shield-bold")
	local Immunity = { Snuggles = false, Triplets = false, Dolly = false, StarGirl = false }

	local function isStarGirlModel(inst)
		if not inst then return false end
		local n = string.lower(inst.Name)
		return n == "stargirl" or n:find("stargil", 1, true) ~= nil
	end

	local function isFanModel(inst)
		if not inst then return false end
		return string.lower(inst.Name) == "fan"
	end

	local immStarConn
	local immFanConn
	local fanWindParts = {}

	local function stripStarGirlHitboxes()
		if not Immunity.StarGirl then return end
		local function walk(node, depth)
			if not node or depth > 6 then return end
			for _, c in ipairs(node:GetChildren()) do
				if c:IsA("Model") and isStarGirlModel(c) then
					for _, d in ipairs(c:GetChildren()) do
						if d:IsA("BasePart") then
							local n = string.lower(d.Name)
							if n == "hitbox" or n:find("hitbox", 1, true) then
								pcall(function() d:Destroy() end)
							end
						elseif d:IsA("Folder") or d:IsA("Model") then
							for _, sub in ipairs(d:GetChildren()) do
								if sub:IsA("BasePart") then
									local n = string.lower(sub.Name)
									if n == "hitbox" or n:find("hitbox", 1, true) then
										pcall(function() sub:Destroy() end)
									end
								end
							end
						end
					end
				elseif c:IsA("Folder") or c:IsA("Model") then
					walk(c, depth + 1)
				end
			end
		end
		pcall(function() walk(Workspace, 0) end)
	end

	local function cacheFanWindParts()
		table.clear(fanWindParts)
		local function walk(node, depth)
			if not node or depth > 6 then return end
			for _, c in ipairs(node:GetChildren()) do
				if c:IsA("BasePart") and string.lower(c.Name):find("wind", 1, true) then
					local fan = c:FindFirstAncestorWhichIsA("Model")
					if fan and isFanModel(fan) then
						fanWindParts[c] = true
					end
				elseif c:IsA("Model") and isFanModel(c) then
					for _, d in ipairs(c:GetDescendants()) do
						if d:IsA("BasePart") and string.lower(d.Name):find("wind", 1, true) then
							fanWindParts[d] = true
						end
					end
				elseif c:IsA("Folder") or c:IsA("Model") then
					walk(c, depth + 1)
				end
			end
		end
		pcall(function() walk(Workspace, 0) end)
	end

	local function fanWindImmunity()
		if not Immunity.Fan then return end
		local char = Me.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not hum then return end

		local pos = root.Position
		local insideWind = false
		for part in pairs(fanWindParts) do
			if not part.Parent then
				fanWindParts[part] = nil
			else
				local lp = part.CFrame:PointToObjectSpace(pos)
				local half = part.Size * 0.5
				if math.abs(lp.X) <= half.X + 1 and math.abs(lp.Y) <= half.Y + 1 and math.abs(lp.Z) <= half.Z + 1 then
					insideWind = true
					break
				end
			end
		end

		if insideWind then
			local v = root.AssemblyLinearVelocity
			local move = hum.MoveDirection
			local horizontalSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
			if move.Magnitude > 0.05 then
				local speed = math.max(horizontalSpeed, hum.WalkSpeed)
				root.AssemblyLinearVelocity = Vector3.new(move.X * speed, v.Y, move.Z * speed)
			else
				root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
			end
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local function startImmunityObservers()
		if Immunity.StarGirl and not immStarConn then
			immStarConn = Workspace.DescendantAdded:Connect(function(obj)
				if not Immunity.StarGirl or not obj:IsA("BasePart") then return end
				local n = string.lower(obj.Name)
				local model = obj:FindFirstAncestorWhichIsA("Model")
				if model and isStarGirlModel(model) and (n == "hitbox" or n:find("hitbox", 1, true)) then
					pcall(function() obj:Destroy() end)
				end
			end)
		end
		if Immunity.Fan and not immFanConn then
			immFanConn = Workspace.DescendantAdded:Connect(function(obj)
				if not Immunity.Fan or not obj:IsA("BasePart") then return end
				if string.lower(obj.Name):find("wind", 1, true) then
					local fan = obj:FindFirstAncestorWhichIsA("Model")
					if fan and isFanModel(fan) then fanWindParts[obj] = true end
				end
			end)
		end
	end

	local function stopImmunityObservers()
		if immStarConn then immStarConn:Disconnect(); immStarConn = nil end
		if immFanConn then immFanConn:Disconnect(); immFanConn = nil end
		table.clear(fanWindParts)
	end

	local function stripImm()
		if Immunity.Triplets then pcall(function() local r = RS:FindFirstChild("TripletAlert"); if r then r:Destroy() end end) end
		if Immunity.Snuggles or Immunity.Dolly then pcall(function() local r = RS:FindFirstChild("SnugglesAlert"); if r then r:Destroy() end end) end
		
	end

	Managers.Immunity = { State = Immunity, Apply = stripImm, Set = function(name, on)
		if Immunity[name] == nil then return end
		Immunity[name] = on == true
		if not (Immunity.Snuggles or Immunity.Triplets or Immunity.Dolly or Immunity.StarGirl ) then
			Stop("Imm")
			stopImmunityObservers()
			return
		end
		if Immunity.StarGirl then stripStarGirlHitboxes() end
		startImmunityObservers()
		stripImm()
		Loop("Imm", function() return Immunity.Snuggles or Immunity.Triplets or Immunity.Dolly or Immunity.StarGirl  end, stripImm, 0.15)
	end }
	Add(imm, "Toggle", {
		Title = "Snuggles Immunity",
		Value = false,
		Callback = function(v)
			Managers.Immunity.Set("Snuggles", v)
		end,
	})
	Add(imm, "Toggle", {
		Title = "Triplets Immunity",
		Value = false,
		Callback = function(v)
			Managers.Immunity.Set("Triplets", v)
		end,
	})
	Add(imm, "Toggle", {
		Title = "Dolly Immunity",
		Value = false,
		Callback = function(v)
			Managers.Immunity.Set("Dolly", v)
		end,
	})
	Add(imm, "Toggle", {
		Title = "StarGirl Immunity",
		Value = false,
		Callback = function(v)
			Managers.Immunity.Set("StarGirl", v)
		end,
	})
end)


safeCall("UI:Farms", function()
	local t = Tab("Farms", "Auto Farm", "solar:gameboy-bold")
	local farm = Sec(t, "Auto Farm", nil, "solar:gameboy-bold")
	local stats = Add(farm, "Paragraph", {
		Title = "Farm Stats",
		Desc = "Runtime: 00:00:00\nFloors: 0\nRemnants: 0\nStatus: Idle",
	})
	local function refreshStats()
		if not stats or not stats.SetDesc then return end
		local rt = Farm.start > 0 and math.floor(os.clock() - Farm.start) or 0
		local h = math.floor(rt / 3600)
		local m = math.floor((rt % 3600) / 60)
		local s = rt % 60
		local rem = tonumber(Me:GetAttribute("Remnants")) or 0
		pcall(function()
			stats:SetDesc(string.format(
				"Runtime: %02d:%02d:%02d\nCurrent Floor: %s\nFloors Passed: %d\nRemnants: %d\nState: %s\nStatus: %s",
				h, m, s, tostring(FloorTrack.current or "?"), FloorTrack.passed, rem, Farm.state, Farm.status
			))
		end)
	end

	Add(farm, "Toggle", {
		Title = "Enable Auto Farm",
		Desc = "Full auto farm. Some rare maps may still act weird.",
		Value = false,
		Callback = function(v)
			Farm.on = v
			if not v then
				Stop("Farm")
				Farm.state = "IDLE"
				setFarmStatus("Idle")
				refreshStats()
				return
			end
			Farm.start = os.clock()
			Farm.floors = 0
			Farm.empty = 0
			FloorTrack.passed = 0
			FloorTrack.startFloor = readFloorNumber()
			FloorTrack.lastFloorNum = FloorTrack.startFloor
			FloorTrack.exitCounted = false
			FloorTrack.current = FloorTrack.startFloor
			FloorTrack.lastMap = ""
			onMapMaybeChanged()
			setFarmStatus("Starting")
			Loop("Farm", function() return Farm.on end, function()
				farmTick()
				refreshStats()
			end, function() return Settings.pace end)
		end,
	})
	Add(farm, "Toggle", {
		Title = "Auto Machines",
		Value = false,
		Callback = function(v) Farm.doMach = v end,
	})
	Add(farm, "Toggle", {
		Title = "Auto Exit",
		Value = false,
		Callback = function(v) Farm.doExit = v end,
	})
	Add(farm, "Toggle", {
		Title = "Flee to Safe",
		Value = false,
		Callback = function(v) Farm.doSafe = v end,
	})
	Add(farm, "Toggle", {
		Title = "Auto Loot Remnants",
		Value = false,
		Callback = function(v) Farm.doLoot = v end,
	})
	Add(farm, "Toggle", {
		Title = "Wall Check Cryptid",
		Value = true,
		Callback = function(v) Settings.wallCheck = v end,
	})
	Add(farm, "Button", {
		Title = "Exit Right Now",
		Callback = function() doExit(true) end,
	})
	Add(farm, "Button", {
		Title = "Safe Spot Now",
		Callback = function() goSafe() end,
	})

	local adv = Sec(t, "Farm Settings", nil, "solar:settings-bold")
	Add(adv, "Toggle", { Title = "Include Arcane", Value = true, Callback = function(v) Farm.doArc = v end })
	Add(adv, "Toggle", { Title = "Include Storage", Value = true, Callback = function(v) Farm.doSto = v end })
	Add(adv, "Toggle", { Title = "Include Corey", Value = true, Callback = function(v) Farm.doCor = v end })
	Add(adv, "Slider", {
		Title = "Farm Speed",
		Value = 1.0, Min = 0.4, Max = 2.5, Step = 0.1,
		Callback = function(v) Settings.pace = tonumber(v) or 1 end,
	})
	Add(adv, "Slider", {
		Title = "Machine Cooldown",
		Value = 1.6, Min = 0.5, Max = 4, Step = 0.1,
		Callback = function(v) Settings.machCd = tonumber(v) or 1.6 end,
	})
	Add(adv, "Slider", {
		Title = "Exit Cooldown",
		Value = 2.2, Min = 1, Max = 5, Step = 0.1,
		Callback = function(v) Settings.exitCd = tonumber(v) or 2.2 end,
	})
	Add(adv, "Slider", {
		Title = "Exit Y Offset",
		Value = 2.5, Min = 0, Max = 6, Step = 0.5,
		Callback = function(v) Settings.exitY = tonumber(v) or 2.5 end,
	})
	Add(adv, "Slider", {
		Title = "Cryptid Safe Distance",
		Value = 52, Min = 24, Max = 90, Step = 2,
		Callback = function(v) Settings.safeDist = tonumber(v) or 52 end,
	})

	Add(adv, "Toggle", {
		Title = "Prefer Nearest Machine",
		Value = true,
		Callback = function(v) Farm.priorityNearest = v == true end,
	})
	Add(adv, "Toggle", {
		Title = "Skip Machines if Chased",
		Value = true,
		Callback = function(v) Farm.skipIfChased = v == true end,
	})
	Add(adv, "Toggle", {
		Title = "Aggressive Complete",
		Desc = "More complete attempts per machine.",
		Value = true,
		Callback = function(v) Farm.aggressiveComplete = v == true end,
	})
	Add(adv, "Toggle", {
		Title = "Camera Lock on Machines",
		Value = false,
		Callback = function(v) Farm.camLock = v == true end,
	})
	Add(adv, "Slider", {
		Title = "Wait in Safe (sec)",
		Value = 2, Min = 0.5, Max = 8, Step = 0.5,
		Callback = function(v) Farm.waitSafeSec = tonumber(v) or 2 end,
	})

	local split = Sec(t, "Method Split's", nil, "solar:hand-heart-bold")
	Add(split, "Slider", {
		Title = "Method Split's Speed",
		Value = 10, Min = 1, Max = 30, Step = 1,
		Callback = function(v) SplitCheer.speed = tonumber(v) or 10 end,
	})
	Add(split, "Toggle", {
		Title = "Method Split's Auto-Farm",
		Value = false,
		Callback = function(v)
			if v and not IsPal("split") then
				SplitCheer.on = false
				Ping("Split", "Only works as Split.", 2)
				return
			end
			SplitCheer.on = v == true
			if not SplitCheer.on then
				Stop("Split")
				return
			end
			Stop("Split")
			Loop("Split", function() return SplitCheer.on == true end, function()
				if not IsPal("split") then
					SplitCheer.on = false
					Stop("Split")
					Ping("Split", "Only works as Split.", 2)
					return
				end
				local ok = fireSplitCheer()
			end, function()
				local sp = tonumber(SplitCheer.speed) or 10
				return math.max(0.03, sp * 0.08)
			end)
		end,
	})

	local bring = Sec(t, "Bring Farm V2", nil, "solar:box-minimalistic-bold")
	Add(bring, "Toggle", {
		Title = "Enable Bring Farm",
		Value = false,
		Callback = function(v)
			Bring.on = v
			if not v then
				Stop("Bring")
				Bring.status = "Idle"
				return
			end
			Bring.floors = 0
			Bring.pause = false
			FloorTrack.passed = 0
			FloorTrack.startFloor = readFloorNumber()
			FloorTrack.lastFloorNum = FloorTrack.startFloor
			FloorTrack.exitCounted = false
			FloorTrack.current = FloorTrack.startFloor
			FloorTrack.lastMap = ""
			Bring.coreyPhase = 0
			Bring.coreyDidOne = false
			onMapMaybeChanged()
			refreshChar(Me.Character)
			sessionReset("Bring")
			Loop("Bring", function() return Bring.on end, function()
				if not isIntermission() then
					FloorSession.mode = "Bring"
					sessionNoteCryptids()
				end
				bringTick()
			end, function() return Bring.pace end)
		end,
	})
	Add(bring, "Toggle", {
		Title = "Bring Items",
		Value = false,
		Callback = function(v) Bring.items = v == true end,
	})
	Add(bring, "Toggle", {
		Title = "Prompt Before Remote",
		Value = true,
		Callback = function(v) Bring.promptFirst = v == true end,
	})
	Add(bring, "Toggle", {
		Title = "Corey Special Routine",
		Value = true,
		Callback = function(v) Bring.coreyRoutine = v == true end,
	})
	Add(bring, "Slider", {
		Title = "Bring Farm Speed",
		Value = 1.2, Min = 0.4, Max = 3, Step = 0.1,
		Callback = function(v) Bring.pace = tonumber(v) or 1.2 end,
	})
	Add(bring, "Slider", {
		Title = "Bring Complete Tries",
		Value = 10, Min = 4, Max = 16, Step = 1,
		Callback = function(v) Bring.tries = math.floor(tonumber(v) or 10) end,
	})
	Add(bring, "Slider", {
		Title = "Retry Complete Count",
		Value = 6, Min = 2, Max = 12, Step = 1,
		Callback = function(v) Bring.retryComplete = math.floor(tonumber(v) or 6) end,
	})
	Add(bring, "Slider", {
		Title = "Max Bring Distance",
		Value = 120, Min = 40, Max = 250, Step = 5,
		Callback = function(v) Bring.maxBringDist = tonumber(v) or 120 end,
	})
end)

safeCall("UI:Keybinds", function()
	local t = Tab("Keybinds", "Hotkeys", "solar:keyboard-bold")
	local s = Sec(t, "Keybinds", nil, "solar:keyboard-bold")
	local binds = {
		{ name = "Toggle Farm", key = Enum.KeyCode.F },
		{ name = "Toggle Bring", key = Enum.KeyCode.B },
		{ name = "Safe Spot", key = Enum.KeyCode.V },
		{ name = "Exit Now", key = Enum.KeyCode.G },
		{ name = "Toggle Fly", key = Enum.KeyCode.X },
	}
	for _, b in ipairs(binds) do
		Add(s, "Paragraph", {
			Title = b.name,
			Desc = "Default: " .. tostring(b.key.Name),
		})
	end
	Conn("keybinds", UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.V then
			pcall(goSafe)
		elseif input.KeyCode == Enum.KeyCode.G then
			pcall(function() doExit(true) end)
		elseif input.KeyCode == Enum.KeyCode.X then
			pcall(function() SetFly(not flyWant) end)
		end
	end))
end)


safeCall("UI:Utility", function()
	local t = Tab("Utility", "Helpers", "solar:widget-bold")

	local help = Sec(t, "Helper's", nil, "solar:widget-bold")
	Add(help, "Button", {
		Title = "Skip to floor 10+ Experimental",
		Desc = "GameTP to in-dev place. If blocked, use IY GameTP with ID: 127752496426569. Delta: disable Verify Teleport.",
		Callback = function()
			local placeId = 127752496426569
			local lp = game:GetService("Players").LocalPlayer
			if not lp then
				Notify("Skip Floor", "Player not found.", 3)
				return
			end
			Notify("Skip Floor", "GameTP...", 3)
			pcall(function()
				game:GetService("TeleportService"):Teleport(placeId, lp)
			end)
		end,
	})
	Add(help, "Button", {
		Title = "Force Release Stuck",
		Desc = "Fires ForceReleaseAll (local) if stuck in a machine/minigame.",
		Callback = function()
			fireBindable("ForceReleaseAll")
			Notify("Release", "Tried ForceReleaseAll", 2)
		end,
	})
	Add(help, "Toggle", {
		Title = "Fullbright",
		Value = false,
		Callback = function(v)
			Util.fullbright = v
			if v then
				if not lightSnap then snapLighting() end
				Loop("FB", function() return Util.fullbright end, applyFullbright, 0.35)
			else
				Stop("FB")
				restoreLighting()
			end
		end,
	})
	Add(help, "Toggle", {
		Title = "No Fog",
		Value = false,
		Callback = function(v)
			Util.nofog = v
			if v then
				if not lightSnap then snapLighting() end
				Loop("Fog", function() return Util.nofog end, applyNoFog, 0.35)
			else
				Stop("Fog")
				restoreFog()
			end
		end,
	})
	Add(help, "Toggle", {
		Title = "Always Max Stamina",
		Value = false,
		Callback = function(v)
			Util.maxStam = v
			DisconnectKey("stamAttr")
			if not v then Stop("Stam") return end
			staminaTick()
			local c = Char()
			if c then
				for _, attr in ipairs({ "Stamina", "stamina", "CurrentStamina" }) do
					pcall(function()
						Conn("stamAttr", c:GetAttributeChangedSignal(attr):Connect(function()
							if Util.maxStam then staminaTick() end
						end))
					end)
				end
			end
			Conn("stamAttr", Me.CharacterAdded:Connect(function(ch)
				task.wait(0.3)
				if not Util.maxStam then return end
				staminaTick()
			end))
			Loop("Stam", function() return Util.maxStam end, staminaTick, 0.18)
		end,
	})
	Add(help, "Toggle", {
		Title = "Skip Busy Lock",
		Value = false,
		Callback = function(v)
			Util.noBusy = v
			if not v then Stop("Busy") return end
			Loop("Busy", function() return Util.noBusy end, busyTick, 0.15)
		end,
	})
	Add(help, "Toggle", {
		Title = "Noclip",
		Value = false,
		Callback = function(v)
			Util.noclip = v
			if not v then
				Stop("Noclip")
				DisconnectKey("noclip")
				setNoclip(false)
				return
			end
			setNoclip(true)
			Conn("noclip", RunService.Heartbeat:Connect(function()
				if Util.noclip then setNoclip(true) end
			end))
			Conn("noclip", Me.CharacterAdded:Connect(function()
				task.wait(0.3)
				if Util.noclip then setNoclip(true) end
			end))
		end,
	})
	Add(help, "Toggle", {
		Title = "Fly",
		Value = false,
		Callback = function(v)
			SetFly(v == true)
		end,
	})
	Add(help, "Toggle", {
		Title = "TeleportWalk",
		Value = false,
		Callback = function(v)
			TW.on = v == true
			if not TW.on then
				stopTPWalk()
				return
			end
			startTPWalk()
		end,
	})
	Add(help, "Toggle", {
		Title = "Dodge Cryptids",
		Value = false,
		Callback = function(v)
			Features.dodgeCryptids = v == true
			if not v then Stop("DodgeC") return end
			Loop("DodgeC", function() return Features.dodgeCryptids end, function()
				if Features.cryptidAlert or (Settings.wallCheck and CryptidNear((Root() and Root().Position) or Vector3.zero, 28, true)) then
					if not isIntermission() then goSafe() end
				end
			end, 0.55)
		end,
	})
	Add(help, "Toggle", {
		Title = "Dodge Ranged Mode",
		Value = false,
		Callback = function(v)
			Features.dodgeRanged = v == true
			if not v then Stop("DodgeR") return end
			Loop("DodgeR", function() return Features.dodgeRanged end, dodgeRangedTick, 0.2)
		end,
	})
	Add(help, "Toggle", {
		Title = "Bullet ESP (Dusty/Corey)",
		Value = false,
		Callback = function(v)
			Features.bulletESP = v == true
		end,
	})
	Add(help, "Toggle", {
		Title = "Machine Walk",
		Value = false,
		Callback = function(v)
			Features.machineWalk = v == true
		end,
	})
	Add(help, "Toggle", {
		Title = "Remove Collisions on Machines",
		Value = false,
		Callback = function(v)
			Features.machineNoCollide = v == true
			if not v then Stop("MachCol") return end
			Loop("MachCol", function() return Features.machineNoCollide end, machineNoCollideTick, 1.2)
		end,
	})
	Add(help, "Toggle", {
		Title = "Pause Farm on Boss Intro",
		Value = true,
		Callback = function(v)
			Features.bossIntroPause = v == true
		end,
	})
	Add(help, "Toggle", {
		Title = "Re-queue on Machine Interrupt",
		Value = true,
		Callback = function(v)
			Features.requeueOnInterrupt = v == true
		end,
	})
	Add(help, "Toggle", {
		Title = "Exit Warning Auto Exit",
		Value = true,
		Callback = function(v)
			Features.exitWarnWatch = v == true
			if not v then Stop("ExitWarn") return end
			Loop("ExitWarn", function() return Features.exitWarnWatch end, watchExitWarning, 0.8)
		end,
	})
	Add(help, "Toggle", {
		Title = "Force Release if Stuck",
		Value = true,
		Callback = function(v)
			Features.forceReleaseStuck = v == true
			if not v then Stop("FRel") return end
			Loop("FRel", function() return Features.forceReleaseStuck end, forceReleaseIfStuck, 2.5)
		end,
	})
	Add(help, "Toggle", {
		Title = "Enable Jump",
		Value = false,
		Callback = function(v)
			CamUtil.jumpOn = v == true
			if not v then Stop("Jump") return end
			Loop("Jump", function() return CamUtil.jumpOn end, function()
				local h = Hum()
				if h then
					pcall(function()
						h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
						if h.JumpPower < 50 then h.JumpPower = 50 end
						if h.JumpHeight < 7.2 then h.JumpHeight = 7.2 end
					end)
				end
			end, 0.4)
		end,
	})
	Add(help, "Toggle", {
		Title = "Infinite Jump",
		Value = false,
		Callback = function(v)
			CamUtil.infJump = v == true
			DisconnectKey("infJ")
			if not v then return end
			Conn("infJ", UIS.JumpRequest:Connect(function()
				if not CamUtil.infJump then return end
				local h = Hum()
				if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
			end))
		end,
	})
	Add(help, "Toggle", {
		Title = "Shift Lock",
		Value = false,
		Callback = function(v)
			CamUtil.shiftLock = v == true
			pcall(function()
				Me.DevEnableMouseLock = true
				local stag = UIS.MouseBehavior
				UIS.MouseBehavior = v and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
			end)
		end,
	})
	Add(help, "Toggle", {
		Title = "First Person View",
		Value = false,
		Callback = function(v)
			CamUtil.firstPerson = v == true
			applyCameraSettings()
		end,
	})
	Add(help, "Toggle", {
		Title = "Anti-Lag",
		Value = false,
		Callback = function(v)
			CamUtil.antiLag = v == true
			if not v then Stop("ALag") return end
			Loop("ALag", function() return CamUtil.antiLag end, function()
				pcall(function()
					pcall(function()
						local st = settings()
						if st and st.Rendering then
							st.Rendering.QualityLevel = 1
						end
					end)
					local n = 0
					for _, fx in ipairs(Workspace:GetChildren()) do
						for _, d in ipairs(fx:GetDescendants()) do
							if n > 80 then break end
							if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") then
								d.Enabled = false
								n = n + 1
							end
						end
						if n > 80 then break end
					end
				end)
			end, 3)
		end,
	})
	Add(help, "Toggle", {
		Title = "Disable Rendering (experimental)",
		Value = false,
		Callback = function(v)
			CamUtil.noRender = v == true
			pcall(function()
				Workspace.CurrentCamera.CameraType = v and Enum.CameraType.Scriptable or Enum.CameraType.Custom
			end)
		end,
	})
	Add(help, "Toggle", {
		Title = "Backflip",
		Value = false,
		Callback = function(v)
			CamUtil.backflip = v == true
			if not v then Stop("BFlip") return end
			Loop("BFlip", function() return CamUtil.backflip end, function()
				local r = Root()
				if r then pcall(function() r.CFrame = r.CFrame * CFrame.Angles(math.rad(-12), 0, 0) end) end
			end, 0.05)
		end,
	})
	Add(help, "Toggle", {
		Title = "Frontflip",
		Value = false,
		Callback = function(v)
			CamUtil.frontflip = v == true
			if not v then Stop("FFlip") return end
			Loop("FFlip", function() return CamUtil.frontflip end, function()
				local r = Root()
				if r then pcall(function() r.CFrame = r.CFrame * CFrame.Angles(math.rad(12), 0, 0) end) end
			end, 0.05)
		end,
	})
	Add(help, "Toggle", {
		Title = "Upside Down",
		Value = false,
		Callback = function(v)
			CamUtil.upsideDown = v == true
			if not v then Stop("UpD") return end
			Loop("UpD", function() return CamUtil.upsideDown end, function()
				local r = Root()
				if r then pcall(function() r.CFrame = CFrame.new(r.Position) * CFrame.Angles(math.rad(180), 0, 0) end) end
			end, 0.1)
		end,
	})

	Add(help, "Slider", {
		Title = "Fly Speed",
		Value = 50, Min = 10, Max = 150, Step = 5,
		Callback = function(v) Util.flySpeed = tonumber(v) or 50 end,
	})
	Add(help, "Slider", {
		Title = "TeleportWalk Speed",
		Value = 3, Min = 1, Max = 15, Step = 0.5,
		Callback = function(v)
			TW.speed = math.clamp(tonumber(v) or 3, 1, 15)
		end,
	})
	Add(help, "Slider", {
		Title = "Field of View",
		Value = 70, Min = 40, Max = 120, Step = 1,
		Callback = function(v)
			CamUtil.fov = tonumber(v) or 70
			applyCameraSettings()
		end,
	})
	Add(help, "Slider", {
		Title = "Min Camera Zoom",
		Value = 0.5, Min = 0.5, Max = 20, Step = 0.5,
		Callback = function(v)
			CamUtil.minZoom = tonumber(v) or 0.5
			applyCameraSettings()
		end,
	})
	Add(help, "Slider", {
		Title = "Max Camera Zoom",
		Value = 128, Min = 16, Max = 400, Step = 1,
		Callback = function(v)
			CamUtil.maxZoom = tonumber(v) or 128
			applyCameraSettings()
		end,
	})

	local haz = Sec(t, "Anti-Debuff", nil, "solar:danger-bold")
	Add(haz, "Toggle", {
		Title = "Anti RottenBanana",
		Value = false,
		Callback = function(v)
			setDebuff("RottenBanana", v)
			if v then setDebuff("RottenBananaCrash", true) end
		end,
	})
	Add(haz, "Toggle", {
		Title = "Anti Butter",
		Value = false,
		Callback = function(v)
			setDebuff("Butter", v)
		end,
	})
	Add(haz, "Toggle", {
		Title = "Anti Puddle",
		Value = false,
		Callback = function(v)
			setDebuff("Puddle", v)
			if v then setDebuff("FreddiePuddle", true) end
		end,
	})
	Add(haz, "Toggle", {
		Title = "Anti FreddiePuddle",
		Value = false,
		Callback = function(v)
			setDebuff("FreddiePuddle", v)
		end,
	})

	local cam = Sec(t, "Camera", nil, "solar:camera-bold")
	Add(cam, "Button", {
		Title = "Unlock Camera",
		Callback = function()
			pcall(function()
				Me.CameraMinZoomDistance = 0.5
				Me.CameraMaxZoomDistance = 128
				Me.CameraMode = Enum.CameraMode.Classic
				CamUtil.firstPerson = false
			end)
		end,
	})
	Add(cam, "Button", {
		Title = "Reset Camera",
		Desc = "Fix your camera if it's bugged, but be careful, it might bug even more",
		Callback = function()
			pcall(function()
				Me.CameraMode = Enum.CameraMode.Classic
				local c = Workspace.CurrentCamera
				local r = Root()
				if c and r then
					c.CameraType = Enum.CameraType.Custom
					c.CFrame = CFrame.new(r.Position + Vector3.new(0, 5, 12), r.Position)
				end
			end)
		end,
	})

	local extra = Sec(t, "Extra", nil, "solar:widget-2-bold")
	Add(extra, "Button", {
		Title = "God Mode",
		Desc = "You'll only be invincible for one round; in the next round, you'll be your own character and you'll be healed. But at the cost of losing all your items",
		Callback = function()
			godModeOneRound()
		end,
	})
	Add(extra, "Toggle", {
		Title = "Anti-Afk",
		Value = false,
		Callback = function(v)
			Util.afk = v
			DisconnectKey("afk")
			if not v then return end
			Conn("afk", Me.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			end))
		end,
	})

	local maskMode = "Off"
	local savedNames = {}
	local function applyMask()
		local pg = Me:FindFirstChildOfClass("PlayerGui")
		if not pg then return end
		local function handle(label, isSelf)
			if not label or not label:IsA("TextLabel") then return end
			if not savedNames[label] then savedNames[label] = label.Text end
			if maskMode == "Off" then
				label.Text = savedNames[label]
			elseif maskMode == "Hide" and isSelf then
				label.Text = ""
			elseif maskMode == "Self" and isSelf then
				label.Text = "???"
			elseif maskMode == "Everyone" then
				label.Text = "???"
			end
		end
		local function walk(node)
			for _, d in ipairs(node:GetDescendants()) do
				if d.Name == "Username" and d:IsA("TextLabel") then
					local self = false
					local cur = d
					for _ = 1, 6 do
						if not cur then break end
						local n = tostring(cur.Name)
						if n:find(tostring(Me.UserId), 1, true) or n:lower():find(Me.Name:lower(), 1, true) then
							self = true
							break
						end
						cur = cur.Parent
					end
					if tostring(savedNames[d] or d.Text) == Me.Name or d.Text == Me.DisplayName then
						self = true
					end
					handle(d, self)
				end
			end
		end
		local mt = pg:FindFirstChild("MemberTab")
		if mt then walk(mt) end
		local sp = pg:FindFirstChild("Spectate") or game:GetService("StarterGui"):FindFirstChild("Spectate")
		if sp then walk(sp) end
	end
	Add(extra, "Dropdown", {
		Title = "Protect Username",
		Desc = "Protect your username in the player list",
		Values = { "Off", "Self", "Hide", "Everyone" },
		Value = "Off",
		Callback = function(v)
			maskMode = v
			if v == "Off" then
				Stop("Mask")
				applyMask()
				return
			end
			applyMask()
			Loop("Mask", function() return maskMode ~= "Off" end, applyMask, 1.5)
		end,
	})
end)


safeCall("UI:Config", function()
	local t = Tab("Config", "Save / Load", "solar:settings-bold")
	local perf = Sec(t, "Performance", nil, "solar:cpu-bolt-bold")
	local function applyPerfPreset(name)
		name = tostring(name or "Mid-end")
		if name == "Low-end" then
			ESP.maxObjects = 18
			ESP.maxDistance = 140
			ESP.scanInterval = 4.5
		elseif name == "High-end" then
			ESP.maxObjects = 72
			ESP.maxDistance = 320
			ESP.scanInterval = 1.8
		else
			ESP.maxObjects = OnPhone and 28 or 40
			ESP.maxDistance = OnPhone and 180 or 240
			ESP.scanInterval = OnPhone and 3.4 or 2.6
		end
		pcall(function()
			if writefile then
				if not isfolder or not isfolder("PinkBombs_Funhouse_CFGS") then
					pcall(function() makefolder("PinkBombs_Funhouse_CFGS") end)
				end
				writefile("PinkBombs_Funhouse_CFGS/_perf.ec", name)
			end
		end)
		Notify("Performance", name, 2)
	end
	local perfValue = "Mid-end"
	pcall(function()
		if isfile and isfile("PinkBombs_Funhouse_CFGS/_perf.ec") then
			local v = readfile("PinkBombs_Funhouse_CFGS/_perf.ec")
			if v == "Low-end" or v == "Mid-end" or v == "High-end" then
				perfValue = v
			end
		end
	end)
	applyPerfPreset(perfValue)
	Add(perf, "Dropdown", {
		Title = "Device Preset",
		Values = { "Low-end", "Mid-end", "High-end" },
		Value = perfValue,
		Callback = function(v)
			if type(v) == "string" and v ~= "" then
				applyPerfPreset(v)
			end
		end,
	})
	local s = Sec(t, "Configs", "Save it for your last time", "solar:folder-bold")
	local cfgName = "default"
	local cfgList = listConfigs()
	local autoLoadOn = false
	local okA, nameA = readAutoLoad()
	if okA and nameA then
		autoLoadOn = true
		cfgName = nameA
	end
	local drop
	drop = Add(s, "Dropdown", {
		Title = "Saved Configs",
		Values = cfgList,
		Value = cfgName,
		Callback = function(v)
			if type(v) == "string" and v ~= "" then
				cfgName = v
			end
		end,
	})
	Add(s, "Input", {
		Title = "Config Name",
		Value = cfgName,
		Callback = function(v) cfgName = tostring(v or "default") end,
	})
	Add(s, "Toggle", {
		Title = "Auto Load Config",
		Value = autoLoadOn,
		Callback = function(v)
			autoLoadOn = v == true
			ensureCfgFolder()
			if autoLoadOn then
				pcall(function()
					writefile(AUTOLOAD_FILE, cfgName)
				end)
			else
				pcall(function()
					if isfile and isfile(AUTOLOAD_FILE) then delfile(AUTOLOAD_FILE) end
				end)
			end
		end,
	})
	Add(s, "Button", {
		Title = "Save Config",
		Callback = function()
			ensureCfgFolder()
			local data = serializeSettings()
			local ok = pcall(function()
				writefile(cfgPath(cfgName), game:GetService("HttpService"):JSONEncode(data))
			end)
			if autoLoadOn then
				pcall(function() writefile(AUTOLOAD_FILE, cfgName) end)
			end
			Ping("Config", ok and "Saved." or "Save failed.", 2)
		end,
	})
	Add(s, "Button", {
		Title = "Load Config",
		Callback = function()
			local ok, raw = pcall(function()
				return readfile(cfgPath(cfgName))
			end)
			if not ok or not raw then
				Ping("Config", "Not found.", 2)
				return
			end
			local ok2, data = pcall(function()
				return game:GetService("HttpService"):JSONDecode(raw)
			end)
			if ok2 and data then
				applyConfig(data)
				Ping("Config", "Loaded.", 2)
			else
				Ping("Config", "Corrupt config ignored.", 2)
			end
		end,
	})
	Add(s, "Button", {
		Title = "Delete Config",
		Callback = function()
			pcall(function() delfile(cfgPath(cfgName)) end)
			Ping("Config", "Deleted.", 2)
		end,
	})
	Add(s, "Button", {
		Title = "Refresh Config List",
		Callback = function()
			Ping("Config", "Reopen Config tab to refresh list.", 2)
		end,
	})
end)

task.defer(function()
	local ok, name = readAutoLoad()
	if not ok or not name then return end
	local ok2, raw = pcall(function()
		return readfile(cfgPath(name))
	end)
	if not ok2 or not raw then return end
	local ok3, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(raw)
	end)
	if ok3 and data then
		applyConfig(data)
		Ping("Config", "Auto-loaded " .. tostring(name), 2)
	end
end)


pcall(function()
	if Hub and Hub.OnClose then
		Hub.OnClose = function()
			StopAllLoops()
			DisconnectAll()
			clearESP()
			stopFly()
			setNoclip(false)
			stopDebuffWatch()
		end
	end
end)

pcall(function()
	if type(Hub.SelectTab) == "function" then
		Hub:SelectTab(1)
	elseif Hub.Tabs and Hub.Tabs[1] and type(Hub.Tabs[1].Select) == "function" then
		Hub.Tabs[1]:Select()
	end
end)
Managers.GetMachines = MachineManager.Get
Managers.Farm = { State = Farm }
Managers.Bring = { State = Bring }
Managers.ESP = {
	State = ESP,
	Clear = clearESP,
	Refresh = espScan,
	SetLimits = function(maxObjects, maxDistance)
		ESP.maxObjects = math.max(20, math.floor(tonumber(maxObjects) or ESP.maxObjects))
		ESP.maxDistance = math.max(50, tonumber(maxDistance) or ESP.maxDistance)
	end,
}
Managers.Status = function()
	return { Loops = Managers.Loops.Active(), Fly = flyWant, Noclip = Util.noclip, TeleportWalk = TW.on, AntiDebuff = anyDebuffOn(), MachinesCached = machineScanCache ~= nil }
end

pcall(function()
	if WindUI and WindUI.Notify then
		WindUI:Notify({ Title = "Pink bomb's", Content = "v" .. VERSION .. " ready", Duration = 2, Icon = ASSETS.Notify })
	end
end)
