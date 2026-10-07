local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- default configuration
local DEFAULT_SPAWN_TAG = ""

-- function to route the player to the matching tagged part
local function spawnPlayerAtTag(player, character, spawnTag)
	-- look for a part or spawn location tagged with the tag
	for _, object in pairs(CollectionService:GetTagged(spawnTag)) do
		if object:IsA("BasePart") then
			-- Pivot the character safely above the destination point
			local targetCFrame = object.CFrame + Vector3.new(0, 4, 0)
			character:PivotTo(targetCFrame)
			return true
		end
	end
	return false
end

-- runs when a player finishes loading into the place
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- wait for the character to fully load
		task.defer(function()
			-- retrieve data sent via teleportdata
			local joinData = player:GetJoinData()
			local teleportData = joinData.TeleportData

			local spawnTag = DEFAULT_SPAWN_TAG -- Fallback default

			if teleportData and teleportData.ArrivalSpawnTag then
				spawnTag = teleportData.ArrivalSpawnTag
			end

			-- attempt to teleport the player to their teleport destination
			local success = spawnPlayerAtTag(player, character, spawnTag)

			if not success then
				warn("Warning: Could not find any workspace object tagged with: " .. tostring(spawnTag) .. ".")
			end
		end)
	end)
end)
