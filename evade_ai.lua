-- Ultra Human AI for Evade (Delta-ready)
-- Features: Nextbot prediction, pathfinding, human mimicry, safe revives, lava avoidance

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "Universal Hub | Evade",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "EvadeHub"
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local UIS = game:GetService("UserInputService")

local Humanoid, Root

-- Character updater
local function UpdateChar()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
end
UpdateChar()
LocalPlayer.CharacterAdded:Connect(UpdateChar)

-- Ultra AI toggle
local AI_Tab = Window:MakeTab({ Name = "Ultra AI", Icon = "rbxassetid://4483345998" })
_G.UltraAI = false
AI_Tab:AddToggle({ Name = "Ultra Human AI", Default = false, Callback = function(v) _G.UltraAI = v end })

-- Utility functions
local function getBots()
    local t = {}
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.lower(v.Name):find("nextbot") then
            table.insert(t, v)
        end
    end
    return t
end

local function predictBot(bot)
    if bot.Velocity then
        return bot.Position + (bot.Velocity * 0.5)
    end
    return bot.Position
end

local function getThreat()
    local closest, dist = nil, math.huge
    for _,bot in pairs(getBots()) do
        local predicted = predictBot(bot)
        local d = (Root.Position - predicted).Magnitude
        if d < dist then dist = d closest = bot end
    end
    return closest, dist
end

local function getNearestLava()
    local closest, dist = nil, math.huge
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.lower(v.Name):find("lava") then
            local d = (Root.Position - v.Position).Magnitude
            if d < dist then dist = d closest = v end
        end
    end
    return closest, dist
end

local function hasLOS(pos)
    local ray = Ray.new(Root.Position, (pos - Root.Position).Unit * 100)
    local part = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return part == nil
end

local function moveTo(pos)
    local path = PathfindingService:CreatePath({AgentRadius=2, AgentHeight=5, AgentCanJump=true})
    path:ComputeAsync(Root.Position, pos)
    if path.Status == Enum.PathStatus.Success then
        for _,wp in pairs(path:GetWaypoints()) do
            if not _G.UltraAI then return end
            Humanoid:MoveTo(wp.Position)
            Humanoid.MoveToFinished:Wait(0.2)
            if math.random() < 0.1 then wait(math.random(0.1,0.3)) end
        end
    else
        Humanoid:MoveTo(pos)
    end
end

local function getBestRevive()
    local best, score = nil, math.huge
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local downed = plr.Character:FindFirstChild("Downed")
            if downed then
                local pos = plr.Character.HumanoidRootPart.Position
                local dist = (Root.Position - pos).Magnitude
                local bot, botDist = getThreat()
                local danger = botDist < 100 and (100 - botDist) or 0
                local finalScore = dist + (danger * 3)
                if finalScore < score then score = finalScore best = plr end
            end
        end
    end
    return best
end

-- Heartbeat loop
local lastTick = 0
RunService.Heartbeat:Connect(function()
    if not _G.UltraAI or not Root or not Humanoid then return end
    if tick() - lastTick < math.random(0.2,0.5) then return end
    lastTick = tick()

    -- Lava avoidance
    local lava, lavaDist = getNearestLava()
    if lava and lavaDist < 30 then
        local escapeDir = (Root.Position - lava.Position).Unit
        local offset = Vector3.new(math.random(-10,10),0,math.random(-10,10))
        moveTo(Root.Position + escapeDir * 40 + offset)
        return
    end

    -- Nextbot threat
    local bot, dist = getThreat()
    if bot and dist < 40 then
        local escapeDir = (Root.Position - predictBot(bot)).Unit
        local zigzag = Vector3.new(math.random(-25,25),0,math.random(-25,25))
        moveTo(Root.Position + escapeDir * 80 + zigzag)
        return
    elseif bot and dist < 90 then
        local escapeDir = (Root.Position - predictBot(bot)).Unit
        local offset = Vector3.new(math.random(-10,10),0,math.random(-10,10))
        moveTo(Root.Position + escapeDir * 50 + offset)
        return
    end

    -- Safe revive
    local target = getBestRevive()
    if target and target.Character then
        local pos = target.Character.HumanoidRootPart.Position
        local distTo = (Root.Position - pos).Magnitude
        if math.random() < 0.15 then return end
        if distTo > 6 then
            local offset = Vector3.new(math.random(-3,3),0,math.random(-3,3))
            moveTo(pos + offset)
        end
    end
end)

-- Initialize Orion UI
OrionLib:Init()
