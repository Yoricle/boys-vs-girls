local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- component extensions
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local Component = require(ReplicatedStorage.Packages.Component)

local Surfaces = {"TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface"}

--[[
    if player on the opposing team steals your plane, it changes the colour to their team
    if a player on your own team tries taking your plane, they won't be able to
]]
local HingSurfaces = {"Hinge", "Motor", "SteppingMotor"}

-- constants
local NEVER_BREAK_JOINTS = false

local Plane = Component.new({ Tag = "Plane", Extensions = {TroveAdder} })

function Plane:Construct()
    -- children of the plane
    self._engine = self.Instance.Engine
    self._vehicleSeat = self.Instance.VehicleSeat

    self.Parts = {}

    self._seatWeld = nil
end

function Plane:Start()
    print("Plane Started")
    local Weld = self:PerfectionWeld()

    if Weld and script.ClassName == "Script" then
        self.Instance.AncestryChanged:Connect(function()
            self:PerfectionWeld()
        end)
    end
    self:SeatWeldAdded()
    self:SeatWeldRemoved()
    self:RandomizePlaneColour()
end

function Plane:CallOnChildren(Instance, FunctionToCall)
    	-- Calls a function on each of the children of a certain object, using recursion.  

	FunctionToCall(Instance)

	for _, Child in next, Instance:GetChildren() do
		self:CallOnChildren(Child, FunctionToCall)
	end
end

function Plane:GetBricks(StartInstance)
    local List = {}

	-- if StartInstance:IsA("BasePart") then
	-- 	List[#List+1] = StartInstance
	-- end

	self:CallOnChildren(StartInstance, function(Item)
		if Item:IsA("BasePart") then
			List[#List+1] = Item;
		end
	end)

	return List
end

function Plane:PerfectionWeld()
    local Tool = self:GetNearestParent(script, "Tool")

	local Parts = self:GetBricks(self.Instance)
    print(Parts)
    print(self.Instance.PrimaryPart)
	local PrimaryPart =  self.Instance:IsA("Model") and self.Instance.PrimaryPart or Parts[1]

	if PrimaryPart then
		self:WeldParts(Parts, PrimaryPart, "Weld", false)
	else
		warn("qWeld - Unable to weld part")
	end
	
	return Tool
end

function Plane:SeatWeldAdded()
    -- detect the weld that becomes attached
    self._vehicleSeat.ChildAdded:Connect(function(child)
        print(child)
        if child.Name=="SeatWeld" then
            self._seatWeld = child
            local player = game.Players:GetPlayerFromCharacter(child.Part1.Parent) -- Character
            self.Instance:SetAttribute("OwnerId", player.Name)
            self.Instance:SetAttribute("Active", true)
            print(player)
        end
    end)
end

function Plane:HasWheelJoint(Part)
    for _, SurfaceName in pairs(Surfaces) do
		for _, HingSurfaceName in pairs(HingSurfaces) do
			if Part[SurfaceName].Name == HingSurfaceName then
				return true
			end
		end
	end
	
	return false
end

function Plane:ShouldBreakJoints(Part)
    	--- We do not want to break joints of wheels/hinges. This takes the utmost care to not do this. There are
	--  definitely some edge cases. 

	if NEVER_BREAK_JOINTS then
		return false
	end
	
	if self:HasWheelJoint(Part) then
		return false
	end
	
	local Connected = Part:GetConnectedParts()
	
	if #Connected == 1 then
		return false
	end
	
	for _, Item in pairs(Connected) do
		if self:HasWheelJoint(Item) then
			return false
		elseif not Item:IsDescendantOf(script.Parent) then
			return false
		end
	end
	
	return true
end

function Plane:WeldParts(Parts, MainPart, JointType, DoNotUnanchor)
	for _, Part in pairs(Parts) do
		if self:ShouldBreakJoints(Part) then
			Part:BreakJoints()
		end
	end
	
	for _, Part in pairs(Parts) do
		if Part ~= MainPart then
			self:WeldTogether(MainPart, Part, JointType, MainPart)
		end
	end

	if not DoNotUnanchor then
		for _, Part in pairs(Parts) do
			Part.Anchored = false
		end
		MainPart.Anchored = false
	end
end

function Plane:Modify(Instance, Values)
    	-- Modifies an Instance by using a table.  

	assert(type(Values) == "table", "Values is not a table");

	for Index, Value in next, Values do
		if type(Index) == "number" then
			Value.Parent = Instance
		else
			Instance[Index] = Value
		end
	end
	return Instance
end

function Plane:WeldTogether(Part0, Part1, JointType, WeldParent)
    	--- Weld's 2 parts together
	-- @param Part0 The first part
	-- @param Part1 The second part (Dependent part most of the time).
	-- @param [JointType] The type of joint. Defaults to weld.
	-- @param [WeldParent] Parent of the weld, Defaults to Part0 (so GC is better).
	-- @return The weld created.

	JointType = JointType or "Weld"
	local RelativeValue = Part1:FindFirstChild("qRelativeCFrameWeldValue")
	
	local NewWeld = Part1:FindFirstChild("qCFrameWeldThingy") or Instance.new(JointType)
	self:Modify(NewWeld, {
		Name = "qCFrameWeldThingy";
		Part0  = Part0;
		Part1  = Part1;
		C0     = CFrame.new();--Part0.CFrame:inverse();
		C1     = RelativeValue and RelativeValue.Value or Part1.CFrame:toObjectSpace(Part0.CFrame); --Part1.CFrame:inverse() * Part0.CFrame;-- Part1.CFrame:inverse();
		Parent = Part1;
	})

	if not RelativeValue then
		RelativeValue = self:Make("CFrameValue", {
			Parent     = Part1;
			Name       = "qRelativeCFrameWeldValue";
			Archivable = true;
			Value      = NewWeld.C1;
		})
	end

	return NewWeld
end

function Plane:Make(ClassType, Properties)
    return self:Modify(Instance.new(ClassType), Properties)
end

function Plane:SeatWeldRemoved()
    -- weld removed when character jumps off
    self._vehicleSeat.ChildRemoved:Connect(function(child)
        if child == self._seatWeld then
            self.Instance:SetAttribute("Active", false)
            --self._vehicleSeat.Disabled = true
        end
    end)
end

function Plane:GetNearestParent(Instance, ClassName)
    	-- Returns the nearest parent of a certain class, or returns nil

	local Ancestor = Instance
	repeat
		Ancestor = Ancestor.Parent
		if Ancestor == nil then
			return nil
		end
	until Ancestor:IsA(ClassName)

	return Ancestor
end

function Plane:FireRockets()
    --[[
        can't kill team mates
    ]]
end

function Plane:RandomizePlaneColour()
    task.spawn(function()
        local color = BrickColor.random()
        for i, v in pairs(self.Instance:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Name == "Color" or v.Name == "Body" then
                    v.BrickColor = color
                end			
            end
        end
    end)
end

function Plane:FireRocket()
    -- Rockets will be fired with 'F'
    -- mobile rockets will display a button to fire
end

function Plane:DropBombs()
    -- Bombs will be dropped with 'B'
    -- mobile bombs will display a button to fire
end

function Plane:FireMachineGun()
    
end

function Plane:Stop()
    print(self.Instance.Name .. " has been cleaned")
end

return Plane