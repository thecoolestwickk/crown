-- define paths and ui elements
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local dialogueGui = script.Parent
local frame = dialogueGui:WaitForChild("DialogueFrame")
local viewport = frame:WaitForChild("NpcPreview")
local nameLabel = frame:WaitForChild("NameLabel")
local dialogueText = frame:WaitForChild("DialogueText")
local option1 = frame:WaitForChild("DialogueOption1")
local option2 = frame:WaitForChild("DialogueOption2")

local DialogueNetwork = ReplicatedStorage:WaitForChild("CrownEvents"):WaitForChild("DialogueNetwork")

local TYPE_SPEED = 0.02
local currentDialogueId = 0
local isTextFinished = false
local currentLineText = ""

-- configure light properties so models arent black in the viewportframe
viewport.Ambient = Color3.fromRGB(200, 200, 200)
viewport.LightColor = Color3.fromRGB(255, 255, 255)
viewport.LightDirection = Vector3.new(-1, -1, -1)

frame.Visible = false
option1.Visible = false
option2.Visible = false

-- set up or reuse a WorldModel container inside the viewportframe
local worldModel = viewport:FindFirstChildOfClass("WorldModel") or Instance.new("WorldModel")
worldModel.Parent = viewport

local vpCamera = viewport:FindFirstChild("ViewportCam") or Instance.new("Camera")
vpCamera.Name = "ViewportCam"
vpCamera.Parent = viewport
viewport.CurrentCamera = vpCamera

local function updateViewportPortrait(npcModel)
	-- delete old model clones
	worldModel:ClearAllChildren()

	if not npcModel or npcModel == workspace or npcModel:IsA("Workspace") then 
		viewport.Visible = false
		return 
	end

	viewport.Visible = true

	-- clone the entire npc character model to the viewportframe
	local modelClone = npcModel:Clone()

	-- anchor all parts inside the model clone to prevent falling out of the frame
	for _, part in ipairs(modelClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		elseif part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy() -- Strip nested scripts
		end
	end

	-- rotates the model 180 degrees so they face the viewport camera
	modelClone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
	modelClone.Parent = worldModel

	local targetHead = modelClone:FindFirstChild("Head") or modelClone:FindFirstChildWhichIsA("BasePart", true)
	if not targetHead then return end

	-- shoft the camera so the npc model is visible
	local headPos = targetHead.Position
	-- back the camera up 3 studs and point it slightly downward
	vpCamera.CFrame = CFrame.new(headPos + Vector3.new(0, -0.3, 2.8), headPos - Vector3.new(0, 0.4, 0))
	vpCamera.Focus = targetHead.CFrame
end

local function typewrite(text, myId)
	dialogueText.Text = ""
	isTextFinished = false
	currentLineText = text

	for i = 1, #text do
		if currentDialogueId ~= myId then return end
		dialogueText.Text = string.sub(text, 1, i)
		task.wait(TYPE_SPEED)
	end
	isTextFinished = true
end

DialogueNetwork.OnClientEvent:Connect(function(npcName, fullText, npcModel, choices)
	currentDialogueId = currentDialogueId + 1
	local myId = currentDialogueId

	nameLabel.Text = npcName
	updateViewportPortrait(npcModel)

	option1.Visible = false
	option2.Visible = false
	frame.Visible = true

	typewrite(fullText, myId)
	if currentDialogueId ~= myId then return end

	-- ensures buttons populate and display text after typewriter completes
	if choices and #choices > 0 then
		if choices[1] and choices[1] ~= "" then
			option1.Text = choices[1]
			option1.Visible = true
		end
		if choices[2] and choices[2] ~= "" then
			option2.Text = choices[2]
			option2.Visible = true
		end
	end
end)

local function selectOption(index)
	if not isTextFinished then
		-- fast-forward text if clicked mid-typewriter animation
		currentDialogueId = currentDialogueId + 1
		dialogueText.Text = currentLineText
		isTextFinished = true
		return
	end

	-- disable frame visibility immediately,, it broke without this but it makes it
	-- a bit glitchy, so i'd like to make a new solution at some point

	-- TODO: make a new solution to this
	frame.Visible = false
	option1.Visible = false
	option2.Visible = false

	DialogueNetwork:FireServer(index)
end

option1.MouseButton1Click:Connect(function() 
	selectOption(1) 
end)

option2.MouseButton1Click:Connect(function() 
	selectOption(2) 
end)

-- general screen clicks only advance if no options are available
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not frame.Visible then return end

	-- if choices are on screen dont let clicking the background close the box
	if option1.Visible or option2.Visible then return end

	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		selectOption(0) -- normal advance code
	end
end)
