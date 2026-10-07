local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local CrownWorlds = require(ReplicatedStorage.CrownModules.CrownWorlds)
local HintEvent = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("HintEvent")

local RequestFade = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("RequestFade")
local FadeComplete = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("FadeComplete")

local portal = script.Parent

-- WORLD PORTAL METADATA CONFIGURATION
local TARGET_PLACE_NAME = "Monarch's Crossing"
local SPAWN_TAG = "from_crown2"

-- debounce lookup table to verify specific tracking instances
local activeTransitions = {}

portal.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(character)

	if player and not activeTransitions[player] then
		local targetPlaceId = CrownWorlds.PlaceIds[TARGET_PLACE_NAME]
		if not targetPlaceId then
			warn("Error: Location index array holds no matching key for: " .. tostring(TARGET_PLACE_NAME))
			return
		end

		activeTransitions[player] = true -- Lock transit window

		-- signal the client UI layout engine to initiate stepping
		RequestFade:FireClient(player)
		
		HintEvent:FireAllClients("Teleporting " .. player.DisplayName .. ".", { duration = 0})
		task.wait(1)
		HintEvent:FireAllClients("Teleporting " .. player.DisplayName .. "..", { duration = 0})
		task.wait(1)
		HintEvent:FireAllClients("Teleporting " .. player.DisplayName .. "...", { duration = 0})
		task.wait(1)
		HintEvent:FireAllClients("Teleporting " .. player.DisplayName .. "....", { duration = 1})
	end
end)

-- fires once the fade finishes
FadeComplete.OnServerEvent:Connect(function(player)
	if activeTransitions[player] then
		local targetPlaceId = CrownWorlds.PlaceIds[TARGET_PLACE_NAME]

		local teleportOptions = Instance.new("TeleportOptions")
		teleportOptions:SetTeleportData({
			ArrivalSpawnTag = SPAWN_TAG
		})

		local success, errorMessage = pcall(function()
			TeleportService:TeleportAsync(targetPlaceId, {player}, teleportOptions)
		end)

		if not success then
			warn("Universe Teleportation Aborted: " .. tostring(errorMessage))

			-- re-engage baseline controls if connection crashes completely
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then humanoid.WalkSpeed = 16 end
			end
			activeTransitions[player] = nil 
		end
	end
end)
