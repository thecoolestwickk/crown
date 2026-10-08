-- define paths and ui elements
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local HintEvent = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("HintEvent")
local HintBar = script.Parent:WaitForChild("HintBar")
local HintText = HintBar:WaitForChild("HintText")

-- start hidden
HintBar.BackgroundTransparency = 1
HintText.Text = "" -- clear container text string

local currentHintId = 0
local lastHintTime = 0
local originalPos = HintText.Position

-- sine wave settings
local WAVE_AMPLITUDE = 6   -- height variance in pixels
local WAVE_FREQUENCY = 0.4 -- distance between wave peaks
local WAVE_SPEED = 6       -- speed of the wave animation

local lastHintFinished = true

local function displayHint(message, options)
	
	if lastHintFinished == true then
		lastHintFinished = false
	elseif os.clock() - lastHintTime < 2 then
		return
	end


	-- update the last hint time once it starts
	lastHintTime = os.clock()

	options = options or {}
	local duration = options.duration or 2.5
	local typewriter = options.typewriter or false
	local shake = options.shake or false
	local wavy = options.wavy or false
	local textcolor = options.textcolor or Color3.fromRGB(255, 255, 255)
	local textsize = options.textsize or 20

	-- overwrite any currently running hint
	currentHintId = currentHintId + 1
	local myId = currentHintId

	-- clean up old components
	for _, child in ipairs(HintText:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	HintText.Position = originalPos

	-- make the bar appear
	HintBar.BackgroundTransparency = 0

	local isShaking = true
	local activeLetterLabels = {}

	-- start the shaking sequence
	if shake then
		task.spawn(function()
			while isShaking and currentHintId == myId do
				HintText.Position = originalPos + UDim2.new(0, math.random(-4, 4), 0, math.random(-2, 2))
				task.wait(0.04)
			end
			HintText.Position = originalPos
		end)
	end

	-- dynamically generate letters
	for i = 1, #message do
		local char = string.sub(message, i, i)

		-- invisible outer slot for the uilistlayout to organize safely
		local cellFrame = Instance.new("Frame")
		cellFrame.Name = "Cell_" .. i
		cellFrame.BackgroundTransparency = 1
		cellFrame.AutomaticSize = Enum.AutomaticSize.XY
		cellFrame.Parent = HintText

		-- text object floating inside the cell
		local letterLabel = Instance.new("TextLabel")
		letterLabel.Name = "Letter"
		letterLabel.Text = char
		letterLabel.Font = HintText.Font
		letterLabel.TextSize = textsize
		letterLabel.TextColor3 = textcolor
		letterLabel.BackgroundTransparency = 1
		letterLabel.TextTransparency = if typewriter then 1 else 0
		letterLabel.AutomaticSize = Enum.AutomaticSize.XY
		letterLabel.Parent = cellFrame

		table.insert(activeLetterLabels, letterLabel)
	end

	-- 3. sinewave loop thread
	if wavy then
		task.spawn(function()
			local startTime = os.clock()
			while currentHintId == myId and HintBar.BackgroundTransparency == 0 do
				local timePassed = os.clock() - startTime

				for i, label in ipairs(activeLetterLabels) do
					if label and label.Parent then
						local yOffset = math.sin((timePassed * WAVE_SPEED) + (i * WAVE_FREQUENCY)) * WAVE_AMPLITUDE
						label.Position = UDim2.new(0, 0, 0, yOffset)
					end
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end

	-- typewriter effect
	if typewriter then
		for _, label in ipairs(activeLetterLabels) do
			if currentHintId ~= myId then 
				isShaking = false
				HintText.Position = originalPos
				return 
			end
			label.TextTransparency = 0
			task.wait(0.03)
		end
	end
	
	if duration == 0 then
		lastHintFinished = true
		return
	end

	-- hold hint on screen
	task.wait(duration)

	-- stop shaking
	isShaking = false 
	HintText.Position = originalPos

	if currentHintId ~= myId then return end

	-- hide bar and fade text components
	HintBar.BackgroundTransparency = 1
	for _, label in ipairs(activeLetterLabels) do
		label.TextTransparency = 1
	end
	lastHintFinished = true
end

-- listen for server hints
HintEvent.OnClientEvent:Connect(displayHint)

-- create a local function so that other localscripts can call it
_G.ShowLocalHint = displayHint
