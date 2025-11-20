--========================================================--
--   Interface Pet Sims X - Feito por Bomzinho e GPT5     --
--========================================================--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggsDir = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Eggs")

local buyEgg = workspace:WaitForChild("__THINGS")
    :WaitForChild("__REMOTES")
    :WaitForChild("buy egg")

local buyDiamond = workspace:WaitForChild("__THINGS")
    :WaitForChild("__REMOTES")
    :WaitForChild("buy diamondpack")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

----------------------------------------------------------------
-- CONFIGURAÇÃO SALVA (APENAS SETTINGS)
----------------------------------------------------------------

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

----------------------------------------------------------------
-- VARIÁVEIS GERAIS
----------------------------------------------------------------

-- Eggs
local SelectedArea = nil
local SelectedEgg = nil
local ManualNameEnabled = false
local ManualNameValue = ""
local SelectedAmount = 1
local SelectedDelay = 1
local AutoOpenEnabled = false
local AutoOpening = false

-- Diamonds
local DiamondPacks = {
    [1] = { name = "Tiny Packs", costText = "5B Moedas", gemsText = "25k gemas", id = 1, gems = 25000 },
    [2] = { name = "Packs Médios", costText = "17.5B Moedas", gemsText = "80k gemas", id = 2, gems = 80000 },
    [3] = { name = "Packs Grandes", costText = "40B Moedas Fantasia", gemsText = "135k gemas", id = 3, gems = 135000 },
    [5] = { name = "Packs Tecnológicos", costText = "400B Moedas Tech", gemsText = "625k gemas", id = 5, gems = 625000 }, -- era 4 -> agora 5
    [8] = { name = "Packs Coloridos", costText = "3B Moedas Coloridas", gemsText = "1.5M gemas", id = 8, gems = 1500000 } -- era 5 -> agora 8
}
local DiamondOptionsOrder = {1,2,3,5,8}
local SelectedDiamondPackKey = nil
local AutoBuyDiamonds = false
local AutoBuyDelay = 1

----------------------------------------------------------------
-- FUNÇÕES AUXILIARES (Notificações limpas)
----------------------------------------------------------------

local function NotifyStartEggs()
    local eggName = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not eggName or eggName == "" then return end
    local qtd = SelectedAmount or 1
    local plural = (qtd > 1) and "ovos" or "ovo"
    Rayfield:Notify({
        Title = "Iniciando",
        Content = ("Começando a abrir %d %s do tipo %s..."):format(qtd, plural, eggName),
        Duration = 3
    })
end

local function NotifyFinishEggs()
    Rayfield:Notify({
        Title = "Finalizado",
        Content = "Concluiu a abertura dos ovos.",
        Duration = 3
    })
end

local function NotifyStartDiamonds(pack)
    if not pack then return end
    Rayfield:Notify({
        Title = "Iniciando compras",
        Content = ("Iniciando as compras dos %s (%s)…"):format(pack.name, pack.gemsText),
        Duration = 3
    })
end

local function NotifyFinishDiamonds()
    Rayfield:Notify({
        Title = "Finalizado",
        Content = "Concluiu as compras automáticas de packs.",
        Duration = 3
    })
end

----------------------------------------------------------------
-- FUNÇÕES DE BUILD DE ARGS (formato EXATO do jogo)
----------------------------------------------------------------

local function BuildEggArgs()
    local eggName = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not eggName or eggName == "" then return nil end

    return {
        {
            {
                eggName,
                SelectedAmount == 3,
                SelectedAmount == 8
            },
            {
                false,
                false,
                false
            }
        }
    }
end

local function BuildDiamondArgsById(packId)
    -- formato que você mostrou:
    -- local args = { { { <id> }, { false } } }
    return {
        {
            { packId },
            { false }
        }
    }
end

----------------------------------------------------------------
-- ATUALIZAR LISTA DE OVOS
----------------------------------------------------------------

local EggDropdown = nil

local function UpdateEggList()
    if not SelectedArea then return end
    local areaFolder = EggsDir:FindFirstChild(SelectedArea)
    if not areaFolder then return end

    local list = {}
    for _, egg in ipairs(areaFolder:GetChildren()) do
        if egg:IsA("Folder") then
            table.insert(list, egg.Name)
        end
    end

    if EggDropdown then
        EggDropdown:Refresh(list)
    end
end

----------------------------------------------------------------
-- UI: EGGS TAB
----------------------------------------------------------------

-- Área
EggsTab:CreateDropdown({
    Name = "Selecionar área",
    Options = (function()
        local list = {}
        for _, folder in ipairs(EggsDir:GetChildren()) do
            if folder:IsA("Folder") then
                table.insert(list, folder.Name)
            end
        end
        return list
    end)(),
    CurrentOption = {},
    Callback = function(opt)
        SelectedArea = opt[1]
        UpdateEggList()
    end
})

-- Ovo
EggDropdown = EggsTab:CreateDropdown({
    Name = "Selecionar ovo",
    Options = {},
    CurrentOption = {},
    Callback = function(opt)
        SelectedEgg = opt[1]
    end
})

-- Nome manual
EggsTab:CreateToggle({
    Name = "Colocar nome manualmente",
    CurrentValue = false,
    Callback = function(v)
        ManualNameEnabled = v
    end
})

EggsTab:CreateInput({
    Name = "Nome do ovo",
    PlaceholderText = "Insira o nome exato",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        ManualNameValue = text
    end
})

-- Quantidade
EggsTab:CreateDropdown({
    Name = "Quantidade de ovos",
    Options = { "1", "3", "8" },
    CurrentOption = { "1" },
    Callback = function(opt)
        SelectedAmount = tonumber(opt[1])
    end
})

-- Delay
EggsTab:CreateSlider({
    Name = "Delay (segundos)",
    Range = {0, 5},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(val)
        SelectedDelay = val
    end
})

-- Auto-open (uma notificação no início, outra no fim)
EggsTab:CreateToggle({
    Name = "Abrir automaticamente",
    CurrentValue = false,
    Callback = function(v)
        AutoOpenEnabled = v
        if v and not AutoOpening then
            AutoOpening = true
            task.spawn(function()
                NotifyStartEggs()
                while AutoOpenEnabled do
                    local args = BuildEggArgs()
                    if args then
                        buyEgg:InvokeServer(unpack(args))
                    end
                    task.wait(SelectedDelay)
                end
                AutoOpening = false
                NotifyFinishEggs()
            end)
        end
    end
})

----------------------------------------------------------------
-- UI: DIAMANTES TAB (Packs renumerados e valores)
----------------------------------------------------------------

-- Dropdown de packs (em ordem definida)
DiamondsTab:CreateDropdown({
    Name = "Selecionar packs",
    Options = (function()
        local list = {}
        for _, key in ipairs(DiamondOptionsOrder) do
            local p = DiamondPacks[key]
            if p then
                table.insert(list, tostring(key) .. " - " .. p.name .. " (" .. p.gemsText .. " / " .. p.costText .. ")")
            end
        end
        return list
    end)(),
    CurrentOption = {},
    Callback = function(opt)
        -- extrai o número do início da string
        local num = tonumber(opt[1]:match("^(%d+)"))
        SelectedDiamondPackKey = num
    end
})

-- Delay auto-buy
DiamondsTab:CreateSlider({
    Name = "Delay Auto-Buy (segundos)",
    Range = {0, 5},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(val)
        AutoBuyDelay = val
    end
})

-- Toggle Auto-Buy (uma notificação no começo e no fim)
DiamondsTab:CreateToggle({
    Name = "Comprar automaticamente",
    CurrentValue = false,
    Callback = function(v)
        AutoBuyDiamonds = v
        if v then
            task.spawn(function()
                local pack = DiamondPacks[SelectedDiamondPackKey]
                NotifyStartDiamonds(pack)
                while AutoBuyDiamonds do
                    if SelectedDiamondPackKey and DiamondPacks[SelectedDiamondPackKey] then
                        local chosen = DiamondPacks[SelectedDiamondPackKey]
                        local args = BuildDiamondArgsById(chosen.id)
                        buyDiamond:InvokeServer(unpack(args))
                    end
                    task.wait(AutoBuyDelay)
                end
                NotifyFinishDiamonds()
            end)
        end
    end
})

-- Comprar pack selecionado (único)
DiamondsTab:CreateButton({
    Name = "Comprar pack selecionado",
    Callback = function()
        if not SelectedDiamondPackKey or not DiamondPacks[SelectedDiamondPackKey] then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Escolha um pack antes de comprar.",
                Duration = 3
            })
            return
        end

        local pack = DiamondPacks[SelectedDiamondPackKey]
        local args = BuildDiamondArgsById(pack.id)
        buyDiamond:InvokeServer(unpack(args))

        Rayfield:Notify({
            Title = "Comprados",
            Content = ("Comprou os %s e recebeu +%s."):format(pack.name, pack.gemsText),
            Duration = 3
        })
    end
})

-- Seção: comprar individual (botões rápidos)
DiamondsTab:CreateSection("Comprar Individual")

for _, key in ipairs(DiamondOptionsOrder) do
    local p = DiamondPacks[key]
    if p then
        DiamondsTab:CreateButton({
            Name = "Comprar " .. p.name,
            Callback = function()
                local args = BuildDiamondArgsById(p.id)
                buyDiamond:InvokeServer(unpack(args))

                Rayfield:Notify({
                    Title = "Comprados",
                    Content = ("Comprou os %s e recebeu +%s."):format(p.name, p.gemsText),
                    Duration = 2
                })
            end
        })
    end
end

----------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------

SettingsTab:CreateSection("Aparência")

SettingsTab:CreateDropdown({
    Name = "Tema",
    Options = {"Default", "Aether", "Discord", "Dark", "Light"},
    CurrentOption = {"Default"},
    Flag = "ThemeSetting",
    Callback = function(opt)
        Rayfield:LoadTheme(opt[1])
    end
})

SettingsTab:CreateToggle({
    Name = "Animações da UI",
    CurrentValue = true,
    Flag = "AnimationsSetting",
    Callback = function(v)
        Rayfield:ToggleAnimations(v)
    end
})

SettingsTab:CreateButton({
    Name = "Forçar salvar settings",
    Callback = function()
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Salvo",
            Content = "Configurações salvas.",
            Duration = 2
        })
    end
})

----------------------------------------------------------------
-- FINALIZAÇÃO
----------------------------------------------------------------

Rayfield:Notify({
    Title = "Pronto",
    Content = "Interface carregada com sucesso.",
    Duration = 3
})
