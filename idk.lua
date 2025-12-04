-- // RAYFIELD
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Secret Farmer",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Aguarde",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Farm", 4483362458)

--------------------------------------------------------------------

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer

local npcFolder = workspace:WaitForChild("Map")
	:WaitForChild("Zones")
	:WaitForChild("Field")
	:WaitForChild("NPC")

-- VARIÁVEIS EDITÁVEIS
local settings = {
    enabled = false,
    heightOffset = 3,
    tweenTime = 0.1,
    chainsawName = "Basic Chainsaw",
    autoTool = true,

    -- TELEPORT
    tpEnabled = false,
    tpInstant = false,
    tpMinDistance = 25,

    -- FILTRO DE NPC
    onlySecret = true
}

local currentTarget = nil

--------------------------------------------------------------
-- UI ELEMENTS
--------------------------------------------------------------

Tab:CreateToggle({
    Name = "Ativar Auto Farm",
    CurrentValue = false,
    Callback = function(v)
        settings.enabled = v
    end,
})

Tab:CreateToggle({
    Name = "Atacar somente NPC Secret",
    CurrentValue = true,
    Callback = function(v)
        settings.onlySecret = v
    end,
})

Tab:CreateToggle({
    Name = "Auto detectar motosserra na mão",
    CurrentValue = true,
    Callback = function(v)
        settings.autoTool = v
    end,
})

Tab:CreateInput({
    Name = "Nome da Motosserra (manual)",
    PlaceholderText = "Basic Chainsaw",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        settings.chainsawName = text
    end,
})

Tab:CreateButton({
    Name = "Atualizar nome da Tool na mão",
    Callback = function()
        local char = plr.Character
        local tool = char and char:FindFirstChildWhichIsA("Tool")
        if tool then
            settings.chainsawName = tool.Name
            Rayfield:Notify("Motosserra Setada", "Agora usando: " .. tool.Name)
        else
            Rayfield:Notify("Nenhuma tool", "Pegue a motosserra na mão!")
        end
    end
})

Tab:CreateSlider({
    Name = "Altura acima do NPC",
    Range = {0, 20},
    Increment = 1,
    CurrentValue = 3,
    Callback = function(v)
        settings.heightOffset = v
    end,
})

Tab:CreateSlider({
    Name = "Tween Speed",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.1,
    Callback = function(v)
        settings.tweenTime = v
    end,
})

--------------------------------------------------------------------
-- TELEPORT CONFIG
--------------------------------------------------------------------

Tab:CreateToggle({
    Name = "Teleport Automático pro NPC",
    CurrentValue = false,
    Callback = function(v)
        settings.tpEnabled = v
    end,
})

Tab:CreateToggle({
    Name = "Teleport Instantâneo (sem tween)",
    CurrentValue = false,
    Callback = function(v)
        settings.tpInstant = v
    end,
})

Tab:CreateSlider({
    Name = "Distância mínima pra teleport (studs)",
    Range = {5, 100},
    Increment = 1,
    CurrentValue = 25,
    Callback = function(v)
        settings.tpMinDistance = v
    end,
})

Tab:CreateButton({
    Name = "Teleport Manual pro NPC atual",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hrp then return end

        if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
            hrp.CFrame = currentTarget.HumanoidRootPart.CFrame + Vector3.new(0, settings.heightOffset, 0)
        else
            Rayfield:Notify("Nenhum alvo", "Não tem NPC atual pra teleportar.")
        end
    end
})

--------------------------------------------------------------------

-- checa se é Secret
local function isSecret(npc)
	local r = npc:FindFirstChild("OverheadAttachment")
		and npc.OverheadAttachment:FindFirstChild("CharacterInfo")
		and npc.OverheadAttachment.CharacterInfo:FindFirstChild("Frame")
		and npc.OverheadAttachment.CharacterInfo.Frame:FindFirstChild("Rarity")

	if not r then return false end
	return tostring(r.Text) == "Secret"
end

-- pega alvo de acordo com o toggle
local function getClosestTarget(hrp)
	local closest = nil
	local distMin = math.huge

	for _, npc in ipairs(npcFolder:GetChildren()) do
		if npc:IsA("Model")
			and npc:FindFirstChild("HumanoidRootPart")
		then
            -- Se só secret estiver ativado → ignora não-secret
			if settings.onlySecret and not isSecret(npc) then
				continue
			end

			local dist = (npc.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < distMin then
				distMin = dist
				closest = npc
			end
		end
	end

	return closest
end

-- checa se o NPC está vivo
local function npcAlive(npc)
	local guiVal = npc:FindFirstChild("OverheadAttachment")
		and npc.OverheadAttachment:FindFirstChild("CharacterInfo")
		and npc.OverheadAttachment.CharacterInfo:FindFirstChild("Frame")
		and npc.OverheadAttachment.CharacterInfo.Frame:FindFirstChild("Health")
		and npc.OverheadAttachment.CharacterInfo.Frame.Health:FindFirstChild("Amount")

	if not guiVal then return false end
	local text = tostring(guiVal.Text)
	local current = tonumber(text:match("(%d+)/"))
	return current and current > 0
end

-- bater
local function hit(npc)
	local chainsaw = settings.chainsawName

	if settings.autoTool then
		local char = plr.Character
		local tool = char and char:FindFirstChildWhichIsA("Tool")
		if tool then chainsaw = tool.Name end
	end

	local args = { npc, chainsaw }
	Replicated.Remotes.Field.DamageNPC:InvokeServer(unpack(args))
end

-- mover / teleportar / tween
local function goTo(hrp, npc)
	local pos = npc.HumanoidRootPart.Position + Vector3.new(0, settings.heightOffset, 0)

	-- teleport instantâneo
	if settings.tpEnabled and settings.tpInstant then
		hrp.CFrame = CFrame.new(pos)
		return
	end

	-- teleport automático baseado em distância
	if settings.tpEnabled and (hrp.Position - pos).Magnitude > settings.tpMinDistance then
		hrp.CFrame = CFrame.new(pos)
		return
	end

	-- tween
	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(settings.tweenTime, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(pos) }
	)
	tween:Play()
end

--------------------------------------------------------------------

-- LOOP PRINCIPAL
task.spawn(function()
	while task.wait(0) do

		if not settings.enabled then
			continue
		end

		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart")

		if currentTarget
			and currentTarget.Parent
			and npcAlive(currentTarget)
			and (not settings.onlySecret or isSecret(currentTarget))
		then
			goTo(hrp, currentTarget)
			hit(currentTarget)
			continue
		end

		currentTarget = nil

		local newTarget = getClosestTarget(hrp)
		if not newTarget then
			continue
		end

		currentTarget = newTarget
		goTo(hrp, newTarget)
		hit(newTarget)
	end
end)
