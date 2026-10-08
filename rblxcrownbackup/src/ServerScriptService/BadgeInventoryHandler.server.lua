
-- define services and locations
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeConfig = require(ReplicatedStorage:WaitForChild("CrownModules"):WaitForChild("BadgeConfig"))
local updateInventoryEvent = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("UpdateInventoryUI")
local badgeEffectsFolder = ServerStorage:WaitForChild("BadgeEffects")

local BadgeInventoryHandler = {}

-- adds a tool to the player's inventory
local function giftToolToPlayer(player, toolName)
	local backpack = player:WaitForChild("Backpack", 5)
	local starterGear = player:WaitForChild("StarterGear", 5)

	if not (backpack and starterGear) then return end

	-- clone the tool to add to the inventory rather than usign the original
	local originalTool = badgeEffectsFolder:FindFirstChild(toolName)
	if originalTool then
		if not backpack:FindFirstChild(toolName) and not starterGear:FindFirstChild(toolName) then
			originalTool:Clone().Parent = backpack
			originalTool:Clone().Parent = starterGear

			updateInventoryEvent:FireClient(player, toolName)
		end
	end
end

-- loop through and check if a player has a badge in the BadgeConfig module
local function loadPlayerBadgeInventory(player)
	for badgeId, toolName in pairs(BadgeConfig.Rewards) do
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		-- if they have the badge, give them the corresponding item
		if success and hasBadge then
			giftToolToPlayer(player, toolName)
		elseif not success then
			warn("Failed to check badge data for: " .. player.Name .. " (ID: " .. tostring(badgeId) .. ")")
		end
	end
end

-- function to give a player a badge and the item corresponding to it
function BadgeInventoryHandler.AwardBadgeAndItem(player, badgeId)
	local toolName = BadgeConfig.Rewards[badgeId]
	if not toolName then return end

	local success, result = pcall(function()
		return BadgeService:AwardBadgeAsync(player.UserId, badgeId)
	end)

	giftToolToPlayer(player, toolName)
end

-- load the badge inventory upon joining
Players.PlayerAdded:Connect(loadPlayerBadgeInventory)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayerBadgeInventory, player)
end

-- make a global function so it can be called from other scripts
_G.BadgeInventoryHandler = BadgeInventoryHandler
return BadgeInventoryHandler
