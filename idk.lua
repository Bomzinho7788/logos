local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local plr = Players.LocalPlayer

local npcFolder = workspace:WaitForChild("Map")
    :WaitForChild("Zones")
    :WaitForChild("Field")
    :WaitForChild("NPC")

-- Lista de todos os tipos de NPC disponíveis em ordem de raridade (do mais raro ao mais comum)
local npcRarityOrder = {
    "Extinct",          -- Mais raro
    "Secret",
    "Brainrot God",
    "Mythic", 
    "Legendary",
    "Epic",
    "Rare",
    "Uncommon",
    "Common"           -- Mais comum
}

-- Configurações padrão
local config = {
    enabled = false,
    teleport = true,
    heightOffset = 3,
    tweenTime = 0.1,
    tweenStyle = Enum.EasingStyle.Linear,
    autoAttack = true,
    weaponName = "Basic Chainsaw",
    autoDetectWeapon = true,
    -- Tipos de NPC selecionados (todos desmarcados por padrão)
    npcTypes = {
        Common = false,
        Uncommon = false,
        Rare = false,
        Epic = false,
        Legendary = false,
        Mythic = false,
        ["Brainrot God"] = false,
        Secret = false,
        Extinct = false
    },
    -- Priorizar por raridade (do mais raro para o mais comum)
    priorityByRarity = true
}

local currentTarget = nil
local toolName = nil
local window = nil

-- Função para obter o índice de raridade do NPC (quanto menor o número, mais raro)
local function getNpcRarityIndex(npc)
    local rarityComp = npc:FindFirstChild("OverheadAttachment")
        and npc.OverheadAttachment:FindFirstChild("CharacterInfo")
        and npc.OverheadAttachment.CharacterInfo:FindFirstChild("Frame")
        and npc.OverheadAttachment.CharacterInfo.Frame:FindFirstChild("Rarity")

    if not rarityComp then
        return #npcRarityOrder + 1  -- Se não tiver raridade, considera como o menos prioritário
    end

    local rarityText = tostring(rarityComp.Text)
    
    -- Encontrar o índice na tabela de ordem de raridade
    for i, rarityName in ipairs(npcRarityOrder) do
        if rarityName == rarityText then
            return i  -- Quanto menor o índice, mais raro
        end
    end
    
    return #npcRarityOrder + 1  -- Se não encontrar, considera como menos prioritário
end

-- Função para verificar se NPC é do tipo selecionado
local function isSelectedNpcType(npc)
    local rarityComp = npc:FindFirstChild("OverheadAttachment")
        and npc.OverheadAttachment:FindFirstChild("CharacterInfo")
        and npc.OverheadAttachment.CharacterInfo:FindFirstChild("Frame")
        and npc.OverheadAttachment.CharacterInfo.Frame:FindFirstChild("Rarity")

    if not rarityComp then
        return false
    end

    local rarityText = tostring(rarityComp.Text)
    
    -- Verificar se o tipo está na lista de selecionados
    return config.npcTypes[rarityText] == true
end

-- Função para detectar a arma atual na mão do jogador
local function updateWeaponName()
    local char = plr.Character
    if not char then return end
    
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        toolName = tool.Name
        if config.autoDetectWeapon then
            config.weaponName = toolName
        end
    end
end

-- Pega NPC com base na prioridade (raridade primeiro, depois distância)
local function getPriorityNpc(hrp)
    local bestNpc = nil
    local bestRarityIndex = math.huge
    local bestDistance = math.huge
    
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model")
            and npc:FindFirstChild("HumanoidRootPart")
            and isSelectedNpcType(npc)
        then
            local rarityIndex = getNpcRarityIndex(npc)
            local distance = (npc.HumanoidRootPart.Position - hrp.Position).Magnitude
            
            -- Priorizar por raridade primeiro
            if config.priorityByRarity then
                if rarityIndex < bestRarityIndex then
                    bestRarityIndex = rarityIndex
                    bestDistance = distance
                    bestNpc = npc
                elseif rarityIndex == bestRarityIndex then
                    -- Se a raridade for igual, pega o mais próximo
                    if distance < bestDistance then
                        bestDistance = distance
                        bestNpc = npc
                    end
                end
            else
                -- Se não estiver priorizando por raridade, pega o mais próximo
                if distance < bestDistance then
                    bestDistance = distance
                    bestNpc = npc
                end
            end
        end
    end
    
    return bestNpc
end

-- Checar se o NPC ainda tá vivo
local function npcAlive(npc)
    local guiVal = npc:FindFirstChild("OverheadAttachment")
        and npc.OverheadAttachment:FindFirstChild("CharacterInfo")
        and npc.OverheadAttachment.CharacterInfo:FindFirstChild("Frame")
        and npc.OverheadAttachment.CharacterInfo.Frame:FindFirstChild("Health")
        and npc.OverheadAttachment.CharacterInfo.Frame.Health:FindFirstChild("Amount")

    if not guiVal then
        return false
    end

    local text = tostring(guiVal.Text)
    local current = tonumber(text:match("(%d+)/"))
    return current and current > 0
end

-- Atacar
local function hit(npc)
    local weaponToUse = config.weaponName
    local args = {
        npc,
        weaponToUse
    }
    Replicated.Remotes.Field.DamageNPC:InvokeServer(unpack(args))
end

-- Mover pro alvo
local function goTo(hrp, npc)
    if not config.teleport then return end
    
    local pos = npc.HumanoidRootPart.Position + Vector3.new(0, config.heightOffset, 0)
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(config.tweenTime, config.tweenStyle),
        { CFrame = CFrame.new(pos) }
    )
    tween:Play()
end

-- Verificar se pelo menos um tipo está selecionado
local function hasSelectedNpcTypes()
    for _, selected in pairs(config.npcTypes) do
        if selected then
            return true
        end
    end
    return false
end

-- Criar UI
local function createUI()
    window = Rayfield:CreateWindow({
        Name = "Auto Farm NPC Prioritário",
        LoadingTitle = "Carregando...",
        LoadingSubtitle = "por Comunidade",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "AutoFarmNPC",
            FileName = "Config"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true
        },
        KeySystem = false,
    })

    -- Tab principal
    local mainTab = window:CreateTab("Principal")

    -- Toggle principal
    mainTab:CreateToggle({
        Name = "Ativar Auto Farm",
        CurrentValue = config.enabled,
        Flag = "ToggleAutoFarm",
        Callback = function(value)
            if value and not hasSelectedNpcTypes() then
                Rayfield:Notify({
                    Title = "Erro",
                    Content = "Selecione pelo menos um tipo de NPC primeiro!",
                    Duration = 5,
                    Image = 4483362458
                })
                window:GetToggle("ToggleAutoFarm"):Set(false)
                return
            end
            config.enabled = value
            if value then
                Rayfield:Notify({
                    Title = "Auto Farm",
                    Content = "Ativado! Priorizando NPCs mais raros.",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Auto Farm",
                    Content = "Desativado!",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })

    -- Toggle para priorizar por raridade
    mainTab:CreateToggle({
        Name = "Priorizar por Raridade",
        CurrentValue = config.priorityByRarity,
        Flag = "TogglePriorityRarity",
        Callback = function(value)
            config.priorityByRarity = value
            if value then
                Rayfield:Notify({
                    Title = "Prioridade",
                    Content = "Priorizando NPCs mais raros primeiro!",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Prioridade",
                    Content = "Priorizando NPCs mais próximos primeiro!",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })

    -- Seção de Tipos de NPC (em ordem de raridade)
    mainTab:CreateSection("Tipos de NPC (Ordem de Raridade)")
    
    -- Criar toggles para cada tipo de NPC em ordem de raridade
    local toggleRefs = {}
    for _, npcType in ipairs(npcRarityOrder) do
        local toggle = mainTab:CreateToggle({
            Name = npcType .. (npcType == "Extinct" and " ⭐" or ""),
            CurrentValue = config.npcTypes[npcType] or false,
            Flag = "ToggleNPC_" .. npcType:gsub("%s+", ""),
            Callback = function(value)
                config.npcTypes[npcType] = value
                toggleRefs[npcType] = toggle
            end
        })
        toggleRefs[npcType] = toggle
    end

    -- Seção de Configurações
    mainTab:CreateSection("Configurações")

    -- Toggle para teleporte
    mainTab:CreateToggle({
        Name = "Ativar Teleporte",
        CurrentValue = config.teleport,
        Flag = "ToggleTeleport",
        Callback = function(value)
            config.teleport = value
        end
    })

    -- Toggle para auto ataque
    mainTab:CreateToggle({
        Name = "Auto Ataque",
        CurrentValue = config.autoAttack,
        Flag = "ToggleAutoAttack",
        Callback = function(value)
            config.autoAttack = value
        end
    })

    -- Slider para offset de altura
    mainTab:CreateSlider({
        Name = "Offset de Altura (Studs)",
        Range = {0, 10},
        Increment = 0.5,
        Suffix = "studs",
        CurrentValue = config.heightOffset,
        Flag = "SliderHeightOffset",
        Callback = function(value)
            config.heightOffset = value
        end
    })

    -- Slider para tempo do tween
    mainTab:CreateSlider({
        Name = "Velocidade do Teleporte",
        Range = {0.05, 1},
        Increment = 0.05,
        Suffix = "segundos",
        CurrentValue = config.tweenTime,
        Flag = "SliderTweenTime",
        Callback = function(value)
            config.tweenTime = value
        end
    })

    -- Dropdown para estilo do tween
    local easingStyles = {
        "Linear",
        "Sine",
        "Back",
        "Quad",
        "Quart",
        "Quint",
        "Bounce",
        "Elastic",
        "Exponential",
        "Circular",
        "Cubic"
    }

    mainTab:CreateDropdown({
        Name = "Suavidade do Teleporte",
        Options = easingStyles,
        CurrentOption = "Linear",
        Flag = "DropdownTweenStyle",
        Callback = function(option)
            config.tweenStyle = Enum.EasingStyle[option]
        end
    })

    -- Tab de Arma
    local weaponTab = window:CreateTab("Arma")

    -- Toggle para detecção automática
    weaponTab:CreateToggle({
        Name = "Detectar Arma Automaticamente",
        CurrentValue = config.autoDetectWeapon,
        Flag = "ToggleAutoDetect",
        Callback = function(value)
            config.autoDetectWeapon = value
            if value then
                updateWeaponName()
            end
        end
    })

    -- Input para nome da arma
    local weaponInput = weaponTab:CreateInput({
        Name = "Nome da Arma",
        PlaceholderText = config.weaponName,
        RemoveTextAfterFocusLost = false,
        Flag = "InputWeaponName",
        Callback = function(text)
            if text and text ~= "" then
                config.weaponName = text
            end
        end
    })

    -- Botão para atualizar arma atual
    weaponTab:CreateButton({
        Name = "Pegar Arma Atual",
        Callback = function()
            updateWeaponName()
            weaponInput:Set(config.weaponName)
            Rayfield:Notify({
                Title = "Arma Atualizada",
                Content = "Arma definida como: " .. config.weaponName,
                Duration = 5,
                Image = 4483362458
            })
        end
    })

    -- Botão para setar denovo
    weaponTab:CreateButton({
        Name = "Setar Novamente",
        Callback = function()
            if toolName then
                config.weaponName = toolName
                weaponInput:Set(toolName)
                Rayfield:Notify({
                    Title = "Arma Resetada",
                    Content = "Arma resetada para: " .. toolName,
                    Duration = 5,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Erro",
                    Content = "Nenhuma arma detectada! Equipe uma arma primeiro.",
                    Duration = 5,
                    Image = 4483362458
                })
            end
        end
    })
end

-- Loop principal de farm
task.spawn(function()
    while task.wait(0) do
        if not config.enabled or not hasSelectedNpcTypes() then
            currentTarget = nil
            task.wait(0.1)
            continue
        end
        
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        -- Atualizar nome da arma se autoDetect estiver ativado
        if config.autoDetectWeapon then
            updateWeaponName()
        end

        -- Se tem alvo e ainda é do tipo selecionado e tá vivo → continua
        if currentTarget
            and currentTarget.Parent
            and isSelectedNpcType(currentTarget)
            and npcAlive(currentTarget)
        then
            goTo(hrp, currentTarget)
            if config.autoAttack then
                hit(currentTarget)
            end
            continue
        end

        -- Se não tem mais alvo → limpa
        currentTarget = nil

        -- Tenta pegar um novo NPC com base na prioridade
        local newTarget = getPriorityNpc(hrp)

        -- Se não existir NENHUM NPC dos tipos selecionados → não faz nada
        if not newTarget then
            continue
        end

        -- Se achou um → vira alvo
        currentTarget = newTarget
        goTo(hrp, newTarget)
        if config.autoAttack then
            hit(newTarget)
        end
    end
end)

-- Detectar quando o jogador equipa/desequipa uma arma
plr.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and config.autoDetectWeapon then
            updateWeaponName()
        end
    end)
    
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and config.autoDetectWeapon then
            task.wait(0.1)
            updateWeaponName()
        end
    end)
end)

-- Criar UI
createUI()

-- Atualizar arma inicial
updateWeaponName()

-- Notificação inicial
Rayfield:Notify({
    Title = "Auto Farm NPC Prioritário",
    Content = "Script carregado com sucesso!\nPriorizando NPCs mais raros primeiro.",
    Duration = 6,
    Image = 4483362458
})
