--========================================================--
--   Interface Pet Sims X - Feito por Bomzinho e GPT5     --
--========================================================--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local EggsDir = ReplicatedStorage:WaitForChild("__DIRECTORY"):WaitForChild("Eggs")

-- REMOTES CORRETOS --------------------------
local Things = workspace:WaitForChild("__THINGS")
local Remotes = Things:WaitForChild("__REMOTES")
local EggRemote = Remotes:WaitForChild("buy egg")
local DiamondRemote = Remotes:WaitForChild("buy diamondpack")
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
local SettingsTab = Window:CreateTab("Settings")

-------------------------------------------------
-- VARS
-------------------------------------------------
local SelectedArea = nil
local SelectedEgg = nil
local ManualNameEnabled = false
local ManualNameValue = ""
local SelectedAmount = 1
local SelectedDelay = 1
local AutoOpenEnabled = false
local AutoOpening = false

-- DIAMONDS
local DiamondPacks = {} -- Será preenchido dinamicamente
local SelectedDiamond = nil
local AutoBuyDiamonds = false
local AutoBuyDelay = 1

-- Moedas
local CurrencyIcons = {
    ["rbxassetid://6501310411"] = "Coins",
    ["rbxassetid://6501310291"] = "Fantasy Coins", 
    ["rbxassetid://6501310518"] = "Tech Coins"
}

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
-- VERIFICAR SE EGGSDIR EXISTE
-------------------------------------------------
if not EggsDir then
    Notify("Erro", "Não foi possível encontrar Eggs em __DIRECTORY")
    EggsDir = Instance.new("Folder")
else
    Notify("Sucesso", "Eggs encontrado em __DIRECTORY")
end

-------------------------------------------------
-- DETECTAR INFO DOS PACKS DE DIAMANTES
-------------------------------------------------
local function GetDiamondPackInfo(packName)
    local gui = Player.PlayerGui:FindFirstChild("Diamonds Animation")
    if not gui then return nil end
    
    local shop = gui:FindFirstChild("ExclusiveShop")
    if not shop then return nil end
    
    local container = shop.Frame:FindFirstChild("Container")
    if not container then return nil end
    
    local diamonds = container:FindFirstChild("Diamonds")
    if not diamonds then return nil end
    
    if packName == "Tech Diamonds" then
        -- Pack 4 (Tech Diamonds) - BestCurrency
        local bestCurrency = diamonds:FindFirstChild("BestCurrency")
        if bestCurrency and bestCurrency:IsA("TextButton") then
            local amount = bestCurrency:FindFirstChild("Amount")
            local price = bestCurrency:FindFirstChild("Price")
            
            if amount and price then
                local robux = price:FindFirstChild("Robux")
                local icon = price:FindFirstChild("RobuxIcon")
                
                if robux and icon then
                    local currencyType = CurrencyIcons[icon.Image] or "Unknown"
                    return {
                        DisplayName = "Tech Diamonds",
                        Amount = amount.Text,
                        Price = robux.Text,
                        Currency = currencyType,
                        PackId = 4
                    }
                end
            end
        end
    else
        -- Packs 1-3 (Tiny, Medium, Large) - CurrencyGroup
        local currencyGroup = diamonds:FindFirstChild("CurrencyGroup")
        if currencyGroup then
            for _, child in ipairs(currencyGroup:GetChildren()) do
                if child:IsA("TextButton") and child.Name == "Currency" then
                    local title = child:FindFirstChild("Title")
                    if title and title.Text == packName then
                        local amount = child:FindFirstChild("Amount")
                        local price = child:FindFirstChild("Price")
                        
                        if amount and price then
                            local robux = price:FindFirstChild("Robux")
                            local icon = price:FindFirstChild("RobuxIcon")
                            
                            if robux and icon then
                                local currencyType = CurrencyIcons[icon.Image] or "Unknown"
                                
                                -- Determinar PackId baseado no nome
                                local packId = 0
                                if packName == "Tiny" then
                                    packId = 1
                                elseif packName == "Medium" then
                                    packId = 2
                                elseif packName == "Large" then
                                    packId = 3
                                end
                                
                                return {
                                    DisplayName = packName .. " Diamonds",
                                    Amount = amount.Text,
                                    Price = robux.Text,
                                    Currency = currencyType,
                                    PackId = packId
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return nil
end

-- Função para obter todos os packs disponíveis com formato bonito
local function GetAllDiamondPacks()
    local packs = {}
    local packInfoList = {}
    
    local gui = Player.PlayerGui
    
    if gui and gui:FindFirstChild("ExclusiveShop") then
        local container = gui.ExclusiveShop.Frame.Container
        local diamonds = container and container.Diamonds
        
        if diamonds then
            -- Verificar BestCurrency (Tech Diamonds)
            local bestCurrency = diamonds:FindFirstChild("BestCurrency")
            if bestCurrency and bestCurrency:IsA("TextButton") then
                local amount = bestCurrency:FindFirstChild("Amount")
                local price = bestCurrency:FindFirstChild("Price")
                
                if amount and price then
                    local robux = price:FindFirstChild("Robux")
                    local icon = price:FindFirstChild("RobuxIcon")
                    
                    if robux and icon then
                        local currencyType = CurrencyIcons[icon.Image] or "Unknown"
                        local displayText = string.format("Tech Diamonds | %s | %s | ID: 4", 
                            amount.Text, robux.Text .. " " .. currencyType)
                        
                        table.insert(packs, displayText)
                        packInfoList[displayText] = {
                            DisplayName = "Tech Diamonds",
                            Amount = amount.Text,
                            Price = robux.Text,
                            Currency = currencyType,
                            PackId = 4
                        }
                    end
                end
            end
            
            -- Verificar CurrencyGroup (Tiny, Medium, Large)
            local currencyGroup = diamonds:FindFirstChild("CurrencyGroup")
            if currencyGroup then
                for _, child in ipairs(currencyGroup:GetChildren()) do
                    if child:IsA("TextButton") and child.Name == "Currency" then
                        local title = child:FindFirstChild("Title")
                        local amount = child:FindFirstChild("Amount")
                        local price = child:FindFirstChild("Price")
                        
                        if title and amount and price then
                            local robux = price:FindFirstChild("Robux")
                            local icon = price:FindFirstChild("RobuxIcon")
                            
                            if robux and icon then
                                local currencyType = CurrencyIcons[icon.Image] or "Unknown"
                                
                                -- Determinar PackId baseado no nome
                                local packId = 0
                                if title.Text == "Tiny" then
                                    packId = 1
                                elseif title.Text == "Medium" then
                                    packId = 2
                                elseif title.Text == "Large" then
                                    packId = 3
                                end
                                
                                local displayText = string.format("%s Diamonds | %s | %s | ID: %d", 
                                    title.Text, amount.Text, robux.Text .. " " .. currencyType, packId)
                                
                                table.insert(packs, displayText)
                                packInfoList[displayText] = {
                                    DisplayName = title.Text .. " Diamonds",
                                    Amount = amount.Text,
                                    Price = robux.Text,
                                    Currency = currencyType,
                                    PackId = packId
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return packs, packInfoList
end

-------------------------------------------------
-- ATUALIZAR LISTA DE DIAMANTES DINAMICAMENTE
-------------------------------------------------
local DiamondPackInfoList = {}

local function UpdateDiamondPacks()
    local availablePacks, packInfo = GetAllDiamondPacks()
    DiamondPacks = availablePacks
    DiamondPackInfoList = packInfo
    return availablePacks
end

-------------------------------------------------
-- BUILD DE ARGUMENTO DE OVO (FORMATO REAL)
-------------------------------------------------
local function BuildEggArgs()
    local egg = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not egg then return end

    return {
        {
            egg,
            (SelectedAmount == 3),
            (SelectedAmount == 8)
        }
    }
end

-------------------------------------------------
-- UPDATE LISTA DE OVOS
-------------------------------------------------
local EggDropdown = nil

local function UpdateEggList()
    if not SelectedArea then return end
    
    -- Verificar se EggsDir existe
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
    Options = {"1", "3", "8"},
    CurrentOption = {"1"},
    Callback = function(opt)
        SelectedAmount = tonumber(opt[1])
        Notify("Quantidade", "Abrir " .. opt[1] .. " ovos")
    end
})

EggsTab:CreateSlider({
    Name = "Delay (segundos)",
    Range = {0.1, 10},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v)
        SelectedDelay = v
        Notify("Delay", string.format("%.1f segundos", v))
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
local DiamondInfoLabel = DiamondsTab:CreateLabel("Atualize a lista para ver os packs disponíveis")

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
                DiamondInfoLabel:Set(
                    string.format(
                        "Pack: %s\nQuantidade: %s diamantes\nPreço: %s %s\nID do Pack: %d",
                        SelectedPackInfo.DisplayName,
                        SelectedPackInfo.Amount,
                        SelectedPackInfo.Price,
                        SelectedPackInfo.Currency,
                        SelectedPackInfo.PackId
                    ), 
                    4483362458, 
                    Color3.fromRGB(255, 255, 255), 
                    false
                )
                Notify("Pack Selecionado", SelectedPackInfo.DisplayName)
            else
                DiamondInfoLabel:Set("Informações do pack não disponíveis", 4483362458, Color3.fromRGB(255, 255, 255), false)
            end
        end
    })
    
    if #DiamondPacks > 0 and DiamondPackInfoList[DiamondPacks[1]] then
        SelectedPackInfo = DiamondPackInfoList[DiamondPacks[1]]
        DiamondInfoLabel:Set(
            string.format(
                "Pack: %s\nQuantidade: %s diamantes\nPreço: %s %s\nID do Pack: %d",
                SelectedPackInfo.DisplayName,
                SelectedPackInfo.Amount,
                SelectedPackInfo.Price,
                SelectedPackInfo.Currency,
                SelectedPackInfo.PackId
            ), 
            4483362458, 
            Color3.fromRGB(255, 255, 255), 
            false
        )
    end
end

-- Criar dropdown inicial
CreateDiamondDropdown()

DiamondsTab:CreateSlider({
    Name = "Delay entre compras (segundos)",
    Range = {0.5, 10},
    Increment = 0.5,
    CurrentValue = 1,
    Callback = function(v)
        AutoBuyDelay = v
        Notify("Delay", string.format("%.1f segundos", v))
    end
})

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
                        {SelectedPackInfo.PackId}
                    }
                    
                    local success, errorMsg = pcall(function()
                        DiamondRemote:InvokeServer(unpack(args))
                    end)
                    
                    if success then
                        count = count + 1
                        Notify("Comprado", SelectedPackInfo.DisplayName .. " (" .. count .. ")")
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
            {SelectedPackInfo.PackId}
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
-- SETTINGS
-------------------------------------------------

SettingsTab:CreateDropdown({
    Name = "Tema",
    Options = {"Default","Aether","Discord","Dark","Light","Midnight","Aqua"},
    CurrentOption = {"Default"},
    Callback = function(opt)
        Rayfield:LoadTheme(opt[1])
        Notify("Tema", "Tema alterado para: " .. opt[1])
    end
})

SettingsTab:CreateToggle({
    Name = "Animações",
    CurrentValue = true,
    Callback = function(v)
        Rayfield:ToggleAnimations(v)
        Notify("Animações", v and "Ativadas" or "Desativadas")
    end
})

SettingsTab:CreateToggle({
    Name = "Notificações",
    CurrentValue = true,
    Callback = function(v)
        Notify("Notificações", v and "Ativadas" or "Desativadas")
    end
})

SettingsTab:CreateButton({
    Name = "Salvar configurações",
    Callback = function()
        Rayfield:SaveConfiguration()
        Notify("Salvo", "Configurações salvas com sucesso.")
    end
})

SettingsTab:CreateButton({
    Name = "Recarregar Interface",
    Callback = function()
        Notify("Recarregando", "A interface será recarregada...")
        wait(1)
        Rayfield:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/seu-repositorio/script.lua"))()
    end
})

SettingsTab:CreateButton({
    Name = "Fechar Interface",
    Callback = function()
        Rayfield:Destroy()
        Notify("Interface", "Interface fechada")
    end
})

-------------------------------------------------

Notify("Pronto", "Interface Pet Sims X carregada!")
if #DiamondPacks > 0 then
    Notify("Packs Encontrados", string.format("%d packs de diamantes disponíveis", #DiamondPacks))
else
    Notify("Aviso", "Nenhum pack de diamantes encontrado. Clique em 'Atualizar lista'")
end

-- Verificar se EggsDir tem conteúdo
if EggsDir and EggsDir.Name ~= "Folder" then
    local eggCount = 0
    for _, area in ipairs(EggsDir:GetChildren()) do
        if area:IsA("Folder") then
            eggCount = eggCount + 1
        end
    end
    Notify("Eggs", string.format("%d áreas de ovos encontradas", eggCount))
else
    Notify("Aviso", "Diretório de eggs não encontrado em __DIRECTORY")
end
