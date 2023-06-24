local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local T = { "K", "M", "B", "T", "q", "Q", "s", "S", "O", "N", "d", "U", "D" }

local LeaderstatsService = Knit.CreateService({
	Name = "LeaderstatsService",
	Client = {},
})

local function formatNumber(n)
	if not tonumber(n) then
		return n
	end
	if n < 10000 then
		return math.floor(n)
	end
	local d = math.floor(math.log10(n) / 3) * 3
	local s = tostring(n / (10 ^ d)):sub(1, 5)
	return s .. " " .. tostring(T[math.floor(d / 3)])
end

function LeaderstatsService:KnitStart()
	Knit.GetService("ValueService").Changed:Connect(function(player, newValue)
		local leaderstats = player:WaitForChild("leaderstats", 5) -- player might have left the game
	
		if not leaderstats then
			return 
		end

		leaderstats.KOs.Value = formatNumber(newValue)
	end)

	for _, player in pairs(Players:GetPlayers()) do
		self:PlayerAdded(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:PlayerAdded(player)
	end)
end

function LeaderstatsService:PlayerAdded(player: Player)
	local ValueService = Knit.GetService("ValueService") -- required the bonk service to get the level value
	--BonkService.Client.level
	print(ValueService.Client.Amount)

	local leaderStats = Instance.new("Folder")
	leaderStats.Name = "leaderstats"

	-- Values
	self:KillValue(player, leaderStats)
	self:WipeoutValue(player, leaderStats)

	leaderStats.Parent = player
end

function LeaderstatsService:KillValue(player: Player, leaderstats : Folder)
	local kills = Instance.new("IntValue")
	kills.Name = "KOs"
	kills.Value = 0
	kills.Parent = leaderstats
end

function LeaderstatsService:WipeoutValue(player: Player, leaderstats : Folder)
	local Wipeout = Instance.new("IntValue")
	Wipeout.Name = "Wipeouts"
	Wipeout.Value = 0
	Wipeout.Parent = leaderstats
end

return LeaderstatsService
