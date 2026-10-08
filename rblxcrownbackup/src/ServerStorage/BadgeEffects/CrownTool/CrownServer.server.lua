local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CrownWorlds = require(ReplicatedStorage.CrownModules.CrownWorlds)

local tool = script.Parent
local crownActivatedEvent = tool:WaitForChild("CrownActivated")

-- target details
local TARGET_PLACE_NAME = "crown."
local SPAWN_TAG = "."

local activeTransitions = {}

crownActivatedEvent.OnServerEvent:Connect(function(player)
	if activeTransitions[player] then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- verify that the target place name exists in the CrownWorlds module
	local targetPlaceId = CrownWorlds.PlaceIds[TARGET_PLACE_NAME]
	if not targetPlaceId then
		warn("Error: Location index array holds no matching key for: " .. tostring(TARGET_PLACE_NAME))
		return
	end

	activeTransitions[player] = true

	-- wait 3 seconds for the local spinning/rising effect to finish
	task.wait(3)

	-- create a server-side explosion above their head
	local explosion = Instance.new("Explosion")
	explosion.Position = rootPart.Position + Vector3.new(0, 5, 0)
	explosion.BlastRadius = 0 -- keeps pressure and damage at 0
	explosion.BlastPressure = 0
	explosion.Parent = workspace

	-- teleport parameters with the blank spawn tag
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions:SetTeleportData({
		ArrivalSpawnTag = SPAWN_TAG
	})

	-- teleport execution
	local success, errorMessage = pcall(function()
		TeleportService:TeleportAsync(targetPlaceId, {player}, teleportOptions)
	end)

	if not success then
		warn("Crown Experience Teleportation Aborted: " .. tostring(errorMessage))
		activeTransitions[player] = nil
	end
end)
