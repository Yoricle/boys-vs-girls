local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local Comm = require(ReplicatedStorage.Packages.Comm)

local ServerComm = Comm.ServerComm

local function Bullet()
    local Bullet =Instance.new("Part")
    Bullet.Name ="Bullet"
    Bullet.BrickColor =BrickColor.new("Bright yellow")
    Bullet.Anchored = true
    Bullet.CanCollide = false
    Bullet.Locked = true
    Bullet.Size = Vector3.new(1,1,1)
    Bullet.formFactor = 0
    Bullet.TopSurface = 0
    Bullet.BottomSurface = 0
    Bullet.Transparency = 1
    Bullet.Material = Enum.Material.Neon
    local Mesh = Instance.new("SpecialMesh")
    Mesh.Parent = Bullet
    Mesh.MeshType = "Brick"
    Mesh.Name = "Mesh"
    Mesh.Scale = Vector3.new(.15,.15,1)
    return Bullet
end

local Gun = Component.new({ Tag = "Gun", Extensions = {TroveAdder} })

function Gun:Construct()
    self._comm = ServerComm.new(self.Instance)
    self._gunFire = self._comm:CreateSignal("GunFire")
    self._tagHumanoid = self._comm:CreateSignal("TagHumanoid")
    self._takeDamage = self._comm:CreateSignal("TakeDamage")
    self._playSound = self._comm:CreateSignal("PlaySound")

end


function Gun:Start()
    self._gunFire:Connect(function(player, startpoint, pos)
        self:ActivateGun(player, startpoint, pos)
    end)

    -- make player take damage
    self._takeDamage:Connect(function(player, humanoid, damage, head)
        self:TakeDamage(player, humanoid, damage, head)
    end)

    self._playSound:Connect(function(player, sound)
        self:PlaySound(player, sound)
    end)
    
    self._tagHumanoid:Connect(function(player, humanoid)
        local tag = Instance.new("ObjectValue")
        tag.Value = player
        tag.Name = "creator"
        tag.Parent = humanoid
        task.delay(2,function()
            if tag ~= nil then
                tag.Parent = nil
            end
        end)
    end)
end

function Gun:PlaySound(player, sound)
    
end

function Gun:ActivateGun(player, startpoint, pos)
    local newBullet = Bullet()
    newBullet.Name = player.Name.."Bullet"
    local distance=(startpoint-pos).magnitude
    local bulletLength = distance/2
    if distance > 40 then
        newBullet.CFrame=CFrame.new(startpoint, pos) * CFrame.new(0, 0, -distance / 2)
        newBullet.Mesh.Scale=Vector3.new(.15,.15,bulletLength)
        newBullet.Mesh.Offset=Vector3.new(0,0,bulletLength/2)
    else
        newBullet.CFrame=CFrame.new(startpoint, pos) * CFrame.new(0, 0, -distance)
        newBullet.Mesh.Scale=Vector3.new(.15,.15,distance)
        newBullet.Mesh.Offset=Vector3.new(0,0,distance/2)
    end
    newBullet.Transparency = 0
    newBullet.Parent = game.Workspace
    if distance > 40 then
        while newBullet.Mesh.Offset.Z > (bulletLength/2)*-1 do
            task.wait()
            newBullet.Mesh.Offset=Vector3.new(0,0,newBullet.Mesh.Offset.Z-20) 
        end
    else
        task.wait(0.03)
    end
    newBullet:Destroy()
end

function Gun:Stop()

end

return Gun