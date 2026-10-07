local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local tool = script.Parent
local player = Players.LocalPlayer

local AnchorAttack = tool:WaitForChild("AnchorAttack")
local AnchorDropAbility = tool:WaitForChild("AnchorDropAbility")
local AbilityFired = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("AbilityFired")

local animsFolder = tool:WaitForChild("Anims")
local idleAnim = animsFolder:WaitForChild("Idle")
local m1Anim = animsFolder:WaitForChild("M1")
local beamAnim = animsFolder:WaitForChild("Beam")
local walkAnim = animsFolder:WaitForChild("Walk")

local attackCooldown = false
local dropCooldown = false
local shipyardCooldown = false
local isEquipped = false
local inShipyardMode = false

local currentCombo = 1
local lastAttackTime = 0
local COMBO_WINDOW = 1.2

local activeIdleTrack = nil
local activeM1Track = nil
local activeBeamTrack = nil
local activeWalkTrack = nil

-- Unified move table structure using explicit string dictionary tags
local MOVES = {
	["1"] = {Slot = 1, Name = "Cleave Swipes", Key = "LClick", Cooldown = 0.3, ToolIdentity = "⚓ ANCHOR GEAR v2"},
	["2"] = {Slot = 2, Name = "Shipyard Overdrive", Key = "R", Cooldown = 0.8, ToolIdentity = "⚓ ANCHOR GEAR v2"},
	["3"] = {Slot = 3, Name = "Downward Spike Slam", Key = "X", Cooldown = 2.0, ToolIdentity = "⚓ ANCHOR GEAR v2"},
	["4"] = {Slot = 4, Name = "Overdrive Secret Beam", Key = "F", Cooldown = 1.5, ToolIdentity = "⚓ ANCHOR GEAR v2"}
}

local function broadcastAbilities()
	if CollectionService:HasTag(tool, "weapon") then
		AbilityFired:FireServer("EquipLoadout", MOVES)
	end
end

local function failFlash(slot)
	if CollectionService:HasTag(tool, "weapon") then
		AbilityFired:FireServer("TriggerFailFlash", slot)
	end
end

tool.Activated:Connect(function()
	if not isEquipped then return end
	if attackCooldown or not AnchorAttack then 
		failFlash(MOVES["1"].Slot)
		return 
	end
	attackCooldown = true

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then attackCooldown = false return end

	local currentTime = os.clock()
	if currentTime - lastAttackTime > COMBO_WINDOW then currentCombo = 1 end
	lastAttackTime = currentTime

	if activeM1Track then activeM1Track:Stop(0.01) end

	activeM1Track = animator:LoadAnimation(m1Anim)
	if activeM1Track then
		activeM1Track.Priority = Enum.AnimationPriority.Action
		activeM1Track:Play(0.01)
		if currentCombo == 3 then activeM1Track:AdjustSpeed(0.85) else activeM1Track:AdjustSpeed(1.2) end
	end

	AnchorAttack:FireServer("Cleave", currentCombo)
	AbilityFired:FireServer("TriggerCooldown", MOVES["1"].Slot)

	if currentCombo >= 3 then
		currentCombo = 1
		task.wait(0.5)
	else
		currentCombo += 1
		task.wait(0.3)
	end
	attackCooldown = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not isEquipped then return end

	if input.KeyCode == Enum.KeyCode.R and AnchorAttack then
		if shipyardCooldown or attackCooldown then
			failFlash(MOVES["2"].Slot)
			return
		end
		shipyardCooldown = true
		attackCooldown = true
		inShipyardMode = not inShipyardMode
		AnchorAttack:FireServer("ToggleShipyard", inShipyardMode)

		AbilityFired:FireServer("TriggerCooldown", MOVES["2"].Slot)
		task.wait(MOVES["2"].Cooldown)
		shipyardCooldown = false
		attackCooldown = false

	elseif input.KeyCode == Enum.KeyCode.X and AnchorDropAbility then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local isInAir = humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping or humanoid.FloorMaterial == Enum.Material.Air)

		if dropCooldown or not isInAir then
			failFlash(MOVES["3"].Slot)
			return
		end

		dropCooldown = true
		AnchorDropAbility:FireServer()

		AbilityFired:FireServer("TriggerCooldown", MOVES["3"].Slot)
		task.wait(MOVES["3"].Cooldown)
		dropCooldown = false

	elseif input.KeyCode == Enum.KeyCode.F and player.UserId == 4102926354 and AnchorAttack then
		if not inShipyardMode or attackCooldown then
			failFlash(MOVES["4"].Slot)
			return
		end
		attackCooldown = true

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator and beamAnim then
			activeBeamTrack = animator:LoadAnimation(beamAnim)
			if activeBeamTrack then 
				activeBeamTrack.Priority = Enum.AnimationPriority.Action2
				activeBeamTrack:Play(0.1) 
			end
		end

		AnchorAttack:FireServer("SecretBeam")

		AbilityFired:FireServer("TriggerCooldown", MOVES["4"].Slot)
		task.wait(MOVES["4"].Cooldown)
		attackCooldown = false
	end
end)

RunService.RenderStepped:Connect(function()
	if not isEquipped then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local horizontalVelocity = (rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude

	if horizontalVelocity > 1.5 and humanoid.FloorMaterial ~= Enum.Material.Air then
		if activeIdleTrack and activeIdleTrack.IsPlaying then activeIdleTrack:Stop(0.2) end
		if activeWalkTrack then
			if not activeWalkTrack.IsPlaying then
				activeWalkTrack:Play(0.2)
			end
			activeWalkTrack:AdjustSpeed(humanoid.WalkSpeed / 16)
		end
	else
		if activeWalkTrack and activeWalkTrack.IsPlaying then activeWalkTrack:Stop(0.2) end
		if activeIdleTrack and not activeIdleTrack.IsPlaying then
			activeIdleTrack:Play(0.2)
		end
	end
end)

tool.Equipped:Connect(function()
	isEquipped = true
	local character = player.Character
	local humanoid = character and character:WaitForChild("Humanoid", 5)
	local animator = humanoid and humanoid:WaitForChild("Animator", 5)

	if animator then
		if idleAnim then
			activeIdleTrack = animator:LoadAnimation(idleAnim)
			activeIdleTrack.Priority = Enum.AnimationPriority.Action
		end
		if walkAnim then
			activeWalkTrack = animator:LoadAnimation(walkAnim)
			activeWalkTrack.Priority = Enum.AnimationPriority.Action
		end
	end
	broadcastAbilities()
end)

tool.Unequipped:Connect(function()
	isEquipped = false
	inShipyardMode = false
	currentCombo = 1
	if activeIdleTrack then activeIdleTrack:Stop(0.1) activeIdleTrack = nil end
	if activeWalkTrack then activeWalkTrack:Stop(0.1) activeWalkTrack = nil end
	if activeM1Track then activeM1Track:Stop(0.1) activeM1Track = nil end
	if activeBeamTrack then activeBeamTrack:Stop(0.1) activeBeamTrack = nil end
	AbilityFired:FireServer("ClearLoadout")
end)
