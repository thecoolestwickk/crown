-- define paths and parts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local tool = script.Parent
local shovelDiggedEvent = tool:WaitForChild("ShovelDigged")
local handle = tool:WaitForChild("Handle")

-- point directory links to ServerStorage to prevent items falling onto the ground
local badgeEffects = ServerStorage:WaitForChild("BadgeEffects")
local lootFolder = badgeEffects:WaitForChild("Loot")

local HintEvent = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("HintEvent")

-- raycast floor detection to get the color of the floor
local function getFloorColor(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return Color3.fromRGB(120, 120, 120) end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = Workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), raycastParams)

	if rayResult and rayResult.Instance then
		if rayResult.Instance:IsA("Terrain") then
			return Workspace.Terrain:GetMaterialColor(rayResult.Material)
		else
			return rayResult.Instance.Color
		end
	end
	return Color3.fromRGB(120, 120, 120)
end

-- 2. bubble particles ground color matching with occasional blue/gray tints
local function emitFloorParticles(originPart, baseColor)
	local PARTICLE_COUNT = 35 
	local random = Random.new()
	local h, s, v = baseColor:ToHSV()

	for i = 1, PARTICLE_COUNT do
		task.spawn(function()
			local sphere = Instance.new("Part")
			sphere.Shape = Enum.PartType.Ball

			local size = random:NextNumber(0.35, 0.65)
			sphere.Size = Vector3.new(size, size, size)
			sphere.Material = Enum.Material.SmoothPlastic
			sphere.Transparency = random:NextNumber(0.1, 0.3)
			sphere.Anchored = true
			sphere.CanCollide = false
			sphere.CanQuery = false
			sphere.CanTouch = false

			-- blend gray base tones with gentle blue hints occasionally
			local colorRoll = random:NextInteger(1, 10)
			if colorRoll <= 2 then
				-- 20% chance for soft slate gray mixed with a cyan/blue tint
				local grayBase = random:NextInteger(160, 200)
				sphere.Color = Color3.fromRGB(grayBase - 30, grayBase - 10, grayBase + 45)
			else
				-- 80% chance for ground matching tone with subtle shadows
				local variedValue = math.clamp(v + random:NextNumber(-0.15, 0.15), 0, 1)
				local variedSat = math.clamp(s + random:NextNumber(-0.1, 0.1), 0, 1)
				sphere.Color = Color3.fromHSV(h, variedSat, variedValue)
			end

			local startOffset = Vector3.new(random:NextNumber(-0.4, 0.4), random:NextNumber(0.1, 0.3), random:NextNumber(-0.4, 0.4))
			local startPosition = originPart.Position + startOffset
			sphere.Position = startPosition
			sphere.Parent = Workspace

			local driftDuration = random:NextNumber(1.4, 2.2) 
			local floatHeight = random:NextNumber(6.5, 9.5)   
			local spiralRadius = random:NextNumber(0.5, 1.2)  
			local spiralSpeed = random:NextNumber(6, 12)     
			local startAngle = random:NextNumber(0, math.pi * 2)

			local startTime = os.clock()
			while os.clock() - startTime < driftDuration do
				local elapsed = os.clock() - startTime
				local progress = elapsed / driftDuration

				local currentAngle = startAngle + (elapsed * spiralSpeed)
				local currentRadius = spiralRadius * (0.4 + progress * 0.6)

				local offsetX = math.cos(currentAngle) * currentRadius
				local offsetZ = math.sin(currentAngle) * currentRadius
				local offsetY = progress * floatHeight

				sphere.Position = startPosition + Vector3.new(offsetX, offsetY, offsetZ)
				sphere.Transparency = math.clamp(sphere.Transparency + (progress * 0.08), 0, 1)
				task.wait()
			end
			sphere:Destroy()
		end)
	end
end

-- clear old dug up items
local function wipeDugItemsFromInventory(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	local targetLists = {backpack, character}
	for _, storage in ipairs(targetLists) do
		if storage then
			for _, item in ipairs(storage:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("DugItem") == true then
					item:Destroy()
				end
			end
		end
	end
end

-- cloning and hand welding pipelines
local function generateDugArtifact(player, templateObject)
	local newArtifact = templateObject:Clone()

	if newArtifact:IsA("Tool") then
		local artifactHandle = newArtifact:FindFirstChild("Handle")

		for _, desc in ipairs(newArtifact:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = false
				desc.CanCollide = false 
				desc.Massless = true 

				-- generate structural welds to ensure the mesh renders inside the hand plane
				if artifactHandle and desc ~= artifactHandle then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = artifactHandle
					weld.Part1 = desc
					weld.Parent = artifactHandle
				end
			end
		end
	else
		-- fallback wrapper setup
		local wrapperTool = Instance.new("Tool")
		wrapperTool.Name = templateObject.Name
		wrapperTool.RequiresHandle = true

		local newHandle = Instance.new("Part")
		newHandle.Name = "Handle"
		newHandle.Size = Vector3.new(1, 1, 1)
		newHandle.Transparency = 1
		newHandle.CanCollide = false
		newHandle.Massless = true
		newHandle.Parent = wrapperTool

		newArtifact.Name = "DisplayModel"
		newArtifact.Parent = wrapperTool
		newArtifact = wrapperTool
	end

	newArtifact:SetAttribute("DugItem", true)
	newArtifact:SetAttribute("Enabled", true) 
	newArtifact:SetAttribute("DisabledIcon", "")

	newArtifact.Parent = player:FindFirstChild("Backpack")
end

shovelDiggedEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character or not character:FindFirstChild(tool.Name) then return end

	local availableLoot = lootFolder:GetChildren()
	if #availableLoot == 0 then
		warn("Shovel Error: ServerStorage Loot folder is completely empty!")
		return
	end

	local floorColor = getFloorColor(character)
	wipeDugItemsFromInventory(player)

	local selectedTemplate = availableLoot[math.random(1, #availableLoot)]
	generateDugArtifact(player, selectedTemplate)

	emitFloorParticles(handle, floorColor)

	local customTextColor = selectedTemplate:GetAttribute("HintColor") or Color3.fromRGB(255, 255, 255)
	local message = "you dug up a " .. selectedTemplate.Name .. "!"

	-- fire a local hint saying what item you dug up
	HintEvent:FireClient(player, message, {
		duration = 2.5,
		textcolor = customTextColor,
		textsize = 20,
		typewriter = true
	})
end)
