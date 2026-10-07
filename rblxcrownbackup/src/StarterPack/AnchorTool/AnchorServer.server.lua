local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local anchorModel = tool:WaitForChild("AnchorModel")

local AnchorAttack = tool:WaitForChild("AnchorAttack")
local AnchorDropAbility = tool:WaitForChild("AnchorDropAbility")

local shipyardStates = {}

local COLORS = {
	NormalBody = Color3.fromRGB(13, 105, 172),
	NormalTrim = Color3.fromRGB(9, 137, 207),
	ShipyardBody = Color3.fromRGB(51, 88, 130),
	ShipyardTrim = Color3.fromRGB(16, 42, 220)
}

-- Locates the specific model part containing your explicit configuration tag name
local function getCorePart()
	if anchorModel then
		for _, part in ipairs(anchorModel:GetDescendants()) do
			if part:IsA("BasePart") and part.Name == "core" then
				return part
			end
		end
	end
	return handle
end

local function tweenAnchorColors(isOverdrive)
	local targetBodyColor = isOverdrive and COLORS.ShipyardBody or COLORS.NormalBody
	local targetTrimColor = isOverdrive and COLORS.ShipyardTrim or COLORS.NormalTrim
	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, part in ipairs(anchorModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "Body" then
				TweenService:Create(part, tweenInfo, {Color = targetBodyColor}):Play()
			elseif part.Name == "Trim" then
				TweenService:Create(part, tweenInfo, {Color = targetTrimColor}):Play()
			end
		end
	end
end

local function getAnchorBaseColor()
	local bodyPart = anchorModel:FindFirstChild("Body", true)
	if bodyPart then return bodyPart.Color end
	return COLORS.NormalBody
end

-- PROCEDURAL SABRE^2 SPHERE INDICATOR GENERATOR
local function generateSabre2VFXSphere(position, parentInstance)
	local random = Random.new()
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball

	sphere.Size = Vector3.new(1, 1, 1) * random:NextNumber(0.69, 1.69)
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Massless = true
	sphere.Position = position
	sphere.Transparency = random:NextNumber(0.1, 0.5)

	local colorPalette = {
		Color3.fromRGB(245, 250, 255),
		Color3.fromRGB(0, 160, 255),   
		Color3.fromRGB(115, 200, 255), 
		Color3.fromRGB(140, 255, 195)  
	}
	sphere.Color = colorPalette[random:NextInteger(1, #colorPalette)]
	sphere.Parent = parentInstance or Workspace

	task.spawn(function()
		local duration = random:NextNumber(1.2, 2.2)
		local goalScale = random:NextNumber(0.1, 0.3)
		local floatVelocity = Vector3.new(random:NextNumber(-1.5, 1.5), random:NextNumber(2.5, 5), random:NextNumber(-1.5, 1.5))

		local startTime = os.clock()
		while os.clock() - startTime < duration do
			local elapsed = os.clock() - startTime
			local progress = elapsed / duration

			sphere.Position = sphere.Position + (floatVelocity * task.wait())
			sphere.Size = sphere.Size:Lerp(Vector3.new(1, 1, 1) * goalScale, progress)

			if progress > 0.6 then
				sphere.Transparency = sphere.Transparency + ((1 - sphere.Transparency) * (task.wait() * 3))
			end
		end
		sphere:Destroy()
	end)
end

local function injectSabre2BubbleEngines()
	local corePart = getCorePart()
	if corePart:FindFirstChild("ShipyardBubbles") then return end
	local baseColor = getAnchorBaseColor()

	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "ShipyardBubbles"
	bubbles.Texture = "http://roblox.com"
	bubbles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.6, 0.8), NumberSequenceKeypoint.new(1, 0.1)})
	bubbles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1)})
	bubbles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, baseColor),                        
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(150, 255, 210)), 
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(130, 210, 255)), 
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))    
	})
	bubbles.Lifetime = NumberRange.new(0.8, 1.5)
	bubbles.Rate = 0
	bubbles.Speed = NumberRange.new(3, 7)
	bubbles.VelocitySpread = 65
	bubbles.Acceleration = Vector3.new(0, 8, 0)
	bubbles.Parent = corePart

	local mist = Instance.new("ParticleEmitter")
	mist.Name = "ShipyardMist"
	mist.Texture = "rbxassetid://242406544"
	mist.Color = ColorSequence.new(Color3.fromRGB(220, 225, 230))
	mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4.0)})
	mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.85), NumberSequenceKeypoint.new(0.8, 0.85), NumberSequenceKeypoint.new(1, 1)})
	mist.Lifetime = NumberRange.new(1.0, 1.8)
	mist.Rate = 0
	mist.Speed = NumberRange.new(1, 4)
	mist.VelocitySpread = 180
	mist.Parent = corePart
end

local function spawnVanishingRubbleBlock(spawnPosition, baseColor, baseMaterial)
	local random = Random.new()
	local rubble = Instance.new("Part")

	rubble.Size = Vector3.new(random:NextNumber(0.6, 1.3), random:NextNumber(0.5, 1.1), random:NextNumber(0.6, 1.3))
	rubble.Color = baseColor
	rubble.Material = baseMaterial
	rubble.CanCollide = false
	rubble.Massless = true
	rubble.Position = spawnPosition
	rubble.Anchored = true
	rubble.Parent = Workspace

	task.spawn(function()
		local duration = random:NextNumber(0.7, 1.3)
		local popHeight = random:NextNumber(1.6, 2.7)
		local startCFrame = rubble.CFrame
		local randomRotation = Vector3.new(random:NextNumber(-3, 3), random:NextNumber(-3, 3), 0)

		local startTime = os.clock()
		while os.clock() - startTime < duration do
			local elapsed = os.clock() - startTime
			local progress = elapsed / duration

			local currentY = math.sin(progress * math.pi) * popHeight
			rubble.CFrame = (startCFrame + Vector3.new(0, currentY - (progress * 1.6), 0)) * CFrame.Angles(math.rad(randomRotation.X * progress), math.rad(randomRotation.Y * progress), 0)

			if progress > 0.6 then
				rubble.Transparency = (progress - 0.6) / 0.4
			end
			task.wait()
		end
		rubble:Destroy()
	end)
end

local function spawnBeamRingsWithEdgeRubble(startPos, endPos, character)
	local distance = (endPos - startPos).Magnitude
	local baseColor = getAnchorBaseColor()
	local random = Random.new()

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character, Workspace.CurrentCamera}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	for i = 0, distance, 4 do
		task.spawn(function()
			task.wait(i * 0.003)
			local lookCFrame = CFrame.lookAt(startPos, endPos)
			local pointCFrame = lookCFrame * CFrame.new(0, 0, -i)

			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder
			ring.Material = Enum.Material.Neon
			ring.Color = baseColor
			ring.Size = Vector3.new(0.4, 4, 4)
			ring.CFrame = pointCFrame * CFrame.Angles(0, math.rad(90), 0)
			ring.Anchored = true
			ring.CanCollide = false
			ring.Parent = Workspace

			TweenService:Create(ring, TweenInfo.new(0.35), {Size = Vector3.new(0, 12, 11), Transparency = 1}):Play()
			task.delay(0.35, function() ring:Destroy() end)

			for count = 1, 7 do
				local randomSphereOffset = pointCFrame.Position + Vector3.new(random:NextNumber(-4, 4), random:NextNumber(-2, 5), random:NextNumber(-2, 2))
				generateSabre2VFXSphere(randomSphereOffset, Workspace)
			end

			local flankOffsets = {-5, -2.5, 2.5, 5}
			for _, sideOffset in ipairs(flankOffsets) do
				local flankOrigin = (pointCFrame * CFrame.new(sideOffset, 2, 0)).Position
				local floorRay = Workspace:Raycast(flankOrigin, Vector3.new(0, -6, 0), rayParams)

				if floorRay and floorRay.Instance then
					spawnVanishingRubbleBlock(floorRay.Position, floorRay.Instance.Color, floorRay.Instance.Material)
				end
			end
		end)
	end
end

tool.Equipped:Connect(function()
	task.wait(0.02)
	injectSabre2BubbleEngines()
end)
-- ============================================================================
-- ⚔️ COMBAT CALCULATIONS & NETWORK OVERDRIVE MANAGERS
-- ============================================================================
task.spawn(function()
	local random = Random.new()
	while true do
		task.wait(0.04)
		for player, stateValue in pairs(shipyardStates) do
			if stateValue and player.Character and player.Character:FindFirstChild(tool.Name) then
				local corePart = getCorePart()
				if corePart then
					for i = 1, 2 do
						local randomPartOffset = corePart.Position + Vector3.new(random:NextNumber(-2, 2), random:NextNumber(-3, 3), random:NextNumber(-2, 2))
						generateSabre2VFXSphere(randomPartOffset, Workspace)
					end
				end
			end
		end
	end
end)

AnchorAttack.OnServerEvent:Connect(function(player, attackType, stateValue)
	local character = player.Character
	if not character or not character:FindFirstChild(tool.Name) then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local isOverdrive = shipyardStates[player] or false
	local corePart = getCorePart()

	if attackType == "ToggleShipyard" then
		shipyardStates[player] = stateValue
		local bubbles = corePart:FindFirstChild("ShipyardBubbles")
		local mist = corePart:FindFirstChild("ShipyardMist")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		tweenAnchorColors(stateValue)

		if stateValue then
			if bubbles then bubbles.Rate = 180 end 
			if mist then mist.Rate = 45 end 
			if humanoid then humanoid.WalkSpeed = 28 end 
		else
			if bubbles then bubbles.Rate = 0 end
			if mist then mist.Rate = 0 end
			if humanoid then humanoid.WalkSpeed = 16 end
		end

	elseif attackType == "Cleave" then
		local bubbles = corePart:FindFirstChild("ShipyardBubbles")
		if bubbles then bubbles:Emit(35) end

		local scar = Instance.new("Part")
		scar.Material = Enum.Material.Neon
		scar.Color = getAnchorBaseColor()
		scar.Size = Vector3.new(5, 0.1, 0.5)
		scar.CFrame = rootPart.CFrame * CFrame.new(0, -2, -3.5) * CFrame.Angles(0, math.rad(45), 0)
		scar.Anchored = true
		scar.CanCollide = false
		scar.Parent = Workspace
		TweenService:Create(scar, TweenInfo.new(0.35), {Transparency = 1, Size = Vector3.new(0, 0.1, 0.5)}):Play()
		task.delay(0.35, function() scar:Destroy() end)

		local baseDamage = 18
		if stateValue == 2 then baseDamage = 24 end
		if stateValue == 3 then baseDamage = 38 end

		local finalDamage = baseDamage
		if isOverdrive then finalDamage = baseDamage * 1.5 end

		local params = OverlapParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude

		local targets = Workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0, 0, -3.5), Vector3.new(6, 5, 6), params)
		local hitList = {}
		for _, part in ipairs(targets) do
			local enemyHum = part.Parent:FindFirstChildOfClass("Humanoid")
			if enemyHum and not hitList[enemyHum] then
				hitList[enemyHum] = true
				enemyHum:TakeDamage(finalDamage)
			end
		end

	elseif attackType == "SecretBeam" and player.UserId == 4102926354 and isOverdrive then
		local beam = Instance.new("Part")
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.fromRGB(245, 250, 255)
		beam.CanCollide = false
		beam.Anchored = true

		local RANGE = 75
		beam.Size = Vector3.new(2, 2, RANGE)
		beam.CFrame = rootPart.CFrame * CFrame.new(0, 0, -RANGE/2)
		beam.Parent = Workspace

		local endTargetCFrame = rootPart.CFrame * CFrame.new(0, 0, -RANGE)
		spawnBeamRingsWithEdgeRubble(rootPart.Position, endTargetCFrame.Position, character)

		local params = OverlapParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude

		local victims = Workspace:GetPartBoundsInBox(beam.CFrame, beam.Size, params)
		local beamHitTrack = {}
		for _, part in ipairs(victims) do
			local enemyHum = part.Parent:FindFirstChildOfClass("Humanoid")
			if enemyHum and not beamHitTrack[enemyHum] then
				beamHitTrack[enemyHum] = true
				enemyHum:TakeDamage(65)
			end
		end

		TweenService:Create(beam, TweenInfo.new(0.4), {Size = Vector3.new(0, 0, RANGE), Transparency = 1}):Play()
		task.delay(0.4, function() beam:Destroy() end)
	end
end)

AnchorDropAbility.OnServerEvent:Connect(function(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local isOverdrive = shipyardStates[player] or false
	local corePart = getCorePart()

	rootPart.AssemblyLinearVelocity = Vector3.new(0, -320, 0)

	local grounded = false
	local checkConnection = nil

	checkConnection = RunService.Heartbeat:Connect(function()
		if grounded or not rootPart.Parent then 
			if checkConnection then checkConnection:Disconnect() end
			return 
		end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {character}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local ray = Workspace:Raycast(rootPart.Position, Vector3.new(0, -7.5, 0), rayParams)
		if ray then
			grounded = true
			if checkConnection then checkConnection:Disconnect() end

			local bubbles = corePart:FindFirstChild("ShipyardBubbles")
			if bubbles then bubbles:Emit(90) end

			local floorColor = ray.Instance and ray.Instance.Color or Color3.fromRGB(100, 100, 100)
			local floorMaterial = ray.Instance and ray.Instance.Material or Enum.Material.Plastic
			for r = 1, 16 do
				spawnVanishingRubbleBlock(ray.Position + Vector3.new(math.random(-5,5), 0.1, math.random(-5,5)), floorColor, floorMaterial)
			end

			local impactColor = getAnchorBaseColor()
			for r = 1, 3 do
				task.spawn(function()
					task.wait(r * 0.05)
					local wave = Instance.new("Part")
					wave.Shape = Enum.PartType.Cylinder
					wave.Material = Enum.Material.Neon
					wave.Color = impactColor
					wave.Size = Vector3.new(0.2, 3, 3)
					wave.CFrame = CFrame.new(ray.Position) * CFrame.Angles(0, 0, math.rad(90))
					wave.Anchored = true
					wave.CanCollide = false
					wave.Parent = Workspace

					local growth = isOverdrive and 25 or 15
					TweenService:Create(wave, TweenInfo.new(0.35), {Size = Vector3.new(0, growth, growth), Transparency = 1}):Play()
					task.delay(0.35, function() wave:Destroy() end)
				end)
			end

			for count = 1, 12 do
				local randomSphereOffset = ray.Position + Vector3.new(math.random(-6, 6), math.random(1, 5), math.random(-6, 6))
				generateSabre2VFXSphere(randomSphereOffset, Workspace)
			end

			local params = OverlapParams.new()
			params.FilterDescendantsInstances = {character}
			params.FilterType = Enum.RaycastFilterType.Exclude

			local range = isOverdrive and 22 or 14
			local damage = isOverdrive and 55 or 35

			local closeObjects = Workspace:GetPartBoundsInRadius(rootPart.Position, range, params)
			local hitTrack = {}
			for _, part in ipairs(closeObjects) do
				local enemyHum = part.Parent:FindFirstChildOfClass("Humanoid")
				if enemyHum and not hitTrack[enemyHum] then
					hitTrack[enemyHum] = true
					enemyHum:TakeDamage(damage)

					local enemyRoot = part.Parent:FindFirstChild("HumanoidRootPart")
					if enemyRoot then
						enemyRoot:ApplyImpulse((enemyRoot.Position - rootPart.Position).Unit * 500 + Vector3.new(0, 200, 0))
					end
				end
			end

			task.wait(0.01)
			rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z)
		end
	end)
end)

tool.Unequipped:Connect(function()
	for player, _ in pairs(shipyardStates) do
		if player.Character == tool.Parent or player.Character == tool.Parent.Parent then
			shipyardStates[player] = nil
			tweenAnchorColors(false)
			break
		end
	end
end)
