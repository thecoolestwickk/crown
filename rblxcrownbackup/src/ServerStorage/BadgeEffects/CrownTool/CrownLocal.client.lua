local RunService = game:GetService("RunService")
local tool = script.Parent
local crownActivatedEvent = tool:WaitForChild("CrownActivated")
local originalCrownModel = tool:WaitForChild("CrownModel")
local handle = tool:WaitForChild("Handle")

local SPIN_DURATION = 3 -- Time to finish animation
local TOTAL_SPINS = 5   -- Exact number of rotations
local TOTAL_DEGREES = TOTAL_SPINS * 360

-- ADJUST THESE TO PERFECTION (Unified for both states):
local CHUNK_SIZE = 2.0             -- Distance gap between chunks (Higher = wider steps)
local CHUNK_SMOOTHNESS = 25        -- Smoothness of the chunk updates (Lower = softer/less jerky, Higher = snappier)

-- IDLE BOBBING CONFIGURATION:
local BOB_SPEED = 3                -- How fast the crown floats up and down
local BOB_HEIGHT = 0.4             -- How high/low the float wave goes
local IDLE_HEIGHT_OFFSET = 3.5     -- Default height above the character's head
local IDLE_SPIN_SPEED = 45         -- Degrees per second the crown slowly spins while idling

local isCountingDown = false
local idleConnection = nil
local activeIdleClone = nil

-- Global function shortcuts for frame runtime speed
local math_sin = math.sin
local math_floor = math.floor
local math_min = math.min
local math_clamp = math.clamp
local math_rad = math.rad

-- ============================================================================
-- STRUCTURAL POSITION EXTRACTION INTERFACES
-- ============================================================================
-- We tag every part with a unique name signature string to maintain structure
local originalPartsList = originalCrownModel:GetDescendants()
local masterGeometryOffsets = {}
local partNamingIndex = 0

local boundingCFrame, boundingSize = originalCrownModel:GetBoundingBox()
local flatCenterBase = CFrame.new(boundingCFrame.Position)

-- Assign distinct structural string IDs so collapsed stacking can never occur
for _, part in ipairs(originalPartsList) do
	if part:IsA("BasePart") then
		partNamingIndex = partNamingIndex + 1
		local uniquePartID = "CrownMeshComponent_" .. tostring(partNamingIndex)
		part.Name = uniquePartID
		masterGeometryOffsets[uniquePartID] = flatCenterBase:Inverse() * part.CFrame
	end
end

-- Helper to safely clone the shape and isolate tracking components from tool welds
local function prepareAnimationClone(sourceModel, transparency)
	local clone = sourceModel:Clone()
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
			part.CanCollide = false
			part.Anchored = true
		elseif part:IsA("WeldConstraint") or part:IsA("Weld") or part:IsA("ManualWeld") then
			part:Destroy()
		end
	end
	return clone
end

-- Helper function to safely hide the tool model components inside your hand
local function setOriginalModelTransparency(transparency)
	for _, part in ipairs(originalCrownModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
			part.CanCollide = false
		end
	end
end

-- Shared constructor object tracking the chunk vectors
local function createTrackerState(rootPosition)
	local initialPos = rootPosition + Vector3.new(0, IDLE_HEIGHT_OFFSET, 0)
	return {
		actualCrownPos = initialPos,
		internalChunkTarget = initialPos,
		lastStoredHeadPos = initialPos
	}
end

-- Shared movement calculator used 1:1 by both animation states
local function updateMovementPhysics(tracker, targetPosition, deltaTime)
	local travelVector = targetPosition - tracker.lastStoredHeadPos
	local magnitude = travelVector.Magnitude

	if magnitude >= CHUNK_SIZE then
		local steps = math_floor(magnitude / CHUNK_SIZE)
		local chunkMove = travelVector.Unit * (steps * CHUNK_SIZE)

		tracker.internalChunkTarget = tracker.internalChunkTarget + chunkMove
		tracker.lastStoredHeadPos = tracker.lastStoredHeadPos + chunkMove
	elseif magnitude > 0.01 then
		local creepStep = travelVector.Unit * math_min(deltaTime * 10, magnitude)
		tracker.internalChunkTarget = tracker.internalChunkTarget + creepStep
		tracker.lastStoredHeadPos = tracker.lastStoredHeadPos + creepStep
	end

	local lerpAlpha = math_clamp(deltaTime * CHUNK_SMOOTHNESS, 0, 1)
	tracker.actualCrownPos = tracker.actualCrownPos:Lerp(tracker.internalChunkTarget, lerpAlpha)
end
