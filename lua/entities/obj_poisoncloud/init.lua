AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = "models/fallout/goregrenade.mdl"
ENT.ParticleTrail = "antlion_gib_02_gas"
ENT.ParticleTrailSmoke = "antlion_gib_02_gas"
function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetMoveCollide(COLLISION_GROUP_PROJECTILE)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_CUSTOM)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(1)
		phys:EnableDrag(false)
		phys:EnableGravity(false)
		phys:SetBuoyancyRatio(0)
	end

	self.m_dmg = 40
	self.m_force = vector_origin
	self.m_dmgType = DMG_POISON
	self.m_sndHit = "npc/antlion/antlion_shoot1.wav"
	self.cspSound = CreateSound(self,"npc/antlion/antlion_poisonball1.wav")
	self.cspSound:Play()
	local pos = self:GetPos()
	local ang = self:GetAngles()
	self:DeleteOnRemove(util.ParticleEffect(self.ParticleTrail,pos,ang,self,nil,false))
	self:DeleteOnRemove(util.ParticleEffect(self.ParticleTrailSmoke,pos,ang,self,nil,false))
	self.m_flSpeed = 250
	self.delayRemove = CurTime() +15
	self.nextpoisont = 0
end

function ENT:SetEntityOwner(ent)
	self:SetOwner(ent)
	self.entOwner = ent
end

function ENT:OnHit(ent,dist)
	if(ent:IsPlayer()) then if(ent.AddEffect) then ent:AddEffect("AnimalPoison",true,0.2,24,2,self) end end
end

function ENT:PhysicsCollide(data, physobj)
	local valid = IsValid(self.entOwner)
	-- if CurTime() > self.nextpoisont then
		sound.Play(self.m_sndHit,self:GetPos(),75,100)
		-- local tbEnts = util.DealBlastDamage(self:GetPos(),200,5,vector_origin,valid && self.entOwner || self,self,true,DMG_POISON,function(ent)
		local tbEnts = util.DealBlastDamage(self:GetPos(),450,self.m_dmg,vector_origin,valid && self.entOwner || self,self,true,DMG_POISON,function(ent)
			if(!valid) then return true end
			local disp = self.entOwner:Disposition(ent)
			return disp == D_HT || disp == D_FR
		end)
		for ent,dist in pairs(tbEnts) do self:OnHit(ent,dist) end
		self:Remove()
		self.nextpoisont = CurTime() +0.3
	-- end
	return true
end

function ENT:OnRemove()
	if self.cspSound then self.cspSound:Stop() end
end

function ENT:LookForTarget()
	local pos = self:GetPos()
	local dist = math.huge
	local entTgt
	for _,ent in ipairs(ents.FindInSphere(self:GetPos(),18000)) do
		if (ent:IsNPC() || (ent:IsPlayer() && ent:GetMoveType() != MOVETYPE_NOCLIP && GetConVarNumber("ai_ignoreplayers") == 0 && (self.entOwner:IsPlayer() && gamemode.Call("CanPlayerDamagePlayer",ent,self.entOwner) || self.entOwner:IsNPC()))) && ent:Alive() && (!ent:IsNPC() || ent:Disposition(self.entOwner) == D_HT) && self:Visible(ent) then
			local distEnt = ent:NearestPoint(pos):Distance(pos)
			if(distEnt < dist) then
				dist = distEnt
				entTgt = ent
			end
		end
	end
	return entTgt || NULL
	-- for _, ent in ipairs(self:SLVFindInCone(35,8000,function(ent) return (ent:IsNPC() || (ent:IsPlayer() && (self.entOwner:IsPlayer() && gamemode.Call("CanPlayerDamagePlayer",ent,self.entOwner) || self.entOwner:IsNPC()))) && ent:Alive() && (!ent:IsNPC() || ent:Disposition(self.entOwner) == D_HT) && self:Visible(ent) end)) do
		-- local distEnt = ent:NearestPoint(pos):Distance(pos)
		-- if(distEnt < dist) then
			-- dist = distEnt
			-- entTgt = ent
		-- end
	-- end
	-- return entTgt || NULL
end

ENT.nextpat = 0
function ENT:Think()
	if CurTime() > self.nextpat then
		self:DeleteOnRemove(util.ParticleEffect(self.ParticleTrail,self:GetPos(),self:GetAngles(),self,nil,false))
		self.nextpat = CurTime() +0.1
	end
	local phys = self:GetPhysicsObject()
	if(!phys:IsValid()) then return end
	if(CurTime() > self.delayRemove) then
		self:Remove()
	end
	local b
	if(IsValid(self.entOwner)) then
		if(!IsValid(self.entTgt) || !self.entTgt:Alive()) then self.entTgt = self:LookForTarget() end
		if(self.entTgt:IsValid()) then
			local ang = (self.entTgt:GetCenter() -(self:GetPos() +self:OBBCenter())):Angle()
			self:TurnDegree(1,ang,true)
			self:NextThink(CurTime())
			b = true
		end
	end
	phys:SetVelocity(self:GetForward() *self.m_flSpeed)
	return b
end