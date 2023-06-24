local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Datastore2 = require(ReplicatedStorage.Packages.Datastore2)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
--local TopCoinCollector = require(ServerScriptService.GameSystems.Leaderboards.GlobalLeaderboards.TopCoinCollector)

--local Star = require(script.Parent.Star)

local VALUE_DS_NAME = "bvg_01"

local DEFAULT_BONKS = 0

local GROUP_ID = 16763338

Datastore2.Combine("DATA", VALUE_DS_NAME)

local ValueService = Knit.CreateService({
	Name = "ValueService",
	Client = {
		Amount = Knit.CreateProperty(DEFAULT_BONKS),
		Multiplier = Knit.CreateProperty(1),
	},
	DEFAULT = DEFAULT_BONKS,
	DS_NAME = VALUE_DS_NAME,
})

ValueService.Changed = Signal.new() -- to update the leaderstats top left of screen

function ValueService:PlayerAdded(player: Player)
	local coinStore = Datastore2(VALUE_DS_NAME, player)
	local amount = coinStore:Get(DEFAULT_BONKS)

	self.Changed:Fire(player, amount)

	local function update(newAmount)
		self.Client.Amount:SetFor(player, newAmount) -- when store is updated, this will fire to set for client
	end

	coinStore:OnUpdate(update)

	update(amount)

	local multiplier = self:GetMultiplier(player)
	self.Client.Multiplier:SetFor(player, multiplier)

	coinStore:BeforeSave(function(value) -- converts the amount before it's saved into the datastore2
		return math.round(value)
	end)

	player.Chatted:Connect(function(msg)
		if player:GetRankInGroup(GROUP_ID) < 101 then
			return
		end

		-- TODO: add chat commands
		if msg == "/addkills" then
			self:Increment(player) -- need to send the amount to increment by through message
		end
	end)
end

function ValueService:KnitStart()
	for _, player in pairs(Players:GetPlayers()) do
		self:PlayerAdded(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:PlayerAdded(player)
	end)

	--[[
	Knit.GetService("PrestigeService").Changed:Connect(function(player)
		local multiplier = self:GetMultiplier(player)
		self.Client.Multiplier:SetFor(player, multiplier)
	end)
	
	]]

end

--[[
function CoinService.Client:Collect(player, instance)
	local comp = Star:FromInstance(instance)

	if not comp then
		warn("Tried to collect a coin that wasn't a star")
		return
	end

	comp:Collect(player)
end
]]


function ValueService:GetMultiplier(player)
	local playersBonks = self.Client.Amount:GetFor(player)

	local multiplier = 1 + playersBonks * 0.1

	return multiplier
end

function ValueService:Increment(player, amount, ignoreMultiplier)
	local coinStore = Datastore2(VALUE_DS_NAME, player)

	if not ignoreMultiplier then
		amount *= self:GetMultiplier(player)
	end

	coinStore:Increment(amount)
	--TopCoinCollector.CoinsCollected:Fire(player, amount) -- this is to keep track on leaderboards
	--Knit.GetService("BadgeAwardingService"):CoinsCollected(player, amount)
end

function ValueService:Remove(player, amount)
	local coinStore = Datastore2(VALUE_DS_NAME, player)
	coinStore:Increment(-amount)
end

function ValueService:Set(player, amount)
	local coinStore = Datastore2(VALUE_DS_NAME, player)
	coinStore:Set(amount)
end

function ValueService:Get(player)
	local coinStore = Datastore2(VALUE_DS_NAME, player)
	return coinStore:Get(DEFAULT_BONKS)
end

return ValueService
