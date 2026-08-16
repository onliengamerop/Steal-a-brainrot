--!native
--!optimize 2

pcall(function()
    local getHui = gethui or get_hidden_gui
    local parent = getHui and getHui() or game:GetService("CoreGui")
    for _, child in ipairs(parent:GetChildren()) do
        for _, desc in ipairs(child:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text == "AJJANS" then
                child:Destroy()
                break
            end
        end
    end
end)

local Library
if typeof(getgenv) == "function" and getgenv()._AjjansLibSource then
    Library = loadstring(getgenv()._AjjansLibSource)()
else
    local ok, src = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/onliengamerop/Steal-a-brainrot/main/guisrc.txt") end)
    if ok and src and typeof(src) == "string" and #src > 100 then
        if typeof(getgenv) == "function" then getgenv()._AjjansLibSource = src end
        Library = loadstring(src)()
    else
        local ok2, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/onliengamerop/Steal-a-brainrot/main/guisrc.txt") end)
        if ok2 and res then
            Library = loadstring(res)()
        end
    end
end

Library.Scheme.BackgroundColor = Color3.fromRGB(20, 0, 0)
Library.Scheme.MainColor = Color3.fromRGB(40, 0, 0)
Library.Scheme.AccentColor = Color3.fromRGB(255, 0, 0)
Library.Scheme.OutlineColor = Color3.fromRGB(60, 0, 0)
Library.Scheme.FontColor = Color3.fromRGB(255, 255, 255)
Library.CornerRadius = 12

local Window = Library:CreateWindow({
    Title = "AJJANS",
    Icon = "rbxassetid://102621356530489",
    ShowCustomCursor = true,
    Size = UDim2.fromOffset(700, 520),
    SidebarCompacted = false,
    Footer = "Ajjans Steal a Egg V1.5",
})

--====================================================
-- SERVICES & CONSTANTS
--====================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local SAFEZONE_X = 550.3670654296875
local SAFEZONE_Y = 70.57431030273438

local Toggles = Library.Toggles
local Options = Library.Options

-- State variables
local isAutoStealing = false
local isAutoStealSelected = false
local isSpeedEnabled = false
local isAntiHitEnabled = false
local isAutoGainSpeedEnabled = false
local isServerHopEnabled = false
local isKillAuraEnabled = false
local isAutoPlaceSelected = false
local isAutoPlaceAll = false
local isAutoHatchReady = false
local isAutoSellSelected = false
local isAutoSellAllEligible = false
local isSyncAutoSellRarities = false
local isAutoClaimIndex = false
local isAutoClaimGroup = false
local isAutoClaimOffline = false
local isAutoBaseUpgrade = false
local isAutoTreadmillUpgrade = false
local isAutoEquipBestPet = false
local isAutoBuyTrail = false
local isAutoEquipBestTrail = false
local isAutoEquipBestGear = false
local isAutoFusePets = false
local isRotationEnabled = false
local isStealBigEggs = false
local isAutoDropHeldEgg = false
local isInfJumpEnabled = false
local isNoclipEnabled = false
local isFlyEnabled = false
local isPlayerEspEnabled = false
local isPlotEspEnabled = false
local isEggEspEnabled = false
local isAutoHopForWeather = false
local isAutoFocusEventMutation = false
local isEventNotifyEnabled = false
local activeEventMutationName = nil
local sessionStealCount = 0
local sessionStartTime = os.clock()
local lastMatchingEggTime = os.clock()
local cashReserveAmount = 0
local isManualUnequip = false
local isStealingInProgress = false
local isPlacingInProgress = false
local cachedBatToken = nil

-- Natural speed tracking
local initialHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
local originalWalkSpeed = (initialHumanoid and initialHumanoid.WalkSpeed > 0 and initialHumanoid.WalkSpeed) or 16

-- Optional EggCmds, PlotCmds, Save & WeatherSchedule require
local EggCmds = nil
local PlotCmds = nil
local Save = nil
local RuntimeInstanceRegistry = nil
local WeatherSchedule = nil

pcall(function()
    if ReplicatedStorage:FindFirstChild("Library") then
        local clientLib = ReplicatedStorage.Library:FindFirstChild("Client")
        if clientLib then
            if clientLib:FindFirstChild("EggCmds") then
                EggCmds = require(clientLib.EggCmds)
            end
            if clientLib:FindFirstChild("PlotCmds") then
                PlotCmds = require(clientLib.PlotCmds)
            end
            if clientLib:FindFirstChild("Save") then
                Save = require(clientLib.Save)
            end
        end
        local modFolder = ReplicatedStorage.Library:FindFirstChild("Modules")
        if modFolder and modFolder:FindFirstChild("RuntimeInstanceRegistry") then
            RuntimeInstanceRegistry = require(modFolder.RuntimeInstanceRegistry)
        end
        local weatherFolder = ReplicatedStorage.Library:FindFirstChild("Weather")
        if weatherFolder and weatherFolder:FindFirstChild("Schedule") then
            WeatherSchedule = require(weatherFolder.Schedule)
        end
    end
end)

--====================================================
-- 1. REMOTE INTERCEPTION (__namecall & hookfunction)
--====================================================
local function isTreadmillUnequipBlocked(name)
    if not name or typeof(name) ~= "string" then return false end
    if isAutoGainSpeedEnabled and not isManualUnequip then
        if name:find("Treadmills:") and (name:find("Unequip") or name:find("Exit") or name:find("Leave")) then
            return true
        end
    end
    return false
end

local rawNamecall
rawNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if checkcaller and checkcaller() then
        return rawNamecall(self, ...)
    end

    if (method == "FireServer" or method == "InvokeServer") then
        local name = tostring(self.Name)
        
        -- Intercept and cache latest live Bat Event Token
        if name == "Bat:Activate" then
            local args = { ... }
            if args[2] and typeof(args[2]) == "string" and #args[2] > 5 then
                cachedBatToken = args[2]
            end
        end

        if isTreadmillUnequipBlocked(name) then
            return nil
        end
    end
    return rawNamecall(self, ...)
end))

-- Direct hook on RemoteEvent.FireServer to catch dot-notation calls Event.FireServer(Event, ...)
pcall(function()
    if hookfunction then
        local dummyEvent = Instance.new("RemoteEvent")
        local rawFireServer
        rawFireServer = hookfunction(dummyEvent.FireServer, newcclosure(function(self, ...)
            if checkcaller and checkcaller() then
                return rawFireServer(self, ...)
            end
            if typeof(self) == "Instance" and isTreadmillUnequipBlocked(tostring(self.Name)) then
                return nil
            end
            return rawFireServer(self, ...)
        end))
        dummyEvent:Destroy()

        local dummyFunc = Instance.new("RemoteFunction")
        local rawInvokeServer
        rawInvokeServer = hookfunction(dummyFunc.InvokeServer, newcclosure(function(self, ...)
            if checkcaller and checkcaller() then
                return rawInvokeServer(self, ...)
            end
            if typeof(self) == "Instance" and isTreadmillUnequipBlocked(tostring(self.Name)) then
                return nil
            end
            return rawInvokeServer(self, ...)
        end))
        dummyFunc:Destroy()
    end
end)

-- Hook Network.Fire directly if client Network module is loaded
pcall(function()
    if ReplicatedStorage:FindFirstChild("Library") and ReplicatedStorage.Library:FindFirstChild("Client") then
        local netMod = ReplicatedStorage.Library.Client:FindFirstChild("Network")
        if netMod then
            local Network = require(netMod)
            if Network and typeof(Network.Fire) == "function" then
                local oldFire = Network.Fire
                Network.Fire = function(event, ...)
                    if event then
                        local evStr = tostring(event)
                        if isTreadmillUnequipBlocked(evStr) then
                            return nil
                        end
                    end
                    return oldFire(event, ...)
                end
            end
        end
    end
end)

--====================================================
-- 2. ONE-TIME / EVENT-DRIVEN ANTI-CHEAT BYPASS (NO LAG SPIKES)
--====================================================
local function neutralizeIntegrity()
    pcall(function()
        if getgc then
            for _, obj in ipairs(getgc(true)) do
                if typeof(obj) == "table" then
                    pcall(function()
                        if rawget(obj, "Enabled") == true and rawget(obj, "TickInterval") ~= nil then
                            if setreadonly then setreadonly(obj, false) end
                            rawset(obj, "Enabled", false)
                            rawset(obj, "TickInterval", math.huge)
                        end
                    end)
                elseif typeof(obj) == "function" and islclosure and islclosure(obj) then
                    pcall(function()
                        local info = debug.getinfo(obj)
                        local name = info.name or ""
                        if name == "MonitorPlayer" or name == "Hold" or name == "onPostSimulation" or name == "requestCharacterReset" or name == "bindCharacter" then
                            hookfunction(obj, function(...)
                                return true
                            end)
                        end
                    end)
                end
            end
        end
    end)
end

task.spawn(neutralizeIntegrity)

--====================================================
-- 3. CHARACTER CONTROLLER & TREADMILL UNANCHOR
--====================================================
local function applySpeed(character)
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and isSpeedEnabled then
        local targetSpeed = (Options and Options.SpeedSlider and Options.SpeedSlider.Value) or originalWalkSpeed
        humanoid.WalkSpeed = targetSpeed
    end
end

local function handleCharacter(character)
    if not character then return end

    local pushback = character:WaitForChild("AntiCollisionHighSeedPushBack", 2)
    if pushback then
        pushback.Disabled = true
        pushback:Destroy()
    end

    local humanoid = character:WaitForChild("Humanoid", 4)
    if humanoid then
        if not isSpeedEnabled then
            originalWalkSpeed = humanoid.WalkSpeed
        else
            applySpeed(character)
        end

        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if isSpeedEnabled then
                local targetSpeed = (Options and Options.SpeedSlider and Options.SpeedSlider.Value) or originalWalkSpeed
                if humanoid.WalkSpeed ~= targetSpeed then
                    humanoid.WalkSpeed = targetSpeed
                end
            else
                if humanoid.WalkSpeed > 0 then
                    originalWalkSpeed = humanoid.WalkSpeed
                end
            end
        end)
    end

    local root = character:WaitForChild("HumanoidRootPart", 4)
    if root then
        root:GetPropertyChangedSignal("Anchored"):Connect(function()
            if not isAutoGainSpeedEnabled or isStealingInProgress or isPlacingInProgress then
                if root.Anchored then
                    root.Anchored = false
                    task.defer(function()
                        pcall(function()
                            local unequipRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Treadmills: RequestUnequip")
                            if unequipRemote and unequipRemote:IsA("RemoteFunction") then
                                unequipRemote:InvokeServer()
                            end
                        end)
                        local cam = Workspace.CurrentCamera
                        if cam and cam.CameraType == Enum.CameraType.Scriptable then
                            cam.CameraType = Enum.CameraType.Custom
                        end
                    end)
                end
            elseif isAutoGainSpeedEnabled and root.Anchored and not isStealingInProgress and not isPlacingInProgress then
                root.Anchored = false
            end
        end)
    end

    character.ChildAdded:Connect(function(child)
        if child.Name == "AntiCollisionHighSeedPushBack" then
            task.defer(function()
                child.Disabled = true
                child:Destroy()
            end)
        end
    end)
end

-- ZERO-LAG Event-Driven Camera Custom Mode & Anti-Stuck Watchdog
pcall(function()
    local cam = Workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("CameraType"):Connect(function()
            if (not isAutoGainSpeedEnabled or isStealingInProgress) and cam.CameraType == Enum.CameraType.Scriptable then
                cam.CameraType = Enum.CameraType.Custom
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and root.Anchored then
            if not isAutoGainSpeedEnabled or isStealingInProgress or isPlacingInProgress then
                root.Anchored = false
                pcall(function()
                    local unequipRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Treadmills: RequestUnequip")
                    if unequipRemote and unequipRemote:IsA("RemoteFunction") then
                        unequipRemote:InvokeServer()
                    end
                end)
                local cam = Workspace.CurrentCamera
                if cam and cam.CameraType == Enum.CameraType.Scriptable then
                    cam.CameraType = Enum.CameraType.Custom
                end
            end
        end
    end
end)

-- ZERO-LAG Event-Driven Anti-Hit Guard Touch & Collision Suppression
local function disableGuardPart(part)
    if part:IsA("BasePart") then
        part.CanTouch = false
        part.CanCollide = false
        part.CanQuery = false
    end
end

local function setupGuardAreaDisabler()
    pcall(function()
        local objects = Workspace:FindFirstChild("__OBJECTS")
        local areas = objects and objects:FindFirstChild("Areas")
        local guardAreas = areas and areas:FindFirstChild("GuardAreas")
        if guardAreas then
            if isAntiHitEnabled then
                for _, desc in ipairs(guardAreas:GetDescendants()) do
                    disableGuardPart(desc)
                end
            end
            guardAreas.DescendantAdded:Connect(function(desc)
                if isAntiHitEnabled then
                    disableGuardPart(desc)
                end
            end)
        end
        
        -- Also scan entire Workspace for any spawned Guard models
        if isAntiHitEnabled then
            for _, desc in ipairs(Workspace:GetDescendants()) do
                if desc:IsA("Model") and (desc.Name == "Guard" or desc.Name:find("Guard")) then
                    for _, p in ipairs(desc:GetDescendants()) do
                        disableGuardPart(p)
                    end
                end
            end
        end
        Workspace.DescendantAdded:Connect(function(desc)
            if isAntiHitEnabled and desc:IsA("Model") and (desc.Name == "Guard" or desc.Name:find("Guard")) then
                for _, p in ipairs(desc:GetDescendants()) do
                    disableGuardPart(p)
                end
            end
        end)
    end)
end

task.spawn(setupGuardAreaDisabler)

--====================================================
-- 5. DYNAMIC CATALOG: RARITIES, PETS, AREAS, MUTATIONS
--====================================================
local DynamicRarityScores = {}
local PetCatalog = {}
local AreasList = {}
local CategoriesList = {}
local RaritiesList = {}
local MutationsList = { "None", "Silver", "Golden", "Rainbow", "Diamond", "Void", "Shiny" }
local TrailsList = {}

local MutationMultipliers = {
    ["none"] = 1,
    ["silver"] = 2,
    ["golden"] = 3,
    ["rainbow"] = 5,
    ["diamond"] = 10,
    ["void"] = 20,
    ["shiny"] = 2,
    ["bloodlit"] = 4,
}

local function parseOddsNumber(str)
    if not str or typeof(str) ~= "string" then return 0 end
    local raw = str:match("1%s*in%s*([%d%.,%s%a]+)") or str
    raw = raw:gsub(",", ""):gsub("%s+", ""):upper()
    
    local mult = 1
    if raw:find("Q") then mult = 1e15; raw = raw:gsub("Q", "")
    elseif raw:find("T") then mult = 1e12; raw = raw:gsub("T", "")
    elseif raw:find("B") then mult = 1e9; raw = raw:gsub("B", "")
    elseif raw:find("M") then mult = 1e6; raw = raw:gsub("M", "")
    elseif raw:find("K") then mult = 1e3; raw = raw:gsub("K", "")
    end
    
    return (tonumber(raw) or 0) * mult
end

local function loadGameDirectories()
    table.clear(DynamicRarityScores)
    table.clear(PetCatalog)
    table.clear(AreasList)
    table.clear(CategoriesList)
    table.clear(RaritiesList)
    
    -- 1. Load Rarities
    local rarityFolder = ReplicatedStorage:FindFirstChild("Directory") and ReplicatedStorage.Directory:FindFirstChild("Rarity")
    local rarityIndex = rarityFolder and (rarityFolder:FindFirstChild("_Index") or rarityFolder)
    
    local sortedRarities = {}
    if rarityIndex then
        for _, module in ipairs(rarityIndex:GetChildren()) do
            if module:IsA("ModuleScript") then
                local success, data = pcall(require, module)
                if success and typeof(data) == "table" and data.RarityNumber then
                    local name = (data.DisplayName or module.Name)
                    DynamicRarityScores[name:lower():gsub("%s+", "")] = data.RarityNumber
                    DynamicRarityScores[module.Name:lower():gsub("%s+", "")] = data.RarityNumber
                    table.insert(sortedRarities, { Name = name, Tier = data.RarityNumber })
                end
            end
        end
    end
    
    local fallbackRarities = {
        { Name = "Brainrot God", Tier = 16 },
        { Name = "Secret", Tier = 15 },
        { Name = "Transcendent", Tier = 14 },
        { Name = "Prismatic", Tier = 13 },
        { Name = "Celestial", Tier = 12 },
        { Name = "Divine", Tier = 11 },
        { Name = "Eternal", Tier = 10 },
        { Name = "Cosmic", Tier = 9 },
        { Name = "Mythical", Tier = 8 },
        { Name = "Mythic", Tier = 8 },
        { Name = "Legendary", Tier = 7 },
        { Name = "Super Rare", Tier = 6 },
        { Name = "Rare", Tier = 5 },
        { Name = "Uncommon", Tier = 4 },
        { Name = "Common", Tier = 3 },
        { Name = "Basic", Tier = 2 },
    }
    
    for _, item in ipairs(fallbackRarities) do
        local key = item.Name:lower():gsub("%s+", "")
        if not DynamicRarityScores[key] then
            DynamicRarityScores[key] = item.Tier
            table.insert(sortedRarities, item)
        end
    end
    
    table.sort(sortedRarities, function(a, b) return a.Tier > b.Tier end)
    
    local seenR = {}
    for _, r in ipairs(sortedRarities) do
        if not seenR[r.Name] then
            seenR[r.Name] = true
            table.insert(RaritiesList, r.Name)
        end
    end

    -- 2. Load Pets / Categories
    local assetsFolder = ReplicatedStorage:FindFirstChild("Directory") and ReplicatedStorage.Directory:FindFirstChild("Assets")
    local assetIndex = assetsFolder and (assetsFolder:FindFirstChild("_Index") or assetsFolder)
    
    local petNames = {}
    if assetIndex then
        for _, module in ipairs(assetIndex:GetChildren()) do
            if module:IsA("ModuleScript") then
                pcall(function()
                    local data = require(module)
                    local id = data._id or module.Name
                    local dispName = data.DisplayName or id
                    local rName = (data.Rarity and (data.Rarity.DisplayName or data.Rarity._id)) or "Basic"
                    local rTier = (data.Rarity and data.Rarity.RarityNumber) or DynamicRarityScores[rName:lower():gsub("%s+", "")] or 1
                    local earnings = data.EarningRate or 0
                    
                    local info = {
                        Id = id,
                        DisplayName = dispName,
                        Rarity = rName,
                        Tier = rTier,
                        EarningRate = earnings
                    }
                    PetCatalog[id:lower()] = info
                    PetCatalog[dispName:lower()] = info
                    table.insert(petNames, dispName)
                end)
            end
        end
    end
    
    table.sort(petNames)
    local seenP = {}
    for _, name in ipairs(petNames) do
        if not seenP[name] then
            seenP[name] = true
            table.insert(CategoriesList, name)
        end
    end

    -- 3. Load Areas
    table.clear(AreasList)
    local areaFolder = ReplicatedStorage:FindFirstChild("Directory") and ReplicatedStorage.Directory:FindFirstChild("Areas")
    local areaIndex = areaFolder and (areaFolder:FindFirstChild("_Index") or areaFolder)
    
    local foundAreas = {}
    if areaIndex then
        for _, module in ipairs(areaIndex:GetChildren()) do
            if module:IsA("ModuleScript") then
                table.insert(foundAreas, module.Name)
            end
        end
    end
    
    local fallbackAreas = { "Cosmic", "Volcano", "Snow", "Prehistoric", "Desert", "Jungle", "Lake", "Forest", "Abyss Ocean" }
    for _, a in ipairs(fallbackAreas) do
        if not table.find(foundAreas, a) then
            table.insert(foundAreas, a)
        end
    end

    table.sort(foundAreas)
    local seenA = {}
    for _, a in ipairs(foundAreas) do
        if not seenA[a] then
            seenA[a] = true
            table.insert(AreasList, a)
        end
    end
    
    -- 4. Load Mutations
    table.clear(MutationsList)
    table.clear(MutationMultipliers)
    MutationMultipliers["none"] = 1
    
    local dynamicMuts = {}
    pcall(function()
        local lib = ReplicatedStorage:FindFirstChild("Library")
        local modFolder = lib and lib:FindFirstChild("Modules")
        local mutMod = modFolder and modFolder:FindFirstChild("Mutations")
        if mutMod then
            local Mutations = require(mutMod)
            if Mutations then
                local rawNames = Mutations.MutationNames
                if rawNames then
                    for name in pairs(rawNames) do
                        if name ~= "None" then
                            table.insert(dynamicMuts, name)
                        end
                        if Mutations.GetTotalMutationsEarningMulti then
                            local multi = Mutations.GetTotalMutationsEarningMulti({ name }) or 1
                            MutationMultipliers[name:lower()] = multi
                        end
                    end
                elseif Mutations.GetMutations then
                    local muts = Mutations.GetMutations()
                    for k, v in pairs(muts) do
                        local name = v.DisplayName or v.Name or k
                        if name ~= "None" then
                            table.insert(dynamicMuts, name)
                        end
                        local multi = v.Multiplier or v.EarningMultiplier or v.Value or 1
                        MutationMultipliers[name:lower()] = multi
                    end
                end
            end
        end
    end)

    if #dynamicMuts == 0 then
        dynamicMuts = { "Silver", "Golden", "Rainbow", "Diamond", "Void", "Shiny", "Bloodmoon", "Celestial", "Magma", "Frozen", "Candy", "Plasma" }
        MutationMultipliers["silver"] = 1.2
        MutationMultipliers["golden"] = 2.5
        MutationMultipliers["rainbow"] = 3.5
        MutationMultipliers["magma"] = 2
        MutationMultipliers["frozen"] = 2
        MutationMultipliers["alpha"] = 4
        MutationMultipliers["shocked"] = 1.5
    end

    table.sort(dynamicMuts)
    table.insert(MutationsList, "None")
    for _, m in ipairs(dynamicMuts) do
        if not table.find(MutationsList, m) then
            table.insert(MutationsList, m)
        end
    end

    -- 5. Load Trails
    table.clear(TrailsList)
    local trailsFolder = ReplicatedStorage:FindFirstChild("Directory") and ReplicatedStorage.Directory:FindFirstChild("Trails")
    local trailIndex = trailsFolder and (trailsFolder:FindFirstChild("_Index") or trailsFolder)
    local foundTrails = {}
    if trailIndex then
        for _, module in ipairs(trailIndex:GetChildren()) do
            if module:IsA("ModuleScript") then
                table.insert(foundTrails, module.Name)
            end
        end
    end
    local fallbackTrails = { "Rainbow", "Fire", "Ice", "Electric", "Galaxy", "Shadow", "Gold", "Diamond" }
    for _, t in ipairs(fallbackTrails) do
        if not table.find(foundTrails, t) then
            table.insert(foundTrails, t)
        end
    end
    table.sort(foundTrails)
    for _, t in ipairs(foundTrails) do
        table.insert(TrailsList, t)
    end
end

loadGameDirectories()

-- Helper function to check multi-dropdown selection
local function hasAnySelection(tbl)
    if typeof(tbl) ~= "table" then return false end
    for _, v in pairs(tbl) do
        if v == true then return true end
    end
    return false
end

-- Helper function to check if a pet is in player's Index book
local function isPetIndexed(assetCategory, displayName)
    local localSave = Save and Save.Get and Save.Get()
    local indexTbl = localSave and localSave.Index
    if not indexTbl then return false end
    
    if assetCategory and indexTbl[assetCategory] == true then
        return true
    end
    if displayName and indexTbl[displayName] == true then
        return true
    end
    return false
end

-- Fast O(1) Prompt Sanitizer
local function isValidStealPrompt(prompt)
    if not prompt or not prompt.Enabled or not prompt.Parent then return false end
    
    local action = (prompt.ActionText or ""):lower()
    local obj = (prompt.ObjectText or ""):lower()
    local name = (prompt.Name or ""):lower()

    if action:find("dna") or obj:find("dna") or name:find("dna") then
        return false
    end

    if action:find("buy") or action:find("purchase") or action:find("unlock") or action:find("shop") or action:find("robux") or action:find("r%$") or action:find("\238\128\130") then
        return false
    end
    if obj:find("buy") or obj:find("purchase") or obj:find("gamepass") or obj:find("exclusive") or obj:find("robux") or obj:find("r%$") or obj:find("\238\128\130") then
        return false
    end
    if name:find("buy") or name:find("purchase") or name:find("product") or name:find("gamepass") or name:find("shop") or name:find("multiplier") or name:find("gift") or name:find("unplace") then
        return false
    end

    if name == "carryareaegg" then
        return true
    end

    if (action == "steal" or action:find("steal") or action:find("carry")) and (obj:find("egg") or obj == "" or name:find("egg")) then
        return true
    end

    return false
end

--====================================================
-- 6. AREA EGG SLOTS RESOLVER & MULTI-FILTER ENGINE
--====================================================
local function getSlotPosition(model)
    if model:IsA("Model") then
        local pivot = model:GetPivot()
        if pivot and pivot.Position ~= Vector3.zero then
            return pivot.Position
        end
        local hitbox = model:FindFirstChild("Hitbox") or model:FindFirstChildWhichIsA("BasePart", true)
        if hitbox then
            return hitbox.Position
        end
    elseif model:IsA("BasePart") then
        return model.Position
    end
    return nil
end

local function parseSlotRecord(model, snapshotRecord)
    local slotUid = model.Name
    local pos = getSlotPosition(model)
    if not pos then return nil end

    local areaId = snapshotRecord and snapshotRecord.AreaId or "Forest"
    local assetCategory = snapshotRecord and snapshotRecord.AssetCategory or "Unknown"
    local mutation = snapshotRecord and (snapshotRecord.BaseMutation or (snapshotRecord.Mutations and snapshotRecord.Mutations[1])) or "None"
    
    local petInfo = PetCatalog[assetCategory:lower()]
    local displayName = petInfo and petInfo.DisplayName or assetCategory
    local rarityName = petInfo and petInfo.Rarity or "Basic"
    local rarityTier = petInfo and petInfo.Tier or DynamicRarityScores[rarityName:lower():gsub("%s+", "")] or 1
    local baseEarnings = petInfo and petInfo.EarningRate or 100
    
    local dataGui = model:FindFirstChild("Data")
    if dataGui then
        local rLabel = dataGui:FindFirstChild("Rarity")
        if rLabel and rLabel:IsA("TextLabel") then
            local rText = rLabel.Text:gsub("%s+", "")
            rarityTier = DynamicRarityScores[rText:lower()] or rarityTier
            rarityName = rLabel.Text
        end
    end

    local mutMult = MutationMultipliers[mutation:lower()] or 1
    local finalEarnings = baseEarnings * mutMult
    
    local assetScale = tonumber(snapshotRecord and snapshotRecord.AssetScale)
    if not assetScale and model:IsA("Model") and model.GetScale then
        local sc = model:GetScale()
        if sc and sc > 0 then
            assetScale = sc
        end
    end
    assetScale = assetScale or 1.0

    local score = (rarityTier * 1e18) + (assetScale * 1e12) + finalEarnings
    if isStealBigEggs then
        score = (assetScale * 1e20) + (rarityTier * 1e15) + finalEarnings
    end

    return {
        Model = model,
        Name = slotUid,
        Position = pos,
        AreaId = areaId,
        AssetCategory = assetCategory,
        DisplayName = displayName,
        RarityName = rarityName,
        RarityTier = rarityTier,
        Mutation = mutation,
        AssetScale = assetScale,
        EarningRate = finalEarnings,
        Score = score
    }
end

local function getFilteredAreaEggSlots(filterMode)
    local slots = {}
    local areaFolder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if not areaFolder then return slots end

    local snapshotMap = {}
    pcall(function()
        if EggCmds and EggCmds.GetAreaEggSnapshot then
            local areasToQuery = (#AreasList > 0 and AreasList) or { "Grassland", "Desert", "Lake", "Prehistoric", "Candy Land", "Cosmic", "Volcano", "Jungle", "Forest", "Abyss Ocean" }
            for _, areaName in ipairs(areasToQuery) do
                local snap = EggCmds.GetAreaEggSnapshot(areaName)
                local records = snap and snap.Records
                if records then
                    for _, rec in ipairs(records) do
                        if rec.Uid then
                            snapshotMap[rec.Uid] = rec
                        end
                    end
                end
            end
        end
    end)

    local selAreas = Options and Options.AreaDropdown and Options.AreaDropdown.Value
    local selCategories = Options and Options.CategoryDropdown and Options.CategoryDropdown.Value
    local selRarities = Options and Options.RarityDropdown and Options.RarityDropdown.Value
    local selMutations = Options and Options.MutationDropdown and Options.MutationDropdown.Value
    local targetPriority = (Options and Options.PriorityDropdown and Options.PriorityDropdown.Value) or "Rarest"

    local filterAreaActive = hasAnySelection(selAreas)
    local filterCategoryActive = hasAnySelection(selCategories)
    local filterRarityActive = hasAnySelection(selRarities)
    local filterMutationActive = hasAnySelection(selMutations)

    for _, model in ipairs(areaFolder:GetChildren()) do
        local rec = snapshotMap[model.Name]
        local slotData = parseSlotRecord(model, rec)
        if slotData then
            local include = true
            
            if filterMode == "Selected" then
                if filterAreaActive then
                    local matchedArea = false
                    for aName, selected in pairs(selAreas) do
                        if selected == true and aName:lower() == slotData.AreaId:lower() then
                            matchedArea = true
                            break
                        end
                    end
                    if not matchedArea then include = false end
                end

                if include and filterCategoryActive then
                    local matchedCat = false
                    for cName, selected in pairs(selCategories) do
                        if selected == true then
                            local cLower = cName:lower()
                            if cLower == slotData.AssetCategory:lower() or cLower == slotData.DisplayName:lower() then
                                matchedCat = true
                                break
                            end
                        end
                    end
                    if not matchedCat then include = false end
                end

                if include and filterRarityActive then
                    local matchedRarity = false
                    local slotRKey = slotData.RarityName:lower():gsub("%s+", "")
                    for rName, selected in pairs(selRarities) do
                        if selected == true then
                            local rKey = rName:lower():gsub("%s+", "")
                            if rKey == slotRKey then
                                matchedRarity = true
                                break
                            end
                        end
                    end
                    if not matchedRarity then include = false end
                end

                if include and filterMutationActive then
                    local matchedMut = false
                    local slotMKey = slotData.Mutation:lower()
                    for mName, selected in pairs(selMutations) do
                        if selected == true then
                            if mName:lower() == slotMKey then
                                matchedMut = true
                                break
                            end
                        end
                    end
                    if not matchedMut then include = false end
                end
            end

            if isStealBigEggs then
                local minBigEggSize = (Options and Options.BigEggMinSize and Options.BigEggMinSize.Value) or 1.5
                if (slotData.AssetScale or 1) < minBigEggSize then
                    include = false
                end
            end

            if include then
                table.insert(slots, slotData)
            end
        end
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local rootPos = root and root.Position or Vector3.zero

    if isStealBigEggs then
        table.sort(slots, function(a, b)
            if math.abs((a.AssetScale or 1) - (b.AssetScale or 1)) > 0.05 then
                return (a.AssetScale or 1) > (b.AssetScale or 1)
            end
            return a.Score > b.Score
        end)
    elseif targetPriority == "Un-Indexed" then
        table.sort(slots, function(a, b)
            local aIndexed = isPetIndexed(a.AssetCategory, a.DisplayName)
            local bIndexed = isPetIndexed(b.AssetCategory, b.DisplayName)
            
            if not aIndexed and bIndexed then
                return true
            elseif aIndexed and not bIndexed then
                return false
            else
                return a.Score > b.Score
            end
        end)
    elseif targetPriority == "Highest Earnings" then
        table.sort(slots, function(a, b)
            return a.EarningRate > b.EarningRate
        end)
    elseif targetPriority == "Nearest" then
        table.sort(slots, function(a, b)
            return (a.Position - rootPos).Magnitude < (b.Position - rootPos).Magnitude
        end)
    else
        table.sort(slots, function(a, b)
            return a.Score > b.Score
        end)
    end

    if isAutoFocusEventMutation and activeEventMutationName then
        local targetMut = activeEventMutationName:lower()
        table.sort(slots, function(a, b)
            local aIsTarget = (a.Mutation and a.Mutation:lower() == targetMut)
            local bIsTarget = (b.Mutation and b.Mutation:lower() == targetMut)
            if aIsTarget and not bIsTarget then
                return true
            elseif not aIsTarget and bIsTarget then
                return false
            else
                return a.Score > b.Score
            end
        end)
    end

    if #slots > 0 then
        lastMatchingEggTime = os.clock()
    end

    return slots
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    
    if fireproximityprompt then
        fireproximityprompt(prompt, 0)
    end
    
    pcall(function()
        prompt:InputHoldBegin()
        prompt:InputHoldEnd()
    end)

    return true
end

local function fireEggSteal(modelName)
    local triggered = false

    -- 1. Game Client Module Invocation
    if modelName and EggCmds and EggCmds.RequestCarryAreaEgg then
        pcall(function()
            EggCmds.RequestCarryAreaEgg(modelName)
            triggered = true
        end)
    end

    -- 2. Direct Network Remote Invocation (Protected Table Payload)
    if modelName then
        pcall(function()
            local net = ReplicatedStorage:FindFirstChild("Network")
            local carryRemote = net and (net:FindFirstChild("Eggs: RequestCarryAreaEgg") or net:FindFirstChild("Eggs: RequestAreaEggCarry"))
            if carryRemote then
                local payload = { EggUid = modelName, Uid = modelName, AreaEggId = modelName }
                if carryRemote:IsA("RemoteFunction") then
                    task.spawn(function()
                        pcall(function() carryRemote:InvokeServer(payload) end)
                    end)
                    triggered = true
                elseif carryRemote:IsA("RemoteEvent") then
                    pcall(function() carryRemote:FireServer(payload) end)
                    triggered = true
                end
            end
        end)
    end

    -- 3. SmartPromptPart Immediate Fire
    local smartPart = Workspace:FindFirstChild("SmartPromptPart")
    if smartPart then
        for _, p in ipairs(smartPart:GetChildren()) do
            if p:IsA("ProximityPrompt") and p.Enabled and isValidStealPrompt(p) then
                triggerPrompt(p)
                triggered = true
            end
        end
    end

    -- 3. Local Vicinity Prompts Immediate Fire
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local rootPos = root.Position
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled and isValidStealPrompt(prompt) then
                local pParent = prompt.Parent
                if pParent:IsA("BasePart") and (pParent.Position - rootPos).Magnitude <= 25 then
                    triggerPrompt(prompt)
                    triggered = true
                end
            end
        end
    end

    return triggered
end

local function teleportCharacter(targetPos)
    local char = LocalPlayer.Character
    if not char then return false end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return false end

    local startPos = root.Position
    local distance = (targetPos - startPos).Magnitude

    if distance < 1 then
        root.CFrame = CFrame.new(targetPos)
        return true
    end

    local speed = (Options and Options.TweenSpeed and Options.TweenSpeed.Value) or 150

    -- Camera-Shake-Free RenderStepped Smooth Glide
    local duration = math.clamp(distance / speed, 0.04, 15)
    local elapsed = 0
    local startCF = root.CFrame
    local endCF = CFrame.new(targetPos, targetPos + (startCF.LookVector * Vector3.new(1, 0, 1)).Unit)
    if distance > 1 then
        local flatDir = (targetPos - startPos) * Vector3.new(1, 0, 1)
        if flatDir.Magnitude > 0.1 then
            endCF = CFrame.new(targetPos, targetPos + flatDir.Unit)
        end
    end

    local savedCollisions = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            savedCollisions[part] = part.CanCollide
            part.CanCollide = false
        end
    end

    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    local completed = false
    local glideConn
    glideConn = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        
        -- Lockstep RenderStepped Lerp (Zero Camera Jitter / Shake)
        root.CFrame = startCF:Lerp(endCF, alpha)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        
        if alpha >= 1 then
            completed = true
        end
    end)

    while not completed and char and char.Parent do
        RunService.Heartbeat:Wait()
    end

    if glideConn then
        glideConn:Disconnect()
        glideConn = nil
    end

    for part, canCol in pairs(savedCollisions) do
        if part and part.Parent then
            part.CanCollide = canCol
        end
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.new(targetPos)
    return true
end

local function dropHeldEgg()
    pcall(function()
        if EggCmds and EggCmds.RequestDropHeldAreaEgg then
            EggCmds.RequestDropHeldAreaEgg()
        end
        local network = ReplicatedStorage:FindFirstChild("Network")
        local dropRemote = network and (network:FindFirstChild("Eggs: RequestAreaEggDrop") or network:FindFirstChild("Eggs: RequestDropHeldAreaEgg"))
        if dropRemote then
            if dropRemote:IsA("RemoteFunction") then
                dropRemote:InvokeServer()
            elseif dropRemote:IsA("RemoteEvent") then
                dropRemote:FireServer()
            end
        end
    end)
end

--====================================================
-- 7. BAT KILL AURA & COMBAT ENGINE (PROXIMITY)
--====================================================
local function getBatTool()
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("bat") then
                return item, true
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("bat") then
                return item, false
            end
        end
    end
    return nil, false
end

local function strikeTargetPlayer(targetPlayer, targetHrp)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not root or not hum then return end

    local batTool, isEquipped = getBatTool()
    if not batTool then return end

    local autoEquip = Toggles and Toggles.AutoEquipBat and Toggles.AutoEquipBat.Value or false
    if not isEquipped and autoEquip then
        hum:EquipTool(batTool)
        task.wait(0.02)
    end

    local batRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Bat:Activate")
    local token = cachedBatToken or string.format("%s:18:%s", tostring(LocalPlayer.UserId), tostring(DateTime.now().UnixTimestampMillis))

    if batRemote and batRemote:IsA("RemoteEvent") then
        batRemote:FireServer(targetPlayer, token)
    end

    pcall(function()
        batTool:Activate()
    end)
end

local function getValidCombatTargets(maxDistance)
    local targets = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return targets end

    local myPos = root.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local tChar = player.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChild("Humanoid")

            if tHrp and tHum and tHum.Health > 0 then
                local dist = (myPos - tHrp.Position).Magnitude
                if dist <= maxDistance then
                    table.insert(targets, { Player = player, Hrp = tHrp, Distance = dist })
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

local killAuraThread = nil

local function runKillAuraEngine()
    while isKillAuraEnabled do
        if not isStealingInProgress and not isPlacingInProgress and LocalPlayer.Character then
            local maxRange = (Options and Options.AuraRange and Options.AuraRange.Value) or 9.5
            local interval = (Options and Options.AttackInterval and Options.AttackInterval.Value) or 0.1

            local targets = getValidCombatTargets(maxRange)
            for _, entry in ipairs(targets) do
                if not isKillAuraEnabled then break end
                strikeTargetPlayer(entry.Player, entry.Hrp)
            end
            task.wait(interval)
        else
            task.wait(0.2)
        end
    end
end

--====================================================
-- TREADMILL RESOLVER & AUTO GAIN SPEED
--====================================================
local function getMyTreadmillRoot()
    if PlotCmds and PlotCmds.GetMySlot then
        local mySlot = PlotCmds.GetMySlot()
        if mySlot then
            local renders = Workspace:FindFirstChild("__ClientTreadmillRenders")
            local render = renders and renders:FindFirstChild("TreadmillRender_" .. tostring(mySlot))
            if render then
                local root = render:FindFirstChild("Root") or render:FindFirstChildWhichIsA("BasePart")
                if root then return root, render end
            end
        end
    end
    
    local renders = Workspace:FindFirstChild("__ClientTreadmillRenders")
    if renders then
        for _, render in ipairs(renders:GetChildren()) do
            if render:IsA("Model") then
                local root = render:FindFirstChild("Root") or render:FindFirstChildWhichIsA("BasePart")
                if root then return root, render end
            end
        end
    end
    
    return nil, nil
end

local function triggerTreadmillSession(force)
    if not force and not isAutoGainSpeedEnabled and not isRotationEnabled then return end
    if isStealingInProgress or isPlacingInProgress then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then return end

    local tmRoot, tmRender = getMyTreadmillRoot()
    if not tmRoot then return end

    local savedPivot = char:GetPivot()
    
    -- 1. Instant mount above treadmill for server raycast check
    char:PivotTo(CFrame.new(tmRoot.Position + Vector3.new(0, 3, 0)))
    task.wait(0.12)
    
    -- 2. Register runtime instance and invoke remote
    pcall(function()
        if RuntimeInstanceRegistry and tmRender then
            RuntimeInstanceRegistry.Set("Treadmill", tmRender.Name, tmRender)
        end
        local equipRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Treadmills: RequestEquipStatic")
        if equipRemote and equipRemote:IsA("RemoteFunction") then
            equipRemote:InvokeServer()
        end
    end)
    
    -- 3. Unanchor and snap back to saved spot
    task.wait(0.04)
    root.Anchored = false
    char:PivotTo(savedPivot)
end

local function unequipTreadmillWithoutTeleport()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local savedPivot = char and char:GetPivot()
    
    isManualUnequip = true
    pcall(function()
        local unequipRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Treadmills: RequestUnequip")
        if unequipRemote and unequipRemote:IsA("RemoteFunction") then
            unequipRemote:InvokeServer()
        end
    end)
    
    if char and savedPivot then
        for i = 1, 4 do
            char:PivotTo(savedPivot)
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait(0.05)
        end
    end
    isManualUnequip = false
end

--====================================================
-- 8. PLOT RESOLVER & AUTO PLACE ENGINE (SAFE PLOT SPAWN TP)
--====================================================
local function getMyPlotSafePosition()
    local mySlot = (PlotCmds and PlotCmds.GetMySlot and PlotCmds.GetMySlot())
    if not mySlot then return nil end
    
    local plots = Workspace:FindFirstChild("Plots") or (Workspace:FindFirstChild("__OBJECTS") and Workspace.__OBJECTS:FindFirstChild("Plots"))
    if not plots then return nil end
    
    local myPlot = plots:FindFirstChild(tostring(mySlot)) or plots:FindFirstChild("Plot_" .. tostring(mySlot)) or plots:FindFirstChild("Plot" .. tostring(mySlot))
    if not myPlot then return nil end
    
    -- Safe spawn position away from egg nest
    local spawnPt = myPlot:FindFirstChild("SpawnPoint") or myPlot:FindFirstChild("Spawn") or myPlot:FindFirstChild("PlotSign")
    if spawnPt and spawnPt:IsA("BasePart") then
        return spawnPt.Position + Vector3.new(0, 3.5, 0)
    end
    
    local center = myPlot:FindFirstChild("CenterPoint") or myPlot:FindFirstChild("Center") or myPlot.PrimaryPart or myPlot:FindFirstChildWhichIsA("BasePart")
    if center then
        return center.Position + Vector3.new(0, 8, 12)
    end
    
    return myPlot:GetPivot().Position + Vector3.new(0, 8, 12)
end

local function resetCharacterToSpawn()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        else
            char:BreakJoints()
        end
    end
    local newChar = LocalPlayer.CharacterAdded:Wait()
    local newRoot = newChar:WaitForChild("HumanoidRootPart", 10)
    local newHum = newChar:WaitForChild("Humanoid", 10)
    
    -- Wait for character physics to stabilize and touch the ground
    task.wait(1.0)
    if newRoot then
        newRoot.Anchored = false
        newRoot.AssemblyLinearVelocity = Vector3.zero
    end
    return newChar
end

local function executeStealSlot(slotData)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    isStealingInProgress = true

    -- 1. Pause treadmill session
    local wasTreadmillActive = isAutoGainSpeedEnabled
    if wasTreadmillActive then
        isManualUnequip = true
        pcall(function()
            local unequipRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Treadmills: RequestUnequip")
            if unequipRemote and unequipRemote:IsA("RemoteFunction") then
                unequipRemote:InvokeServer()
            end
        end)
        task.wait(0.04)
    end

    -- 2. Position Check: If X > 551 (stuck outside safe zone), reset character to respawn at base
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root.Position.X > 551 then
        char = resetCharacterToSpawn()
        root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            isStealingInProgress = false
            return false
        end
        -- Wait before move after reset!
        task.wait(0.8)
    end

    local eggPos = slotData.Position

    -- 3. Step 1: Align to Safe Zone axis at current Z if not already in corridor
    local currentPos = root.Position
    if math.abs(currentPos.X - SAFEZONE_X) > 4 or math.abs(currentPos.Y - SAFEZONE_Y) > 5 then
        teleportCharacter(Vector3.new(SAFEZONE_X, SAFEZONE_Y, currentPos.Z))
    end

    -- 4. Step 2: Tween inside Safe Zone along Z axis to match targeted egg's Z
    teleportCharacter(Vector3.new(SAFEZONE_X, SAFEZONE_Y, eggPos.Z))

    -- 5. Step 3: Tween perpendicularly into the area directly onto the egg nest
    teleportCharacter(eggPos + Vector3.new(0, 1.8, 0))

    -- 6. Pick up egg (Rapid instant prompt & remote fire)
    task.wait(0.03)
    fireEggSteal(slotData.Name)
    task.wait(0.03)
    fireEggSteal(slotData.Name)
    task.wait(0.04)

    -- 7. Step 4: Tween straight back to Safe Zone / Claim corridor along X axis (Egg instantly claimed!)
    teleportCharacter(Vector3.new(SAFEZONE_X, SAFEZONE_Y, eggPos.Z))

    -- 8. Cooldown & Resume treadmill session
    task.wait(0.10)
    isStealingInProgress = false
    sessionStealCount = sessionStealCount + 1
    if wasTreadmillActive and (isAutoGainSpeedEnabled or isRotationEnabled) then
        isManualUnequip = false
        task.spawn(triggerTreadmillSession, true)
    end

    return true
end

local function getUnplacedInventoryItems(mode)
    local results = {}
    local seenUids = {}
    local save = Save and Save.Get and Save.Get()
    if not save then return results end

    local equippedMap = {}
    if save.EquippedAssets then
        for _, uid in ipairs(save.EquippedAssets) do
            equippedMap[uid] = true
        end
    end

    local selCategories = Options and Options.AutoPlaceCategoryDropdown and Options.AutoPlaceCategoryDropdown.Value
    local selRarities = Options and Options.AutoPlaceRarityDropdown and Options.AutoPlaceRarityDropdown.Value
    local selMutations = Options and Options.AutoPlaceMutationDropdown and Options.AutoPlaceMutationDropdown.Value

    local filterCatActive = hasAnySelection(selCategories)
    local filterRarityActive = hasAnySelection(selRarities)
    local filterMutActive = hasAnySelection(selMutations)

    local function evaluateItem(uid, category, mutations, baseMutation, itemType)
        if not uid or seenUids[uid] then return end
        seenUids[uid] = true

        local cat = category or "Unknown"
        local petInfo = PetCatalog[cat:lower()]
        local dispName = petInfo and petInfo.DisplayName or cat
        local rarityName = petInfo and petInfo.Rarity or "Basic"
        local mutation = baseMutation or (mutations and mutations[1]) or "None"

        local include = true
        if mode == "Selected" then
            if filterCatActive then
                local matched = false
                for cName, sel in pairs(selCategories) do
                    if sel == true and (cName:lower() == cat:lower() or cName:lower() == dispName:lower()) then
                        matched = true
                        break
                    end
                end
                if not matched then include = false end
            end

            if include and filterRarityActive then
                local matched = false
                local rKey = rarityName:lower():gsub("%s+", "")
                for rName, sel in pairs(selRarities) do
                    if sel == true and rName:lower():gsub("%s+", "") == rKey then
                        matched = true
                        break
                    end
                end
                if not matched then include = false end
            end

            if include and filterMutActive then
                local matched = false
                local mKey = mutation:lower()
                for mName, sel in pairs(selMutations) do
                    if sel == true and mName:lower() == mKey then
                        matched = true
                        break
                    end
                end
                if not matched then include = false end
            end
        end

        if include then
            table.insert(results, {
                Uid = uid,
                Category = cat,
                DisplayName = dispName,
                Rarity = rarityName,
                Mutation = mutation,
                Type = itemType
            })
        end
    end

    -- 1. Scan Save.EggInventory (Unplaced nest eggs)
    if save.EggInventory then
        for uid, data in pairs(save.EggInventory) do
            if not data.Placement and not data.InFuse then
                local cat = data.AssetCategory or data.Category or "Unknown"
                evaluateItem(uid, cat, data.Mutations, data.BaseMutation, "Egg")
            end
        end
    end

    -- 2. Scan Save.Inventory (Hatched pet assets)
    if save.Inventory then
        for uid, data in pairs(save.Inventory) do
            if not data.InFuse and not equippedMap[uid] then
                local cat = data.Category or data.AssetCategory or "Unknown"
                evaluateItem(uid, cat, data.Mutations, data.BaseMutation, "Asset")
            end
        end
    end

    return results
end

local function placeItemOnPlot(item)
    local uid = item.Uid
    if not uid then return false end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local success = false

    -- 1. Equip Egg Tool Remote
    pcall(function()
        local equipRemote = network and network:FindFirstChild("Eggs: RequestEquipTool")
        if equipRemote and equipRemote:IsA("RemoteFunction") then
            equipRemote:InvokeServer(uid)
        end
    end)
    task.wait(0.04)

    -- 2. Request Place Egg inside own plot with valid local coordinates
    pcall(function()
        local placeRemote = network and network:FindFirstChild("Eggs: RequestPlaceEgg")
        if placeRemote and placeRemote:IsA("RemoteFunction") then
            local randX = (math.random() * 26) - 13
            local randZ = (math.random() * 26) - 13
            local localCf = CFrame.new(randX, -0.50011444091797, randZ, -1, 0, 0, 0, 1, 0, 0, 0, -1)
            
            success = placeRemote:InvokeServer({
                Uid = uid,
                LocalCFrame = localCf
            })
        end
    end)

    -- 3. Fallback: Request ActiveAsset Equip Remote
    if not success then
        pcall(function()
            local activeEquip = network and network:FindFirstChild("ActiveAssets: RequestEquip")
            if activeEquip and activeEquip:IsA("RemoteFunction") then
                success = activeEquip:InvokeServer(uid)
            end
        end)
    end

    return success
end

local function processHatchReadyEggs()
    if not EggCmds or not EggCmds.GetOwnerRuntimeRecords then return end
    local placed = EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId) or {}
    for uid, rec in pairs(placed) do
        if not isAutoHatchReady and not isRotationEnabled then break end
        if EggCmds.IsLocalEggReady and EggCmds.IsLocalEggReady(uid) then
            pcall(function()
                local hatchRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Eggs: RequestHatchEgg")
                if hatchRemote and hatchRemote:IsA("RemoteFunction") then
                    hatchRemote:InvokeServer(uid)
                else
                    EggCmds.RequestHatchEgg(uid)
                end
            end)
            pcall(function()
                local completeRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Eggs: RequestCompleteHatchEgg")
                if completeRemote and completeRemote:IsA("RemoteFunction") then
                    completeRemote:InvokeServer(uid)
                else
                    EggCmds.RequestCompleteHatchEgg(uid)
                end
            end)
            task.wait(0.06)
        end
    end
end

local function processAutoPlaceBatch()
    local mode = (Toggles and Toggles.AutoPlaceSelected and Toggles.AutoPlaceSelected.Value) and "Selected" or "All"
    local items = getUnplacedInventoryItems(mode)
    
    if #items > 0 and not isStealingInProgress then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local safePlotPos = getMyPlotSafePosition()

        if root and safePlotPos then
            local distToPlot = (root.Position - safePlotPos).Magnitude
            local savedPos = nil
            local wasTreadmillActive = isAutoGainSpeedEnabled or isRotationEnabled

            -- If player is away from plot (> 25 studs), teleport to safe plot spawn
            if distToPlot > 25 then
                isPlacingInProgress = true
                savedPos = root.Position

                -- Pause treadmill if running
                if wasTreadmillActive then
                    isManualUnequip = true
                    pcall(function()
                        local unequipRemote = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Treadmills: RequestUnequip")
                        if unequipRemote and unequipRemote:IsA("RemoteFunction") then
                            unequipRemote:InvokeServer()
                        end
                    end)
                    task.wait(0.06)
                end

                -- Teleport cleanly onto plot spawn
                teleportCharacter(safePlotPos)
                task.wait(0.12)
            end

            -- Place all items
            for _, item in ipairs(items) do
                if not isAutoPlaceSelected and not isAutoPlaceAll and not isRotationEnabled then break end
                placeItemOnPlot(item)
                task.wait(0.08)
            end

            -- Return to saved location if we teleported
            if savedPos then
                task.wait(0.1)
                teleportCharacter(savedPos)
                task.wait(0.12)
                isPlacingInProgress = false

                -- Resume treadmill if it was active
                if wasTreadmillActive and (isAutoGainSpeedEnabled or isRotationEnabled) then
                    isManualUnequip = false
                    task.spawn(triggerTreadmillSession, true)
                end
            end
        else
            for _, item in ipairs(items) do
                if not isAutoPlaceSelected and not isAutoPlaceAll and not isRotationEnabled then break end
                placeItemOnPlot(item)
                task.wait(0.08)
            end
        end
    end
end

local autoPlaceThread = nil
local function runAutoPlaceEngine()
    while isAutoPlaceSelected or isAutoPlaceAll do
        processAutoPlaceBatch()
        task.wait(1.5)
    end
end

local autoHatchThread = nil
local function runAutoHatchEngine()
    while isAutoHatchReady do
        processHatchReadyEggs()
        task.wait(2.5)
    end
end

--====================================================
-- AUTO SELL ENGINE (SELECTED & ALL ELIGIBLE)
--====================================================
local function getSellableInventoryItems(mode)
    local results = {}
    local save = Save and Save.Get and Save.Get()
    if not save or not save.Inventory then return results end

    local equippedMap = {}
    if save.EquippedAssets then
        for _, uid in ipairs(save.EquippedAssets) do
            equippedMap[uid] = true
        end
    end

    local selCategories = Options and Options.SellCategoryDropdown and Options.SellCategoryDropdown.Value
    local selRarities = Options and Options.SellRarityDropdown and Options.SellRarityDropdown.Value
    local selMutations = Options and Options.SellMutationDropdown and Options.SellMutationDropdown.Value

    local filterCatActive = hasAnySelection(selCategories)
    local filterRarityActive = hasAnySelection(selRarities)
    local filterMutActive = hasAnySelection(selMutations)

    for uid, data in pairs(save.Inventory) do
        -- Exclude equipped assets, favorited pets, and items inside fusion machines
        if not equippedMap[uid] and not data.IsFavorite and not data.InFuse then
            local cat = data.Category or data.AssetCategory or "Unknown"
            local petInfo = PetCatalog[cat:lower()]
            local dispName = petInfo and petInfo.DisplayName or cat
            local rarityName = petInfo and petInfo.Rarity or "Basic"
            local mutation = data.BaseMutation or (data.Mutations and data.Mutations[1]) or "None"

            local include = true
            if mode == "Selected" then
                if filterCatActive then
                    local matched = false
                    for cName, sel in pairs(selCategories) do
                        if sel == true and (cName:lower() == cat:lower() or cName:lower() == dispName:lower()) then
                            matched = true
                            break
                        end
                    end
                    if not matched then include = false end
                end

                if include and filterRarityActive then
                    local matched = false
                    local rKey = rarityName:lower():gsub("%s+", "")
                    for rName, sel in pairs(selRarities) do
                        if sel == true and rName:lower():gsub("%s+", "") == rKey then
                            matched = true
                            break
                        end
                    end
                    if not matched then include = false end
                end

                if include and filterMutActive then
                    local matched = false
                    local mKey = mutation:lower()
                    for mName, sel in pairs(selMutations) do
                        if sel == true and mName:lower() == mKey then
                            matched = true
                            break
                        end
                    end
                    if not matched then include = false end
                end
            end

            if include then
                table.insert(results, uid)
            end
        end
    end

    return results
end

local function sellAssetUids(uids)
    if not uids or #uids == 0 then return false end

    local network = ReplicatedStorage:FindFirstChild("Network")
    local sellAllRemote = network and network:FindFirstChild("AssetInventory: SellAllAssets")
    local sellSingleRemote = network and network:FindFirstChild("AssetInventory: SellAsset")

    -- Batch in chunks of 50 for optimal server performance
    local chunkSize = 50
    for i = 1, #uids, chunkSize do
        local batch = {}
        for j = i, math.min(i + chunkSize - 1, #uids) do
            table.insert(batch, uids[j])
        end

        if sellAllRemote and sellAllRemote:IsA("RemoteEvent") then
            pcall(function()
                sellAllRemote:FireServer(batch)
            end)
        elseif sellSingleRemote and sellSingleRemote:IsA("RemoteEvent") then
            for _, uid in ipairs(batch) do
                pcall(function()
                    sellSingleRemote:FireServer({ uid })
                end)
                task.wait(0.02)
            end
        end
        task.wait(0.1)
    end
    return true
end

local function syncAutoSellRaritiesWithServer(raritiesMap)
    pcall(function()
        local network = ReplicatedStorage:FindFirstChild("Network")
        local autoSellRemote = network and network:FindFirstChild("Backpack: SetAutoSellState")
        if autoSellRemote and autoSellRemote:IsA("RemoteFunction") then
            autoSellRemote:InvokeServer(raritiesMap or {})
        end
    end)
end

local autoSellThread = nil
local function runAutoSellEngine()
    while isAutoSellSelected or isAutoSellAllEligible do
        local mode = isAutoSellSelected and "Selected" or "All"
        local uidsToSell = getSellableInventoryItems(mode)

        if #uidsToSell > 0 then
            sellAssetUids(uidsToSell)
            task.wait(1.5)
        else
            task.wait(2.5)
        end
    end
end

--====================================================
-- AUTO FUSE PETS ENGINE
--====================================================
local function pickFuseGroup()
    local save = Save and Save.Get and Save.Get()
    if not save or not save.Inventory then return nil end

    local equippedMap = {}
    if save.EquippedAssets then
        for _, uid in ipairs(save.EquippedAssets) do
            equippedMap[uid] = true
        end
    end

    local selRarities = Options and Options.FuseRaritiesDropdown and Options.FuseRaritiesDropdown.Value
    local selMutations = Options and Options.FuseMutationsDropdown and Options.FuseMutationsDropdown.Value
    local filterRarityActive = hasAnySelection(selRarities)
    local filterMutActive = hasAnySelection(selMutations)

    local neverMutated = Toggles and Toggles.NeverFuseMutated and Toggles.NeverFuseMutated.Value
    local neverEquipped = Toggles and Toggles.NeverFuseEquipped and Toggles.NeverFuseEquipped.Value
    local maxScale = (Options and Options.MaxScaleToFuse and Options.MaxScaleToFuse.Value) or 10
    local keepPerType = (Options and Options.KeepPerPetType and Options.KeepPerPetType.Value) or 0
    local pickGroupBy = (Options and Options.PickGroupByDropdown and Options.PickGroupByDropdown.Value) or "Highest Rarity"

    local groupedByType = {}

    for uid, data in pairs(save.Inventory) do
        if not data.InFuse and not data.IsFavorite then
            local isEquipped = equippedMap[uid] == true
            if not (neverEquipped and isEquipped) then
                local cat = data.Category or data.AssetCategory or "Unknown"
                local catalog = PetCatalog[cat:lower()]
                local rarityName = (data.Rarity and (data.Rarity.DisplayName or data.Rarity._id)) or (catalog and catalog.Rarity) or "Basic"
                local rarityTier = (data.Rarity and data.Rarity.RarityNumber) or DynamicRarityScores[rarityName:lower():gsub("%s+", "")] or (catalog and catalog.Tier) or 1
                
                local mut = "None"
                if data.Mutations and typeof(data.Mutations) == "table" and #data.Mutations > 0 then
                    mut = tostring(data.Mutations[1])
                elseif data.BaseMutation and tostring(data.BaseMutation) ~= "" and tostring(data.BaseMutation) ~= "None" then
                    mut = tostring(data.BaseMutation)
                end

                local isMutated = (mut ~= "None" and mut ~= "")
                local allow = true

                if neverMutated and isMutated then
                    allow = false
                end

                if allow and filterMutActive then
                    local matched = false
                    local mKey = mut:lower()
                    for mName, sel in pairs(selMutations) do
                        if sel == true and mName:lower() == mKey then
                            matched = true
                            break
                        end
                    end
                    if not matched then allow = false end
                end

                if allow and filterRarityActive then
                    local matched = false
                    local rKey = rarityName:lower():gsub("%s+", "")
                    for rName, sel in pairs(selRarities) do
                        if sel == true and rName:lower():gsub("%s+", "") == rKey then
                            matched = true
                            break
                        end
                    end
                    if not matched then allow = false end
                end

                local scaleVal = tonumber(data.Scale or data.Size or data.Multiplier or 1) or 1
                if allow and scaleVal > maxScale then
                    allow = false
                end

                if allow then
                    if not groupedByType[cat] then
                        groupedByType[cat] = {}
                    end
                    table.insert(groupedByType[cat], {
                        Uid = uid,
                        Category = cat,
                        Rarity = rarityName,
                        Tier = rarityTier,
                        Scale = scaleVal,
                        Mutation = mut,
                        IsEquipped = isEquipped
                    })
                end
            end
        end
    end

    local eligibleGroups = {}
    for cat, list in pairs(groupedByType) do
        table.sort(list, function(a, b)
            return a.Scale > b.Scale
        end)

        local available = {}
        for i = (keepPerType + 1), #list do
            table.insert(available, list[i])
        end

        if #available >= 5 then
            local topPet = available[1]
            table.insert(eligibleGroups, {
                Category = cat,
                Tier = topPet.Tier,
                Count = #available,
                Pets = available
            })
        end
    end

    if #eligibleGroups == 0 then return nil end

    if pickGroupBy == "Highest Rarity" then
        table.sort(eligibleGroups, function(a, b)
            if a.Tier == b.Tier then return a.Count > b.Count end
            return a.Tier > b.Tier
        end)
    elseif pickGroupBy == "Lowest Rarity" then
        table.sort(eligibleGroups, function(a, b)
            if a.Tier == b.Tier then return a.Count > b.Count end
            return a.Tier < b.Tier
        end)
    elseif pickGroupBy == "Most Count" then
        table.sort(eligibleGroups, function(a, b)
            return a.Count > b.Count
        end)
    elseif pickGroupBy == "Least Count" then
        table.sort(eligibleGroups, function(a, b)
            return a.Count < b.Count
        end)
    end

    local selectedGroup = eligibleGroups[1]
    local uidsToFuse = {}
    for i = 1, 5 do
        table.insert(uidsToFuse, selectedGroup.Pets[i].Uid)
    end

    return uidsToFuse, selectedGroup
end

local function executeFuseBatch(uids, groupInfo)
    if not uids or #uids < 5 then return false end

    local network = ReplicatedStorage:FindFirstChild("Network")
    if not network then return false end

    local ackRemote = network:FindFirstChild("FuseMachine: AcknowledgeInfo")
    local insertRemote = network:FindFirstChild("FuseMachine: InsertMob")
    local startRemote = network:FindFirstChild("FuseMachine: StartFuse")
    local revealRemote = network:FindFirstChild("FuseMachine: CompleteReveal")

    -- 1. Acknowledge Machine Info
    if ackRemote and ackRemote:IsA("RemoteFunction") then
        pcall(function() ackRemote:InvokeServer() end)
    end
    task.wait(0.05)

    -- 2. Insert 5 Mobs
    for _, uid in ipairs(uids) do
        if insertRemote and insertRemote:IsA("RemoteFunction") then
            pcall(function() insertRemote:InvokeServer(uid) end)
        end
        task.wait(0.04)
    end

    -- 3. Start Fuse
    local fused = false
    if startRemote and startRemote:IsA("RemoteFunction") then
        local ok, res = pcall(function() return startRemote:InvokeServer() end)
        if ok and res ~= false then
            fused = true
        end
    end
    task.wait(0.08)

    -- 4. Auto Complete Reveal if enabled
    local autoReveal = Toggles and Toggles.AutoCompleteReveal and Toggles.AutoCompleteReveal.Value
    if autoReveal and revealRemote and revealRemote:IsA("RemoteFunction") then
        pcall(function() revealRemote:InvokeServer() end)
    end

    if fused and groupInfo then
        Library:Notify(string.format("Fused 5x %s (%s)", groupInfo.Category, groupInfo.Pets[1].Rarity), 3)
    end

    return fused
end

local autoFuseThread = nil
local function runAutoFuseEngine()
    while isAutoFusePets do
        local uids, groupInfo = pickFuseGroup()
        if uids and #uids >= 5 then
            executeFuseBatch(uids, groupInfo)
        end

        local interval = (Options and Options.FuseInterval and Options.FuseInterval.Value) or 8
        task.wait(interval)
    end
end

--====================================================
-- AUTO CLAIM REWARDS ENGINE (INDEX & GROUP REWARDS)
--====================================================
local autoClaimIndexThread = nil
local function runAutoClaimIndexEngine()
    while isAutoClaimIndex do
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local claimRemote = network and network:FindFirstChild("Index: RequestClaimAll")
            if claimRemote and claimRemote:IsA("RemoteFunction") then
                claimRemote:InvokeServer()
            end
        end)
        task.wait(6.0)
    end
end

local autoClaimGroupThread = nil
local function runAutoClaimGroupEngine()
    while isAutoClaimGroup do
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local claimRemote = network and network:FindFirstChild("GroupReward: ClaimReward")
            if claimRemote and claimRemote:IsA("RemoteFunction") then
                claimRemote:InvokeServer(true)
            end
        end)
        task.wait(15.0)
    end
end

local autoClaimOfflineThread = nil
local function runAutoClaimOfflineEngine()
    while isAutoClaimOffline do
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local claimRemote = network and (network:FindFirstChild("OfflineAssets: RequestClaim") or network:FindFirstChild("Backpack: ClaimOffline") or network:FindFirstChild("Backpack: RequestClaimOffline") or network:FindFirstChild("Offline: RequestClaim"))
            if claimRemote and claimRemote:IsA("RemoteFunction") then
                claimRemote:InvokeServer()
            end
        end)
        task.wait(10.0)
    end
end

--====================================================
-- AUTO TRAILS & GEARS ENGINE
--====================================================
local autoBuyTrailThread = nil
local function runAutoBuyTrailEngine()
    while isAutoBuyTrail do
        pcall(function()
            local trailWanted = Options and Options.TrailWantedDropdown and Options.TrailWantedDropdown.Value
            if trailWanted then
                local network = ReplicatedStorage:FindFirstChild("Network")
                local buyRemote = network and network:FindFirstChild("Trail: RequestBuy")
                if buyRemote and buyRemote:IsA("RemoteFunction") then
                    buyRemote:InvokeServer(trailWanted)
                end
            end
        end)
        task.wait(3.0)
    end
end

local autoEquipBestTrailThread = nil
local function runAutoEquipBestTrailEngine()
    while isAutoEquipBestTrail do
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local equipRemote = network and network:FindFirstChild("Backpack: EquipBestTrail")
            if equipRemote and equipRemote:IsA("RemoteFunction") then
                equipRemote:InvokeServer()
            end
        end)
        task.wait(5.0)
    end
end

local autoEquipBestGearThread = nil
local function runAutoEquipBestGearEngine()
    while isAutoEquipBestGear do
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local equipRemote = network and network:FindFirstChild("Backpack: EquipBestGear")
            if equipRemote and equipRemote:IsA("RemoteFunction") then
                equipRemote:InvokeServer()
            end
        end)
        task.wait(5.0)
    end
end

--====================================================
-- MOVEMENT & EXPLOITS ENGINE (FLY, NOCLIP, INF JUMP)
--====================================================
local UserInputService = game:GetService("UserInputService")
local infJumpConn = nil
local noclipConn = nil
local flyConn = nil
local flyBV = nil
local flyBG = nil

infJumpConn = UserInputService.JumpRequest:Connect(function()
    if isInfJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

noclipConn = RunService.Stepped:Connect(function()
    if isNoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

local function updateFlyState()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end

    if not isFlyEnabled then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "__FlyBV"
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "__FlyBG"
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root

    flyConn = RunService.RenderStepped:Connect(function()
        if not isFlyEnabled or not root or not root.Parent then
            if flyBV then flyBV:Destroy(); flyBV = nil end
            if flyBG then flyBG:Destroy(); flyBG = nil end
            if flyConn then flyConn:Disconnect(); flyConn = nil end
            return
        end

        local speed = (Options and Options.FlySpeed and Options.FlySpeed.Value) or 50
        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            flyBV.Velocity = moveDir.Unit * speed
        else
            flyBV.Velocity = Vector3.zero
        end
        flyBG.CFrame = cam.CFrame
    end)
end

--====================================================
-- VISUALS & ESP ENGINE
--====================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "__Ouroboros_ESP"
pcall(function()
    espFolder.Parent = game:GetService("CoreGui")
end)
if not espFolder.Parent then
    espFolder.Parent = Workspace
end

local activePlayerEsp = {}
local activePlotEsp = {}
local activeEggEsp = {}

local function clearEspCategory(tbl)
    for k, v in pairs(tbl) do
        if typeof(v) == "Instance" then
            pcall(function() v:Destroy() end)
        end
        tbl[k] = nil
    end
end

local function updatePlayerEsp()
    if not isPlayerEspEnabled then
        clearEspCategory(activePlayerEsp)
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or Vector3.zero

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if root and head then
                local dist = math.floor((myPos - root.Position).Magnitude)
                local bb = activePlayerEsp[player]

                if not bb or not bb.Parent then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "ESP_" .. player.Name
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 150, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 2.5, 0)
                    bb.Adornee = head
                    bb.Parent = espFolder

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Label"
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 12
                    lbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.Parent = bb

                    activePlayerEsp[player] = bb
                end

                local label = bb:FindFirstChild("Label")
                if label then
                    label.Text = string.format("%s\n[%d studs]", player.DisplayName or player.Name, dist)
                end
            else
                if activePlayerEsp[player] then
                    pcall(function() activePlayerEsp[player]:Destroy() end)
                    activePlayerEsp[player] = nil
                end
            end
        end
    end
end

local function updatePlotEsp()
    if not isPlotEspEnabled then
        clearEspCategory(activePlotEsp)
        return
    end

    local plots = Workspace:FindFirstChild("Plots") or (Workspace:FindFirstChild("__OBJECTS") and Workspace.__OBJECTS:FindFirstChild("Plots"))
    if not plots then return end

    for _, plot in ipairs(plots:GetChildren()) do
        local slotNum = tonumber(plot.Name:match("%d+"))
        if slotNum then
            local ownerName = "Unclaimed"
            if PlotCmds and PlotCmds.GetSlotOwner then
                local ownerId = PlotCmds.GetSlotOwner(slotNum)
                if ownerId then
                    local p = Players:GetPlayerByUserId(ownerId)
                    ownerName = p and (p.DisplayName or p.Name) or ("User " .. tostring(ownerId))
                end
            end

            local bb = activePlotEsp[plot]
            local targetPart = plot:FindFirstChild("PlotSign") or plot:FindFirstChild("SpawnPoint") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")

            if targetPart then
                if not bb or not bb.Parent then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "PlotESP_" .. tostring(slotNum)
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 140, 0, 35)
                    bb.StudsOffset = Vector3.new(0, 4, 0)
                    bb.Adornee = targetPart
                    bb.Parent = espFolder

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Label"
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 11
                    lbl.TextColor3 = Color3.fromRGB(120, 220, 255)
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.Parent = bb

                    activePlotEsp[plot] = bb
                end

                local label = bb:FindFirstChild("Label")
                if label then
                    label.Text = string.format("Plot #%d\n%s", slotNum, ownerName)
                end
            end
        end
    end
end

local function updateEggEsp()
    if not isEggEspEnabled then
        clearEspCategory(activeEggEsp)
        return
    end

    local areaEggs = getFilteredAreaEggSlots("All")
    for _, eggSlot in ipairs(areaEggs) do
        local key = eggSlot.ModelName or tostring(eggSlot.Position)
        local bb = activeEggEsp[key]

        if not bb or not bb.Parent then
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            part.Size = Vector3.new(1, 1, 1)
            part.Position = eggSlot.Position
            part.Parent = espFolder

            local bGui = Instance.new("BillboardGui")
            bGui.Name = "EggESP"
            bGui.AlwaysOnTop = true
            bGui.Size = UDim2.new(0, 160, 0, 35)
            bGui.StudsOffset = Vector3.new(0, 2, 0)
            bGui.Adornee = part
            bGui.Parent = part

            local lbl = Instance.new("TextLabel")
            lbl.Name = "Label"
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.Parent = bGui

            activeEggEsp[key] = part
        end

        local billboard = activeEggEsp[key] and activeEggEsp[key]:FindFirstChildWhichIsA("BillboardGui")
        local label = billboard and billboard:FindFirstChild("Label")
        if label then
            label.Text = string.format("[%s] %s (%.1fx)", eggSlot.RarityName, eggSlot.DisplayName, eggSlot.AssetScale or 1)
        end
    end
end

local function runEspLoop()
    while true do
        if isPlayerEspEnabled then pcall(updatePlayerEsp) end
        if isPlotEspEnabled then pcall(updatePlotEsp) end
        if isEggEspEnabled then pcall(updateEggEsp) end
        task.wait(1.0)
    end
end
task.spawn(runEspLoop)

--====================================================
-- AUTO UPGRADES ENGINE (BASE & TREADMILL)
--====================================================
local function parseCashInput(str)
    if not str or typeof(str) ~= "string" then return 0 end
    local raw = str:gsub(",", ""):gsub("%s+", ""):upper()
    local mult = 1
    if raw:find("Q") then mult = 1e15; raw = raw:gsub("Q", "")
    elseif raw:find("T") then mult = 1e12; raw = raw:gsub("T", "")
    elseif raw:find("B") then mult = 1e9; raw = raw:gsub("B", "")
    elseif raw:find("M") then mult = 1e6; raw = raw:gsub("M", "")
    elseif raw:find("K") then mult = 1e3; raw = raw:gsub("K", "")
    end
    return (tonumber(raw) or 0) * mult
end

local SortedTreadmills = {
    { Level = 1, Name = "Treadmill", Price = 0 },
    { Level = 2, Name = "Sci-FiTreadmill", Price = 15000 },
    { Level = 3, Name = "FlameTreadmill", Price = 250000 },
    { Level = 4, Name = "CelebrityTreadmill", Price = 5000000 },
    { Level = 5, Name = "GoldenTreadmill", Price = 120000000 },
    { Level = 6, Name = "The FreezeTreadmill", Price = 3000000000 },
    { Level = 7, Name = "Lucky BlockTreadmill", Price = 75000000000 },
    { Level = 8, Name = "HackerTreadmill", Price = 2000000000000 },
    { Level = 9, Name = "DemonicTreadmill", Price = 50000000000000 },
    { Level = 10, Name = "AngelicTreadmill", Price = 1e15 },
}

local BaseUpgradeCosts = {
    [1] = 1000,
    [2] = 1000000,
    [3] = 75000000,
    [4] = 500000000,
    [5] = 1000000000,
    [6] = 50000000000,
    [7] = 500000000000,
    [8] = 1000000000000,
    [9] = 25000000000000,
    [10] = 1e14,
    [11] = 5e14,
}

local autoUpgradeThread = nil
local function runAutoUpgradeEngine()
    while isAutoBaseUpgrade or isAutoTreadmillUpgrade do
        local save = Save and Save.Get and Save.Get()
        local currentMoney = save and save.Money or 0
        local reserve = cashReserveAmount or 0
        local spendableMoney = currentMoney - reserve

        -- 1. Auto Base Upgrade
        if isAutoBaseUpgrade and spendableMoney > 0 then
            local currentBaseLvl = save and save.BaseUpgradeLevel or 0
            local nextBaseLvl = currentBaseLvl + 1
            local nextBaseCost = BaseUpgradeCosts[nextBaseLvl]

            if nextBaseCost and spendableMoney >= nextBaseCost then
                pcall(function()
                    local network = ReplicatedStorage:FindFirstChild("Network")
                    local baseUpgradeRemote = network and network:FindFirstChild("Plots: RequestBaseUpgrade")
                    if baseUpgradeRemote and baseUpgradeRemote:IsA("RemoteEvent") then
                        baseUpgradeRemote:FireServer()
                    end
                end)
                task.wait(0.2)
            end
        end

        -- 2. Auto Treadmill Upgrade
        if isAutoTreadmillUpgrade and spendableMoney > 0 then
            local currentTmLvl = save and save.TreadmillUpgradeLevel or 1
            local nextTmLvl = currentTmLvl + 1
            local nextTm = SortedTreadmills[nextTmLvl]

            if nextTm and spendableMoney >= nextTm.Price then
                pcall(function()
                    local network = ReplicatedStorage:FindFirstChild("Network")
                    local tmUpgradeRemote = network and network:FindFirstChild("Treadmills: RequestUpgrade")
                    if tmUpgradeRemote and tmUpgradeRemote:IsA("RemoteFunction") then
                        tmUpgradeRemote:InvokeServer(nextTm.Name)
                    end
                end)
                task.wait(0.2)
            end
        end

        task.wait(2.0)
    end
end

local autoEquipBestThread = nil
local function runAutoEquipBestEngine()
    while isAutoEquipBestPet do
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local equipRemote = network and network:FindFirstChild("Backpack: EquipBest")
            if equipRemote and equipRemote:IsA("RemoteFunction") then
                equipRemote:InvokeServer()
            end
        end)
        task.wait(5.0)
    end
end

--====================================================
-- AUTOMATION ROTATION / PRIORITY ENGINE
--====================================================
local RotationStatusLabel = nil
local RotationPriorityLabel = nil
local rotationThread = nil

local function updateRotationUI(activeTaskName, remainingSeconds)
    if not RotationStatusLabel or not RotationPriorityLabel then return end
    
    local selMap = Options and Options.AutomationPriorityDropdown and Options.AutomationPriorityDropdown.Value or {}
    local allTasks = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill", "Auto Sell" }
    local enabledTasks = {}
    for _, tName in ipairs(allTasks) do
        if selMap[tName] == true then
            table.insert(enabledTasks, tName)
        end
    end

    if #enabledTasks == 0 then
        RotationStatusLabel:SetText("<font color=\"#FF7F7F\">Status:</font> <font color=\"#888888\">Idle - no ready work</font>")
        RotationPriorityLabel:SetText("<font color=\"#FF7F7F\">Priority:</font>\n<font color=\"#666666\">No tasks selected</font>")
        return
    end

    if not isRotationEnabled then
        RotationStatusLabel:SetText("<font color=\"#FF7F7F\">Status:</font> <font color=\"#888888\">Idle - no ready work</font>")
        local priorityText = "<font color=\"#FF7F7F\">Priority:</font>\n"
        for i, tName in ipairs(enabledTasks) do
            priorityText = priorityText .. string.format("<font color=\"#888888\">%d. %s</font>\n", i, tName)
        end
        RotationPriorityLabel:SetText(priorityText:sub(1, -2))
        return
    end

    if activeTaskName then
        RotationStatusLabel:SetText(string.format("<font color=\"#FF7F7F\">Status:</font> <font color=\"#00FF7F\">%s - active</font>", activeTaskName))
    else
        RotationStatusLabel:SetText("<font color=\"#FF7F7F\">Status:</font> <font color=\"#00FF7F\">Idle</font>")
    end

    local priorityText = "<font color=\"#FF7F7F\">Priority:</font>\n"
    for i, tName in ipairs(enabledTasks) do
        if tName == activeTaskName then
            priorityText = priorityText .. string.format("<font color=\"#00FF7F\">%d. %s [%ds]</font>\n", i, tName, remainingSeconds or 0)
        else
            priorityText = priorityText .. string.format("<font color=\"#888888\">%d. %s</font>\n", i, tName)
        end
    end
    RotationPriorityLabel:SetText(priorityText:sub(1, -2))
end

local function runRotationEngine()
    while isRotationEnabled do
        local selMap = Options and Options.AutomationPriorityDropdown and Options.AutomationPriorityDropdown.Value or {}
        local allTasks = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill", "Auto Sell" }
        local enabledTasks = {}
        for _, tName in ipairs(allTasks) do
            if selMap[tName] == true then
                table.insert(enabledTasks, tName)
            end
        end

        if #enabledTasks == 0 then
            updateRotationUI(nil, 0)
            task.wait(1.0)
        else
            local switchCd = (Options and Options.RotationSwitchCD and Options.RotationSwitchCD.Value) or 30
            
            for _, taskName in ipairs(enabledTasks) do
                if not isRotationEnabled then break end
                if selMap[taskName] ~= true then continue end

                local taskStartTime = os.clock()
                local lastActionTime = 0
                local plotFullFlag = false
                
                if taskName == "Auto Treadmill" then
                    task.spawn(triggerTreadmillSession)
                end

                while isRotationEnabled and (os.clock() - taskStartTime) < switchCd do
                    if selMap[taskName] ~= true then break end

                    local elapsed = os.clock() - taskStartTime
                    local timeLeft = math.max(0, math.ceil(switchCd - elapsed))
                    updateRotationUI(taskName, timeLeft)

                    local now = os.clock()
                    if (now - lastActionTime) >= 0.8 then
                        lastActionTime = now

                        if taskName == "Auto Steal Egg" then
                            if not isStealingInProgress and not isPlacingInProgress then
                                local mode = (Toggles and Toggles.AutoStealSelected and Toggles.AutoStealSelected.Value) and "Selected" or "All"
                                local slots = getFilteredAreaEggSlots(mode)
                                if #slots > 0 then
                                    task.spawn(executeStealSlot, slots[1])
                                end
                            end
                        elseif taskName == "Auto Place Egg" then
                            if not isStealingInProgress and not isPlacingInProgress then
                                task.spawn(processAutoPlaceBatch)
                            end
                        elseif taskName == "Auto Hatch" then
                            task.spawn(processHatchReadyEggs)
                        elseif taskName == "Auto Sell" then
                            local mode = (Toggles and Toggles.AutoSellSelected and Toggles.AutoSellSelected.Value) and "Selected" or "All"
                            local uids = getSellableInventoryItems(mode)
                            if #uids > 0 then
                                task.spawn(sellAssetUids, uids)
                            end
                        end
                    end

                    task.wait(0.2)
                end

                if taskName == "Auto Treadmill" then
                    task.spawn(unequipTreadmillWithoutTeleport)
                end
            end
        end
    end

    updateRotationUI(nil, 0)
end

--====================================================
-- SERVER HOP ENGINE (ADVANCED CONDITIONS)
--====================================================
local function serverHop(reason)
    Library:Notify(string.format("%s. Server hopping...", reason or "Server hopping"), 3)
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    
    local success, result = pcall(function()
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(placeId))
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                return
            end
        end
    end
    
    TeleportService:Teleport(placeId, LocalPlayer)
end

local function checkAdvancedServerHop()
    if not isServerHopEnabled then return end
    local hopWhen = (Options and Options.HopWhenDropdown and Options.HopWhenDropdown.Value) or "No Matching Eggs"
    local threshold = (Options and Options.HopThreshold and Options.HopThreshold.Value) or 30

    if hopWhen == "No Matching Eggs" then
        if (os.clock() - lastMatchingEggTime) >= threshold then
            serverHop("No matching eggs found for " .. tostring(threshold) .. "s")
        end
    elseif hopWhen == "Timed Interval" then
        local thresholdSecs = threshold * 60
        if (os.clock() - sessionStartTime) >= thresholdSecs then
            serverHop("Timed interval of " .. tostring(threshold) .. "m reached")
        end
    elseif hopWhen == "After Steal Count" then
        if sessionStealCount >= threshold then
            serverHop("Steal quota of " .. tostring(threshold) .. " eggs reached")
        end
    end
end

--====================================================
-- UI TABS
--====================================================
local Tabs = {
    Main = Window:AddTab("Main", "home"),
    Automation = Window:AddTab("Automation", "cpu"),
    Prediction = Window:AddTab("Prediction", "cloud-lightning"),
    Misc = Window:AddTab("Misc", "settings"),
}

--====================================================
-- MAIN TAB: STEAL EGGS (with 'egg' icon)
--====================================================
do
    local MainTab = Tabs.Main
    local StealGroup = MainTab:AddLeftGroupbox("Steal Eggs", "egg")

StealGroup:AddDropdown("AreaDropdown", {
    Values = AreasList,
    Default = {},
    Multi = true,
    Text = "Areas",
    Searchable = true,
    Tooltip = "Select target areas. Leaving empty (---) matches all areas.",
})

StealGroup:AddDropdown("CategoryDropdown", {
    Values = CategoriesList,
    Default = {},
    Multi = true,
    Text = "Categories",
    Searchable = true,
    Tooltip = "Select pet categories. Leaving empty (---) matches all pets.",
})

StealGroup:AddDropdown("RarityDropdown", {
    Values = RaritiesList,
    Default = {},
    Multi = true,
    Text = "Rarities",
    Searchable = true,
    Tooltip = "Select rarities. Leaving empty (---) matches all rarities.",
})

StealGroup:AddDropdown("MutationDropdown", {
    Values = MutationsList,
    Default = {},
    Multi = true,
    Text = "Mutations",
    Searchable = true,
    Tooltip = "Select mutations. Leaving empty (---) matches all mutations.",
})

StealGroup:AddDropdown("PriorityDropdown", {
    Values = { "Rarest", "Highest Earnings", "Nearest", "Un-Indexed" },
    Default = 1,
    Multi = false,
    Text = "Target Priority",
    Tooltip = "Choose how eggs are ranked and prioritized",
})

StealGroup:AddToggle("AutoStealSelected", {
    Text = "Auto Steal Selected",
    Default = false,
    Tooltip = "Steals only eggs matching the selected dropdown filters",
})

StealGroup:AddToggle("AutoStealAll", {
    Text = "Auto Steal All",
    Default = false,
    Tooltip = "Steals all area eggs ordered by Target Priority",
})

StealGroup:AddToggle("StealBigEggs", {
    Text = "Steal Big Eggs",
    Default = false,
    Tooltip = "Only steals eggs that exceed the minimum size multiplier",
})

StealGroup:AddSlider("BigEggMinSize", {
    Text = "Big Egg Minimum Size",
    Default = 1.5,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Compact = true,
    compact = true,
})

StealGroup:AddToggle("AutoDropHeldEgg", {
    Text = "Auto Drop Held Egg",
    Default = false,
    Tooltip = "Automatically drops any currently carried egg",
})

StealGroup:AddSlider("TweenSpeed", {
    Text = "Tween Speed",
    Default = 150,
    Min = 30,
    Max = 500,
    Rounding = 0,
    Compact = true,
    compact = true,
    Tooltip = "Movement speed in studs per second (30 - 500)",
})

StealGroup:AddToggle("ServerHopMatching", {
    Text = "Enable Server Hop",
    Default = false,
    Tooltip = "Automatically hops to another server based on chosen condition",
})

StealGroup:AddDropdown("HopWhenDropdown", {
    Values = { "No Matching Eggs", "Timed Interval", "After Steal Count" },
    Default = 1,
    Multi = false,
    Text = "Hop When",
    Tooltip = "Condition that triggers server hopping",
})

StealGroup:AddSlider("HopThreshold", {
    Text = "Hop Threshold",
    Default = 30,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Compact = true,
    compact = true,
    Tooltip = "Seconds for No Matching Eggs, Minutes for Timed Interval, or Steal Count threshold",
})

StealGroup:AddButton({
    Text = "Steal Single Best Egg",
    Func = function()
        local mode = Toggles.AutoStealSelected.Value and "Selected" or "All"
        local slots = getFilteredAreaEggSlots(mode)
        if #slots > 0 then
            local best = slots[1]
            Library:Notify(string.format("Stealing [%s | %.2fx Size | %s]", best.DisplayName, best.AssetScale or 1, best.RarityName), 2.5)
            executeStealSlot(best)
        else
            Library:Notify("No matching area eggs found!", 2)
        end
    end,
    DoubleClick = false,
})

StealGroup:AddButton({
    Text = "Teleport to Safezone",
    Func = function()
        local char = LocalPlayer.Character
        local z = (char and char:FindFirstChild("HumanoidRootPart")) and char.HumanoidRootPart.Position.Z or 0
        teleportCharacter(Vector3.new(SAFEZONE_X, SAFEZONE_Y, z))
        Library:Notify("Teleported to Safezone!", 2)
    end,
    DoubleClick = false,
})

--====================================================
-- MAIN TAB: DEFENSE & GEARS (SUB GROUPBOX TABBOX)
--====================================================
local DefenseGroup = MainTab:AddRightGroupbox("Defense & Gears")

if DefenseGroup.Holder then
    DefenseGroup.Holder.BackgroundTransparency = 1
    for _, obj in ipairs(DefenseGroup.Holder:GetChildren()) do
        if obj:IsA("TextLabel") or obj:IsA("ImageButton") or obj:IsA("ImageLabel") or obj:IsA("UIStroke") then
            pcall(function() obj.Visible = false end)
        elseif obj:IsA("Frame") and obj ~= DefenseGroup.Container then
            pcall(function() obj.Visible = false end)
        end
    end
    if DefenseGroup.Container then
        DefenseGroup.Container.Position = UDim2.fromOffset(0, 0)
        DefenseGroup.Container.Size = UDim2.fromScale(1, 1)
        local pad = DefenseGroup.Container:FindFirstChildWhichIsA("UIPadding")
        if pad then
            pad.PaddingTop = UDim.new(0, 0)
            pad.PaddingBottom = UDim.new(0, 0)
            pad.PaddingLeft = UDim.new(0, 0)
            pad.PaddingRight = UDim.new(0, 0)
        end
    end
end

local DefenseTabbox = DefenseGroup:AddTabbox()

function DefenseGroup:Resize()
    if DefenseTabbox and DefenseTabbox.BoxHolder and DefenseGroup.Holder then
        local h = DefenseTabbox.BoxHolder.Size.Y.Offset
        if not h or h <= 0 then
            h = DefenseTabbox.BoxHolder.AbsoluteSize.Y
        end
        if h and h > 0 then
            DefenseGroup.Holder.Size = UDim2.new(1, 0, 0, h)
        end
    end
end

if DefenseTabbox and DefenseTabbox.BoxHolder then
    DefenseTabbox.BoxHolder:GetPropertyChangedSignal("Size"):Connect(function()
        DefenseGroup:Resize()
    end)
end

local DefenseTab = DefenseTabbox:AddTab("Defense", "shield")
local GearsTab = DefenseTabbox:AddTab("Trails & Gears", "shopping-bag")

-- 1. DEFENSE TAB
DefenseTab:AddToggle("AntiHit", {
    Text = "Anti-Hit",
    Default = false,
    Tooltip = "Blocks guard hit remotes & collision damage without lag",
})

DefenseTab:AddToggle("KillAuraToggle", {
    Text = "Bat Kill Aura",
    Default = false,
    Tooltip = "Automatically attacks nearby players within range using Bat",
})

DefenseTab:AddSlider("AuraRange", {
    Text = "Aura Range",
    Default = 9.5,
    Min = 3,
    Max = 10,
    Rounding = 1,
    Compact = true,
    compact = true,
})

DefenseTab:AddSlider("AttackInterval", {
    Text = "Attack Delay",
    Default = 0.1,
    Min = 0.05,
    Max = 1.0,
    Rounding = 2,
    Compact = true,
    compact = true,
})

DefenseTab:AddToggle("AutoEquipBat", {
    Text = "Auto Equip Bat",
    Default = false,
    Tooltip = "Automatically equips Bat from backpack when attacking",
})

-- 2. TRAILS & GEARS TAB
GearsTab:AddToggle("AutoBuyTrail", {
    Text = "Auto Buy Trail",
    Default = false,
    Tooltip = "Automatically purchases selected trail when cash is available",
})

GearsTab:AddDropdown("TrailWantedDropdown", {
    Values = TrailsList,
    Default = 1,
    Multi = false,
    Text = "Trail Wanted",
    Searchable = true,
    Tooltip = "Select which trail to automatically purchase",
})

GearsTab:AddToggle("AutoEquipBestTrail", {
    Text = "Auto Equip Best Trail",
    Default = false,
    Tooltip = "Automatically equips highest tier trail in your backpack",
})

GearsTab:AddToggle("AutoEquipBestGear", {
    Text = "Auto Equip Best Gear",
    Default = false,
    Tooltip = "Automatically equips highest tier weapon & utility gear",
})

--====================================================
-- MAIN TAB: UPGRADES (with 'trending-up' icon)
--====================================================
local UpgradesGroup = MainTab:AddRightGroupbox("Upgrades", "trending-up")

UpgradesGroup:AddToggle("AutoEquipBestPet", {
    Text = "Auto Equip Best Pet",
    Default = false,
    Tooltip = "Automatically equips the strongest pets in your backpack continuously",
})

UpgradesGroup:AddToggle("AutoGainSpeed", {
    Text = "Auto Treadmill Training",
    Default = false,
    Tooltip = "Gains treadmill speed continuously and auto-pauses during egg steals",
})

UpgradesGroup:AddToggle("AutoTreadmillUpgrade", {
    Text = "Auto Treadmill Upgrade",
    Default = false,
    Tooltip = "Automatically purchases the next treadmill upgrade tier when cash allows",
})

UpgradesGroup:AddToggle("AutoBaseUpgrade", {
    Text = "Auto Base Upgrade",
    Default = false,
    Tooltip = "Automatically purchases the next base/plot upgrade when cash allows",
})

UpgradesGroup:AddInput("CashReserveInput", {
    Default = "0",
    Numeric = false,
    Finished = false,
    Text = "Cash Reserve",
    Placeholder = "0 (e.g. 100k, 1M, 50B)",
    Tooltip = "Minimum money balance to keep in reserve before buying upgrades",
})

Toggles.AutoEquipBestPet:OnChanged(function()
    isAutoEquipBestPet = Toggles.AutoEquipBestPet.Value
    if isAutoEquipBestPet then
        pcall(function()
            local network = ReplicatedStorage:FindFirstChild("Network")
            local equipRemote = network and network:FindFirstChild("Backpack: EquipBest")
            if equipRemote and equipRemote:IsA("RemoteFunction") then
                equipRemote:InvokeServer()
            end
        end)
        if not autoEquipBestThread or coroutine.status(autoEquipBestThread) == "dead" then
            autoEquipBestThread = task.spawn(runAutoEquipBestEngine)
        end
    end
end)

Toggles.AutoGainSpeed:OnChanged(function()
    isAutoGainSpeedEnabled = Toggles.AutoGainSpeed.Value
    if isAutoGainSpeedEnabled then
        task.spawn(triggerTreadmillSession)
    else
        task.spawn(unequipTreadmillWithoutTeleport)
    end
end)

Toggles.AutoTreadmillUpgrade:OnChanged(function()
    isAutoTreadmillUpgrade = Toggles.AutoTreadmillUpgrade.Value
    if isAutoTreadmillUpgrade then
        if not autoUpgradeThread or coroutine.status(autoUpgradeThread) == "dead" then
            autoUpgradeThread = task.spawn(runAutoUpgradeEngine)
        end
    end
end)

Toggles.AutoBaseUpgrade:OnChanged(function()
    isAutoBaseUpgrade = Toggles.AutoBaseUpgrade.Value
    if isAutoBaseUpgrade then
        if not autoUpgradeThread or coroutine.status(autoUpgradeThread) == "dead" then
            autoUpgradeThread = task.spawn(runAutoUpgradeEngine)
        end
    end
end)

Options.CashReserveInput:OnChanged(function()
    local val = Options.CashReserveInput.Value
    cashReserveAmount = parseCashInput(val)
end)

-- Wire Defense & Gears Listeners
Toggles.AntiHit:OnChanged(function()
    isAntiHitEnabled = Toggles.AntiHit.Value
end)

Toggles.KillAuraToggle:OnChanged(function()
    isKillAuraEnabled = Toggles.KillAuraToggle.Value
    if isKillAuraEnabled then
        if not killAuraThread or coroutine.status(killAuraThread) == "dead" then
            killAuraThread = task.spawn(runKillAuraEngine)
        end
    end
end)

Toggles.AutoBuyTrail:OnChanged(function()
    isAutoBuyTrail = Toggles.AutoBuyTrail.Value
    if isAutoBuyTrail then
        if not autoBuyTrailThread or coroutine.status(autoBuyTrailThread) == "dead" then
            autoBuyTrailThread = task.spawn(runAutoBuyTrailEngine)
        end
    end
end)

Toggles.AutoEquipBestTrail:OnChanged(function()
    isAutoEquipBestTrail = Toggles.AutoEquipBestTrail.Value
    if isAutoEquipBestTrail then
        if not autoEquipBestTrailThread or coroutine.status(autoEquipBestTrailThread) == "dead" then
            autoEquipBestTrailThread = task.spawn(runAutoEquipBestTrailEngine)
        end
    end
end)

Toggles.AutoEquipBestGear:OnChanged(function()
    isAutoEquipBestGear = Toggles.AutoEquipBestGear.Value
    if isAutoEquipBestGear then
        if not autoEquipBestGearThread or coroutine.status(autoEquipBestGearThread) == "dead" then
            autoEquipBestGearThread = task.spawn(runAutoEquipBestGearEngine)
        end
    end
end)

-- Wire Character Listeners
if LocalPlayer.Character then
    task.spawn(handleCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(handleCharacter, char)
    task.delay(0.2, neutralizeIntegrity)
    if isAutoGainSpeedEnabled then
        task.delay(0.5, triggerTreadmillSession)
    end
end)

--====================================================
-- 9. AUTO-STEAL LOOPS (ALL & SELECTED)
--====================================================
local autoStealThread = nil

local function runAutoStealEngine()
    while isAutoStealing or isAutoStealSelected or isStealBigEggs do
        local mode = isAutoStealSelected and "Selected" or "All"
        local slots = getFilteredAreaEggSlots(mode)
        
        if #slots > 0 then
            for _, slot in ipairs(slots) do
                if not isAutoStealing and not isAutoStealSelected and not isStealBigEggs then
                    break
                end
                executeStealSlot(slot)
                if isServerHopEnabled then
                    checkAdvancedServerHop()
                end
            end
        else
            if isServerHopEnabled then
                checkAdvancedServerHop()
            end
            task.wait(0.5)
        end
        task.wait(0.05)
    end
end

Toggles.AutoStealAll:OnChanged(function()
    isAutoStealing = Toggles.AutoStealAll.Value
    if isAutoStealing then
        if Toggles.AutoStealSelected.Value then
            Toggles.AutoStealSelected:SetValue(false)
        end
        if not autoStealThread or coroutine.status(autoStealThread) == "dead" then
            autoStealThread = task.spawn(runAutoStealEngine)
        end
    end
end)

Toggles.AutoStealSelected:OnChanged(function()
    isAutoStealSelected = Toggles.AutoStealSelected.Value
    if isAutoStealSelected then
        if Toggles.AutoStealAll.Value then
            Toggles.AutoStealAll:SetValue(false)
        end
        if not autoStealThread or coroutine.status(autoStealThread) == "dead" then
            autoStealThread = task.spawn(runAutoStealEngine)
        end
    end
end)

Toggles.ServerHopMatching:OnChanged(function()
    isServerHopEnabled = Toggles.ServerHopMatching.Value
end)

Toggles.StealBigEggs:OnChanged(function()
    isStealBigEggs = Toggles.StealBigEggs.Value
    if isStealBigEggs then
        if not autoStealThread or coroutine.status(autoStealThread) == "dead" then
            autoStealThread = task.spawn(runAutoStealEngine)
        end
    end
end)

Toggles.AutoDropHeldEgg:OnChanged(function()
    isAutoDropHeldEgg = Toggles.AutoDropHeldEgg.Value
    if isAutoDropHeldEgg then
        dropHeldEgg()
    end
end)
end -- end MainTab block

--====================================================
-- AUTOMATION TAB: ROTATION (with 'repeat' icon)
--====================================================
do
    local AutomationTab = Tabs.Automation
    local RotationGroup = AutomationTab:AddLeftGroupbox("Rotation", "repeat")

RotationGroup:AddToggle("EnableRotation", {
    Text = "Enable Rotation",
    Default = false,
    Tooltip = "Sequentially executes selected automation tasks on an active timer cycle",
})

RotationGroup:AddDropdown("AutomationPriorityDropdown", {
    Values = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill", "Auto Sell" },
    Default = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill", "Auto Sell" },
    Multi = true,
    Text = "Automation Priority",
    Searchable = true,
    Tooltip = "Select which automated tasks are included in the rotation cycle",
})

if Options and Options.AutomationPriorityDropdown then
    Options.AutomationPriorityDropdown:SetValue({
        ["Auto Steal Egg"] = true,
        ["Auto Place Egg"] = true,
        ["Auto Hatch"] = true,
        ["Auto Treadmill"] = true,
        ["Auto Sell"] = true,
    })
end

RotationGroup:AddSlider("RotationSwitchCD", {
    Text = "Rotation Switch CD",
    Default = 30,
    Min = 5,
    Max = 120,
    Rounding = 0,
    Compact = true,
    compact = true,
})

RotationStatusLabel = RotationGroup:AddLabel("<font color=\"#FF7F7F\">Status:</font> <font color=\"#888888\">Idle - no ready work</font>", true)
RotationPriorityLabel = RotationGroup:AddLabel("<font color=\"#FF7F7F\">Priority:</font>\n<font color=\"#888888\">1. Auto Steal Egg</font>\n<font color=\"#888888\">2. Auto Place Egg</font>\n<font color=\"#888888\">3. Auto Hatch</font>\n<font color=\"#888888\">4. Auto Treadmill</font>\n<font color=\"#888888\">5. Auto Sell</font>", true)

updateRotationUI(nil, 0)

Toggles.EnableRotation:OnChanged(function()
    isRotationEnabled = Toggles.EnableRotation.Value
    if isRotationEnabled then
        if not rotationThread or coroutine.status(rotationThread) == "dead" then
            rotationThread = task.spawn(runRotationEngine)
        end
    else
        updateRotationUI(nil, 0)
    end
end)

Options.AutomationPriorityDropdown:OnChanged(function()
    if not isRotationEnabled then
        updateRotationUI(nil, 0)
    end
end)

--====================================================
-- AUTOMATION TAB: EGG LIFECYCLE (with 'package' icon)
--====================================================
local EggLifecycleGroup = AutomationTab:AddLeftGroupbox("Egg Lifecycle", "package")

EggLifecycleGroup:AddDropdown("AutoPlaceCategoryDropdown", {
    Values = CategoriesList,
    Default = {},
    Multi = true,
    Text = "Categories",
    Searchable = true,
    Tooltip = "Select pet categories to auto place. Leaving empty (---) matches all pets.",
})

EggLifecycleGroup:AddDropdown("AutoPlaceRarityDropdown", {
    Values = RaritiesList,
    Default = {},
    Multi = true,
    Text = "Rarities",
    Searchable = true,
    Tooltip = "Select rarities to auto place. Leaving empty (---) matches all rarities.",
})

EggLifecycleGroup:AddDropdown("AutoPlaceMutationDropdown", {
    Values = MutationsList,
    Default = {},
    Multi = true,
    Text = "Mutations",
    Searchable = true,
    Tooltip = "Select mutations to auto place. Leaving empty (---) matches all mutations.",
})

EggLifecycleGroup:AddToggle("AutoPlaceSelected", {
    Text = "Auto Place Selected",
    Default = false,
    Tooltip = "Automatically equips and places inventory eggs/pets matching dropdown filters onto your plot",
})

EggLifecycleGroup:AddToggle("AutoPlaceAll", {
    Text = "Auto Place All",
    Default = false,
    Tooltip = "Automatically equips and places all inventory eggs/pets onto your plot",
})

EggLifecycleGroup:AddToggle("AutoHatchReady", {
    Text = "Auto Hatch Ready",
    Default = false,
    Tooltip = "Automatically claims and hatches eggs on your plot when ready",
})

Toggles.AutoPlaceSelected:OnChanged(function()
    isAutoPlaceSelected = Toggles.AutoPlaceSelected.Value
    if isAutoPlaceSelected then
        if Toggles.AutoPlaceAll.Value then
            Toggles.AutoPlaceAll:SetValue(false)
        end
        if not autoPlaceThread or coroutine.status(autoPlaceThread) == "dead" then
            autoPlaceThread = task.spawn(runAutoPlaceEngine)
        end
    end
end)

Toggles.AutoPlaceAll:OnChanged(function()
    isAutoPlaceAll = Toggles.AutoPlaceAll.Value
    if isAutoPlaceAll then
        if Toggles.AutoPlaceSelected.Value then
            Toggles.AutoPlaceSelected:SetValue(false)
        end
        if not autoPlaceThread or coroutine.status(autoPlaceThread) == "dead" then
            autoPlaceThread = task.spawn(runAutoPlaceEngine)
        end
    end
end)

Toggles.AutoHatchReady:OnChanged(function()
    isAutoHatchReady = Toggles.AutoHatchReady.Value
    if isAutoHatchReady then
        if not autoHatchThread or coroutine.status(autoHatchThread) == "dead" then
            autoHatchThread = task.spawn(runAutoHatchEngine)
        end
    end
end)

--====================================================
-- AUTOMATION TAB: SELL & AUTO FUSE (SUB GROUPBOX TABBOX)
--====================================================
local SellGroup = AutomationTab:AddRightGroupbox("Sell")

if SellGroup.Holder then
    SellGroup.Holder.BackgroundTransparency = 1
    for _, obj in ipairs(SellGroup.Holder:GetChildren()) do
        if obj:IsA("TextLabel") or obj:IsA("ImageButton") or obj:IsA("ImageLabel") or obj:IsA("UIStroke") then
            pcall(function() obj.Visible = false end)
        elseif obj:IsA("Frame") and obj ~= SellGroup.Container then
            pcall(function() obj.Visible = false end)
        end
    end
    if SellGroup.Container then
        SellGroup.Container.Position = UDim2.fromOffset(0, 0)
        SellGroup.Container.Size = UDim2.fromScale(1, 1)
        local pad = SellGroup.Container:FindFirstChildWhichIsA("UIPadding")
        if pad then
            pad.PaddingTop = UDim.new(0, 0)
            pad.PaddingBottom = UDim.new(0, 0)
            pad.PaddingLeft = UDim.new(0, 0)
            pad.PaddingRight = UDim.new(0, 0)
        end
    end
end

local SellTabbox = SellGroup:AddTabbox()

function SellGroup:Resize()
    if SellTabbox and SellTabbox.BoxHolder and SellGroup.Holder then
        local h = SellTabbox.BoxHolder.Size.Y.Offset
        if not h or h <= 0 then
            h = SellTabbox.BoxHolder.AbsoluteSize.Y
        end
        if h and h > 0 then
            SellGroup.Holder.Size = UDim2.new(1, 0, 0, h)
        end
    end
end

if SellTabbox and SellTabbox.BoxHolder then
    SellTabbox.BoxHolder:GetPropertyChangedSignal("Size"):Connect(function()
        SellGroup:Resize()
    end)
end

local EggsTab = SellTabbox:AddTab("Eggs", "egg")
local PetsTab = SellTabbox:AddTab("Pets", "dog")

-- 1. EGGS / SELL TAB
EggsTab:AddDropdown("SellCategoryDropdown", {
    Values = CategoriesList,
    Default = {},
    Multi = true,
    Text = "Categories",
    Searchable = true,
    Tooltip = "Select pet categories to sell. Leaving empty (---) matches all pets.",
})

EggsTab:AddDropdown("SellRarityDropdown", {
    Values = RaritiesList,
    Default = {},
    Multi = true,
    Text = "Rarities",
    Searchable = true,
    Tooltip = "Select rarities to sell. Leaving empty (---) matches all rarities.",
})

EggsTab:AddDropdown("SellMutationDropdown", {
    Values = MutationsList,
    Default = {},
    Multi = true,
    Text = "Mutations",
    Searchable = true,
    Tooltip = "Select mutations to sell. Leaving empty (---) matches all mutations.",
})

EggsTab:AddToggle("AutoSellSelected", {
    Text = "Auto Sell Selected",
    Default = false,
    Tooltip = "Automatically sells inventory pets matching dropdown filters (excludes favorites & equipped)",
})

EggsTab:AddToggle("AutoSellAllEligible", {
    Text = "Auto Sell All Eligible",
    Default = false,
    Tooltip = "Automatically sells all unequipped and non-favorited inventory pets",
})

EggsTab:AddDropdown("AutoSellRaritiesDropdown", {
    Values = RaritiesList,
    Default = {},
    Multi = true,
    Text = "Auto Sell Rarities",
    Searchable = true,
    Tooltip = "Select rarities to synchronize with the server's in-game auto-sell system",
})

EggsTab:AddToggle("SyncAutoSellRarities", {
    Text = "Sync Auto Sell Rarities",
    Default = false,
    Tooltip = "Synchronizes selected Auto Sell Rarities with the game server",
})

-- 2. PETS / AUTO FUSE TAB
PetsTab:AddToggle("AutoFusePets", {
    Text = "Auto Fuse Pets[Beta]",
    Default = false,
    Tooltip = "Automatically fuses eligible duplicate pets in your inventory",
})

PetsTab:AddDropdown("FuseRaritiesDropdown", {
    Values = RaritiesList,
    Default = {},
    Multi = true,
    Text = "Fuse Rarities",
    Searchable = true,
    Tooltip = "Select rarities to fuse. Leaving empty (---) matches all rarities.",
})

PetsTab:AddDropdown("FuseMutationsDropdown", {
    Values = MutationsList,
    Default = {},
    Multi = true,
    Text = "Fuse Mutations",
    Searchable = true,
    Tooltip = "Select mutations to fuse. Leaving empty (---) matches all mutations.",
})

PetsTab:AddDropdown("PickGroupByDropdown", {
    Values = { "Highest Rarity", "Lowest Rarity", "Most Count", "Least Count" },
    Default = 1,
    Multi = false,
    Text = "Pick Group By",
    Tooltip = "Prioritize which pet group to fuse first",
})

PetsTab:AddToggle("NeverFuseMutated", {
    Text = "Never Fuse Mutated",
    Default = false,
    Tooltip = "Prevents any mutated pets from being used as fusion materials",
})

PetsTab:AddToggle("NeverFuseEquipped", {
    Text = "Never Fuse Equipped",
    Default = false,
    Tooltip = "Prevents currently equipped pets from being fused",
})

PetsTab:AddToggle("AutoCompleteReveal", {
    Text = "Auto Complete Reveal",
    Default = false,
    Tooltip = "Instantly skips and reveals fusion animation",
})

PetsTab:AddSlider("MaxScaleToFuse", {
    Text = "Maximum Scale to Fuse",
    Default = 10,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Compact = true,
    compact = true,
})

PetsTab:AddSlider("KeepPerPetType", {
    Text = "Keep Per Pet Type",
    Default = 0,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Compact = true,
    compact = true,
})

PetsTab:AddSlider("FuseInterval", {
    Text = "Fuse Interval",
    Default = 8,
    Min = 1,
    Max = 120,
    Rounding = 0,
    Suffix = "s",
    Compact = true,
    compact = true,
})

PetsTab:AddButton({
    Text = "Fuse Now",
    Func = function()
        local uids, groupInfo = pickFuseGroup()
        if uids and #uids >= 5 then
            local ok = executeFuseBatch(uids, groupInfo)
            if not ok then
                Library:Notify("Fusion completed or attempted.", 2)
            end
        else
            Library:Notify("No eligible 5 duplicate pets found to fuse.", 3)
        end
    end,
    DoubleClick = false,
})

Toggles.AutoFusePets:OnChanged(function()
    isAutoFusePets = Toggles.AutoFusePets.Value
    if isAutoFusePets then
        if not autoFuseThread or coroutine.status(autoFuseThread) == "dead" then
            autoFuseThread = task.spawn(runAutoFuseEngine)
        end
    end
end)

Toggles.AutoSellSelected:OnChanged(function()
    isAutoSellSelected = Toggles.AutoSellSelected.Value
    if isAutoSellSelected then
        if Toggles.AutoSellAllEligible.Value then
            Toggles.AutoSellAllEligible:SetValue(false)
        end
        if not autoSellThread or coroutine.status(autoSellThread) == "dead" then
            autoSellThread = task.spawn(runAutoSellEngine)
        end
    end
end)

Toggles.AutoSellAllEligible:OnChanged(function()
    isAutoSellAllEligible = Toggles.AutoSellAllEligible.Value
    if isAutoSellAllEligible then
        if Toggles.AutoSellSelected.Value then
            Toggles.AutoSellSelected:SetValue(false)
        end
        if not autoSellThread or coroutine.status(autoSellThread) == "dead" then
            autoSellThread = task.spawn(runAutoSellEngine)
        end
    end
end)

Toggles.SyncAutoSellRarities:OnChanged(function()
    isSyncAutoSellRarities = Toggles.SyncAutoSellRarities.Value
    if isSyncAutoSellRarities then
        local selRarities = Options.AutoSellRaritiesDropdown and Options.AutoSellRaritiesDropdown.Value
        syncAutoSellRaritiesWithServer(selRarities or {})
    else
        syncAutoSellRaritiesWithServer({})
    end
end)

Options.AutoSellRaritiesDropdown:OnChanged(function()
    if Toggles.SyncAutoSellRarities and Toggles.SyncAutoSellRarities.Value then
        syncAutoSellRaritiesWithServer(Options.AutoSellRaritiesDropdown.Value or {})
    end
end)

--====================================================
-- AUTOMATION TAB: REWARDS (with 'gift' icon)
--====================================================
local RewardsGroup = AutomationTab:AddRightGroupbox("Rewards", "gift")

RewardsGroup:AddToggle("AutoClaimIndexRewards", {
    Text = "Auto Claim Index Rewards",
    Default = false,
    Tooltip = "Automatically claims all completed index rewards in the background",
})

RewardsGroup:AddToggle("AutoClaimGroupReward", {
    Text = "Auto Claim Group Reward",
    Default = false,
    Tooltip = "Automatically claims the daily Roblox group reward in the background",
})

RewardsGroup:AddToggle("AutoClaimOfflineEarnings", {
    Text = "Auto Claim Offline Earnings",
    Default = false,
    Tooltip = "Automatically claims accumulated offline earnings in the background",
})

Toggles.AutoClaimIndexRewards:OnChanged(function()
    isAutoClaimIndex = Toggles.AutoClaimIndexRewards.Value
    if isAutoClaimIndex then
        if not autoClaimIndexThread or coroutine.status(autoClaimIndexThread) == "dead" then
            autoClaimIndexThread = task.spawn(runAutoClaimIndexEngine)
        end
    end
end)

Toggles.AutoClaimGroupReward:OnChanged(function()
    isAutoClaimGroup = Toggles.AutoClaimGroupReward.Value
    if isAutoClaimGroup then
        if not autoClaimGroupThread or coroutine.status(autoClaimGroupThread) == "dead" then
            autoClaimGroupThread = task.spawn(runAutoClaimGroupEngine)
        end
    end
end)

Toggles.AutoClaimOfflineEarnings:OnChanged(function()
    isAutoClaimOffline = Toggles.AutoClaimOfflineEarnings.Value
    if isAutoClaimOffline then
        if not autoClaimOfflineThread or coroutine.status(autoClaimOfflineThread) == "dead" then
            autoClaimOfflineThread = task.spawn(runAutoClaimOfflineEngine)
        end
    end
end)

end -- end AutomationTab block

--====================================================
-- PREDICTION TAB: EVENT PREDICTOR & SCHEDULE
--====================================================
do
    local PredictionTab = Tabs.Prediction
    local ActiveStatusLabel = nil
    local ActiveBoostLabel = nil
    local ActiveTimeLeftLabel = nil
    local NextEventNameLabel = nil
    local NextEventCountdownLabel = nil
    local SchedRow1 = nil
    local SchedRow2 = nil
    local SchedRow3 = nil
    local SchedRow4 = nil
    local SchedRow5 = nil
    local lastNotifiedEventKey = nil

    local function formatCountdown(secs)
        if not secs or secs < 0 then return "00s" end
        local h = math.floor(secs / 3600)
        local m = math.floor((secs % 3600) / 60)
        local s = math.floor(secs % 60)
        if h > 0 then
            return string.format("%02dh %02dm", h, m)
        elseif m > 0 then
            return string.format("%02dm %02ds", m, s)
        else
            return string.format("%02ds", s)
        end
    end

    local function getFriendlyEventInfo(weatherId)
        if weatherId == "ThunderstormWeather" then
            return "⚡ Thunderstorm", "Shocked", "10x", "#00FFFF"
        elseif weatherId == "FrostWeather" then
            return "❄️ Frost Weather", "Frozen", "10x", "#80D0FF"
        elseif weatherId == "MagmaWeather" or weatherId == "MoltenWeather" then
            return "🌋 Magma Storm", "Magma", "10x", "#FF6030"
        else
            return weatherId or "Special Event", "None", "1x", "#FFFFFF"
        end
    end

    local function updatePredictionUI()
        if not WeatherSchedule then return end

        local now = workspace:GetServerTimeNow()
        local duration = WeatherSchedule.DEFAULT_DURATION or 180
        local upcoming = nil
        pcall(function()
            upcoming = WeatherSchedule.GetUpcomingWeathers(now, 6)
        end)

        if not upcoming or #upcoming == 0 then return end

        local activeEntry = nil
        local nextUpcoming = {}

        for _, entry in ipairs(upcoming) do
            local startsAt = entry.StartsAt or 0
            local endsAt = startsAt + duration

            if now >= startsAt and now < endsAt then
                activeEntry = entry
            elseif startsAt > now then
                table.insert(nextUpcoming, entry)
            end
        end

        if activeEntry then
            local _, mutName = getFriendlyEventInfo(activeEntry.WeatherId)
            activeEventMutationName = mutName
        else
            activeEventMutationName = nil
        end

        -- 1. Update Active Weather Status Labels
        if activeEntry then
            local name, mut, boost, col = getFriendlyEventInfo(activeEntry.WeatherId)
            local remainingSecs = math.max(0, math.ceil((activeEntry.StartsAt + duration) - now))
            
            if ActiveStatusLabel then ActiveStatusLabel:SetText(string.format("<font color=\"#FF7F7F\">Active Event:</font> <font color=\"%s\"><b>%s</b></font>", col, name)) end
            if ActiveBoostLabel then ActiveBoostLabel:SetText(string.format("<font color=\"#00FF7F\">Active Boost:</font> <font color=\"#FFFFFF\">+%s %s</font>", boost, mut)) end
            if ActiveTimeLeftLabel then ActiveTimeLeftLabel:SetText(string.format("<font color=\"#FFD700\">Time Left:</font> <font color=\"#FFFFFF\"><b>%s</b></font>", formatCountdown(remainingSecs))) end

            -- Notify on event start
            local eventKey = tostring(activeEntry.WeatherId) .. "_" .. tostring(activeEntry.StartsAt)
            if isEventNotifyEnabled and lastNotifiedEventKey ~= eventKey then
                lastNotifiedEventKey = eventKey
                Library:Notify(string.format("Special Event Started: %s (+%s %s)!", name, boost, mut), 6)
            end
        else
            if ActiveStatusLabel then ActiveStatusLabel:SetText("<font color=\"#FF7F7F\">Active Event:</font> <font color=\"#888888\">None (Normal Weather)</font>") end
            if ActiveBoostLabel then ActiveBoostLabel:SetText("<font color=\"#888888\">Boost: None active</font>") end
            if ActiveTimeLeftLabel then ActiveTimeLeftLabel:SetText("<font color=\"#888888\">Time Left: --</font>") end
        end

        -- 2. Update Next Event Countdown Labels
        if #nextUpcoming > 0 then
            local firstNext = nextUpcoming[1]
            local name, mut, boost, col = getFriendlyEventInfo(firstNext.WeatherId)
            local countdownSecs = math.max(0, math.ceil(firstNext.StartsAt - now))

            if NextEventNameLabel then NextEventNameLabel:SetText(string.format("<font color=\"#00FF7F\">Next Event:</font> <font color=\"%s\"><b>%s</b></font>", col, name)) end
            if NextEventCountdownLabel then NextEventCountdownLabel:SetText(string.format("<font color=\"#FFD700\">Starts in:</font> <font color=\"#FFFF00\"><b>%s</b></font> <font color=\"#AAAAAA\">(+%s %s)</font>", formatCountdown(countdownSecs), boost, mut)) end
        end

        -- 3. Update Scheduled Rows
        local rowLabels = { SchedRow1, SchedRow2, SchedRow3, SchedRow4, SchedRow5 }
        for i = 1, 5 do
            local rLabel = rowLabels[i]
            if rLabel then
                local item = nextUpcoming[i]
                if item then
                    local name, mut, boost, col = getFriendlyEventInfo(item.WeatherId)
                    local cd = math.max(0, math.ceil(item.StartsAt - now))
                    rLabel:SetText(string.format("<font color=\"#AAAAAA\">%d.</font> <font color=\"%s\">%s</font> <font color=\"#FFFF00\">[%s]</font>", i, col, name, formatCountdown(cd)))
                else
                    rLabel:SetText(string.format("<font color=\"#666666\">%d. --</font>", i))
                end
            end
        end

        -- 4. Auto Hop for Weather Engine
        if isAutoHopForWeather then
            local target = (Options and Options.TargetWeatherDropdown and Options.TargetWeatherDropdown.Value) or "Any Event"
            local match = false
            if activeEntry then
                if target == "Any Event" then
                    match = true
                elseif target == "Thunderstorm (Shocked)" and activeEntry.WeatherId == "ThunderstormWeather" then
                    match = true
                elseif target == "Frost (Frozen)" and activeEntry.WeatherId == "FrostWeather" then
                    match = true
                elseif target == "Magma (Magma)" and (activeEntry.WeatherId == "MagmaWeather" or activeEntry.WeatherId == "MoltenWeather") then
                    match = true
                end
            end

            if not match then
                serverHop("Searching for server with active " .. target)
            end
        end
    end

    local function runPredictionEngine()
        while true do
            pcall(updatePredictionUI)
            task.wait(1.0)
        end
    end
    task.spawn(runPredictionEngine)

    -- LEFT: Live Weather Status
    local PredictorGroup = PredictionTab:AddLeftGroupbox("Live Status", "cloud-lightning")

    ActiveStatusLabel = PredictorGroup:AddLabel("<font color=\"#FF7F7F\">Active Event:</font> <font color=\"#888888\">Scanning...</font>")
    ActiveBoostLabel = PredictorGroup:AddLabel("<font color=\"#888888\">Boost: None active</font>")
    ActiveTimeLeftLabel = PredictorGroup:AddLabel("<font color=\"#888888\">Time Left: --</font>")

    NextEventNameLabel = PredictorGroup:AddLabel("<font color=\"#00FF7F\">Next Event:</font> <font color=\"#888888\">Calculating...</font>")
    NextEventCountdownLabel = PredictorGroup:AddLabel("<font color=\"#FFD700\">Starts in:</font> <font color=\"#888888\">--</font>")

    PredictorGroup:AddToggle("NotifyEventStart", {
        Text = "Notify on Event Start",
        Default = false,
        Tooltip = "Displays an alert notification when a special weather event begins",
    })

    PredictorGroup:AddButton({
        Text = "Refresh Predictions",
        Func = function()
            pcall(updatePredictionUI)
            Library:Notify("Predictions refreshed!", 2)
        end,
        DoubleClick = false,
    })

    -- RIGHT: Predicted Schedule & Automation
    local WeatherAutoGroup = PredictionTab:AddRightGroupbox("Scheduled Events", "calendar")

    SchedRow1 = WeatherAutoGroup:AddLabel("<font color=\"#AAAAAA\">1.</font> Loading...")
    SchedRow2 = WeatherAutoGroup:AddLabel("<font color=\"#AAAAAA\">2.</font> Loading...")
    SchedRow3 = WeatherAutoGroup:AddLabel("<font color=\"#AAAAAA\">3.</font> Loading...")
    SchedRow4 = WeatherAutoGroup:AddLabel("<font color=\"#AAAAAA\">4.</font> Loading...")
    SchedRow5 = WeatherAutoGroup:AddLabel("<font color=\"#AAAAAA\">5.</font> Loading...")

    WeatherAutoGroup:AddToggle("AutoHopForWeather", {
        Text = "Auto Hop for Active Event",
        Default = false,
        Tooltip = "Automatically hops servers until finding a server with the chosen active weather event",
    })

    WeatherAutoGroup:AddDropdown("TargetWeatherDropdown", {
        Values = { "Any Event", "Thunderstorm (Shocked)", "Frost (Frozen)", "Magma (Magma)" },
        Default = 1,
        Multi = false,
        Text = "Target Weather",
        Tooltip = "Which weather event to search for while server hopping",
    })

    WeatherAutoGroup:AddToggle("AutoFocusEventMutation", {
        Text = "Auto Focus Event Mutation",
        Default = false,
        Tooltip = "Automatically prioritizes stealing the boosted mutation when a weather event is active",
    })

    Toggles.NotifyEventStart:OnChanged(function()
        isEventNotifyEnabled = Toggles.NotifyEventStart.Value
    end)

    Toggles.AutoHopForWeather:OnChanged(function()
        isAutoHopForWeather = Toggles.AutoHopForWeather.Value
    end)

    Toggles.AutoFocusEventMutation:OnChanged(function()
        isAutoFocusEventMutation = Toggles.AutoFocusEventMutation.Value
    end)
end -- end PredictionTab block

--====================================================
-- MISC TAB: MOVEMENT & PHYSICS (with 'activity' icon)
--====================================================
do
    local MiscTab = Tabs.Misc
    local MovementGroup = MiscTab:AddLeftGroupbox("Movement & Physics", "activity")

MovementGroup:AddToggle("EnableSpeed", {
    Text = "Enable Speed",
    Default = false,
    Tooltip = "Overrides WalkSpeed with continuous Anti-Cheat bypass",
})

MovementGroup:AddSlider("SpeedSlider", {
    Text = "Speed Value",
    Default = math.clamp(math.floor(originalWalkSpeed or 16), 16, 300),
    Min = 16,
    Max = 300,
    Rounding = 0,
    Compact = true,
    compact = true,
})

MovementGroup:AddToggle("InfJump", {
    Text = "Infinite Jump",
    Default = false,
    Tooltip = "Allows continuous mid-air jumping without touching the ground",
})

MovementGroup:AddToggle("Noclip", {
    Text = "NoClip",
    Default = false,
    Tooltip = "Disables character collision allowing walking through walls",
})

MovementGroup:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Tooltip = "Allows flying with WASD, Space (Up), and LeftShift (Down)",
})

MovementGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Compact = true,
    compact = true,
})

Toggles.EnableSpeed:OnChanged(function()
    isSpeedEnabled = Toggles.EnableSpeed.Value
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        if isSpeedEnabled then
            applySpeed(LocalPlayer.Character)
        else
            hum.WalkSpeed = originalWalkSpeed or 16
        end
    end
end)

Options.SpeedSlider:OnChanged(function()
    if isSpeedEnabled then
        applySpeed(LocalPlayer.Character)
    end
end)

Toggles.InfJump:OnChanged(function()
    isInfJumpEnabled = Toggles.InfJump.Value
end)

Toggles.Noclip:OnChanged(function()
    isNoclipEnabled = Toggles.Noclip.Value
end)

Toggles.Fly:OnChanged(function()
    isFlyEnabled = Toggles.Fly.Value
    updateFlyState()
end)

--====================================================
-- MISC TAB: VISUALS (with 'eye' icon)
--====================================================
local VisualsGroup = MiscTab:AddLeftGroupbox("Visuals", "eye")

VisualsGroup:AddToggle("PlayerEsp", {
    Text = "Player ESP",
    Default = false,
    Tooltip = "Displays player names, distance, and equipped pets overhead",
})

VisualsGroup:AddToggle("PlotEsp", {
    Text = "Plot ESP",
    Default = false,
    Tooltip = "Displays plot number, base level, and owner overhead",
})

VisualsGroup:AddToggle("EggEsp", {
    Text = "Egg ESP",
    Default = false,
    Tooltip = "Displays unplaced and dropped eggs with rarity colors & size",
})

Toggles.PlayerEsp:OnChanged(function()
    isPlayerEspEnabled = Toggles.PlayerEsp.Value
    if not isPlayerEspEnabled then
        clearEspCategory(activePlayerEsp)
    end
end)

Toggles.PlotEsp:OnChanged(function()
    isPlotEspEnabled = Toggles.PlotEsp.Value
    if not isPlotEspEnabled then
        clearEspCategory(activePlotEsp)
    end
end)

Toggles.EggEsp:OnChanged(function()
    isEggEspEnabled = Toggles.EggEsp.Value
    if not isEggEspEnabled then
        clearEspCategory(activeEggEsp)
    end
end)

--====================================================
-- MISC TAB: UI SETTINGS (with 'settings' icon)
--====================================================
local MiscGroup = MiscTab:AddRightGroupbox("UI Settings", "settings")

MiscGroup:AddButton({
    Text = "Unload UI",
    Func = function()
        isAutoStealing = false
        isAutoStealSelected = false
        isSpeedEnabled = false
        isAntiHitEnabled = false
        isAutoGainSpeedEnabled = false
        isServerHopEnabled = false
        isKillAuraEnabled = false
        isAutoPlaceSelected = false
        isAutoPlaceAll = false
        isAutoHatchReady = false
        isAutoSellSelected = false
        isAutoSellAllEligible = false
        isSyncAutoSellRarities = false
        isAutoClaimIndex = false
        isAutoClaimGroup = false
        isAutoClaimOffline = false
        isAutoBaseUpgrade = false
        isAutoTreadmillUpgrade = false
        isAutoEquipBestPet = false
        isAutoBuyTrail = false
        isAutoEquipBestTrail = false
        isAutoEquipBestGear = false
        isAutoFusePets = false
        isRotationEnabled = false
        isStealBigEggs = false
        isAutoDropHeldEgg = false
        isAutoReturnToBase = false
        isInfJumpEnabled = false
        isNoclipEnabled = false
        isFlyEnabled = false
        isPlayerEspEnabled = false
        isPlotEspEnabled = false
        isEggEspEnabled = false
        isAutoHopForWeather = false
        isAutoFocusEventMutation = false
        isEventNotifyEnabled = false

        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        clearEspCategory(activePlayerEsp)
        clearEspCategory(activePlotEsp)
        clearEspCategory(activeEggEsp)
        if espFolder then pcall(function() espFolder:Destroy() end) end

        task.spawn(unequipTreadmillWithoutTeleport)
        if Toggles.AutoStealAll then Toggles.AutoStealAll:SetValue(false) end
        if Toggles.AutoStealSelected then Toggles.AutoStealSelected:SetValue(false) end
        if Toggles.StealBigEggs then Toggles.StealBigEggs:SetValue(false) end
        if Toggles.AutoDropHeldEgg then Toggles.AutoDropHeldEgg:SetValue(false) end
        if Toggles.ServerHopMatching then Toggles.ServerHopMatching:SetValue(false) end
        if Toggles.EnableSpeed then Toggles.EnableSpeed:SetValue(false) end
        if Toggles.AntiHit then Toggles.AntiHit:SetValue(false) end
        if Toggles.AutoEquipBestPet then Toggles.AutoEquipBestPet:SetValue(false) end
        if Toggles.AutoGainSpeed then Toggles.AutoGainSpeed:SetValue(false) end
        if Toggles.AutoTreadmillUpgrade then Toggles.AutoTreadmillUpgrade:SetValue(false) end
        if Toggles.AutoBaseUpgrade then Toggles.AutoBaseUpgrade:SetValue(false) end
        if Toggles.EnableRotation then Toggles.EnableRotation:SetValue(false) end
        if Toggles.KillAuraToggle then Toggles.KillAuraToggle:SetValue(false) end
        if Toggles.AutoBuyTrail then Toggles.AutoBuyTrail:SetValue(false) end
        if Toggles.AutoEquipBestTrail then Toggles.AutoEquipBestTrail:SetValue(false) end
        if Toggles.AutoEquipBestGear then Toggles.AutoEquipBestGear:SetValue(false) end
        if Toggles.AutoPlaceSelected then Toggles.AutoPlaceSelected:SetValue(false) end
        if Toggles.AutoPlaceAll then Toggles.AutoPlaceAll:SetValue(false) end
        if Toggles.AutoHatchReady then Toggles.AutoHatchReady:SetValue(false) end
        if Toggles.AutoSellSelected then Toggles.AutoSellSelected:SetValue(false) end
        if Toggles.AutoSellAllEligible then Toggles.AutoSellAllEligible:SetValue(false) end
        if Toggles.AutoFusePets then Toggles.AutoFusePets:SetValue(false) end
        if Toggles.SyncAutoSellRarities then Toggles.SyncAutoSellRarities:SetValue(false) end
        if Toggles.AutoClaimIndexRewards then Toggles.AutoClaimIndexRewards:SetValue(false) end
        if Toggles.AutoClaimGroupReward then Toggles.AutoClaimGroupReward:SetValue(false) end
        if Toggles.AutoClaimOfflineEarnings then Toggles.AutoClaimOfflineEarnings:SetValue(false) end
        if Toggles.NotifyEventStart then Toggles.NotifyEventStart:SetValue(false) end
        if Toggles.AutoHopForWeather then Toggles.AutoHopForWeather:SetValue(false) end
        if Toggles.AutoFocusEventMutation then Toggles.AutoFocusEventMutation:SetValue(false) end
        if Toggles.InfJump then Toggles.InfJump:SetValue(false) end
        if Toggles.Noclip then Toggles.Noclip:SetValue(false) end
        if Toggles.Fly then Toggles.Fly:SetValue(false) end
        if Toggles.PlayerEsp then Toggles.PlayerEsp:SetValue(false) end
        if Toggles.PlotEsp then Toggles.PlotEsp:SetValue(false) end
        if Toggles.EggEsp then Toggles.EggEsp:SetValue(false) end
        Library:Unload()
    end,
    DoubleClick = true,
})

local KeybindLabel = MiscGroup:AddLabel("Keybind to Open/Close")
KeybindLabel:AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu Keybind",
})

if Options and Options.MenuKeybind then
    Library.ToggleKeybind = Options.MenuKeybind
end
end -- end MiscTab block


task.defer(function()
    SaveManager:SetLibrary(Library)
    SaveManager:SetFolder("AjjanHub")
    SaveManager:SetSubFolder("Config")
    SaveManager:BuildConfigSection(Tabs.Misc)
    SaveManager:LoadAutoloadConfig()
end)
