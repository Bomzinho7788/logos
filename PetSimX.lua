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

Rayfield:LoadConfiguration()

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
local ThemesTab = Window:CreateTab("Temas", "palette")
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

-- Themes
local CustomThemes = {}
local CurrentThemeName = "Default"
local ThemeDropdown = nil

----------------------------------------------------------------
-- FUNÇÕES DE TEMAS
----------------------------------------------------------------

-- Carregar temas salvos
local function LoadCustomThemes()
    local success, savedThemes = pcall(function()
        return Rayfield.Flags.CustomThemes and Rayfield.Flags.CustomThemes.CurrentValue or {}
    end)
    
    if success and savedThemes then
        CustomThemes = savedThemes
    else
        CustomThemes = {}
    end
    
    -- Atualizar dropdown de temas
    if ThemeDropdown then
        UpdateThemesDropdown()
    end
end

-- Salvar temas
local function SaveCustomThemes()
    Rayfield.Flags.CustomThemes.CurrentValue = CustomThemes
    Rayfield:SaveConfiguration()
end

-- Atualizar dropdown de temas
local function UpdateThemesDropdown()
    local themeOptions = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"}
    
    -- Adicionar temas personalizados
    for themeName, _ in pairs(CustomThemes) do
        table.insert(themeOptions, "⭐ " .. themeName)
    end
    
    if ThemeDropdown then
        ThemeDropdown:Refresh(themeOptions)
    end
end

-- Aplicar tema
local function ApplyTheme(themeName)
    if themeName == "Default" or themeName == "AmberGlow" or themeName == "Amethyst" or 
       themeName == "Bloom" or themeName == "DarkBlue" or themeName == "Green" or 
       themeName == "Light" or themeName == "Ocean" or themeName == "Serenity" then
        Window:ModifyTheme(themeName)
    elseif themeName:sub(1, 2) == "⭐ " then
        local customThemeName = themeName:sub(4)
        if CustomThemes[customThemeName] then
            Window:ModifyTheme(CustomThemes[customThemeName])
        end
    end
    
    CurrentThemeName = themeName
end

-- Criar tema padrão para edição
local function GetDefaultThemeTemplate()
    return {
        TextColor = Color3.fromRGB(240, 240, 240),

        Background = Color3.fromRGB(25, 25, 25),
        Topbar = Color3.fromRGB(34, 34, 34),
        Shadow = Color3.fromRGB(20, 20, 20),

        NotificationBackground = Color3.fromRGB(20, 20, 20),
        NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

        TabBackground = Color3.fromRGB(80, 80, 80),
        TabStroke = Color3.fromRGB(85, 85, 85),
        TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
        TabTextColor = Color3.fromRGB(240, 240, 240),
        SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

        ElementBackground = Color3.fromRGB(35, 35, 35),
        ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
        SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
        ElementStroke = Color3.fromRGB(50, 50, 50),
        SecondaryElementStroke = Color3.fromRGB(40, 40, 40),
                
        SliderBackground = Color3.fromRGB(50, 138, 220),
        SliderProgress = Color3.fromRGB(50, 138, 220),
        SliderStroke = Color3.fromRGB(58, 163, 255),

        ToggleBackground = Color3.fromRGB(30, 30, 30),
        ToggleEnabled = Color3.fromRGB(0, 146, 214),
        ToggleDisabled = Color3.fromRGB(100, 100, 100),
        ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
        ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
        ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
        ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

        DropdownSelected = Color3.fromRGB(40, 40, 40),
        DropdownUnselected = Color3.fromRGB(30, 30, 30),

        InputBackground = Color3.fromRGB(30, 30, 30),
        InputStroke = Color3.fromRGB(65, 65, 65),
        PlaceholderColor = Color3.fromRGB(178, 178, 178)
    }
end

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
        Content = ("Começando a abrir %d %s do tipo %s..."):format(qtd, plural, eggName),
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
        Content = ("Iniciando as compras dos %s (%s)…"):format(pack.name, pack.gemsText),
        Duration = 3,
        Image = "shopping-bag"
    })
end

local function NotifyFinishDiamonds()
    Rayfield:Notify({
        Title = "Finalizado",
        Content = "Concluiu as compras automáticas de packs.",
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

EggsTab:CreateSection("Configuração de Ovos")

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

EggsTab:CreateSection("Automação")

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

DiamondsTab:CreateSection("Configuração de Diamantes")

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

DiamondsTab:CreateSection("Automação de Compras")

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
-- UI: TEMAS TAB
----------------------------------------------------------------

ThemesTab:CreateSection("Selecionar Tema")

-- Dropdown para selecionar temas
ThemeDropdown = ThemesTab:CreateDropdown({
    Name = "Temas Disponíveis",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {"Default"},
    Flag = "SelectedTheme",
    Callback = function(opt)
        ApplyTheme(opt[1])
        Rayfield:Notify({
            Title = "Tema Aplicado",
            Content = ("Tema '%s' aplicado com sucesso!"):format(opt[1]),
            Duration = 3,
            Image = "palette"
        })
    end
})

ThemesTab:CreateSection("Criar Tema Personalizado")

-- Nome do tema personalizado
local CustomThemeName = ""
ThemesTab:CreateInput({
    Name = "Nome do Tema Personalizado",
    PlaceholderText = "Digite um nome único para seu tema",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        CustomThemeName = text
    end
})

-- Cores principais do tema
local ThemeColors = GetDefaultThemeTemplate()

-- Função para criar color pickers
local function CreateColorPicker(name, themeKey)
    ThemesTab:CreateColorPicker({
        Name = name,
        Color = ThemeColors[themeKey],
        Callback = function(color)
            ThemeColors[themeKey] = color
        end
    })
end

-- Grupo de cores principais
ThemesTab:CreateSection("Cores Principais")

CreateColorPicker("Cor do Texto", "TextColor")
CreateColorPicker("Fundo Principal", "Background")
CreateColorPicker("Barra Superior", "Topbar")
CreateColorPicker("Sombra", "Shadow")

-- Grupo de cores de notificação
ThemesTab:CreateSection("Cores de Notificação")

CreateColorPicker("Fundo da Notificação", "NotificationBackground")
CreateColorPicker("Ações da Notificação", "NotificationActionsBackground")

-- Grupo de cores das abas
ThemesTab:CreateSection("Cores das Abas")

CreateColorPicker("Fundo da Aba", "TabBackground")
CreateColorPicker("Borda da Aba", "TabStroke")
CreateColorPicker("Aba Selecionada", "TabBackgroundSelected")
CreateColorPicker("Texto da Aba", "TabTextColor")
CreateColorPicker("Texto da Aba Selecionada", "SelectedTabTextColor")

-- Grupo de cores dos elementos
ThemesTab:CreateSection("Cores dos Elementos")

CreateColorPicker("Fundo do Elemento", "ElementBackground")
CreateColorPicker("Fundo do Elemento (Hover)", "ElementBackgroundHover")
CreateColorPicker("Fundo Secundário", "SecondaryElementBackground")
CreateColorPicker("Borda do Elemento", "ElementStroke")
CreateColorPicker("Borda Secundária", "SecondaryElementStroke")

-- Grupo de cores específicas
ThemesTab:CreateSection("Cores Específicas")

CreateColorPicker("Fundo do Slider", "SliderBackground")
CreateColorPicker("Progresso do Slider", "SliderProgress")
CreateColorPicker("Borda do Slider", "SliderStroke")

CreateColorPicker("Fundo do Toggle", "ToggleBackground")
CreateColorPicker("Toggle Ativado", "ToggleEnabled")
CreateColorPicker("Toggle Desativado", "ToggleDisabled")
CreateColorPicker("Borda Toggle Ativado", "ToggleEnabledStroke")
CreateColorPicker("Borda Toggle Desativado", "ToggleDisabledStroke")

CreateColorPicker("Dropdown Selecionado", "DropdownSelected")
CreateColorPicker("Dropdown Não Selecionado", "DropdownUnselected")

CreateColorPicker("Fundo do Input", "InputBackground")
CreateColorPicker("Borda do Input", "InputStroke")
CreateColorPicker("Cor do Placeholder", "PlaceholderColor")

-- Botões de gerenciamento de temas
ThemesTab:CreateSection("Gerenciar Temas")

-- Salvar tema personalizado
ThemesTab:CreateButton({
    Name = "💾 Salvar Tema Personalizado",
    Callback = function()
        if CustomThemeName == "" then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Digite um nome para o tema primeiro!",
                Duration = 3,
                Image = "alert-circle"
            })
            return
        end
        
        if CustomThemes[CustomThemeName] then
            Rayfield:Notify({
                Title = "Aviso",
                Content = "Tema com este nome já existe. Sobrescrevendo...",
                Duration = 3,
                Image = "alert-triangle"
            })
        end
        
        CustomThemes[CustomThemeName] = ThemeColors
        SaveCustomThemes()
        UpdateThemesDropdown()
        
        Rayfield:Notify({
            Title = "Tema Salvo",
            Content = ("Tema '%s' salvo com sucesso!"):format(CustomThemeName),
            Duration = 3,
            Image = "check-circle"
        })
    end
})

-- Aplicar tema personalizado
ThemesTab:CreateButton({
    Name = "🎨 Aplicar Tema Personalizado",
    Callback = function()
        if CustomThemeName == "" then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Digite um nome para o tema primeiro!",
                Duration = 3,
                Image = "alert-circle"
            })
            return
        end
        
        if not CustomThemes[CustomThemeName] then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Tema não encontrado! Salve o tema primeiro.",
                Duration = 3,
                Image = "alert-circle"
            })
            return
        end
        
        ApplyTheme("⭐ " .. CustomThemeName)
        Rayfield:Notify({
            Title = "Tema Aplicado",
            Content = ("Tema personalizado '%s' aplicado!"):format(CustomThemeName),
            Duration = 3,
            Image = "palette"
        })
    end
})

-- Deletar tema personalizado
ThemesTab:CreateButton({
    Name = "🗑️ Deletar Tema Personalizado",
    Callback = function()
        if CustomThemeName == "" then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Digite o nome do tema que deseja deletar!",
                Duration = 3,
                Image = "alert-circle"
            })
            return
        end
        
        if not CustomThemes[CustomThemeName] then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Tema não encontrado!",
                Duration = 3,
                Image = "alert-circle"
            })
            return
        end
        
        CustomThemes[CustomThemeName] = nil
        SaveCustomThemes()
        UpdateThemesDropdown()
        
        Rayfield:Notify({
            Title = "Tema Deletado",
            Content = ("Tema '%s' deletado com sucesso!"):format(CustomThemeName),
            Duration = 3,
            Image = "trash-2"
        })
    end
})

-- Resetar para tema padrão
ThemesTab:CreateButton({
    Name = "🔄 Resetar para Tema Padrão",
    Callback = function()
        ThemeColors = GetDefaultThemeTemplate()
        Rayfield:Notify({
            Title = "Tema Resetado",
            Content = "Cores resetadas para o tema padrão!",
            Duration = 3,
            Image = "refresh-cw"
        })
    end
})

-- Lista de temas salvos
ThemesTab:CreateSection("Temas Salvos")

local ThemesListLabel = ThemesTab:CreateLabel("Carregando temas...", "list", Color3.fromRGB(255, 255, 255), false)

-- Função para atualizar a lista de temas
local function UpdateThemesList()
    local themeCount = 0
    local themeNames = ""
    
    for themeName, _ in pairs(CustomThemes) do
        themeCount = themeCount + 1
        if themeNames == "" then
            themeNames = "• " .. themeName
        else
            themeNames = themeNames .. "\n• " .. themeName
        end
    end
    
    if themeCount == 0 then
        ThemesListLabel:Set("Nenhum tema personalizado salvo.", "list", Color3.fromRGB(255, 150, 150), false)
    else
        ThemesListLabel:Set(("Temas salvos (%d):\n%s"):format(themeCount, themeNames), "bookmark", Color3.fromRGB(150, 255, 150), false)
    end
end

----------------------------------------------------------------
-- UI: SETTINGS TAB
----------------------------------------------------------------

SettingsTab:CreateSection("Aparência")

SettingsTab:CreateDropdown({
    Name = "Tema da Interface",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {"Default"},
    Flag = "InterfaceTheme",
    Callback = function(opt)
        ApplyTheme(opt[1])
        Rayfield:Notify({
            Title = "Tema Alterado",
            Content = ("Tema mudado para: %s"):format(opt[1]),
            Duration = 3,
            Image = "palette"
        })
    end
})

SettingsTab:CreateToggle({
    Name = "Animações da Interface",
    CurrentValue = true,
    Flag = "InterfaceAnimations",
    Callback = function(v)
        Rayfield:ToggleAnimations(v)
        Rayfield:Notify({
            Title = "Animações",
            Content = v and "Animações ativadas" or "Animações desativadas",
            Duration = 2,
            Image = v and "play" or "pause"
        })
    end
})

SettingsTab:CreateSection("Configurações")

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
    Name = "Salvar Configurações",
    Callback = function()
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Configurações Salvas",
            Content = "Todas as configurações foram salvas com sucesso!",
            Duration = 3,
            Image = "save"
        })
    end
})

SettingsTab:CreateButton({
    Name = "Carregar Configurações",
    Callback = function()
        Rayfield:LoadConfiguration()
        LoadCustomThemes()
        UpdateThemesDropdown()
        UpdateThemesList()
        Rayfield:Notify({
            Title = "Configurações Carregadas",
            Content = "Configurações anteriores carregadas!",
            Duration = 3,
            Image = "download"
        })
    end
})

SettingsTab:CreateSection("Informações")

SettingsTab:CreateLabel("Pet Sims X Interface v1.0", "info", Color3.fromRGB(255, 255, 255), false)

SettingsTab:CreateParagraph({
    Title = "Sobre esta Interface",
    Content = "Desenvolvida por Bomzinho e GPT5\nRecursos: Abertura automática de ovos, Compra de diamantes, Criação de temas personalizados"
})

SettingsTab:CreateSection("Controles Rápidos")

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

-- Carregar temas personalizados
LoadCustomThemes()
UpdateThemesDropdown()
UpdateThemesList()

-- Notificação de inicialização
Rayfield:Notify({
    Title = "Interface Carregada",
    Content = "Pet Sims X está pronto para uso! Sistema de temas personalizados ativo!",
    Duration = 5,
    Image = "check-circle"
})

-- Atualizar lista de ovos se já tiver uma área selecionada
if SelectedArea then
    UpdateEggList()
end
