-- [[ HYLORD OPTIMIZER HUB ]] --
-- Created and Architected by Hylord
-- Features: Recent Waypoint (Config System), Ultra-Fast Parsing, P Key Toggle

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:WaitForChild("Terrain")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")


local HylordScreen = Instance.new("ScreenGui")
HylordScreen.Name = "HylordOptimizer"
HylordScreen.Enabled = false -- P tuşu ile açılacak
HylordScreen.ResetOnSpawn = false

local success, err = pcall(function() HylordScreen.Parent = CoreGui end)
if not success then HylordScreen.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 180)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = HylordScreen

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 35)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "HYLORD OPTIMIZER V4.1"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -30, 0, 20)
SubTitle.Position = UDim2.new(0, 15, 0, 25)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Waypoint Config & Combat Tuned"
SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
SubTitle.TextSize = 12
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local OptimizeBtn = Instance.new("TextButton")
OptimizeBtn.Size = UDim2.new(0, 280, 0, 45)
OptimizeBtn.Position = UDim2.new(0.5, -140, 0.5, 10)
OptimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
OptimizeBtn.Text = "ENABLE OPTIMIZATION"
OptimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
OptimizeBtn.Font = Enum.Font.GothamBold
OptimizeBtn.TextSize = 16
OptimizeBtn.Parent = MainFrame
local OptCorner = Instance.new("UICorner")
OptCorner.CornerRadius = UDim.new(0, 6)
OptCorner.Parent = OptimizeBtn

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 0, 20)
StatusText.Position = UDim2.new(0, 0, 1, -25)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Idle | Press 'P' to hide"
StatusText.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusText.TextSize = 12
StatusText.Font = Enum.Font.Gotham
StatusText.Parent = MainFrame


local isOptimized = false
local MapScanned = false 
local WaypointFile = "Hylord_Waypoint.json"

local Cache = {
    Parts = {}, PostProcessing = {}, Meshes = {}
}

local GlobalConfig = {
    GlobalShadows = true,
    Brightness = 1,
    FogEnd = 100000,
    EnvironmentDiffuseScale = 1,
    EnvironmentSpecularScale = 1,
    Decoration = true
}


local function LoadWaypointConfig()
    if isfile and readfile and isfile(WaypointFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(WaypointFile))
        end)
        if success and data then
            GlobalConfig = data
            print("[Hylord] Recent Waypoint loaded from computer config.")
        end
    else

        GlobalConfig.GlobalShadows = Lighting.GlobalShadows
        GlobalConfig.Brightness = Lighting.Brightness
        GlobalConfig.FogEnd = Lighting.FogEnd
        GlobalConfig.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
        GlobalConfig.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
        
        -- HATA ÇÖZÜMÜ: Terrain.Decoration güvenli okuma
        local successDeco, decoValue = pcall(function() return Terrain.Decoration end)
        GlobalConfig.Decoration = successDeco and decoValue or false
        
        if writefile then
            pcall(function()
                writefile(WaypointFile, HttpService:JSONEncode(GlobalConfig))
            end)
        end
    end
end


LoadWaypointConfig()


local function IsProtectedCharacter(instance)
    local model = instance:FindFirstAncestorWhichIsA("Model")
    if model then
        if model:FindFirstChild("Humanoid") then return true end
        if model.Name:match("Stand") or model.Name:match("Aura") then return true end
    end
    return false
end


local function CreateSessionWaypoint()
    if MapScanned then return end 
    StatusText.Text = "Status: Creating Session Waypoint..."
    
    table.clear(Cache.PostProcessing)
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
            Cache.PostProcessing[obj] = obj.Enabled
        end
    end

    table.clear(Cache.Parts)
    table.clear(Cache.Meshes)
    
    local descendants = Workspace:GetDescendants()
    for i, part in ipairs(descendants) do
        if not IsProtectedCharacter(part) then
            if part:IsA("BasePart") then
                Cache.Parts[part] = {
                    CastShadow = part.CastShadow,
                    Material = part.Material,
                    CanTouch = part.CanTouch,
                    CanQuery = part.CanQuery
                }
            elseif part:IsA("MeshPart") then
                Cache.Meshes[part] = { RenderFidelity = part.RenderFidelity }
            elseif part:IsA("Decal") or part:IsA("Texture") then
                Cache.Parts[part] = { Transparency = part.Transparency }
            end
        end
        if i % 4000 == 0 then RunService.Heartbeat:Wait() end
    end
    
    MapScanned = true
    print("[Hylord] Map successfully cached to Session Waypoint.")
end

-- Optimizasyonu Uygula
local function ApplyOptimizations()
    StatusText.Text = "Status: Applying Combat Optimizations..."
    
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.Brightness = 2 end)
    pcall(function() Lighting.FogEnd = 9e9 end) 
    pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
    pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
    
    -- HATA ÇÖZÜMÜ: Terrain.Decoration güvenli yazma
    pcall(function() Terrain.Decoration = false end)

    for obj, _ in pairs(Cache.PostProcessing) do 
        pcall(function() obj.Enabled = false end) 
    end

    for part, data in pairs(Cache.Parts) do
        if part:IsA("BasePart") then
            pcall(function() part.CastShadow = false end)
            if part.Material ~= Enum.Material.ForceField and part.Material ~= Enum.Material.Neon then
                pcall(function() part.Material = Enum.Material.SmoothPlastic end)
            end
            if part.Anchored and part.Name ~= "SpawnLocation" then
                pcall(function()
                    part.CanTouch = false
                    part.CanQuery = false
                end)
            end
        elseif part:IsA("Decal") or part:IsA("Texture") then
            pcall(function() part.Transparency = 1 end)
        end
    end
    
    for mesh, data in pairs(Cache.Meshes) do
        if mesh:IsA("MeshPart") then
            pcall(function() mesh.RenderFidelity = Enum.RenderFidelity.Performance end)
        end
    end

    if setfpscap then pcall(function() setfpscap(9999) end) end
    pcall(function() settings():GetService("NetworkSettings").IncomingReplicationLag = 0 end)
    
    StatusText.Text = "Status: ON!"
end


local function RestoreSettings()
    StatusText.Text = "Status: Restoring to Recent Waypoint..."
    

    pcall(function() Lighting.GlobalShadows = GlobalConfig.GlobalShadows end)
    pcall(function() Lighting.Brightness = GlobalConfig.Brightness end)
    pcall(function() Lighting.FogEnd = GlobalConfig.FogEnd end)
    pcall(function() Lighting.EnvironmentDiffuseScale = GlobalConfig.EnvironmentDiffuseScale end)
    pcall(function() Lighting.EnvironmentSpecularScale = GlobalConfig.EnvironmentSpecularScale end)
    
    -- HATA ÇÖZÜMÜ: Terrain.Decoration güvenli yazma
    pcall(function() Terrain.Decoration = GlobalConfig.Decoration end)

    for obj, wasEnabled in pairs(Cache.PostProcessing) do
        if obj and obj.Parent then 
            pcall(function() obj.Enabled = wasEnabled end) 
        end
    end

    local i = 0
    for part, data in pairs(Cache.Parts) do
        if part and part.Parent then
            if part:IsA("BasePart") then
                pcall(function()
                    part.CastShadow = data.CastShadow
                    part.Material = data.Material
                    part.CanTouch = data.CanTouch
                    part.CanQuery = data.CanQuery
                end)
            elseif part:IsA("Decal") or part:IsA("Texture") then
                pcall(function() part.Transparency = data.Transparency end)
            end
        end
        i = i + 1
        if i % 4000 == 0 then RunService.Heartbeat:Wait() end
    end
    
    for mesh, data in pairs(Cache.Meshes) do
        if mesh and mesh.Parent then
            pcall(function() mesh.RenderFidelity = data.RenderFidelity end)
        end
    end

    if setfpscap then pcall(function() setfpscap(60) end) end
    StatusText.Text = "Status: Idle | Restored to Waypoint Config"
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then 
        HylordScreen.Enabled = not HylordScreen.Enabled
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if isOptimized then RestoreSettings() end
    HylordScreen:Destroy()
end)

OptimizeBtn.MouseButton1Click:Connect(function()
    if not isOptimized then
        OptimizeBtn.Text = "PLEASE WAIT..."
        OptimizeBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
        
        task.spawn(function()
            CreateSessionWaypoint() 
            ApplyOptimizations()
            isOptimized = true
            OptimizeBtn.Text = "OPTIMIZATION: ON"
            OptimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
            OptimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    else
        OptimizeBtn.Text = "PLEASE WAIT..."
        OptimizeBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
        
        task.spawn(function()
            RestoreSettings()
            isOptimized = false
            OptimizeBtn.Text = "ENABLE OPTIMIZATION"
            OptimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            OptimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)
    end
end)

print("[Hylord] Optimizer applied.")