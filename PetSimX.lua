--========================================================--
--   Interface Pet Sims X - Feito por Bomzinho e GPT5     --
--========================================================--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- REMOTES CORRETOS --------------------------
local THINGS = workspace:WaitForChild("__THINGS")
local ORBS = THINGS:WaitForChild("Orbs")
local REMOTES = THINGS:WaitForChild("__REMOTES")
local EggRemote = REMOTES:WaitForChild("buy egg")
local DiamondRemote = REMOTES:WaitForChild("buy diamondpack")
local CLAIM = REMOTES:WaitForChild("claim orbs")
------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

Rayfield:LoadConfiguration()

local Window = Rayfield:CreateWindow({
    Name = "Pet Sims X",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Feito por Bomzinho e GPT5",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PetSimsX",
        FileName = "SettingsOnly"
    }
})

local EggsTab = Window:CreateTab("Eggs")
local DiamondsTab = Window:CreateTab("Diamantes")
local OrbsTab = Window:CreateTab("Orbs Auto Collect")

-------------------------------------------------
-- VARS
-------------------------------------------------
local SelectedArea = nil
local SelectedEgg = nil
local ManualNameEnabled = false
local ManualNameValue = ""
local SelectedAmount = 1
local SelectedDelay = 0
local AutoOpenEnabled = false
local AutoOpening = false

-- DIAMONDS
local DiamondPacks = {} -- Será preenchido dinamicamente
local SelectedDiamond = nil
local AutoBuyDiamonds = false
local AutoBuyDelay = 0

-- ORBS
local AutoCollectOrbs = false

-------------------------------------------------
-- NOTIFICAÇÕES
-------------------------------------------------

local function Notify(title, text)
    Rayfield:Notify({
        Title = title,
        Content = text,
        Duration = 3
    })
end

-------------------------------------------------
-- VERIFICAR SE EGGS EXISTEM
-------------------------------------------------
local EggsDir = ReplicatedStorage:FindFirstChild("Game") and ReplicatedStorage.Game:FindFirstChild("Eggs")
if not EggsDir then
    Notify("Aviso", "Diretório de eggs não encontrado em ReplicatedStorage.Game")
    EggsDir = Instance.new("Folder")
else
    Notify("Sucesso", "Eggs encontrado")
end

-------------------------------------------------
-- DETECTAR INFO DOS PACKS DE DIAMANTES
-------------------------------------------------
local function GetAllDiamondPacks()
    local packs = {}
    local packInfoList = {}
    
    -- Packs pré-definidos (IDs 1-4)
    local predefinedPacks = {
        {
            DisplayName = "Tiny Diamonds",
            PackId = 1
        },
        {
            DisplayName = "Medium Diamonds", 
            PackId = 2
        },
        {
            DisplayName = "Large Diamonds",
            PackId = 3
        },
        {
            DisplayName = "Tech Diamonds",
            PackId = 4
        }
    }
    
    for _, pack in ipairs(predefinedPacks) do
        local displayText = string.format("%s | ID: %d", pack.DisplayName, pack.PackId)
        table.insert(packs, displayText)
        packInfoList[displayText] = {
            DisplayName = pack.DisplayName,
            PackId = pack.PackId
        }
    end
    
    return packs, packInfoList
end

-------------------------------------------------
-- ATUALIZAR LISTA DE DIAMANTES
-------------------------------------------------
local DiamondPackInfoList = {}

local function UpdateDiamondPacks()
    local availablePacks, packInfo = GetAllDiamondPacks()
    DiamondPacks = availablePacks
    DiamondPackInfoList = packInfo
    return availablePacks
end

-------------------------------------------------
-- BUILD DE ARGUMENTO DE OVO (FORMATO CORRETO)
-------------------------------------------------
local function BuildEggArgs()
    local egg = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not egg then return end

    return {
        {
            {
                egg,
                (SelectedAmount == 3)
            },
            {
                false,
                false
            }
        }
    }
end

-------------------------------------------------
-- UPDATE LISTA DE OVOS
-------------------------------------------------
local EggDropdown = nil

local function UpdateEggList()
    if not SelectedArea then return end
    
    if not EggsDir or EggsDir.Name == "Folder" then
        Notify("Erro", "Diretório de eggs não encontrado")
        return
    end
    
    local area = EggsDir:FindFirstChild(SelectedArea)
    if not area then 
        Notify("Erro", "Área não encontrada: " .. SelectedArea)
        return 
    end

    local list = {}
    for _, egg in ipairs(area:GetChildren()) do
        if egg:IsA("Folder") then
            table.insert(list, egg.Name)
        end
    end

    if EggDropdown then 
        EggDropdown:Refresh(list)
        Notify("Atualizado", string.format("%d ovos encontrados em %s", #list, SelectedArea))
    end
end

-------------------------------------------------
-- UI EGGS
-------------------------------------------------

EggsTab:CreateDropdown({
    Name = "Selecionar área",
    Options = (function()
        local t = {}
        if EggsDir and EggsDir.Name ~= "Folder" then
            for _, f in ipairs(EggsDir:GetChildren()) do
                if f:IsA("Folder") then 
                    table.insert(t, f.Name) 
                end
            end
        else
            table.insert(t, "Diretório não encontrado")
        end
        return t
    end)(),
    CurrentOption = {},
    Callback = function(opt)
        SelectedArea = opt[1]
        if SelectedArea ~= "Diretório não encontrado" then
            UpdateEggList()
        end
    end
})

EggDropdown = EggsTab:CreateDropdown({
    Name = "Selecionar ovo",
    Options = {},
    CurrentOption = {},
    Callback = function(opt)
        SelectedEgg = opt[1]
        if SelectedEgg then
            Notify("Ovo Selecionado", SelectedEgg)
        end
    end
})

EggsTab:CreateToggle({
    Name = "Nome manual",
    CurrentValue = false,
    Callback = function(v)
        ManualNameEnabled = v
        if v then
            Notify("Modo Manual", "Digite o nome exato do ovo")
        end
    end
})

EggsTab:CreateInput({
    Name = "Nome exato do ovo",
    PlaceholderText = "Ex: Cracked Egg",
    Callback = function(t)
        ManualNameValue = t
        Notify("Nome Definido", "Ovo: " .. t)
    end
})

EggsTab:CreateDropdown({
    Name = "Quantidade",
    Options = {"1", "3"},
    CurrentOption = {"1"},
    Callback = function(opt)
        SelectedAmount = tonumber(opt[1])
        Notify("Quantidade", "Abrir " .. opt[1] .. " ovos")
    end
})

EggsTab:CreateToggle({
    Name = "Auto abrir ovos",
    CurrentValue = false,
    Callback = function(v)
        AutoOpenEnabled = v
        if v and not AutoOpening then
            AutoOpening = true
            Notify("Iniciando", "Auto open ligado")
            task.spawn(function()
                local count = 0
                while AutoOpenEnabled do
                    local args = BuildEggArgs()
                    if args then
                        local success, errorMsg = pcall(function()
                            EggRemote:InvokeServer(unpack(args))
                        end)
                        
                        if success then
                            count = count + 1
                            if count % 10 == 0 then
                                Notify("Progresso", string.format("%d ovos abertos", count))
                            end
                        else
                            Notify("Erro", "Falha ao abrir ovo: " .. tostring(errorMsg))
                        end
                    end
                    task.wait(SelectedDelay)
                end
                AutoOpening = false
                Notify("Finalizado", string.format("Total: %d ovos abertos", count))
            end)
        else
            Notify("Auto Open", "Desligado")
        end
    end
})

EggsTab:CreateButton({
    Name = "Abrir 1 ovo agora",
    Callback = function()
        local args = BuildEggArgs()
        if args then
            local success, errorMsg = pcall(function()
                EggRemote:InvokeServer(unpack(args))
            end)
            
            if success then
                Notify("Sucesso", "Ovo aberto!")
            else
                Notify("Erro", "Falha: " .. tostring(errorMsg))
            end
        else
            Notify("Erro", "Selecione um ovo primeiro")
        end
    end
})

-------------------------------------------------
-- UI DIAMANTES
-------------------------------------------------

-- Atualizar lista de packs dinamicamente
local availablePacks = UpdateDiamondPacks()

local DiamondDropdown = nil
local SelectedPackInfo = nil

-- Função para criar/atualizar o dropdown
local function CreateDiamondDropdown()
    if DiamondDropdown then
        DiamondDropdown:Destroy()
    end
    
    DiamondDropdown = DiamondsTab:CreateDropdown({
        Name = "Selecionar Pack de Diamantes",
        Options = DiamondPacks,
        CurrentOption = DiamondPacks[1] and {DiamondPacks[1]} or {},
        Callback = function(opt)
            local selectedOption = opt[1]
            SelectedDiamond = selectedOption
            SelectedPackInfo = DiamondPackInfoList[selectedOption]
            
            if SelectedPackInfo then
                Notify("Pack Selecionado", SelectedPackInfo.DisplayName .. " (ID: " .. SelectedPackInfo.PackId .. ")")
            end
        end
    })
end

-- Criar dropdown inicial
CreateDiamondDropdown()

DiamondsTab:CreateToggle({
    Name = "Comprar automaticamente",
    CurrentValue = false,
    Callback = function(v)
        AutoBuyDiamonds = v
        if v then
            if not SelectedPackInfo then
                Notify("Erro", "Selecione um pack primeiro")
                return
            end
            
            Notify("Iniciando", "Auto compra ligada - " .. SelectedPackInfo.DisplayName)
            task.spawn(function()
                local count = 0
                while AutoBuyDiamonds and SelectedPackInfo do
                    local args = {
                        {
                            {
                                SelectedPackInfo.PackId
                            },
                            {
                                false
                            }
                        }
                    }
                    
                    local success, errorMsg = pcall(function()
                        DiamondRemote:InvokeServer(unpack(args))
                    end)
                    
                    if success then
                        count = count + 1
                        if count % 5 == 0 then
                            Notify("Comprado", SelectedPackInfo.DisplayName .. " (" .. count .. ")")
                        end
                    else
                        Notify("Erro", "Falha na compra: " .. tostring(errorMsg))
                    end
                    
                    task.wait(AutoBuyDelay)
                end
                Notify("Finalizado", string.format("Total: %d packs comprados", count))
            end)
        else
            Notify("Auto Compra", "Desligada")
        end
    end
})

DiamondsTab:CreateButton({
    Name = "Comprar 1 vez",
    Callback = function()
        if not SelectedPackInfo then
            Notify("Erro", "Selecione um pack primeiro.")
            return
        end

        local args = {
            {
                {
                    SelectedPackInfo.PackId
                },
                {
                    false
                }
            }
        }
        
        local success, errorMsg = pcall(function()
            DiamondRemote:InvokeServer(unpack(args))
        end)
        
        if success then
            Notify("Sucesso", SelectedPackInfo.DisplayName .. " comprado!")
        else
            Notify("Erro", "Falha: " .. tostring(errorMsg))
        end
    end
})

DiamondsTab:CreateButton({
    Name = "Atualizar lista de packs",
    Callback = function()
        UpdateDiamondPacks()
        CreateDiamondDropdown()
        Notify("Atualizado", "Lista de packs atualizada: " .. #DiamondPacks .. " packs encontrados")
    end
})

-------------------------------------------------
-- UI ORBS AUTO COLLECT
-------------------------------------------------

OrbsTab:CreateToggle({
    Name = "Auto Collect Orbs",
    CurrentValue = false,
    Callback = function(v)
        AutoCollectOrbs = v
        if v then
            Notify("Iniciando", "Auto Collect Orbs ligado")
            task.spawn(function()
                while AutoCollectOrbs do
                    for _, orb in ipairs(ORBS:GetChildren()) do
                        local orbName = orb.Name
                        
                        local args = {
                            {
                                {
                                    {
                                        orbName
                                    }
                                },
                                {
                                    false
                                }
                            }
                        }
                        
                        CLAIM:FireServer(unpack(args))
                    end
                    task.wait(0)
                end
                Notify("Finalizado", "Auto Collect Orbs desligado")
            end)
        else
            Notify("Auto Collect Orbs", "Desligado")
        end
    end
})

OrbsTab:CreateButton({
    Name = "Collect Orbs Agora",
    Callback = function()
        local collected = 0
        for _, orb in ipairs(ORBS:GetChildren()) do
            local orbName = orb.Name
            
            local args = {
                {
                    {
                        {
                            orbName
                        }
                    },
                    {
                        false
                    }
                }
            }
            
            local success = pcall(function()
                CLAIM:FireServer(unpack(args))
            end)
            
            if success then
                collected = collected + 1
            end
        end
        Notify("Coletado", string.format("%d orbs coletados", collected))
    end
})

-------------------------------------------------

Notify("Pronto", "Interface Pet Sims X carregada!")

if EggsDir and EggsDir.Name ~= "Folder" then
    local eggCount = 0
    for _, area in ipairs(EggsDir:GetChildren()) do
        if area:IsA("Folder") then
            eggCount = eggCount + 1
        end
    end
    Notify("Eggs", string.format("%d áreas de ovos encontradas", eggCount))
else
    Notify("Aviso", "Diretório de eggs não encontrado")
end

Notify("Packs de Diamantes", "4 packs disponíveis (IDs 1-4)")
