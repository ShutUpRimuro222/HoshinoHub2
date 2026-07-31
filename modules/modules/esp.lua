-- ==========================================
-- HOSHINO: ESP MODULE
-- ==========================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPModule = {}
local ESP_Instances = {}
local DodgeCooldownCache = {}
local MDCache = {}

function ESPModule.Init(Settings, Theme)
    local function get_player_mode(character)
        if not character then return nil end
        local success, result = pcall(function()
            local combat = character:FindFirstChild("combat")
            if combat then
                local mode = combat:FindFirstChild("mode")
                if mode then return mode.Value end
            end
            return nil
        end)
        return success and result or nil
    end

    local function get_cached_mode(character, player)
        if MDCache[player] then
            local cached = MDCache[player]
            if tick() - cached.time < 0.5 then return cached.value end
        end
        local mode = get_player_mode(character)
        MDCache[player] = { value = mode, time = tick() }
        return mode
    end

    local function get_player_dodge_cooldown(player)
        if not player then return "N/A" end
        if DodgeCooldownCache[player] then
            local cached = DodgeCooldownCache[player]
            if cached.keyObj and cached.keyObj.Parent and cached.cdObj and cached.cdObj.Parent then
                if cached.keyObj.Value == "taijutsudodge" then return cached.cdObj.Value end
            end
            DodgeCooldownCache[player] = nil
        end

        local statz = player:FindFirstChild("statz")
        if not statz then return "N/A" end
        local keys = statz:FindFirstChild("keys")
        if not keys then return "N/A" end

        for _, keyObj in pairs(keys:GetChildren()) do
            if keyObj:IsA("StringValue") and keyObj.Value == "taijutsudodge" then
                local cd_val = keyObj:FindFirstChild("cooldown")
                if cd_val and cd_val:IsA("IntValue") then
                    DodgeCooldownCache[player] = { keyObj = keyObj, cdObj = cd_val }
                    return cd_val.Value
                else return 0 end
            end
        end
        return "N/A"
    end

    local function clearESP()
        for _, esp in pairs(ESP_Instances) do
            if esp.Billboard and esp.Billboard.Parent then esp.Billboard.Parent = nil end
        end
    end

    local function CreateESP(player)
        local ESP = {}
        local Billboard = Instance.new("BillboardGui")
        Billboard.Name = "ShindoESP_" .. player.Name
        Billboard.AlwaysOnTop = true
        Billboard.Size = UDim2.new(0, Settings.ESPWidth, 0, Settings.ESPHeight)
        Billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        
        local success, _ = pcall(function() if syn and syn.protect_gui then syn.protect_gui(Billboard) end; Billboard.Parent = CoreGui end)
        if not success then Billboard.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local Container = Instance.new("Frame")
        Container.Parent = Billboard; Container.Size = UDim2.new(1, 0, 1, 0); Container.BackgroundTransparency = 1; Container.AnchorPoint = Vector2.new(0.5, 0.5); Container.Position = UDim2.new(0.5, 0, 0.5, 0)

        local StatsContainer = Instance.new("Frame")
        StatsContainer.Parent = Container; StatsContainer.Size = UDim2.new(0.9, 0, 0, 50); StatsContainer.Position = UDim2.new(0.5, 0, 0.5, 0); StatsContainer.AnchorPoint = Vector2.new(0.5, 0.5); StatsContainer.BackgroundTransparency = 1

        local NameFrame = Instance.new("Frame")
        NameFrame.Parent = StatsContainer; NameFrame.Size = UDim2.new(1, 0, 0, 20); NameFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0); NameFrame.BackgroundTransparency = 0.4
        Instance.new("UICorner", NameFrame).CornerRadius = UDim.new(0, 4)

        local Icon = Instance.new("ImageLabel"); Icon.Parent = NameFrame; Icon.Size = UDim2.new(0, 14, 0, 14); Icon.Position = UDim2.new(0, 4, 0.5, -7); Icon.BackgroundTransparency = 1; Icon.Image = "rbxassetid://11600642540"
        local NameLabel = Instance.new("TextLabel"); NameLabel.Parent = NameFrame; NameLabel.Position = UDim2.new(0, 21, 0, 0); NameLabel.Size = UDim2.new(1, -23, 1, 0); NameLabel.BackgroundTransparency = 1; NameLabel.Font = Enum.Font.GothamBlack; NameLabel.TextColor3 = Theme.Accent; NameLabel.TextSize = Settings.ESPNameSize; NameLabel.Text = player.Name; NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        local textStroke = Instance.new("UIStroke"); textStroke.Parent = NameLabel; textStroke.Thickness = 1.5; textStroke.Color = Color3.fromRGB(0,0,0); textStroke.Transparency = 0.2

        local HPBarBG = Instance.new("Frame"); HPBarBG.Parent = StatsContainer; HPBarBG.Size = UDim2.new(1, 0, 0, 3); HPBarBG.Position = UDim2.new(0, 0, 0, 22); HPBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30); HPBarBG.BackgroundTransparency = 0.3; HPBarBG.BorderSizePixel = 0; Instance.new("UICorner", HPBarBG).CornerRadius = UDim.new(0, 1)
        local HPBarFill = Instance.new("Frame"); HPBarFill.Parent = HPBarBG; HPBarFill.Size = UDim2.new(1, 0, 1, 0); HPBarFill.BackgroundColor3 = Theme.Green; HPBarFill.BorderSizePixel = 0; Instance.new("UICorner", HPBarFill).CornerRadius = UDim.new(0, 1)

        local MDFrame = Instance.new("Frame"); MDFrame.Parent = StatsContainer; MDFrame.Size = UDim2.new(1, 0, 0, 11); MDFrame.Position = UDim2.new(0, 0, 0, 27); MDFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); MDFrame.BackgroundTransparency = 0.4; Instance.new("UICorner", MDFrame).CornerRadius = UDim.new(0, 3)
        local MDStroke = Instance.new("UIStroke"); MDStroke.Parent = MDFrame; MDStroke.Thickness = 1; MDStroke.Color = Color3.fromRGB(100, 100, 100); MDStroke.Transparency = 0.5
        local MDLabel = Instance.new("TextLabel"); MDLabel.Parent = MDFrame; MDLabel.Size = UDim2.new(1, 0, 1, 0); MDLabel.BackgroundTransparency = 1; MDLabel.Font = Enum.Font.GothamBold; MDLabel.TextSize = Settings.ESPMDSize; MDLabel.TextColor3 = Color3.fromRGB(255, 255, 255); MDLabel.Text = "MD: -"; MDLabel.TextXAlignment = Enum.TextXAlignment.Center
        local mdTextStroke = Instance.new("UIStroke"); mdTextStroke.Parent = MDLabel; mdTextStroke.Thickness = 1; mdTextStroke.Color = Color3.fromRGB(0,0,0); mdTextStroke.Transparency = 0.4

        local BottomRow = Instance.new("Frame"); BottomRow.Parent = StatsContainer; BottomRow.Size = UDim2.new(1, 0, 0, 11); BottomRow.Position = UDim2.new(0, 0, 0, 40); BottomRow.BackgroundTransparency = 1

        local function createStatBox(parent, xPos, defaultText, textSize)
            local box = Instance.new("TextLabel"); box.Parent = parent; box.Position = UDim2.new(xPos, 0, 0, 0); box.Size = UDim2.new(0.48, 0, 1, 0); box.BackgroundTransparency = 0.6; box.BackgroundColor3 = Color3.fromRGB(0, 0, 0); box.TextColor3 = Color3.fromRGB(255, 255, 255); box.Font = Enum.Font.GothamBold; box.TextSize = textSize; box.Text = defaultText; box.RichText = true
            local stroke = Instance.new("UIStroke"); stroke.Parent = box; stroke.Thickness = 1; stroke.Color = Color3.fromRGB(0,0,0); stroke.Transparency = 0.4; Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
            return box
        end

        local DistBox = createStatBox(BottomRow, 0, "0M", Settings.ESPMeterSize) 
        local HPTextBox = createStatBox(BottomRow, 0.52, "HP 0K", Settings.ESPHPTextSize) 

        local DodgeIconFrame = Instance.new("Frame"); DodgeIconFrame.Parent = Container; DodgeIconFrame.Size = UDim2.new(0, 26, 0, 26); DodgeIconFrame.Position = UDim2.new(0.95, 0, 0.5, -13); DodgeIconFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); DodgeIconFrame.BackgroundTransparency = 0.3
        Instance.new("UICorner", DodgeIconFrame).CornerRadius = UDim.new(0, 3)
        local DodgeIconStroke = Instance.new("UIStroke"); DodgeIconStroke.Parent = DodgeIconFrame; DodgeIconStroke.Thickness = 1; DodgeIconStroke.Color = Color3.fromRGB(0, 0, 0); DodgeIconStroke.Transparency = 0.4
        local DodgeIcon = Instance.new("ImageLabel"); DodgeIcon.Parent = DodgeIconFrame; DodgeIcon.Size = UDim2.new(1, -3, 1, -3); DodgeIcon.Position = UDim2.new(0, 1.5, 0, 1.5); DodgeIcon.BackgroundTransparency = 1; DodgeIcon.Image = "rbxassetid://11600642540"; DodgeIcon.ScaleType = Enum.ScaleType.Fit
        local DodgeCDText = Instance.new("TextLabel"); DodgeCDText.Parent = DodgeIconFrame; DodgeCDText.Size = UDim2.new(1, 0, 1, 0); DodgeCDText.BackgroundTransparency = 1; DodgeCDText.Font = Enum.Font.GothamBlack; DodgeCDText.TextSize = 10; DodgeCDText.TextColor3 = Color3.fromRGB(255, 255, 255); DodgeCDText.Text = ""; DodgeCDText.ZIndex = 2
        local textStrokeCD = Instance.new("UIStroke"); textStrokeCD.Parent = DodgeCDText; textStrokeCD.Thickness = 1.2; textStrokeCD.Color = Color3.fromRGB(0,0,0)

        ESP.Billboard = Billboard; ESP.NameFrame = NameFrame; ESP.NameLabel = NameLabel; ESP.HPBarFill = HPBarFill; ESP.HPBarBG = HPBarBG; ESP.DistBox = DistBox; ESP.HPTextBox = HPTextBox; ESP.DodgeIconFrame = DodgeIconFrame; ESP.DodgeIcon = DodgeIcon; ESP.DodgeCDText = DodgeCDText; ESP.Icon = Icon; ESP.MDFrame = MDFrame; ESP.MDLabel = MDLabel
        return ESP
    end

    local function InternalUpdateESP()
        if not Settings.ESPEnabled then clearESP(); return end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(function()
                    local character = player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                        local root = character.HumanoidRootPart
                        local hum = character.Humanoid
                        local distance = 0
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                        end

                        if distance <= Settings.ESPRange then
                            if not ESP_Instances[player] then ESP_Instances[player] = CreateESP(player) end
                            local esp = ESP_Instances[player]
                            
                            if esp.Billboard.Parent == nil then
                                local success, _ = pcall(function() if syn and syn.protect_gui then syn.protect_gui(esp.Billboard) end; esp.Billboard.Parent = CoreGui end)
                                if not success then esp.Billboard.Parent = LocalPlayer:WaitForChild("PlayerGui") end
                            end
                            
                            esp.Billboard.Adornee = root
                            esp.Billboard.Size = UDim2.new(0, Settings.ESPWidth, 0, Settings.ESPHeight)
                            
                            esp.NameFrame.Visible = Settings.ESPName; esp.Icon.Visible = Settings.ESPName; esp.NameLabel.Text = player.Name; esp.NameLabel.TextSize = Settings.ESPNameSize; esp.NameLabel.TextColor3 = Theme.Accent
                            
                            esp.HPBarBG.Visible = Settings.ESPHPBar
                            if Settings.ESPHPBar then
                                local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                esp.HPBarFill.Size = UDim2.new(healthPct, 0, 1, 0)
                                local r = healthPct > 0.5 and (1 - healthPct) * 2 or 1
                                local g = healthPct > 0.5 and 1 or healthPct * 2
                                esp.HPBarFill.BackgroundColor3 = Color3.new(r, g, 0)
                            end
                            
                            esp.DistBox.Visible = Settings.ESPMeter
                            if Settings.ESPMeter then esp.DistBox.Text = tostring(distance) .. "M"; esp.DistBox.TextSize = Settings.ESPMeterSize end
                            
                            esp.HPTextBox.Visible = Settings.ESPHPText
                            if Settings.ESPHPText then
                                local hpFormat = math.floor(hum.Health)
                                if hpFormat > 1000 then hpFormat = string.format("%.1fK", hpFormat/1000) end
                                esp.HPTextBox.Text = '<font color="#FFFFFF">HP</font> ' .. tostring(hpFormat)
                                esp.HPTextBox.TextSize = Settings.ESPHPTextSize 
                            end
                            
                            esp.MDFrame.Visible = Settings.ESPMD
                            if Settings.ESPMD then
                                esp.MDLabel.TextSize = Settings.ESPMDSize 
                                local mode = get_cached_mode(character, player)
                                if mode ~= nil then
                                    if mode >= 1000 then esp.MDLabel.Text = "MD: " .. string.format("%.1fK", mode/1000) else esp.MDLabel.Text = "MD: " .. tostring(mode) end
                                else
                                    esp.MDLabel.Text = "MD: -"; esp.MDLabel.TextColor3 = Color3.fromRGB(150, 150, 150) 
                                end
                            end
                            
                            esp.DodgeIconFrame.Visible = Settings.ESPCD 
                            if Settings.ESPCD then
                                local dodge_cd = get_player_dodge_cooldown(player)
                                if type(dodge_cd) == "number" and dodge_cd > 0 then
                                    esp.DodgeCDText.Text = tostring(dodge_cd); esp.DodgeCDText.TextColor3 = Theme.Red; esp.DodgeIcon.ImageColor3 = Color3.fromRGB(80, 80, 80); esp.DodgeIconFrame.UIStroke.Color = Theme.Red
                                elseif type(dodge_cd) == "number" and dodge_cd <= 0 then
                                    esp.DodgeCDText.Text = ""; esp.DodgeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255); esp.DodgeIconFrame.UIStroke.Color = Theme.Green
                                else
                                    esp.DodgeCDText.Text = "-"; esp.DodgeCDText.TextColor3 = Color3.fromRGB(150, 150, 150); esp.DodgeIcon.ImageColor3 = Color3.fromRGB(50, 50, 50); esp.DodgeIconFrame.UIStroke.Color = Color3.fromRGB(80, 80, 80)
                                end
                            end
                        else
                            if ESP_Instances[player] and ESP_Instances[player].Billboard then ESP_Instances[player].Billboard.Parent = nil end
                        end
                    else
                        if ESP_Instances[player] then ESP_Instances[player].Billboard:Destroy(); ESP_Instances[player] = nil; DodgeCooldownCache[player] = nil; MDCache[player] = nil end
                    end
                end)
            end
        end
    end

    RunService.RenderStepped:Connect(InternalUpdateESP)

    Players.PlayerRemoving:Connect(function(player)
        if ESP_Instances[player] then pcall(function() ESP_Instances[player].Billboard:Destroy() end); ESP_Instances[player] = nil end
        DodgeCooldownCache[player] = nil; MDCache[player] = nil
    end)
end

return ESPModule
