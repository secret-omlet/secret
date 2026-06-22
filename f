local ExtraModule = {}

function ExtraModule.Init(Deps)
    local Plr = Deps.Plr
    local ReplicatedStorage = Deps.ReplicatedStorage
    local Workspace = Deps.Workspace
    local VirtualInputManager = Deps.VirtualInputManager
    local GuiService = Deps.GuiService
    local WindUI = Deps.WindUI
    local PauseFarms = Deps.PauseFarms
    local ResumeFarms = Deps.ResumeFarms
    local Sea = Deps.Sea
    local SmartTween = Deps.SmartTween
    local Settings = Deps.Settings
    local RegisterAttack = Deps.RegisterAttack

    local State = {
        AutoFish = false, AutoBuyBait = false,
        AutoSellFish = false, SellInterval = 60,
        AutoRoll = false, AutoStore = false,
        AutoBuyDealer = false, TargetFruit = "Rocket-Rocket",
        AutoStats = false, StatsPoint = 1, SelectedStats = {},
        attemptedFruits = {},
        LastCheckedRestockTime = 0,
        IsRolling = false, IsStoring = false, IsBuyingBait = false,
        TotalFishCaught = 0,
        
        AutoSeaEnabled = false, TargetSeaLevel = 7,
        SelectedBoatArg = "PirateGrandBrigade",
        BoatPatrolDist = 0, BoatPatrolDir = 1,
        
        IslandTeleportEnabled = false, SelectedIslandTarget = nil,
        ActiveTween = nil,

        AutoEliteHunter = false,
        AutoYama = false,
        TryLuckYama = false,
        IsDoingPriorityTask = false,
        EliteExpandedEnemy = nil,
        LastEliteAttackTime = 0,
        CurrentEliteSpawnIndex = 1
    }

    local FishingRequest = ReplicatedStorage:WaitForChild("FishReplicated", 5) and ReplicatedStorage.FishReplicated:FindFirstChild("FishingRequest")
    local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    
    local BoatsMap = {["Dinghy"]="Dinghy",["Pirate Sloop"]="PirateSloop",["Pirate Brigade"]="PirateBrigade",["Pirate Grand Brigade (پیشنهادی)"]="PirateGrandBrigade",["Miracle (نیاز به گیم پس)"]="Miracle",["The Sentinel (نیاز به گیم پس)"]="The Sentinel",["Guardian (نیاز به کوئست)"]="Guardian",["Lantern (نیاز به کوئست)"]="Lantern"}
    local BoatNames = {"Dinghy","Pirate Sloop","Pirate Brigade","Pirate Grand Brigade (پیشنهادی)","Miracle (نیاز به گیم پس)","The Sentinel (نیاز به گیم پس)","Guardian (نیاز به کوئست)","Lantern (نیاز به کوئست)"}

    local IslandData, IslandNames = {}, {}
    if Sea == 1 then
        IslandData = { ["Starter Island"] = CFrame.new(1060, 17, 1549), ["Jungle"] = CFrame.new(-1602, 37, 154), ["Pirate Village"] = CFrame.new(-1140, 5, 3830), ["Desert"] = CFrame.new(897, 7, 4390), ["Snow Island"] = CFrame.new(1386, 87, -1299), ["Marine Fortress"] = CFrame.new(-5036, 28, 4325), ["Skylands"] = CFrame.new(-4840, 717, -2620), ["Prison"] = CFrame.new(5308, 2, 475), ["Colosseum"] = CFrame.new(-1576, 8, -2985), ["Magma Village"] = CFrame.new(-5315, 12, 8516), ["Underwater City"] = CFrame.new(61122, 19, 1568), ["Fountain City"] = CFrame.new(5259, 39, 4050) }
    elseif Sea == 2 then
        IslandData = { ["Kingdom of Rose"] = CFrame.new(-425, 73, 1835), ["Cafe"] = CFrame.new(-380, 73, 255), ["Usopp Island"] = CFrame.new(4816, 8, 2863), ["Green Zone"] = CFrame.new(-2442, 75, -3219), ["Graveyard"] = CFrame.new(-5492, 49, -794), ["Snow Mountain"] = CFrame.new(606, 402, -5369), ["Hot and Cold"] = CFrame.new(-5430, 16, -5295), ["Cursed Ship"] = "Special_CursedShip", ["Ice Castle"] = CFrame.new(6115, 29, -6222), ["Forgotten Island"] = CFrame.new(-3053, 237, -10146), ["Dark Arena"] = CFrame.new(3800, 20, -3500) }
    elseif Sea == 3 then
        IslandData = { ["Port Town"] = CFrame.new(-288, 43, 5433), ["Hydra Island"] = CFrame.new(5228, 18, 345), ["Great Tree"] = CFrame.new(2300, 50, -6800), ["Floating Turtle (Mansion)"] = CFrame.new(-12488, 332, -7553), ["Castle on the Sea"] = CFrame.new(-5000, 315, -3000), ["Haunted Castle"] = CFrame.new(-9515, 142, 5537), ["Peanut Island"] = CFrame.new(-2022, 37, -12025), ["Ice Cream Island"] = CFrame.new(-818, 65, -10965), ["Cake Island"] = CFrame.new(-1926, 37, -12850), ["Chocolate Island"] = CFrame.new(-1149, 13, -12836), ["Tiki Outpost"] = CFrame.new(-16234, 9, 331), ["Submerged Island"] = "Special_Submerged" }
    end
    for name, _ in pairs(IslandData) do table.insert(IslandNames, name) end
    table.sort(IslandNames)

    local function GetCastPos() local c=Plr.Character; if c and c:FindFirstChild("HumanoidRootPart") then return c.HumanoidRootPart.Position+(c.HumanoidRootPart.CFrame.LookVector*50)-Vector3.new(0,12,0) end; return Vector3.new(0,0,0) end
    local function TapClick() local x=workspace.CurrentCamera.ViewportSize.X/2; local y=workspace.CurrentCamera.ViewportSize.Y/2; VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,1); task.wait(); VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,1) end
    local function PerfectCast() local x=workspace.CurrentCamera.ViewportSize.X/2; local y=workspace.CurrentCamera.ViewportSize.Y/2; VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,1); task.wait(0.65); pcall(function() if FishingRequest then FishingRequest:InvokeServer("CastLineAtLocation", GetCastPos(), 100, true) end end); VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,1) end

    local function AutoFishSystem()
        local Character = Plr.Character or Plr.CharacterAdded:Wait(); local Backpack = Plr.Backpack; local Humanoid = Character:WaitForChild("Humanoid"); local Head = Character:WaitForChild("Head")
        local toolName = "Fishing Rod"; local tool = Character:FindFirstChild(toolName) or Backpack:FindFirstChild(toolName)
        if not tool then return end
        if tool.Parent == Backpack then Humanoid:EquipTool(tool); pcall(function() if FishingRequest then FishingRequest:InvokeServer("RodEquipped") end end); task.wait(0.4) end
        PerfectCast()
        local FishDetected = false; local StartTime = tick(); local oldAttachments = {}
        for _, v in pairs(Head:GetChildren()) do if v:IsA("Attachment") then oldAttachments[v] = true end end
        repeat task.wait() for _, v in pairs(Head:GetChildren()) do if v:IsA("Attachment") and not oldAttachments[v] then FishDetected = true; break end end; if not Character:FindFirstChild(toolName) then break end until FishDetected or (tick() - StartTime > 40)
        if FishDetected then TapClick(); task.wait(2); local s, r = pcall(function() if FishingRequest then return FishingRequest:InvokeServer("Catch", 1, 0, 1) end end); if s then State.TotalFishCaught = State.TotalFishCaught + 1 end; task.wait(1) else TapClick() end
    end

    local function getCloseButtonDynamic()
        local spinnerWindow = Plr.PlayerGui:FindFirstChild("SpinnerWindow")
        if spinnerWindow then
            local aboveSpinner = spinnerWindow:FindFirstChild("AboveSpinner")
            if aboveSpinner then
                local navigation = aboveSpinner:FindFirstChild("Navigation")
                if navigation then return navigation:FindFirstChild("CloseButton"), spinnerWindow, aboveSpinner end
            end
        end
        return nil, nil, nil
    end

    local function isCloseButtonVisible()
        local closeBtn, spinnerWindow, aboveSpinner = getCloseButtonDynamic()
        if closeBtn and spinnerWindow and aboveSpinner then return spinnerWindow.Enabled and aboveSpinner.Visible and closeBtn.Visible and closeBtn.AbsoluteSize.X > 0, closeBtn end
        return false, nil
    end

    local function simulateClick(btn)
        pcall(function()
            local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2); local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2); local inset = GuiService:GetGuiInset()
            VirtualInputManager:SendMouseButtonEvent(x, y + inset.Y, 0, true, game, 1); task.wait(0.05); VirtualInputManager:SendMouseButtonEvent(x, y + inset.Y, 0, false, game, 1)
        end)
    end

    -- آپدیت و حل مشکل اسم فروت ها با دیکشنری کامل
    local ValidFruitsForStore = {"Rocket", "Spin", "Chop", "Spring", "Bomb", "Spike", "Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light", "Rubber", "Barrier", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider", "Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity", "Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Leopard", "Kitsune"}
    local function getStoreNameForAuto(toolName) 
        local tName = toolName:lower()
        for _, fruit in ipairs(ValidFruitsForStore) do
            if tName:find(fruit:lower()) then
                return fruit .. "-" .. fruit
            end
        end
        local baseName = toolName:gsub(" Fruit", ""):match("^%s*(.-)%s*$")
        if baseName then return baseName .. "-" .. baseName end
        return toolName
    end

    local function tryStoreFruit(item)
        if not State.AutoStore then return end
        if not item:IsA("Tool") or not item.Name:lower():find("fruit") then return end
        if State.attemptedFruits[item] then return end
        State.attemptedFruits[item] = true
        local wasPaused = State.IsStoring
        if not wasPaused then State.IsStoring = true; PauseFarms() end
        task.spawn(function()
            task.wait(0.3)
            local char = Plr.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then if not wasPaused then ResumeFarms(); State.IsStoring=false end; return end
            if item.Parent ~= char then hum:EquipTool(item); task.wait(0.5) end
            if item.Parent == char then
                local formattedName = getStoreNameForAuto(item.Name)
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("StoreFruit", formattedName, item)
                task.wait(0.5); if item.Parent == char or item.Parent == Plr.Backpack then hum:UnequipTools() end
            end
            if not wasPaused then task.wait(0.5); ResumeFarms(); State.IsStoring=false end
        end)
    end

    local function GetCurrentDangerLevel() local level = 0; pcall(function() local text = Plr.PlayerGui.Main.Compass.Frame.DangerLevel.TextLabel.Text; if string.find(text, "?") then level = 6 else local num = string.match(text, "%d+"); if num then level = tonumber(num) end end end); return level end
    local function GetClosestOwnedBoat() local closest, dist = nil, 1000; local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart"); if not root then return nil end; for _, b in pairs(Workspace.Boats:GetChildren()) do local seat = b:FindFirstChild("VehicleSeat"); if seat and not seat.Occupant then local d = (root.Position - seat.Position).Magnitude; if d < dist then dist = d; closest = b end end end; return closest end
    local function IsInsideCursedShip() local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart"); return root and (root.Position - Vector3.new(923, 126, 32852)).Magnitude < 3000 end
    local function IsInsideSubmerged() local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart"); return root and (root.Position - Vector3.new(10779, -2088, 9262)).Magnitude < 3000 end
    local function IsInsideFishmanIsland() local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart"); return root and (root.Position - Vector3.new(61583, 18, 987)).Magnitude < 2000 end
    local function IsPlayerDead() return not Plr.Character or not Plr.Character:FindFirstChild("Humanoid") or Plr.Character.Humanoid.Health<=0 end

    -- ==========================================
    -- توابع مربوط به الایت هانتر
    -- ==========================================
    if Sea == 3 then
        task.spawn(function()
            local EliteSpawns = {
                ["Hydra Island"] = { CFrame.new(4509, 1209, -2), CFrame.new(6218, 76, 2120), CFrame.new(7076, 246, -444), CFrame.new(6126, 184, -2208) },
                ["Floating Turtle"] = { CFrame.new(-10964, 707, -7108), CFrame.new(-11512, 639, -8910), CFrame.new(-12411, 334, -9654), CFrame.new(-13797, 331, -9126), CFrame.new(-13746, 401, -10072), CFrame.new(-11797, 457, -10306), CFrame.new(-10827, 453, -9786) },
                ["Port Town"] = { CFrame.new(-1362, 151, 7334) },
                ["Great Tree"] = { CFrame.new(2532, 567, -8343), CFrame.new(4341, 565, -6169) }
            }

            local function EliteCleanupExpandedHead(E)
                pcall(function()
                    if not E or not E.Parent then return end
                    local H = E:FindFirstChild("Head")
                    local FH = E:FindFirstChild("FakeHead")
                    if FH then if H then H.Size = FH.Size; H.Transparency = FH.Transparency end; FH:Destroy() end
                end)
            end

            while task.wait(0.5) do
                if not State.AutoEliteHunter and not State.AutoYama and not State.TryLuckYama then 
                    if State.IsDoingPriorityTask then
                        State.IsDoingPriorityTask = false
                        ResumeFarms()
                    end
                    continue 
                end
                
                pcall(function()
                    local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
                    if not root or IsPlayerDead() then return end

                    local progressRaw = CommF:InvokeServer("EliteHunter", "Progress")
                    local kills = tonumber(tostring(progressRaw):match("%d+")) or 0
                    
                    -- === 1. چک کردن یاما سورد ===
                    local shouldDoYama = false
                    if State.AutoYama and kills >= 30 then shouldDoYama = true end
                    if State.TryLuckYama and kills >= 20 and kills < 30 then shouldDoYama = true end

                    if shouldDoYama then
                        if not State.IsDoingPriorityTask then
                            State.IsDoingPriorityTask = true
                            PauseFarms()
                            Deps.SetFarmMode("YamaQuest")
                        end

                        local hitbox = Workspace.Map:FindFirstChild("Waterfall") and Workspace.Map.Waterfall:FindFirstChild("SealedKatana") and Workspace.Map.Waterfall.SealedKatana:FindFirstChild("Hitbox")
                        if hitbox then
                            local dist = (root.Position - hitbox.Position).Magnitude
                            if dist > 15 then
                                State.ActiveTween = SmartTween(root, hitbox.CFrame * CFrame.new(0, 5, 5), State.ActiveTween)
                            else
                                if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                                
                                Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, hitbox.Position)
                                
                                local x = Workspace.CurrentCamera.ViewportSize.X/2
                                local y = Workspace.CurrentCamera.ViewportSize.Y/2
                                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                                task.wait(0.1)
                                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                                
                                local notifs = Plr.PlayerGui:FindFirstChild("Notifications")
                                if notifs then
                                    for _, child in pairs(notifs:GetChildren()) do
                                        if child.Name == "NotificationTemplate" and child:IsA("Frame") then
                                            local textStr = ""
                                            local textLabel = child:FindFirstChild("TextLabel") or child:FindFirstChildOfClass("TextLabel")
                                            if textLabel then textStr = textLabel.Text end
                                            
                                            if textStr ~= "" then
                                                if string.find(textStr:lower(), "not worthy") then
                                                    WindUI:Notify({Title="یاما سورد", Content="شانس ناموفق بود! ادامه شکار...", Duration=5})
                                                    child:Destroy()
                                                    State.IsDoingPriorityTask = false
                                                    ResumeFarms()
                                                    task.wait(2)
                                                    return
                                                elseif string.find(textStr:lower(), "accepted you") then
                                                    WindUI:Notify({Title="تبریک!", Content="شمشیر یاما رو گرفتی!", Duration=10})
                                                    State.AutoYama = false
                                                    State.TryLuckYama = false
                                                    child:Destroy()
                                                    State.IsDoingPriorityTask = false
                                                    ResumeFarms()
                                                    return
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        return 
                    end

                    -- === 2. چک کردن الایت هانتر ===
                    if State.AutoEliteHunter then
                        local npcText = CommF:InvokeServer("EliteHunter")
                        if type(npcText) == "string" and not string.find(npcText, "doesn't have anything") and not string.find(npcText, "Come back later") then
                            
                            local islandName = nil
                            if string.find(npcText, "Port Town") then islandName = "Port Town"
                            elseif string.find(npcText, "Hydra Island") then islandName = "Hydra Island"
                            elseif string.find(npcText, "Great Tree") then islandName = "Great Tree"
                            elseif string.find(npcText, "Floating Turtle") then islandName = "Floating Turtle" end

                            if islandName then
                                if not State.IsDoingPriorityTask then
                                    State.IsDoingPriorityTask = true
                                    PauseFarms()
                                    Deps.SetFarmMode("EliteHunter")
                                end

                                local bossFound = nil
                                local enemies = Workspace:FindFirstChild("Enemies")
                                if enemies then
                                    for _, enemy in pairs(enemies:GetChildren()) do
                                        if enemy.Name == "Deandre" or enemy.Name == "Diablo" or enemy.Name == "Urban" then
                                            local hum = enemy:FindFirstChild("Humanoid")
                                            if hum and hum.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
                                                bossFound = enemy
                                                break
                                            end
                                        end
                                    end
                                end

                                if bossFound then
                                    local H = bossFound:FindFirstChild("Head")
                                    if H and not bossFound:FindFirstChild("FakeHead") then
                                        if State.EliteExpandedEnemy and State.EliteExpandedEnemy ~= bossFound then EliteCleanupExpandedHead(State.EliteExpandedEnemy) end
                                        local FH = H:Clone()
                                        FH.Name = "FakeHead"
                                        FH.CanCollide = false
                                        FH.Massless = true
                                        FH.Size = H.Size
                                        FH.Transparency = H.Transparency
                                        FH.Parent = bossFound
                                        local W = Instance.new("WeldConstraint")
                                        W.Part0 = H; W.Part1 = FH; W.Parent = FH
                                        H.Size = Vector3.new(Settings.HeadSize, Settings.HeadSize, Settings.HeadSize)
                                        H.Transparency = 1; H.CanCollide = false
                                        for _, c in pairs(H:GetChildren()) do if c:IsA("SpecialMesh") or c:IsA("Decal") then c:Destroy() end end
                                        State.EliteExpandedEnemy = bossFound
                                    end
                                    local hum = bossFound:FindFirstChild("Humanoid")
                                    if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
                                    for _, p in pairs(bossFound:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end

                                    local ep = bossFound.HumanoidRootPart.Position
                                    local d = (root.Position - ep); d = Vector3.new(d.X, 0, d.Z)
                                    if d.Magnitude < 0.1 then d = Vector3.new(1,0,0) end; d = d.Unit
                                    local dest = CFrame.lookAt(ep + d * Settings.AttackDistance + Vector3.new(0, Settings.AttackHeight, 0), ep)

                                    if (root.Position - dest.Position).Magnitude > 10 then
                                        State.ActiveTween = SmartTween(root, dest, State.ActiveTween)
                                    else
                                        if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                                        root.CFrame = dest

                                        -- تغییرات سرعت اتک: حذف زمان صبر طولانی و جایگزین با اسپم کلیک شبیه دوج کینگ
                                        if bossFound:FindFirstChild("Head") then
                                            Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, bossFound.Head.Position)
                                        end
                                        
                                        local h = Plr.Character:FindFirstChild("Humanoid")
                                        local t = Plr.Character:FindFirstChildOfClass("Tool")
                                        if not (t and (t.ToolTip == "Melee" or t.ToolTip == "Sword" or t.ToolTip == "Blox Fruit")) then
                                            for _, t2 in pairs(Plr.Backpack:GetChildren()) do 
                                                if t2:IsA("Tool") and (t2.ToolTip == "Sword" or t2.ToolTip == "Blox Fruit" or t2.ToolTip == "Melee") then 
                                                    h:EquipTool(t2); break 
                                                end 
                                            end
                                        end
                                        
                                        -- ایجاد ترد جداگانه برای کلیک های سریع و بدون مکس
                                        task.spawn(function()
                                            local CX, CY = Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y/2
                                            for i = 1, 4 do
                                                VirtualInputManager:SendMouseButtonEvent(CX, CY, 0, true, game, 1)
                                                task.wait(Settings.HoldTime or 0.05)
                                                VirtualInputManager:SendMouseButtonEvent(CX, CY, 0, false, game, 1)
                                                
                                                if RegisterAttack then
                                                    RegisterAttack:FireServer(math.floor((0.5 + math.random() * 0.5) * 10000) / 10000)
                                                end
                                                task.wait(0.1)
                                            end
                                        end)
                                        
                                    end
                                else
                                    local spawns = EliteSpawns[islandName]
                                    if spawns then
                                        if State.CurrentEliteSpawnIndex > #spawns then State.CurrentEliteSpawnIndex = 1 end
                                        
                                        local targetSpawn = spawns[State.CurrentEliteSpawnIndex]
                                        local targetDest = targetSpawn * CFrame.new(0, 40, 0)
                                        local distToDest = (root.Position - targetDest.Position).Magnitude
                                        
                                        if distToDest > 20 then
                                            State.ActiveTween = SmartTween(root, targetDest, State.ActiveTween)
                                        else
                                            if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                                            task.wait(0.5)
                                            State.CurrentEliteSpawnIndex = State.CurrentEliteSpawnIndex + 1
                                        end
                                    end
                                end
                            end
                        else
                            if State.IsDoingPriorityTask then
                                if State.EliteExpandedEnemy then EliteCleanupExpandedHead(State.EliteExpandedEnemy); State.EliteExpandedEnemy = nil end
                                State.IsDoingPriorityTask = false
                                WindUI:Notify({Title="الایت هانتر", Content="الایت کشته شد یا دیسپاون شد. بازگشت به کار قبلی...", Duration=5})
                                ResumeFarms()
                            end
                        end
                    end
                end)
            end
        end)
    end

    -- ==========================================
    -- حلقه‌های متفرقه (اتو فیش، رول، دریا، استور)
    -- ==========================================

    task.spawn(function() while task.wait(0.5) do if State.AutoFish then pcall(AutoFishSystem) end end end)

    task.spawn(function()
        while task.wait(5) do
            if State.AutoBuyBait and not State.IsBuyingBait then
                pcall(function()
                    local inv = ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
                    local baitCount = 0
                    if type(inv) == "table" then for _, item in pairs(inv) do if type(item) == "table" and item.Name and string.find(item.Name, "Bait") then baitCount = item.Count or 0; break end end end
                    if baitCount < 15 then
                        State.IsBuyingBait = true
                        while State.AutoBuyBait and baitCount < 85 do
                            if Plr.Data.Beli.Value < 10000 then break end
                            ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/Craft"):InvokeServer("Craft", "Basic Bait", 1, {})
                            baitCount = baitCount + 10; task.wait(0.8)
                        end
                        State.IsBuyingBait = false
                    end
                end)
            end
        end
    end)

    task.spawn(function() local lastSell = tick() while task.wait(1) do if State.AutoSellFish and (tick() - lastSell >= State.SellInterval) then pcall(function() ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/JobsRemoteFunction"):InvokeServer("FishingNPC", "SellFish") end) lastSell = tick() end end end)
    task.spawn(function() while task.wait(0.1) do if State.AutoRoll then local isVis, btn = isCloseButtonVisible() if isVis and btn then simulateClick(btn); task.wait(0.5) end end end end)
    
    task.spawn(function()
        while task.wait(1) do
            if State.AutoRoll then
                local isVis, _ = isCloseButtonVisible()
                if isVis then if not State.IsRolling then State.IsRolling = true; PauseFarms() end else
                    if State.IsRolling then State.IsRolling = false; task.wait(1); ResumeFarms() end
                    local succ, checkTime = pcall(function() return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "CheckTime", "DLCBoxData") end)
                    if succ and (checkTime == true or tostring(checkTime):lower():find("ready") or checkTime == 0) then
                        local mSucc, canBuy = pcall(function() return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "CheckCanBuyType", "DLCBoxData") end)
                        if mSucc and (canBuy == 1 or canBuy == true) then
                            if not State.IsRolling then State.IsRolling = true; PauseFarms() end
                            if pcall(function() return ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy", "DLCBoxData") end) then task.wait(5) else if State.IsRolling then State.IsRolling = false; ResumeFarms() end; task.wait(2) end
                        end
                    end
                end
            else if State.IsRolling then State.IsRolling = false; ResumeFarms() end end
        end
    end)

    task.spawn(function() local idx = 1 while true do if State.AutoStats then local toUp = {} for _, stat in ipairs({"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}) do if State.SelectedStats[stat] then table.insert(toUp, stat) end end if #toUp > 0 then if idx > #toUp then idx = 1 end pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("AddPoint", toUp[idx], State.StatsPoint) end) idx = idx + 1 end task.wait(5) else task.wait(1) end end end)

    task.spawn(function()
        while task.wait(1) do
            if State.AutoBuyDealer and State.TargetFruit then
                local cUTC = os.time(); local cCycle = math.floor(cUTC / 14400)
                if State.LastCheckedRestockTime ~= cCycle then
                    if (14400 - (cUTC % 14400)) > 14390 then task.wait(8) end
                    State.LastCheckedRestockTime = math.floor(os.time() / 14400) 
                    pcall(function()
                        local stock = ReplicatedStorage.Remotes.CommF_:InvokeServer("GetFruits", false)
                        if type(stock) == "table" then
                            for _, f in pairs(stock) do
                                if f.Name == State.TargetFruit and f.OnSale then
                                    if Plr.Data.Beli.Value >= f.Price then ReplicatedStorage.Remotes.CommF_:InvokeServer("PurchaseRawFruit", State.TargetFruit, false); State.AutoBuyDealer = false end
                                    break
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)

    Plr.Backpack.ChildAdded:Connect(function(i) if State.AutoStore and not State.attemptedFruits[i] then tryStoreFruit(i) end end)
    local function listenChar(c) c.ChildAdded:Connect(function(i) if State.AutoStore and i:IsA("Tool") and i.Name:lower():find("fruit") and not State.attemptedFruits[i] then tryStoreFruit(i) end end) end
    if Plr.Character then listenChar(Plr.Character) end
    Plr.CharacterAdded:Connect(listenChar)

    task.spawn(function()
        while task.wait(0.05) do
            pcall(function()
                if not State.AutoSeaEnabled then return end
                if IsPlayerDead() then Deps.SetFarmMode("Respawning"); task.wait(5); return end
                local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = Plr.Character and Plr.Character:FindFirstChild("Humanoid")
                if not root or not hum then return end
                local ActiveBoat = nil
                if hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") and hum.SeatPart.Parent.Parent == Workspace.Boats then ActiveBoat = hum.SeatPart.Parent end
                
                if not ActiveBoat then
                    Deps.SetFarmMode("GettingBoat")
                    local existingBoat = GetClosestOwnedBoat()
                    if existingBoat then
                        local seat = existingBoat:FindFirstChild("VehicleSeat")
                        if seat then root.CFrame = seat.CFrame * CFrame.new(0, 3, 0); task.wait(0.5); seat:Sit(hum); task.wait(1) end
                    else
                        local npcPos = CFrame.new(-16929, 8, 464)
                        if (root.Position - npcPos.Position).Magnitude > 20 then State.ActiveTween = SmartTween(root, npcPos * CFrame.new(0, 50, 0), State.ActiveTween) else
                            if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", State.SelectedBoatArg); task.wait(1.5)
                        end
                    end
                    return
                end

                Deps.SetFarmMode("AutoSea")
                local seat = ActiveBoat:FindFirstChild("VehicleSeat")
                if not seat then return end
                for _, v in pairs(ActiveBoat:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
                for _, p in pairs(Plr.Character:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end

                local currentLevel = GetCurrentDangerLevel()
                local moveSpeed = Settings.BoatSpeed / 20

                if State.TargetSeaLevel == 7 or currentLevel < State.TargetSeaLevel then
                    seat.CFrame = seat.CFrame * CFrame.new(0, 0, -moveSpeed)
                    State.BoatPatrolDist = 0
                else
                    if State.BoatPatrolDir == 1 then
                        seat.CFrame = seat.CFrame * CFrame.new(moveSpeed, 0, 0)
                        State.BoatPatrolDist = State.BoatPatrolDist + moveSpeed
                        if State.BoatPatrolDist >= 200 then State.BoatPatrolDir = -1 end
                    else
                        seat.CFrame = seat.CFrame * CFrame.new(-moveSpeed, 0, 0)
                        State.BoatPatrolDist = State.BoatPatrolDist - moveSpeed
                        if State.BoatPatrolDist <= -200 then State.BoatPatrolDir = 1 end
                    end
                end
            end)
        end
    end)

    task.spawn(function()
        while task.wait(0.2) do
            pcall(function()
                if not State.IslandTeleportEnabled or not State.SelectedIslandTarget then return end
                if IsPlayerDead() then task.wait(2); return end
                local root = Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local targetData = IslandData[State.SelectedIslandTarget]
                local inCursedShip = IsInsideCursedShip()
                local inSubmerged = IsInsideSubmerged()
                local inFishman = IsInsideFishmanIsland()

                if inCursedShip and targetData ~= "Special_CursedShip" then
                    if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-6508.558, 89.035, -132.84)); task.wait(2.5); return
                end
                if inSubmerged and targetData ~= "Special_Submerged" then
                    if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                    ReplicatedStorage.Net:WaitForChild("RF/SubmarineTransportation"):InvokeServer("InitiateTeleport", "Tiki Outpost"); task.wait(2.5); return
                end
                if inFishman and targetData ~= "Underwater City" then
                    if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(3864.69, 6.74, -1926.21)); task.wait(2.5); return
                end

                if type(targetData) == "string" then
                    if targetData == "Special_CursedShip" then
                        if not inCursedShip then
                            if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.213, 126.976, 32852.832)); task.wait(2.5)
                        else State.IslandTeleportEnabled = false; WindUI:Notify({Title="تلپورت انجام شد", Content="به Cursed Ship رسیدید!", Duration=3}) end
                    elseif targetData == "Special_Submerged" then
                        if not inSubmerged then
                            local npcPos = CFrame.new(-16271, 25, 1372)
                            if (root.Position - npcPos.Position).Magnitude > 20 then State.ActiveTween = SmartTween(root, npcPos, State.ActiveTween) else
                                if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                                ReplicatedStorage.Net:WaitForChild("RF/SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland"); task.wait(2.5)
                            end
                        else State.IslandTeleportEnabled = false; WindUI:Notify({Title="تلپورت انجام شد", Content="به Submerged Island رسیدید!", Duration=3}) end
                    end
                else
                    if Sea == 1 and targetData == IslandData["Underwater City"] and not inFishman then
                        if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.85, 11.68, 1819.78)); task.wait(2.5); return
                    end
                    local dist = (root.Position - targetData.Position).Magnitude
                    if dist > 20 then State.ActiveTween = SmartTween(root, targetData * CFrame.new(0, 40, 0), State.ActiveTween) else
                        if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end
                        State.IslandTeleportEnabled = false
                        WindUI:Notify({Title="تلپورت انجام شد", Content="به " .. State.SelectedIslandTarget .. " رسیدید!", Duration=3})
                    end
                end
            end)
        end
    end)

    return { 
        Set = function(k, v) State[k] = v end, 
        Get = function(k) return State[k] end,
        GetBoats = function() return BoatNames, BoatsMap end,
        GetIslands = function() return IslandNames end,
        CancelTweens = function() if State.ActiveTween then State.ActiveTween:Cancel(); State.ActiveTween = nil end end
    }
end

return ExtraModule
