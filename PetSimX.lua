--========================================================--
--   Interface Pet Sims X - Feito por Bomzinho e GPT5     --
--========================================================--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggsDir = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Eggs")

local buyEgg = workspace:WaitForChild("__THINGS")
    :WaitForChild("__REMOTES")
    :WaitForChild("buy egg")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

----------------------------------------------------------------
-- CONFIGURAÇÃO SALVA **APENAS SETTINGS**
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
local SettingsTab = Window:CreateTab("Settings")

----------------------------------------------------------------
-- VARIÁVEIS
----------------------------------------------------------------

local SelectedArea = nil
local SelectedEgg = nil

local ManualNameEnabled = false
local ManualNameValue = ""

local SelectedAmount = 1
local SelectedDelay = 1

local AutoOpenEnabled = false

----------------------------------------------------------------
-- Atualizador de lista de ovos (sem gambiarra)
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
-- Notificação
----------------------------------------------------------------

local function NotifyOpen()
    local eggName = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not eggName or eggName == "" then return end

    local qtd = SelectedAmount or 1
    local plural = (qtd > 1) and "ovos" or "ovo"

    Rayfield:Notify({
        Title = "Abrindo ovos",
        Content = ("Abrindo %d %s do tipo %s..."):format(qtd, plural, eggName),
        Duration = 3,
    })
end

----------------------------------------------------------------
-- Formador de args no formato EXATO do jogo
----------------------------------------------------------------

local function BuildArgs()
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

-- Auto-open
EggsTab:CreateToggle({
    Name = "Abrir automaticamente",
    CurrentValue = false,
    Callback = function(v)
        AutoOpenEnabled = v
        if v then
            task.spawn(function()
                while AutoOpenEnabled do
                    local args = BuildArgs()
                    if args then
                        NotifyOpen()
                        buyEgg:InvokeServer(unpack(args))
                    end
                    task.wait(SelectedDelay)
                end
            end)
        end
    end
})

----------------------------------------------------------------
-- SETTINGS TAB (salvo no config)
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

Rayfield:Notify({
    Title = "Pronto",
    Content = "Interface carregada com sucesso.",
    Duration = 3
})
