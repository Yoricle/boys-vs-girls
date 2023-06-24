local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local Comm = require(ReplicatedStorage.Packages.Comm)

local ClientComm = Comm.ClientComm

local Player = Players.LocalPlayer

local CanTeamkill = false
local FirstPersonArms = true
local HeadshotDamage = true
local IgnoreHats = true

local ClipSize=8
local ReloadTime=2.2
local Firerate=.9
local MinSpread=0.2
local MaxSpread=0.3
local SpreadRate=0.5
local Spread=0.25
local BaseDamage=20
local automatic=false
local burst=false
local shot=true		--Shotgun
local BarrlePos=Vector3.new(-2.4,.60,0)
local Cursors={"rbxasset://textures\\GunCursor.png"}
local ReloadCursor="rbxasset://textures\\GunWaitCursor.png"

local equiped = false

local enabled = true
local reloading = false
local down = false

local Gun = Component.new({ Tag = "Gun", Extensions = { TroveAdder } })

function Gun:Construct()
    self._comm = ClientComm.new(self.Instance)
    self._gunFire = self._comm:GetSignal("GunFire")
    self._tagHumanoid = self._comm:GetSignal("TagHumanoid")
    self._takeDamage = self._comm:GetSignal("TakeDamage")
    self._playSound = self._comm:GetSignal("PlaySound")

    -- descendants
    self._handle = self.Instance.Handle
    self._pointLight = self.Instance.Handle.PointLight

    -- audio
    self.equip = self._handle.Equip
    self.fire = self._handle.Fire
    self.reload = self._handle.Reload
    self.trigger = self._handle.Trigger

    self.mouse = Player:GetMouse()
end

function Gun:Start()
    self.mouse.KeyDown:Connect(function(key)
        if not equiped then
            return
        end
        self:onKeyDown(key) 
    end)

    self.Instance.Equipped:Connect(function(...)
        self:onEquippedLocal(...)
    end)

    self.Instance.Unequipped:Connect(function(...)
        self:onUnequippedLocal(...)
    end)

	self.mouse.Button1Down:Connect(function(...)
        if not equiped then
            return
        end
        self:onButton1Down(...)
    end)

	self.mouse.Button1Up:Connect(function(...) 
        self:onButton1Up(...)
    end)

    game.Workspace.ChildAdded:Connect(function(child)
        if child.Name == Player.Name.."Bullet" then
            child.Transparency = 1
        end
    end)
end

function Gun:onKeyDown(key)
    key = key:lower()
	if key == "r" and not reloading then
		self:Reload()
	end
end

local function getIgnoreList()
	local list = {Player.Character}
	for _,child in pairs(game.Workspace:GetDescendants()) do
		if child:IsA("BasePart") then
			if not child.CanCollide then
				if child.Name == "Handle" and IgnoreHats then
					table.insert(list,child)
				elseif child.Name ~= "Handle" and not child.Parent:FindFirstChild("Humanoid") then
					table.insert(list,child)
				end
			end
		end
	end
	return list
end

function Gun:Bullet()
    local Bullet=Instance.new("Part")
    Bullet.Name="Bullet"
    Bullet.BrickColor=BrickColor.new("Bright yellow")
    Bullet.Anchored=true
    Bullet.CanCollide=false
    Bullet.Locked=true
    Bullet.Size=Vector3.new(1,1,1)
    Bullet.formFactor=0
    Bullet.TopSurface=0
    Bullet.BottomSurface=0
    Bullet.Material = Enum.Material.Neon
    local Mesh=Instance.new("SpecialMesh")
    Mesh.Parent=Bullet
    Mesh.MeshType="Brick"
    Mesh.Name="Mesh"
    Mesh.Scale=Vector3.new(.15,.15,1)
    return Bullet
end

function Gun:onButton1Up()
    down = false
end

function Gun: onButton1Down(mouse)
    local h = self.Instance.Parent:FindFirstChild("Humanoid")
	if not enabled or reloading or down or h==nil then
		return
	end
	if self.Instance.Ammo.Value>0 and h.Health>0 then
		down = true
		enabled = false
		while down do
			if self.Instance.Ammo.Value<=0 then
				break
			end
			if burst then
				local startpoint = self._handle.CFrame * BarrlePos
				local mag = (mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag))
				self:Fire(mouse.Hit.p+rndm)
				self.Instance.Ammo.Value = self.Instance.Ammo.Value-1
				if self.Instance.Ammo.Value<=0 then
					break
				end
				task.wait(.05)
				local startpoint = self._handle.CFrame * BarrlePos
				local mag2=((mouse.Hit.p+rndm)-startpoint).magnitude
				local rndm2=Vector3.new(math.random(-(.1/10)*mag2,(.1/10)*mag2),math.random(-(.1/10)*mag2,(.1/10)*mag2),math.random(-(.1/10)*mag2,(.1/10)*mag2))
				self:Fire(mouse.Hit.p+rndm+rndm2)
				self.Instance.Ammo.Value = self.Instance.Ammo.Value-1
				if self.Instance.Ammo.Value<=0 then
					break
				end
				task.wait(.05)
				self:Fire(mouse.Hit.p+rndm+rndm2+rndm2)
				self.Instance.Ammo.Value = self.Instance.Ammo.Value-1
			elseif shot then
				self.Instance.Ammo.Value = self.Instance.Ammo.Value-1
				local startpoint = self.Instance.Handle.CFrame*BarrlePos
				local mag=(self.mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag))
				self:Fire(self.mouse.Hit.p+rndm)
				local mag2=((self.mouse.Hit.p+rndm)-startpoint).magnitude
				local rndm2=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm2)
				local rndm3=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm3)
				local rndm4=Vector3.new(math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2),math.random(-(.2/10)*mag2,(.2/10)*mag2))
				self:Fire(self.mouse.Hit.p+rndm+rndm4)
			else
				self.Instance.Ammo.Value = self.Instance.Ammo.Value - 1 -- depleet ammo as firing
				local startpoint = self._handle.CFrame*BarrlePos
				local mag=(self.mouse.Hit.p-startpoint).magnitude
				local rndm=Vector3.new(math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag),math.random(-(Spread/10)*mag,(Spread/10)*mag))
				self:Fire(self.mouse.Hit.p+rndm)
			end
			task.wait(Firerate)
			if not automatic then
				break
			end
		end	
		enabled = true
	else
		self._playSound:Fire(self.Trigger)
	end
end


function Gun:bulletEffect(bullet, distance)
    if distance > 40 then
		local bulletLength = distance/2
		bullet.Mesh.Scale=Vector3.new(.15,.15,bulletLength)
		bullet.Mesh.Offset=Vector3.new(0,0,bulletLength/2)
		while bullet.Mesh.Offset.Z > (bulletLength/2) * -1 do
			task.wait()
			bullet.Mesh.Offset=Vector3.new(0,0,bullet.Mesh.Offset.Z-20) 
		end
	else
		bullet.Mesh.Scale=Vector3.new(.15,.15,distance)
		bullet.Mesh.Offset=Vector3.new(0,0,distance/2)
		task.wait(0.03)
	end
	bullet:Destroy()
end



function Gun:Reload()
    self._playSound:Fire(self.reload)
	reloading = true
	self.mouse.Icon = ReloadCursor
	while self.Instance.Ammo.Value<ClipSize and reloading and enabled do
		task.wait(ReloadTime/ClipSize)
		if reloading then
			self.Instance.Ammo.Value = self.Instance.Ammo.Value + 1
		else
			break
		end
	end
	self.mouse.Icon=Cursors[1]
	reloading=false
end

function Gun:onEquippedLocal()
    self._playSound:Fire(self.Equip)

    if self.mouse == nil then
		print("Mouse not found")
		return 
	end
	local Limbs = {"Right Arm", "RightHand", "RightUpperArm", "RightLowerArm"}
	for i, v in pairs(Limbs) do
		local Limb = self.Instance.Parent:FindFirstChild(v)
		self:ArmsTransparency(Limb)
	end
	self.mouse.Icon=Cursors[1]

	equiped=true
	if #Cursors>1 then
		while equiped do
			t = RunService.Stepped:wait()
			local action = self.Instance.Parent:FindFirstChild("Pose")
			if action ~= nil then
				if self.Instance.Parent.Pose.Value=="Standing" then
					Spread=MinSpread
				else
					Spread=MinSpread+((4/10)*(MaxSpread-MinSpread))
				end
			else
				Spread=MinSpread
			end
			if t-last<SpreadRate then
				Spread=Spread+.1*(MaxSpread-MinSpread)
			end
			if t-last2<SpreadRate then
				Spread=Spread+.1*(MaxSpread-MinSpread)
			end
			if t-last3<SpreadRate then
				Spread=Spread+.1*(MaxSpread-MinSpread)
			end
			if t-last4<SpreadRate then
				Spread=Spread+.1*(MaxSpread-MinSpread)
			end
			if t-last5<SpreadRate then
				Spread=Spread+.1*(MaxSpread-MinSpread)
			end
			if t-last6<SpreadRate then
				Spread=Spread+.1*(MaxSpread-MinSpread)
			end
			if not reloading then
				local percent=(Spread-MinSpread)/(MaxSpread-MinSpread)
				for i=0,#Cursors-1 do
					if percent>(i/(#Cursors-1))-((1/(#Cursors-1))/2) and percent<(i/(#Cursors-1))+((1/(#Cursors-1))/2) then
						self.mouse.Icon=Cursors[i+1]
					end
				end
			end
			task.wait(Firerate * .9)
		end
	end
end

local ObjectLocalTransparencyModifier
local LocalObjects = {}

local function onUnequippedLocal(mouse)
	if ObjectLocalTransparencyModifier then
		ObjectLocalTransparencyModifier:disconnect()
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
	
	equiped=false
	reloading=false
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
							local ViewDistance = (Camera.CoordinateFrame.p - self.Instance.Parent.Head.Position).Magnitude
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

function Gun:Fire(aim)
    if self.Instance.Parent.Humanoid.Health < 1 then
		return
	end
	self._playSound:Fire(self.Instance.Handle.Fire)
	
	t = RunService.Stepped:Wait()
	last6 = last5
	last5 = last4
	last4 = last3
	last3 = last2
	last2 = last
	last = t
	local bullet = self:Bullet() -- returns bullet
	local startpoint = self._handle.CFrame*BarrlePos
	local ray = Ray.new(startpoint, (aim - startpoint).unit * 300)
	local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, getIgnoreList(), false, true)
	local distance = (startpoint - position).magnitude
	bullet.Parent=game.Workspace.CurrentCamera
	
	self._gunFire:Fire(startpoint, position, self._pointLight)
	
	if hit ~= nil then
		local humanoid=hit.Parent:FindFirstChild("Humanoid")
		if not humanoid then
			humanoid = hit.Parent.Parent:FindFirstChild("Humanoid")
		end
		if humanoid ~= nil then
			local damage=math.random(BaseDamage-(BaseDamage*.25),BaseDamage+(BaseDamage*.25))
			local headshot = false
			if hit.Name=="Head" and HeadshotDamage then
				damage=damage * 1.3
				--headshot = true
			else
				damage=damage*.75
			end
			if humanoid.Health > 0 then
				local eplr = game.Players:playerFromCharacter(humanoid.Parent)
				local plr = game.Players:playerFromCharacter(self.Instance.Parent)
				if eplr~=nil and plr~=nil then
					if CanTeamkill then
						self._tagHumanoid:Fire(humanoid)
						self._takeDamage:Fire(humanoid,damage,headshot)
					else
						if eplr.TeamColor~=plr.TeamColor or eplr.Neutral or plr.Neutral then
							self._tagHumanoid:Fire(humanoid)
							self._takeDamage:Fire(humanoid,damage,headshot)
						end	
					end
				else
					self._tagHumanoid:Fire(humanoid)
					self._takeDamage:Fire(humanoid, damage, headshot)
				end
			end
		end
	end
	if distance > 40 then
		bullet.CFrame=CFrame.new(startpoint, position) * CFrame.new(0, 0, -distance / 2)
	else
		bullet.CFrame=CFrame.new(startpoint, position) * CFrame.new(0, 0, -distance)
	end
	task.spawn(function()
		self:bulletEffect(bullet, distance)
	end)
end

function Gun:Stop()

end

return Gun