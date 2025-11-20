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
-- CONFIGURAÇÃO SALVA
----------------------------------------------------------------

local Window = Rayfield:CreateWindow({
    Name = "Pet Sims X",
    Icon = "gem",
    LoadingTitle = "Carregando Interface...",
    LoadingSubtitle = "Feito por Bomzinho e GPT5",
    Theme = "Default",
    ToggleUIKeybind = "K",
    
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PetSimsX",
        FileName = "Settings"
    },
    
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    
    KeySystem = false
})

local EggsTab = Window:CreateTab("Eggs", "egg")
local DiamondsTab = Window:CreateTab("Diamantes", "gem")
local SettingsTab = Window:CreateTab("Settings", "settings")

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
    [5] = { name = "Packs Tecnológicos", costText = "400B Moedas Tech", gemsText = "625k gemas", id = 5, gems = 625000 },
    [8] = { name = "Packs Coloridos", costText = "3B Moedas Coloridas", gemsText = "1.5M gemas", id = 8, gems = 1500000 }
}
local DiamondOptionsOrder = {1,2,3,5,8}
local SelectedDiamondPackKey = nil
local AutoBuyDiamonds = false
local AutoBuyDelay = 1

----------------------------------------------------------------
-- FUNÇÕES AUXILIARES
----------------------------------------------------------------

local function NotifyStartEggs()
    local eggName = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not eggName or eggName == "" then return end
    local qtd = SelectedAmount or 1
    local plural = (qtd > 1) and "ovos" or "ovo"
    Rayfield:Notify({
        Title = "Iniciando",
        Content = ("Comecando a abrir %d %s do tipo %s..."):format(qtd, plural, eggName),
        Duration = 3,
        Image = "egg"
    })
end

local function NotifyFinishEggs()
    Rayfield:Notify({
        Title = "Finalizado",
        Content = "Concluiu a abertura dos ovos.",
        Duration = 3,
        Image = "check-circle"
    })
end

local function NotifyStartDiamonds(pack)
    if not pack then return end
    Rayfield:Notify({
        Title = "Iniciando compras",
        Content = ("Iniciando as compras dos %s (%s)..."):format(pack.name, pack.gemsText),
        Duration = 3,
        Image = "shopping-bag"
    })
end

local function NotifyFinishDiamonds()
    Rayfield:Notify({
        Title = "Finalizado",
        Content = "Concluiu as compras automaticas de packs.",
        Duration = 3,
        Image = "check-circle"
    })
end

----------------------------------------------------------------
-- FUNÇÕES DE BUILD DE ARGS
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

EggsTab:CreateSection("Configuracao de Ovos")

EggsTab:CreateDropdown({
    Name = "Selecionar area",
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
    Flag = "EggArea",
    Callback = function(opt)
        SelectedArea = opt[1]
        UpdateEggList()
    end
})

EggDropdown = EggsTab:CreateDropdown({
    Name = "Selecionar ovo",
    Options = {},
    CurrentOption = {},
    Flag = "SelectedEgg",
    Callback = function(opt)
        SelectedEgg = opt[1]
    end
})

EggsTab:CreateToggle({
    Name = "Colocar nome manualmente",
    CurrentValue = false,
    Flag = "ManualNameToggle",
    Callback = function(v)
        ManualNameEnabled = v
    end
})

EggsTab:CreateInput({
    Name = "Nome do ovo",
    PlaceholderText = "Insira o nome exato",
    RemoveTextAfterFocusLost = false,
    Flag = "ManualEggName",
    Callback = function(text)
        ManualNameValue = text
    end
})

EggsTab:CreateSection("Automacao")

EggsTab:CreateDropdown({
    Name = "Quantidade de ovos",
    Options = { "1", "3", "8" },
    CurrentOption = { "1" },
    Flag = "EggAmount",
    Callback = function(opt)
        SelectedAmount = tonumber(opt[1])
    end
})

EggsTab:CreateSlider({
    Name = "Delay (segundos)",
    Range = {0, 5},
    Increment = 1,
    CurrentValue = 1,
    Flag = "EggDelay",
    Callback = function(val)
        SelectedDelay = val
    end
})

EggsTab:CreateToggle({
    Name = "Abrir automaticamente",
    CurrentValue = false,
    Flag = "AutoOpenEggs",
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
-- UI: DIAMANTES TAB
----------------------------------------------------------------

DiamondsTab:CreateSection("Configuracao de Diamantes")

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
    Flag = "SelectedDiamondPack",
    Callback = function(opt)
        local num = tonumber(opt[1]:match("^(%d+)"))
        SelectedDiamondPackKey = num
    end
})

DiamondsTab:CreateSlider({
    Name = "Delay Auto-Buy (segundos)",
    Range = {0, 5},
    Increment = 1,
    CurrentValue = 1,
    Flag = "DiamondDelay",
    Callback = function(val)
        AutoBuyDelay = val
    end
})

DiamondsTab:CreateSection("Automacao de Compras")

DiamondsTab:CreateToggle({
    Name = "Comprar automaticamente",
    CurrentValue = false,
    Flag = "AutoBuyDiamonds",
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

DiamondsTab:CreateButton({
    Name = "Comprar pack selecionado",
    Callback = function()
        if not SelectedDiamondPackKey or not DiamondPacks[SelectedDiamondPackKey] then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Escolha um pack antes de comprar.",
                Duration = 3,
                Image = "alert-circle"
            })
            return
        end

        local pack = DiamondPacks[SelectedDiamondPackKey]
        local args = BuildDiamondArgsById(pack.id)
        buyDiamond:InvokeServer(unpack(args))

        Rayfield:Notify({
            Title = "Comprados",
            Content = ("Comprou os %s e recebeu +%s."):format(pack.name, pack.gemsText),
            Duration = 3,
            Image = "shopping-bag"
        })
    end
})

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
                    Duration = 2,
                    Image = "shopping-bag"
                })
            end
        })
    end
end

----------------------------------------------------------------
-- UI: SETTINGS TAB
----------------------------------------------------------------

SettingsTab:CreateSection("Aparencia")

SettingsTab:CreateDropdown({
    Name = "Tema da Interface",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {"Default"},
    Flag = "InterfaceTheme",
    Callback = function(opt)
        Window:ModifyTheme(opt[1])
        Rayfield:Notify({
            Title = "Tema Alterado",
            Content = ("Tema mudado para: %s"):format(opt[1]),
            Duration = 3,
            Image = "palette"
        })
    end
})

SettingsTab:CreateToggle({
    Name = "Animacoes da Interface",
    CurrentValue = true,
    Flag = "InterfaceAnimations",
    Callback = function(v)
        Rayfield:ToggleAnimations(v)
        Rayfield:Notify({
            Title = "Animacoes",
            Content = v and "Animacoes ativadas" or "Animacoes desativadas",
            Duration = 2,
            Image = v and "play" or "pause"
        })
    end
})

SettingsTab:CreateSection("Configuracoes")

SettingsTab:CreateKeybind({
    Name = "Tecla para Mostrar/Esconder",
    CurrentKeybind = "K",
    HoldToInteract = false,
    Flag = "ToggleUIKeybind",
    Callback = function(Keybind)
        Rayfield:Notify({
            Title = "Tecla Alterada",
            Content = ("Tecla definida para: %s"):format(Keybind),
            Duration = 2,
            Image = "keyboard"
        })
    end,
})

SettingsTab:CreateButton({
    Name = "Salvar Configuracoes",
    Callback = function()
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Configuracoes Salvas",
            Content = "Todas as configuracoes foram salvas com sucesso!",
            Duration = 3,
            Image = "save"
        })
    end
})

SettingsTab:CreateButton({
    Name = "Carregar Configuracoes",
    Callback = function()
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title = "Configuracoes Carregadas",
            Content = "Configuracoes anteriores carregadas!",
            Duration = 3,
            Image = "download"
        })
    end
})

SettingsTab:CreateSection("Informacoes")

SettingsTab:CreateLabel("Pet Sims X Interface v1.0", "info", Color3.fromRGB(255, 255, 255), false)

SettingsTab:CreateParagraph({
    Title = "Sobre esta Interface",
    Content = "Desenvolvida por Bomzinho e GPT5\nRecursos: Abertura automatica de ovos, Compra de diamantes"
})

SettingsTab:CreateSection("Controles Rapidoss")

SettingsTab:CreateButton({
    Name = "Mostrar Interface",
    Callback = function()
        Rayfield:SetVisibility(true)
        Rayfield:Notify({
            Title = "Interface",
            Content = "Interface mostrada",
            Duration = 2,
            Image = "eye"
        })
    end
})

SettingsTab:CreateButton({
    Name = "Esconder Interface",
    Callback = function()
        Rayfield:SetVisibility(false)
        Rayfield:Notify({
            Title = "Interface",
            Content = "Interface escondida",
            Duration = 2,
            Image = "eye-off"
        })
    end
})

SettingsTab:CreateButton({
    Name = "Fechar Interface",
    Callback = function()
        Rayfield:Destroy()
    end
})

----------------------------------------------------------------
-- INICIALIZAÇÃO
----------------------------------------------------------------

-- Carregar configuração depois de criar todos os elementos
Rayfield:LoadConfiguration()

-- Notificação de inicialização
Rayfield:Notify({
    Title = "Interface Carregada",
    Content = "Pet Sims X esta pronto para uso!",
    Duration = 5,
    Image = "check-circle"
})

-- Atualizar lista de ovos se já tiver uma área selecionada
if SelectedArea then
    UpdateEggList()
end
