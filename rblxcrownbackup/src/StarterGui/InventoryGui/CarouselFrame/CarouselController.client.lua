-- define paths
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- disable default roblox backpack
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- track active connections to avoid duplicate execution threads
local backpackAddConn, backpackRemConn, charAddConn, charRemConn
local attributeConnections = {}

-- ui references
local carouselFrame = script.Parent
local slotTemplate = carouselFrame:WaitForChild("SlotTemplate")
slotTemplate.Visible = false -- keep the master template hidden

local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- continuous wobble animation configurations
local WOBBLE_TIME = 1.8         -- time in seconds for one full swing direction
local WOBBLE_ANGLE = 5          -- maximum rotation offset in degrees
local WOBBLE_TWEEN_INFO = TweenInfo.new(
	WOBBLE_TIME,
	Enum.EasingStyle.Sine,     -- smooth deceleration at the edges
	Enum.EasingDirection.InOut,
	-1,                        -- infinite loop
	true                       -- auto reverse back and forth
)

-- orbit settings for center anchored calculations
local CIRCLE_CENTER_X = -90   
local RADIUS = 200       
local ANG_TOP = math.rad(-38)   
local ANG_MID = math.rad(0)     -- active focal point (visual slot 2)
local ANG_BOT = math.rad(38)    
local ANG_EXIT_TOP = math.rad(-90)
local ANG_EXIT_BOT = math.rad(90)

-- 1.25x ccaled sizes for the main slot container
local SIZE_UNSELECTED = UDim2.new(0, 88, 0, 88)
local SIZE_SELECTED = UDim2.new(0, 112, 0, 112)

-- configurable icon asset IDs
local EMPTY_ICON_ID = "rbxassetid://74187689315902" 
local BG_ENABLED_ID = "rbxassetid://91520022472180"
local BG_DISABLED_ID = "rbxassetid://118848175838710"

-- state tracking
local inventory = { "EMPTY" } -- Array storing either valid Tool instances or the string "EMPTY"
local visibleSlots = {}       -- Structure: [ItemKey] = {Frame, AngleValue, Connection}
local equippedIndex = 1       -- Defaults to 1 ("EMPTY")
local isUpdating = false     
local lastDirection = 1      

-- forward declarations
local updateInventoryList
local updateCarouselVisuals
local cycleSelection

-- spherically positions, sizes, and blends elements along the radian layout track
local function renderFrameAtAngle(slotClone, angle, iconImage, frameBg)
	local cos = math.cos(angle)
	local sin = math.sin(angle)

	local posX = CIRCLE_CENTER_X + (RADIUS * cos)
	local posY = RADIUS * sin

	-- calculate scaling ratio based on distance to the active zero center point
	local alpha = math.clamp(math.abs(angle) / ANG_BOT, 0, 1)
	local sizeX = math.floor(SIZE_SELECTED.X.Offset + (SIZE_UNSELECTED.X.Offset - SIZE_SELECTED.X.Offset) * alpha)
	local sizeY = math.floor(SIZE_SELECTED.Y.Offset + (SIZE_UNSELECTED.Y.Offset - SIZE_SELECTED.Y.Offset) * alpha)

	slotClone.AnchorPoint = Vector2.new(0.5, 0.5)
	slotClone.Position = UDim2.new(0, posX, 0.5, posY)
	slotClone.Size = UDim2.new(0, sizeX, 0, sizeY)

	local transparency = alpha * 0.4
	if slotClone:IsA("CanvasGroup") then
		slotClone.GroupTransparency = transparency
	else
		if iconImage and iconImage:IsA("ImageLabel") then iconImage.ImageTransparency = transparency end
		if frameBg and frameBg:IsA("ImageLabel") then frameBg.ImageTransparency = transparency end
	end
end

-- safely cleans up a visual item entry
local function destroyVisualSlot(data)
	if data.Connection then data.Connection:Disconnect() end
	if data.Frame then data.Frame:Destroy() end
	if data.AngleValue then data.AngleValue:Destroy() end
end

-- safely equips or unequips tools based on index selection
local function equipActiveTool()
	if not humanoid then return end

	local targetItem = inventory[equippedIndex]
	local currentEquipped = character:FindFirstChildOfClass("Tool")

	if targetItem == "EMPTY" then
		if currentEquipped then humanoid:UnequipTools() end
		return
	end

	if typeof(targetItem) == "Instance" and targetItem:IsA("Tool") then
		-- double check to make sure you don't accidentally hold a tool that became disabled
		if targetItem:GetAttribute("Enabled") == false then 
			if currentEquipped then humanoid:UnequipTools() end
			return
		end

		if currentEquipped == targetItem then return end 
		if currentEquipped then humanoid:UnequipTools() end

		if targetItem.Parent == player:FindFirstChild("Backpack") then
			humanoid:EquipTool(targetItem)
		end
	end
end

-- refreshes positions or spawns new elements in a circular pattern
updateCarouselVisuals = function(isInitialLoad)
	local targets = {}
	local totalItems = #inventory

	targets[inventory[equippedIndex]] = ANG_MID

	if totalItems >= 2 then
		local topIndex = (equippedIndex - 2 + totalItems) % totalItems + 1
		targets[inventory[topIndex]] = ANG_TOP
	end
	if totalItems >= 3 then
		local botIndex = (equippedIndex % totalItems) + 1
		targets[inventory[botIndex]] = ANG_BOT
	end

	-- update existing items or send them rotating off-screen
	for itemKey, data in pairs(visibleSlots) do
		local targetAngle = targets[itemKey]

		if targetAngle then
			-- visual updates for runtime attribute updates
			local iconImage = data.Frame:FindFirstChild("Icon")
			local frameBg = data.Frame:FindFirstChild("FrameBg")

			if itemKey ~= "EMPTY" then
				local isEnabled = itemKey:GetAttribute("Enabled") ~= false
				if frameBg then frameBg.Image = isEnabled and BG_ENABLED_ID or BG_DISABLED_ID end
				if iconImage then
					local disabledIcon = itemKey:GetAttribute("DisabledIcon")
					iconImage.Image = (not isEnabled and disabledIcon and disabledIcon ~= "") and disabledIcon or itemKey.TextureId
				end
			end

			TweenService:Create(data.AngleValue, TWEEN_INFO, {Value = targetAngle}):Play()
		else
			visibleSlots[itemKey] = nil
			if data.Connection then data.Connection:Disconnect() end

			local exitAngle = (lastDirection == 1) and ANG_EXIT_TOP or ANG_EXIT_BOT
			local oldFrame = data.Frame
			local oldVal = data.AngleValue
			local iconImage = oldFrame:FindFirstChild("Icon")
			local frameBg = oldFrame:FindFirstChild("FrameBg")

			local exitTween = TweenService:Create(oldVal, TWEEN_INFO, {Value = exitAngle})
			local exitConn
			exitConn = oldVal.Changed:Connect(function(val)
				renderFrameAtAngle(oldFrame, val, iconImage, frameBg)
			end)

			exitTween.Completed:Connect(function()
				exitConn:Disconnect()
				oldFrame:Destroy()
				oldVal:Destroy()
			end)
			exitTween:Play()
		end
	end

	-- create new slots for items rotating onto the screen
	for itemKey, targetAngle in pairs(targets) do
		if not visibleSlots[itemKey] then
			local slotClone = slotTemplate:Clone()
			local iconImage = slotClone:WaitForChild("Icon")
			local frameBg = slotClone:WaitForChild("FrameBg")

			slotClone.BackgroundTransparency = 1
			local isItemEnabled = itemKey == "EMPTY" or itemKey:GetAttribute("Enabled") ~= false

			-- outer background frame
			if frameBg and frameBg:IsA("ImageLabel") then
				frameBg.BackgroundTransparency = 1
				frameBg.AnchorPoint = Vector2.new(0.5, 0.5)
				frameBg.Position = UDim2.new(0.5, 0, 0.5, 0)
				frameBg.Size = UDim2.new(1.4, 0, 1.4, 0) 
				frameBg.ZIndex = slotClone.ZIndex 
				frameBg.Image = isItemEnabled and BG_ENABLED_ID or BG_DISABLED_ID

				-- smooth back and forth idle wobble setup
				frameBg.Rotation = -WOBBLE_ANGLE
				local wobbleTween = TweenService:Create(frameBg, WOBBLE_TWEEN_INFO, {
					Rotation = WOBBLE_ANGLE
				})
				wobbleTween:Play()
			end

			-- inner normal tool icon layer
			if iconImage:IsA("ImageLabel") then
				iconImage.BackgroundTransparency = 1
				iconImage.Size = UDim2.new(0.75, 0, 0.75, 0) 
				iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
				iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
				iconImage.ZIndex = slotClone.ZIndex + 1 

				if itemKey == "EMPTY" then
					iconImage.Image = EMPTY_ICON_ID
				else
					local disabledIcon = itemKey:GetAttribute("DisabledIcon")
					if not isItemEnabled and disabledIcon and disabledIcon ~= "" then
						iconImage.Image = disabledIcon
					else
						iconImage.Image = itemKey.TextureId
					end
				end
			end

			local startAngle = isInitialLoad and targetAngle or ((lastDirection == 1) and ANG_EXIT_BOT or ANG_EXIT_TOP)
			local angleValue = Instance.new("NumberValue")
			angleValue.Value = startAngle
			angleValue.Parent = slotClone

			local changedConn = angleValue.Changed:Connect(function(val)
				renderFrameAtAngle(slotClone, val, iconImage, frameBg)
			end)

			renderFrameAtAngle(slotClone, startAngle, iconImage, frameBg)
			slotClone.Visible = true
			slotClone.Parent = carouselFrame

			visibleSlots[itemKey] = {Frame = slotClone, AngleValue = angleValue, Connection = changedConn}
			TweenService:Create(angleValue, TWEEN_INFO, {Value = targetAngle}):Play()
		end
	end
end

-- gathers, preserves disabled items, and stabilizes layout sequence order safely
updateInventoryList = function(isInitialLoad)
	if isUpdating then return end
	isUpdating = true

	local oldEquippedKey = inventory[equippedIndex]
	local gatheredTools = {}
	local backpack = player:FindFirstChild("Backpack")

	for _, conn in ipairs(attributeConnections) do conn:Disconnect() end
	attributeConnections = {}

	local function processTool(tool)
		if not tool:IsA("Tool") then return end

		if tool:GetAttribute("Enabled") == nil then tool:SetAttribute("Enabled", true) end
		if tool:GetAttribute("DisabledIcon") == nil then tool:SetAttribute("DisabledIcon", "") end

		-- re-render visuals instead of rebuilding the list structure when attributes toggle
		local conn = tool:GetAttributeChangedSignal("Enabled"):Connect(function()
			-- force a safe verification step if the active held item gets turned off
			if inventory[equippedIndex] == tool and tool:GetAttribute("Enabled") == false then
				cycleSelection(1) -- auto skip forward to a valid item
			else
				updateCarouselVisuals(false)
			end
		end)
		table.insert(attributeConnections, conn)

		-- keep item in track regardless of accessibility state
		table.insert(gatheredTools, tool)
	end

	local currentEquipped = character:FindFirstChildOfClass("Tool")
	if currentEquipped then processTool(currentEquipped) end
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do processTool(item) end
	end

	table.sort(gatheredTools, function(a, b) return a.Name:lower() < b.Name:lower() end)

	local newInventory = { "EMPTY" }
	for _, tool in ipairs(gatheredTools) do
		table.insert(newInventory, tool)
	end
	inventory = newInventory

	if oldEquippedKey and table.find(inventory, oldEquippedKey) then
		equippedIndex = table.find(inventory, oldEquippedKey)
	else
		equippedIndex = math.clamp(equippedIndex, 1, #inventory)
		task.spawn(equipActiveTool)
	end

	updateCarouselVisuals(isInitialLoad == true)
	isUpdating = false
end

-- shifts layout pointers, dynamically skipping elements with false accessibility attributes
cycleSelection = function(direction)
	if #inventory <= 1 then return end
	lastDirection = direction
	local nextIndex = equippedIndex
	local attempts = 0

	-- keep looking in the direction vector until a valid slot is encountered
	repeat
		attempts = attempts + 1
		nextIndex = nextIndex + direction

		if nextIndex > #inventory then
			nextIndex = 1
		elseif nextIndex < 1 then
			nextIndex = #inventory
		end

		local potentialItem = inventory[nextIndex]
		local isAvailable = potentialItem == "EMPTY" or potentialItem:GetAttribute("Enabled") ~= false

		if isAvailable then
			equippedIndex = nextIndex
			break
		end
		-- safety check stops loops if every single item gets disabled concurrently
	until attempts >= #inventory

	updateCarouselVisuals(false)
	equipActiveTool()
end

-- event binders
local function bindBackpackListeners(backpack)
	if backpackAddConn then backpackAddConn:Disconnect() end
	if backpackRemConn then backpackRemConn:Disconnect() end

	backpackAddConn = backpack.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then updateInventoryList(false) end
	end)
	backpackRemConn = backpack.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") then updateInventoryList(false) end
	end)
end

local function bindCharacterListeners(char)
	if charAddConn then charAddConn:Disconnect() end
	if charRemConn then charRemConn:Disconnect() end

	charAddConn = char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then updateInventoryList(false) end
	end)
	charRemConn = char.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") then updateInventoryList(false) end
	end)
end

-- user key inputs setup
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		cycleSelection(1)
	elseif input.KeyCode == Enum.KeyCode.E then
		cycleSelection(-1)
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	bindCharacterListeners(newCharacter)
	equippedIndex = 1
	bindBackpackListeners(player:WaitForChild("Backpack"))
	updateInventoryList(true)
end)

-- initial run setup on start
bindBackpackListeners(player:WaitForChild("Backpack"))
bindCharacterListeners(character)
updateInventoryList(true)
