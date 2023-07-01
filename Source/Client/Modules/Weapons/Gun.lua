local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local OnlyLocalPlayer = require(ReplicatedStorage.ComponentExtensions.OnlyLocalPlayer)

-- viewmodels
local AmmoViewModel = require(script.Parent.UI.AmmoViewModel)

-- inputs
local PreferredInput = require(ReplicatedStorage.Packages.Input).PreferredInput
local Keyboard = require(ReplicatedStorage.Packages.Input).Keyboard
local Mouse = require(ReplicatedStorage.Packages.Input).Mouse

-- signals
local Comm = require(ReplicatedStorage.Packages.Comm)
local ClientComm = Comm.ClientComm

local Player = Players.LocalPlayer

local CanTeamkill = false
local FirstPersonArms = true
local HeadshotDamage = true
local IgnoreHats = true

local Cursors = { "rbxasset://textures\\GunCursor.png" }
local ReloadCursor="rbxasset://textures\\GunWaitCursor.png"

local ObjectLocalTransparencyModifier
local LocalObjects = {}

local equiped = false

local RayLength = 1000

local enabled = true
local reloading = false
local down = false

local Gun = Component.new({ Tag = "Gun", Extensions = { TroveAdder } })

--[[
	All the constant values on the weapons need their own attribute to determine how to fire, this also makes it easier to add new guns etc.
	new viewModel for every gun generated
	somehow need to make it so that when it equips/unequips it checks for the attributes and the gun barrel position

]]

function Gun:Construct()
    self._comm = ClientComm.new(self.Instance)
    self._gunFire = self._comm:GetSignal("GunFire")
    self._tagHumanoid = self._comm:GetSignal("TagHumanoid")
    self._takeDamage = self._comm:GetSignal("TakeDamage")
    self._playSound = self._comm:GetSignal("PlaySound")

	-- descendants
	self._handle = self.Instance.Handle
	self.attachment = self._handle.Attachment
	self._pointLight = self.Instance.Handle.PointLight

	--self.BarrlePos = self.attachment.Position

    -- audio
    self.equip = self._handle.Equip
    self.fire = self._handle.Fire
    self.reload = self._handle.Reload
    self.trigger = self._handle.Trigger

	-- property attributes	
	self.ClipSize = self.Instance:GetAttribute("Clip") -- clipsize
	self.ReloadTime = self.Instance:GetAttribute("ReloadTime")
	self.Firerate = self.Instance:GetAttribute("FireRate")
	self.MinSpread = self.Instance:GetAttribute("MinSpread")
	self.MaxSpread = self.Instance:GetAttribute("MaxSpread")
	self.SpreadRate = self.Instance:GetAttribute("SpreadRate")
	self.Spread = self.Instance:GetAttribute("Spread")
	self.BaseDamage = self.Instance:GetAttribute("BaseDamage")
	self.automatic = self.Instance:GetAttribute("Automatic")
	self.burst = self.Instance:GetAttribute("Burst")
	self.shot = self.Instance:GetAttribute("Shot")

	self.character = Player.Character or Player.Character:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")

	self._params = RaycastParams.new()

	self.viewModel = AmmoViewModel.new(self.Instance) -- passing the weapon

    self.mouse = Player:GetMouse()
	print(self.Instance.Name .. " constructed")
end

function Gun:InputTypeChanged(input)
	local shouldBeActive = input == "Touch"

	--if shouldBeActive ~= viewModel.active then
		--viewModel:setActive(shouldBeActive)
	--end
end

local function Down(Instance)
	print(Instance)
end

local function Up(Instance)
	print(Instance)
end

function Gun:Start()

	local keyboard = Keyboard.new()
	local mouse = Mouse.new()

	keyboard.KeyDown:Connect(function(key)
		if not equiped then
            return
        end
		self:onKeyDown(key) 
	end)

    self.Instance.Equipped:Connect(function(instance)
		local BarrelPosition = self.Instance.Handle.Attachment.Position
		local Handle = self.Instance.Handle

        self:onEquippedLocal(BarrelPosition)
		Knit.GetController("WeaponController"):MountAmmoUI(self.viewModel, instance)

		self.buttonDown = self.mouse.Button1Down:Connect(function(...)
			self:onButton1Down(BarrelPosition, Handle)
		end)
		
		self.buttonUp = self.mouse.Button1Up:Connect(function(...)
			self:onButton1Up()
		end)
    end)

    self.Instance.Unequipped:Connect(function(instance)
		if self.bulletTrain then
			self.bulletTrain = nil
		end

		-- if event exists, disconnect
		if self.buttonDown then self.buttonDown:Disconnect() end
		if self.buttonUp then self.buttonUp:Disconnect() end

        self:onUnequippedLocal()
		Knit.GetController("WeaponController"):UnmountAmmoUI(self.viewModel, instance)
    end)

	--self.Instance.Activated:Connect(function(...)end)

    game.Workspace.ChildAdded:Connect(function(child)
        if child.Name == Player.Name.."Bullet" then
            child.Transparency = 1
        end
    end)
end

function Gun:onKeyDown(key)
	if key == Enum.KeyCode.R and not reloading then
		self:Reload()
	end
end

function Gun:SetIgnoreList()
	local ignoreList = {self.Instance, Player.Character}

	for _, part in pairs(CollectionService:GetTagged("Gun")) do
		table.insert(ignoreList, part)
	end

	self._params.FilterDescendantsInstances = ignoreList
end

function Gun:Bullet()
    local Bullet = Instance.new("Part")
    Bullet.Name = "Bullet"
    Bullet.BrickColor = BrickColor.new("Bright yellow")
    Bullet.Anchored = true
    Bullet.CanCollide = false
    Bullet.Locked = true
    Bullet.Size = Vector3.new(1,1,1)
    Bullet.formFactor = 0
    Bullet.TopSurface = 0
    Bullet.BottomSurface = 0
    Bullet.Material = Enum.Material.Neon
    local Mesh = Instance.new("SpecialMesh")
    Mesh.Parent = Bullet
    Mesh.MeshType = "Brick"
    Mesh.Name = "Mesh"
    Mesh.Scale = Vector3.new(.15,.15,1)
    return Bullet
end

function Gun:onButton1Up()
    down = false
end

function Gun:onButton1Down(BarrelPosition, Handle)
	if not enabled or reloading or down or self.humanoid == nil then
		return
	end
	if self.viewModel.ammo > 0 and self.humanoid.Health > 0 then
		down = true
		enabled = false
		while down do
			if self.viewModel.ammo <= 0 then
				break
			end
			if self.burst then
				local startpoint = Handle.CFrame * BarrelPosition
				local mag = (self.mouse.Hit.p-startpoint).magnitude
				local rndm = Vector3.new(math.random(-(self.Spread / 10)*mag,(self.Spread / 10)*mag),math.random(-(self.Spread / 10)*mag,(self.Spread / 10) * mag), math.random(-(self.Spread / 10) * mag,(self.Spread / 10) * mag))
				self:Fire(self.Hit.p + rndm, BarrelPosition, Handle)
				self.viewModel:setAmmo(self.viewModel.ammo - 1)
				if self.viewModel.ammo <= 0 then
					break
				end
				task.wait(.05)
				local startpoint = self._handle.CFrame * BarrelPosition
				local mag2 = ((self.mouse.Hit.p+rndm)-startpoint).magnitude
				local rndm2 = Vector3.new(math.random(-(.1/10) * mag2,(.1/10)*mag2),math.random(-(.1/10)*mag2,(.1/10)*mag2),math.random(-(.1/10)*mag2,(.1/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm2, BarrelPosition, Handle)
				self.viewModel:setAmmo(self.viewModel.ammo - 1)
				if self.viewModel.ammo <= 0 then
					break
				end
				task.wait(.05)
				self:Fire(self.mouse.Hit.p+rndm+rndm2+rndm2, BarrelPosition, Handle)
				--Knit.GetController("WeaponController"):setAmmo(-1)
				self.viewModel:setAmmo(self.viewModel.ammo - 1)
			elseif self.shot then
				self.viewModel:setAmmo(self.viewModel.ammo - 1)
				local startpoint = self.Instance.Handle.CFrame * BarrelPosition
				local mag=(self.mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(self.Spread / 10) * mag,(self.Spread / 10) * mag),math.random(-(self.Spread / 10) * mag,(self.Spread / 10) * mag),math.random(-(self.Spread / 10) * mag,(self.Spread / 10) * mag))
				self:Fire(self.mouse.Hit.p + rndm, BarrelPosition, Handle)
				local mag2=((self.mouse.Hit.p+rndm)-startpoint).magnitude
				local rndm2=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2), math.random(-(.2/10)*mag2,(.2/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm2, BarrelPosition, Handle)
				local rndm3=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2), math.random(-(.2/10)*mag2,(.2/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm3, BarrelPosition, Handle)
				local rndm4=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2), math.random(-(.2/10)*mag2,(.2/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm4, BarrelPosition, Handle)
			else
				self.viewModel:setAmmo(self.viewModel.ammo - 1)
				local startpoint = self._handle.CFrame * BarrelPosition
				local mag=(self.mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(self.Spread / 10) * mag,(self.Spread / 10) * mag), math.random(-(self.Spread / 10) * mag,(self.Spread / 10) * mag), math.random(-(self.Spread / 10) * mag,(self.Spread / 10) *mag))
				self:Fire(self.mouse.Hit.p + rndm, BarrelPosition, Handle)
			end
			task.wait(self.Firerate)
			if not self.automatic then
				break
			end
		end	
		enabled = true
	else
		self._playSound:Fire(self.trigger)
	end
end


function Gun:bulletEffect(bullet, distance)
    if distance > 40 then
		local bulletLength = distance / 2
		bullet.Mesh.Scale=Vector3.new(.15,.15, bulletLength)
		bullet.Mesh.Offset=Vector3.new(0,0, bulletLength/2)
		while bullet.Mesh.Offset.Z > (bulletLength / 2) * -1 do
			task.wait()
			bullet.Mesh.Offset=Vector3.new(0, 0, bullet.Mesh.Offset.Z - 20) 
		end
	else
		bullet.Mesh.Scale = Vector3.new(.15, .15, distance)
		bullet.Mesh.Offset = Vector3.new(0, 0, distance / 2)
		task.wait(0.03)
	end
	bullet:Destroy()
end

function Gun:Reload()
    self._playSound:Fire(self.reload)
	reloading = true
	self.mouse.Icon = ReloadCursor
	while self.viewModel.ammo < self.viewModel.clip and reloading and enabled do
		task.wait(self.ReloadTime / self.viewModel.clip)
		if reloading then
			--viewModel:setAmmo(1)
			self.viewModel:setAmmo(self.viewModel.ammo + 1)
			print(self.viewModel.ammo)
		else
			break
		end
	end
	self.mouse.Icon = Cursors[1]
	reloading = false
end

function Gun:onEquippedLocal(BarrelPosition)
    self._playSound:Fire(self.equip)

    if self.mouse == nil then
		print("Mouse not found")
		return 
	end

	local Limbs = {"Right Arm", "RightHand", "RightUpperArm", "RightLowerArm"}

	for i, v in pairs(Limbs) do
		local Limb = self.Instance.Parent:FindFirstChild(v)
		self:ArmsTransparency(Limb)
	end

	self.mouse.Icon = Cursors[1]

	equiped = true

	if #Cursors > 1 then
		while equiped do
			self.bulletTrain = RunService.Stepped:Wait()
			local action = self.Instance.Parent:FindFirstChild("Pose")
			if action ~= nil then
				if self.Instance.Parent.Pose.Value == "Standing" then
					self.Spread = self.MinSpread
				else
					self.Spread = self.MinSpread + ((4/10) * (self.MaxSpread - self.MinSpread))
				end
			else
				self.Spread = self.MinSpread
			end
			if self.bulletTrain - self.last < self.SpreadRate then
				self.Spread = self.Spread + .1*(self.MaxSpread - self.MinSpread)
			end
			if self.bulletTrain - self.last2 < self.SpreadRate then
				self.Spread = self.Spread + .1*(self.MaxSpread - self.MinSpread)
			end
			if self.bulletTrain - self.last3 < self.SpreadRate then
				self.Spread = self.Spread + .1*(self.MaxSpread - self.MinSpread)
			end
			if self.bulletTrain - self.last4 < self.SpreadRate then
				self.Spread = self.Spread + .1*(self.MaxSpread - self.MinSpread)
			end
			if self.bulletTrain - self.last5 < self.SpreadRate then
				self.Spread = self.Spread + .1*(self.MaxSpread - self.MinSpread)
			end
			if self.bulletTrain - self.last6 < self.SpreadRate then
				self.Spread = self.Spread + .1*(self.MaxSpread - self.MinSpread)
			end
			if not reloading then
				local percent = (self.Spread - self.MinSpread) / (self.MaxSpread - self.MinSpread)
				for i = 0, #Cursors - 1 do
					if percent>(i/(#Cursors-1))-((1/(#Cursors-1))/2) and percent<(i/(#Cursors-1))+((1/(#Cursors-1))/2) then
						self.mouse.Icon=Cursors[i+1]
					end
				end
			end
			task.wait(self.Firerate * .9)
		end
	end
end


function Gun:onUnequippedLocal(mouse)
	if ObjectLocalTransparencyModifier then
		ObjectLocalTransparencyModifier:Disconnect()
	end
	local camera = game.Workspace.CurrentCamera
	if (camera.focus.p - camera.CoordinateFrame.p).magnitude <= 1 then
		for i, v in pairs(LocalObjects) do
			if v.Object then
				v.Object.LocalTransparencyModifier = 1
			end
		end
	end
	LocalObjects = {}
	
	equiped = false
	reloading = false
end

function Gun:ArmsTransparency(Limb)
	if FirstPersonArms then
		local value = {Object = Limb, Transparency = 0, AutoUpdate = true}
		pcall(function()
			local ObjectFound = false
			for i, v in pairs(LocalObjects) do
				if v == value then
					ObjectFound = true
				end
			end
			if not ObjectFound then
				table.insert(LocalObjects, value)
				if ObjectLocalTransparencyModifier then
					ObjectLocalTransparencyModifier:Disconnect()
				end
				ObjectLocalTransparencyModifier = RunService.RenderStepped:Connect(function()
					local Camera = game:GetService("Workspace").CurrentCamera
					for i, v in pairs(LocalObjects) do
						if v.Object and v.Object.Parent then
							local CurrentTransparency = v.Object.LocalTransparencyModifier
							local ViewDistance = (Camera.CoordinateFrame.p - self.character.Head.Position).Magnitude
							if ((not v.AutoUpdate and (CurrentTransparency == 1 or CurrentTransparency == 0)) or v.AutoUpdate) then
								if ((v.Distance and ViewDistance <= v.Distance) or not v.Distance) then
									v.Object.LocalTransparencyModifier = v.Transparency
								else
									v.Object.LocalTransparencyModifier = 0
								end
							end
						else
							table.remove(LocalObjects, i)
						end
					end
				end)
			end
		end)
	end
end

function Gun:bulletFireLoop()
	self.bulletTrain = RunService.Stepped:Wait() -- streaming bullets I believe
	self.last6 = self.last5
	self.last5 = self.last4
	self.last4 = self.last3
	self.last3 = self.last2
	self.last2 = self.last
	self.last = self.bulletTrain
end

function Gun:CheckTeamMate(humanoid, damage, headshot)
	if humanoid.Health > 0 then
		local Enemy = Players:GetPlayerFromCharacter(humanoid.Parent) -- enemy you're firing at

		if not Enemy then -- if the player can't be found and it has health, it's a test dummy
			local damageatt = humanoid.Parent:GetAttribute("Damage") -- get attribute from dummy
			local teamatt = humanoid.Parent:GetAttribute("Team") -- team attribute from dummy

			if damageatt == false then
				return 
			end

			if not damageatt then
				return
			end
			self._tagHumanoid:Fire(humanoid)
			self._takeDamage:Fire(humanoid, damage, headshot)
		end
		
		if Enemy then -- this means it's a player, so we can check for team colours etc.
			if Enemy.TeamColor == Player.TeamColor or Enemy.Neutral then
				return
			end
			-- deal damage
			self._tagHumanoid:Fire(humanoid)
			self._takeDamage:Fire(humanoid, damage, headshot)
		end
	end
end

function Gun:Fire(aim, BarrelPosition, Handle)
	-- humanoid
    if self.humanoid.Health < 1 then -- meaning character is already dead before firing
		return
	end

	-- firing bullets
	self._playSound:Fire(self.fire)
	self:bulletFireLoop()

	local bullet = self:Bullet() -- returns bullet
	local origin =  Handle.CFrame * BarrelPosition
	local direction = (aim - origin).Unit

	local result = workspace:Raycast(origin, direction * 300, self.raycastParams)

	local intersection = result and result.Position or origin + direction
	local distance = (origin - intersection).magnitude

	bullet.Parent = game.Workspace.CurrentCamera -- parenting the bullet when fired
	
	self._gunFire:Fire(origin, intersection, self._pointLight)

	if not result then
		print("no result")
	end

	if result then
		local humanoid = result.Instance.Parent:FindFirstChild("Humanoid")

		if not humanoid then
			humanoid = result.Instance.Parent.Parent:FindFirstChild("Humanoid")
		end

		if humanoid then
			local damage = math.random(self.BaseDamage - (self.BaseDamage * .75), self.BaseDamage + (self.BaseDamage * .75))
			local headshot = false

			if result.Instance.Name == "Head" and HeadshotDamage then
				damage = damage * 1.3
				headshot = true
			else
				damage = damage * .75
			end
			self:CheckTeamMate(humanoid, damage, headshot)
		end
	end

	if distance > 40 then
		bullet.CFrame = CFrame.new(origin, intersection) * CFrame.new(0, 0, -distance / 2)
	else
		bullet.CFrame = CFrame.new(origin, intersection) * CFrame.new(0, 0, -distance)
	end
	task.spawn(function()
		self:bulletEffect(bullet, distance)
	end)
end

function Gun:Stop()
	print(self.Instance.Name .. " being destroyed")
	if ObjectLocalTransparencyModifier then
		ObjectLocalTransparencyModifier:Disconnect()
	end

	if self.Input then
		self.input:Disconnect()
	end
end

return Gun