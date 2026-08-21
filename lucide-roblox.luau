--!nolint
--!nocheck
--!optimize 2

local Lucide = {}

export type Asset = {
	IconName: string,
	Id: number,
	Url: string,
	ImageRectSize: Vector2,
	ImageRectOffset: Vector2,
}

local ICONS = {
	egg = 118301878419409,
	moon = 82793625143623,
	dog = 127357729769881,
	cpu = 102269183411553,
	["shopping-bag"] = 76575127361675,
	["cloud-lightning"] = 112981765194161,
	home = 127433770027018,
	calendar = 99703121015148,
	["trending-up"] = 128861141013544,
	gift = 135047450337603,
	package = 73281187294373,
	["repeat"] = 100962261977698,
	settings = 97398088349385,
	shield = 74722795731346,
	["chevron"] = 105797634167645,
	["chevron-up"] = 16898612819,
	["chevron-down"] = 16898617411,
	["chevron-left"] = 16898617509,
	["chevron-right"] = 16898612819,
	["chevron-up-circle"] = 16898617509,
	["chevron-down-circle"] = 16898612819,
	["chevron-left-circle"] = 16898617509,
	["chevron-right-circle"] = 16898612819,
	["chevron-up-square"] = 16898612819,
	["chevron-down-square"] = 16898617411,
	["chevron-left-square"] = 16898617509,
	["chevron-right-square"] = 16898612819,
	["chevrons-up"] = 16898612819,
	["chevrons-down"] = 105797634167645,
	["chevrons-left"] = 16898612819,
	["chevrons-right"] = 16898612819,
	["chevrons-up-down"] = 16898612819,
	["chevrons-left-right"] = 16898612819,
	["chevrons-right-left"] = 16898617626,
	["chevrons-down-up"] = 16898617626,
	["chevron-first"] = 16898617411,
	["chevron-last"] = 16898612819,
}

-- Build icon names list
local iconNames = {}
for name, _ in pairs(ICONS) do
	table.insert(iconNames, name)
end
table.sort(iconNames)
Lucide.IconNames = iconNames

-- Get asset data for an icon
function Lucide.GetAsset(iconName: string, iconSize: number?): Asset
	local size = if iconSize == nil then 256 else iconSize
	
	if size < 0 then
		size = -size
	end
	
	-- Normalize icon name
	local normalizedName = string.match(string.lower(iconName), "^%s*(.*)%s*$")
	
	local assetId = ICONS[normalizedName]
	if not assetId then
		error("Lucide.GetAsset: Failed to find icon by the name of \"" .. normalizedName .. "\". Icon not found.", 2)
	end
	
	local url = "rbxassetid://" .. assetId
	local imageSize = Vector2.new(size, size)
	local imageOffset = Vector2.new(0, 0)
	
	local asset: Asset = {
		IconName = normalizedName,
		Id = assetId,
		Url = url,
		ImageRectSize = imageSize,
		ImageRectOffset = imageOffset,
	}
	
	return asset
end

-- Get all icons as assets
function Lucide.GetAllAssets(inputSize: number?): {Asset}
	local size = if inputSize == nil then 256 else inputSize
	local allAssets = {}
	
	for _, iconName in ipairs(Lucide.IconNames) do
		local asset = Lucide.GetAsset(iconName, size)
		table.insert(allAssets, asset)
	end
	
	return allAssets
end

-- Create an ImageLabel with the icon
function Lucide.ImageLabel(iconName: string, imageSize: number?, propertyOverrides: {[string]: any}?): ImageLabel
	local size = if imageSize == nil then 256 else imageSize
	local overrides = if propertyOverrides == nil then {} else propertyOverrides
	
	local asset = Lucide.GetAsset(iconName, size)
	
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = asset.IconName
	imageLabel.Size = UDim2.fromOffset(size, size)
	imageLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.BorderSizePixel = 0
	imageLabel.Image = asset.Url
	imageLabel.ImageRectSize = asset.ImageRectSize
	imageLabel.ImageRectOffset = asset.ImageRectOffset
	imageLabel.ImageColor3 = Color3.fromRGB(255, 0, 0) -- AccentColor (Red)
	imageLabel.ScaleType = Enum.ScaleType.Fit
	
	-- Apply property overrides
	if overrides then
		for prop, value in pairs(overrides) do
			if prop ~= "Parent" then
				imageLabel[prop] = value
			end
		end
		if overrides.Parent then
			imageLabel.Parent = overrides.Parent
		end
	end
	
	return imageLabel
end

return Lucide
