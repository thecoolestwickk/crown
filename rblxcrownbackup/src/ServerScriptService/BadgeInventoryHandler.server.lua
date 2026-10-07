local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the config module
local BadgeConfig = require(ReplicatedStorage:WaitForChild("CrownModules"):WaitForChild("BadgeConfig"))
local updateInventoryEvent = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("UpdateInventoryUI")
local badgeEffectsFolder = ServerStorage:WaitForChild("BadgeEffects")

-- Shared reference table so other scripts can interact with this system
local BadgeInventoryHandler = {}

-- 1. Internal function to clone a tool to a player's inventory
local function giftToolToPlayer(player, toolName)
	local backpack = player:WaitForChild("Backpack", 5)
	local starterGear = player:WaitForChild("StarterGear", 5)

	if not (backpack and starterGear) then return end

	local originalTool = badgeEffectsFolder:FindFirstChild(toolName)
	if originalTool then
		-- Double-check locations to prevent generating accidental duplicate items
		if not backpack:FindFirstChild(toolName) and not starterGear:FindFirstChild(toolName) then
			originalTool:Clone().Parent = backpack
			originalTool:Clone().Parent = starterGear

			-- Notify the client to update their inventory UI
			updateInventoryEvent:FireClient(player, toolName)
		end
	end
end

-- 2. Checks badge data records when a player joins the game
local function loadPlayerBadgeInventory(player)
	for badgeId, toolName in pairs(BadgeConfig.Rewards) do
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		if success and hasBadge then
			giftToolToPlayer(player, toolName)
		elseif not success then
			warn("Failed to check badge data for: " .. player.Name .. " (ID: " .. tostring(badgeId) .. ")")
		end
	end
end

-- 3. GLOBAL INTERACTION FUNCTION (Call this from Portals, Quests, or NPCs to award badges)
function BadgeInventoryHandler.AwardBadgeAndItem(player, badgeId)
	local toolName = BadgeConfig.Rewards[badgeId]
	if not toolName then return end

	-- Award the badge on Roblox servers
	local success, result = pcall(function()
		return BadgeService:AwardBadgeAsync(player.UserId, badgeId)
	end)

	-- Instantly grant the tool on the server without waiting for database refreshes
	giftToolToPlayer(player, toolName)
end

-- Bind connection events
Players.PlayerAdded:Connect(loadPlayerBadgeInventory)

-- Studio test fallback environment catcher
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayerBadgeInventory, player)
end

-- Export functions to global space so other scripts can access BadgeInventoryHandler
_G.BadgeInventoryHandler = BadgeInventoryHandler
return BadgeInventoryHandler
