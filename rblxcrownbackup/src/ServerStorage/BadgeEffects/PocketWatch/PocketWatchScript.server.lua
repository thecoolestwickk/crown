local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local tool = script.Parent
local watchActivatedEvent = tool:WaitForChild("WatchActivated")

-- effect configurations
local COOLDOWN_DURATION = 3
local BOOST_DURATION = 15
local BASE_SPEED = 16
local BOOST_SPEED = 32

-- state trackers
local lastUsedTime = 0
local isActive = false
local addedSpeed = 0
local targetHumanoid = nil

local function onActivation(player)
	local currentTime = os.clock()
	local globalLastUsed = player:GetAttribute("WatchCooldown") or 0

	-- verify safety gate requirements are met
	if isActive or (currentTime - globalLastUsed < COOLDOWN_DURATION) then
		return
	end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- establish tracking windows
	isActive = true
	player:SetAttribute("WatchCooldown", currentTime)
	targetHumanoid = humanoid
	addedSpeed = BOOST_SPEED - BASE_SPEED

	-- apply double speed modification
	humanoid.WalkSpeed += addedSpeed

	-- track the expiration loop asynchronously
	task.delay(BOOST_DURATION, function()
		-- verify the same character still exists before applying reset configurations
		if character and humanoid and humanoid.Parent and addedSpeed > 0 then
			humanoid.WalkSpeed -= addedSpeed
			addedSpeed = 0
		end
		isActive = false
	end)
end

watchActivatedEvent.OnServerEvent:Connect(onActivation)

-- safety reset validation if a tool is dropped or unequipped mid-run
tool.Unequipped:Connect(function()
	if targetHumanoid and targetHumanoid.Parent and addedSpeed > 0 then
		targetHumanoid.WalkSpeed -= addedSpeed
		addedSpeed = 0
	end
	isActive = false
end)
