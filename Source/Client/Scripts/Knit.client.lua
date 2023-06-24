--[[
-- Created on Thu Aug 05 2023
--
-- Copyright (c) 2022 Yoricle
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local Directory = ReplicatedStorage.Source.Client.Modules

for _, v in pairs(Directory:GetDescendants()) do
	if not v:IsA("ModuleScript") then
		continue
	end

	if not v.Name:find("Controller") then
		continue
	end

	--[[
	if not v.Name:find("Button") then -- required in the door
		continue
	end
	]]

	require(v)
end

Knit.Start()
	:andThen(function()
		for _, v in pairs(Directory:GetDescendants()) do
			if not v:IsA("ModuleScript") then
				continue
			end

			if v.Name:find(".story") then
				continue
			end

			task.spawn(function()
				debug.setmemorycategory(v.Name)
				require(v)
			end)
		end
	end)
	:catch(warn)
