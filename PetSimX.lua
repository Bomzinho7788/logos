-- Carregar Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- UI
local Window = Rayfield:CreateWindow({
    Name = "Pet Sims X",
    LoadingTitle = "Carregando",
    LoadingSubtitle = "Feito por Bonzinho e GPT5"
})

local EggsTab = Window:CreateTab("Eggs")

-- Variáveis
local SelectedArea = nil
local SelectedEgg = nil
local ManualNameEnabled = false
local ManualNameValue = ""
local SelectedAmount = 1
local SelectedDelay = 0

-- Pasta principal (ALTERADO)
local EggsDir = game:GetService("ReplicatedStorage"):WaitForChild("Game"):WaitForChild("Eggs")

-- Util: pegar áreas
local function GetAreas()
    local list = {}
    for _, v in ipairs(EggsDir:GetChildren()) do
        if v:IsA("Folder") then
            table.insert(list, v.Name)
        end
    end
    return list
end

-- Util: pegar ovos dentro da área
local function GetEggs(area)
    local list = {}
    if not area then return list end
    local folder = EggsDir:FindFirstChild(area)
    if not folder then return list end
    for _, v in ipairs(folder:GetChildren()) do
        if v:IsA("Folder") then
            table.insert(list, v.Name)
        end
    end
    return list
end

-- Toggle: abrir ovos automaticamente
local AutoOpen = false
EggsTab:CreateToggle({
    Name = "Abrir ovos automaticamente",
    CurrentValue = false,
    Callback = function(v)
        AutoOpen = v
    end
})

-- Dropdown: selecionar área
local AreaDropdown = EggsTab:CreateDropdown({
    Name = "Selecionar área",
    Options = GetAreas(),
    CurrentOption = {},
    Callback = function(opt)
        SelectedArea = opt[1]
        EggDropdown:Refresh(GetEggs(SelectedArea), true)
    end
})

-- Dropdown: selecionar ovo
EggDropdown = EggsTab:CreateDropdown({
    Name = "Selecionar ovo",
    Options = {},
    CurrentOption = {},
    Callback = function(opt)
        SelectedEgg = opt[1]
    end
})

-- Toggle: inserir nome manual
EggsTab:CreateToggle({
    Name = "Colocar nome manualmente",
    CurrentValue = false,
    Callback = function(v)
        ManualNameEnabled = v
    end
})

-- TextBox: nome manual
EggsTab:CreateInput({
    Name = "Nome do ovo",
    PlaceholderText = "Digite o nome exato",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        ManualNameValue = text
    end
})

-- Dropdown: quantidade de ovos (8 bloqueado)
EggsTab:CreateDropdown({
    Name = "Quantidade de ovos",
    Options = { "1", "3", "[8 indisponível]" },
    CurrentOption = { "1" },
    Callback = function(opt)
        local chosen = opt[1]
        if chosen == "[8 indisponível]" then
            SelectedAmount = "8_blocked"
        else
            SelectedAmount = tonumber(chosen)
        end
    end
})

-- Dropdown: Delay
local Delays = {}
for i = 0, 5 do table.insert(Delays, tostring(i)) end

EggsTab:CreateDropdown({
    Name = "Delay para abrir",
    Options = Delays,
    CurrentOption = { "0" },
    Callback = function(opt)
        SelectedDelay = tonumber(opt[1])
    end
})

-- Função para montar argumentos do remote
local function BuildArgs()
    local eggName = ManualNameEnabled and ManualNameValue or SelectedEgg
    if not eggName or eggName == "" then return nil end

    local triple = false
    local octo = false

    if SelectedAmount == 3 then
        triple = true
    elseif SelectedAmount == 1 then
        triple = false
    elseif SelectedAmount == "8_blocked" then
        octo = true
    end

    return {
        {
            {
                eggName,
                triple,
                octo
            },
            {
                false,
                false,
                false
            }
        }
    }
end

-- Loop de auto open
task.spawn(function()
    while true do
        task.wait(0.1)
        if AutoOpen then
            local args = BuildArgs()
            if args then
                task.wait(SelectedDelay)
                pcall(function()
                    workspace:WaitForChild("__THINGS"):WaitForChild("__REMOTES"):WaitForChild("buy egg"):InvokeServer(unpack(args))
                end)
            end
        end
    end
end)
