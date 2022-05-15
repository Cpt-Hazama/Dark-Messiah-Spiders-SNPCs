AddCSLuaFile("shared.lua")

include('shared.lua')

ENT.sModel = "models/darkmessiah/spider_regular.mdl"
ENT.fMeleeDistance = 64
ENT.fRangeDistance = 500
ENT.fRangeDistanceLeap = 700
ENT.bFlinchOnDamage = true
ENT.m_bForceDeathAnim = true
ENT.UseActivityTranslator = false
ENT.CanSpit = true
ENT.m_bAttackPoison = true
ENT.BoneRagdollMain = "NPC Root [Root]"
ENT.skName = "spider"
ENT.CollisionBounds = Vector(30,30,25)

ENT.DamageScales = {
	[DMG_PARALYZE] = 0,
	[DMG_NERVEGAS] = 0,
	[DMG_POISON] = 0
}

ENT.iBloodType = BLOOD_COLOR_RED
ENT.sSoundDir = "npc/spider/"

ENT.m_tbSounds = {
	["Attack"] = "spider_striking[0-3].wav",
	["Idle"] = "spider_misc[0-3].wav",
	["Alert"] = "spider_threat[0-4].wav",
	["Death"] = "spider_dying[0-2].wav",
	["Pain"] = "spider_ouch[0-2].wav",
	["Burrow"] = "spider_hail[0-2].wav",
	["Unburrow"] = "spider_guardmode[0-2].wav"
}

ENT.tblFlinchActivities = {
	[HITBOX_GENERIC] = ACT_FLINCH_CHEST,
	[HITBOX_HEAD] = ACT_FLINCH_HEAD,
	[HITBOX_LEFTARM] = ACT_FLINCH_LEFTARM,
	[HITBOX_RIGHTARM] = ACT_FLINCH_RIGHTARM,
	[HITBOX_LEFTLEG] = ACT_FLINCH_LEFTLEG,
	[HITBOX_RIGHTLEG] = ACT_FLINCH_RIGHTLEG
}

ENT.bPlayDeathSequence = true
ENT.tblDeathActivities = {
	[HITBOX_GENERIC] = ACT_DIESIMPLE
}

function ENT:SetupSLVFactions()
	self:SetNPCFaction(NPC_FACTION_SPIDER,CLASS_SPIDER)
end

function ENT:OnInit()
	self:SetHullType(HULL_WIDE_SHORT)
	self:SetHullSizeNormal()
	self:SetCollisionBounds(self.CollisionBounds,Vector(self.CollisionBounds.x *-1,self.CollisionBounds.y *-1,0))
	
	self:slvCapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_OPEN_DOORS))
	self:slvSetHealth(GetConVarNumber("sk_" .. self.skName .. "_health"))
	self.DigupChance = 3
	if math.random(1,self.DigupChance) == 1 then
		self:SetNoDraw(true)
		timer.Simple(0.2,function()
			if IsValid(self) then
				self:SetNoDraw(false)
				self:SLVPlayActivity(ACT_ARM)
			end
		end)
	end

	self.m_tNextRangeAttack = 0
	self.m_nextJump = 0
	self.m_nextBurrow = 0
	self.m_burrowNextHpRegen = 0
	self.moveSideways = 0
	self.IsDoneJumping = nil
end

function ENT:DamageHandle(dmginfo)
	if(!self.CanBurrow) then return end
	if(self:Health() <= self:GetMaxHealth() *0.44 && !self:KnockedDown() && !self:IsBurrowed() && CurTime() >= self.m_nextBurrow && math.random(1,3) == 1) then
		self:Burrow(math.Rand(8,18))
	end
end

function ENT:SetBurrowed()
	self:Sleep()
	self.m_bBurrowed = true
	self.bInSchedule = true
end

function ENT:KeyValueHandle(key,val)
	if(key == "startburrowed") then
		if(val == 1) then
			self:SetBurrowed()
		end
		return
	end
end

function ENT:IsBurrowed() return self.m_bBurrowed end

function ENT:UnBurrow()
	if(!self:IsBurrowed()) then return end
	self:Wake()
	self.m_bBurrowed = false
	self.bInSchedule = false
	self:CallOnInitialized(function() self:SLVPlayActivity(ACT_ARM) end)
	self.m_unburrow = nil
	self.bFlinchOnDamage = true
	self.m_burrowNextHpRegen = nil
	self.m_nextBurrow = CurTime() +math.Rand(4,30)
end

function ENT:Burrow(tmUnburrow)
	if(self:IsBurrowed()) then return end
	self.m_bBurrowed = true
	if(tmUnburrow) then self.m_unburrow = CurTime() +tmUnburrow end
	self.m_burrowNextHpRegen = CurTime()
	self.bFlinchOnDamage = false
	self:CallOnInitialized(function() self:SLVPlayActivity(ACT_DISARM) end)
end

function ENT:InputHandle(cvar,activator,caller,data)
	if(cvar == "unburrow") then
		self:UnBurrow()
		return true
	end
	if(cvar == "burrow") then
		self:Burrow(math.Rand(8,18))
		return true
	end
	return false
end

function ENT:_PossShouldFaceMoving(possessor)
	return false
end

function ENT:TranslateActivity(act)
	if(act == ACT_IDLE && !self:slvIsOnFire()) then
		local state = self:GetState()
		if(state == NPC_STATE_ALERT || state == NPC_STATE_COMBAT) then return ACT_IDLE_ANGRY end
	end
	return act
end

function ENT:EventHandle(...)
	local event = select(1,...)
	local atk = select(2,...)
	-- print(event,atk)
	if(event == "mattack") then
		local dist = self.fMeleeDistance
		local skDmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash")
		local force
		local ang
		if(atk == "a") then
			force = Vector(50,0,0)
			ang = Angle(50,0,0)
		elseif(atk == "b") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		elseif(atk == "c") then
			force = Vector(50,0,0)
			ang = Angle(-50,0,0)
		elseif(atk == "d") then
			force = Vector(180,0,20)
			ang = Angle(-80,0,0)
		elseif(atk == "e") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		end
		self:DealMeleeDamage(dist,skDmg,ang,force,DMG_SLASH,nil,true,nil,fcHit)
		return true
	end
	if(event == "rattack") then
		if(atk == "web") then
			local att = self:GetAttachment(self:LookupAttachment("attack_head"))
			if(!att) then return true end
			local vTarget
			if(self:SLV_IsPossesed()) then
				vTarget = self:GetPossessor():GetPossessionEyeTrace().HitPos
				local dir = (vTarget -att.Pos):GetNormal()
				vTarget = att.Pos +dir *math.min(att.Pos:Distance(vTarget),1000)
			else vTarget = self:GetPredictedEnemyPosition(0.8) || (att.Pos +self:GetForward() *500) end
			local entSpit = ents.Create("obj_spit")
			entSpit:SetPos(att.Pos)
			entSpit:SetEntityOwner(self)
			entSpit:SetDamage(GetConVarNumber("sk_" .. self.skName .. "_dmg_spit"))
			entSpit.OnHit = function(entSpit,ent,dist)
				if(ent:IsPlayer()) then if(ent.AddEffect) then ent:AddEffect("AnimalPoison",true,0.2,24,2,self) end end
			end
			entSpit:Spawn()
			entSpit:Activate()
			entSpit:SetArcVelocity(att.Pos,vTarget,600,self:GetForward(),0.65,VectorRand() *0.0125)
		elseif(atk == "jumpstart") then
			self:SetGroundEntity(NULL)
			self:SetVelocity(self:GetForward() *600 +self:GetUp() *300)
			self.m_bInJump = true
			self.m_tJumpStart = CurTime()
		elseif(atk == "jumploop") then
			-- self:SLVPlayActivity(ACT_RANGE_ATTACK1_LOW)
		elseif(atk == "jumpstrike") then
			local dist = 64
			local skDmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash")
			local force = Vector(50,0,0)
			local ang = Angle(50,0,0)
			self:DealMeleeDamage(dist,skDmg,ang,force,DMG_SLASH,nil,true,nil,fcHit)
		end
		return true
	end
	if(event == "burrowed") then
		self:slvPlaySound("Burrow")
		ParticleEffect("rock_impact_stalactite",self:GetPos(),self:GetAngles(),self)
		self:SetBurrowed()
		return true
	end
	if(event == "unburrow") then
		self:slvPlaySound("Unburrow")
		ParticleEffect("rock_impact_stalactite",self:GetPos(),self:GetAngles(),self)
		ParticleEffect("strider_impale_ground",self:GetPos(),self:GetAngles(),self)
		return true
	end
end

local fireran = false
function ENT:OnThink()
	self:UpdateLastEnemyPositions()
	if(self:slvIsOnFire()) then
		if fireran == false && self.entEnemy == nil then
			self:SLVPlayActivity(self:GetSequenceActivity(self:LookupSequence("Backfalling_In")))
			fireran = true
		end
		self.bWander = false
		self.bFlinchOnDamage = false
		self.bPlayDeathSequence = false
		self:SetIdleActivity(self:GetSequenceActivity(self:LookupSequence("Backfalling_Idle")))
	else
		fireran = false
		self.bWander = true
		self.bFlinchOnDamage = true
		self.bPlayDeathSequence = true
		self:SetIdleActivity(ACT_IDLE)
	end
	if(self:IsBurrowed()) then
		if(self.m_unburrow && CurTime() >= self.m_unburrow) then self:UnBurrow()
		elseif(CurTime() >= self.m_burrowNextHpRegen) then
			local hp = self:Health()
			local hpMax = self:GetMaxHealth()
			if(hp < hpMax) then self:slvSetHealth(hp +2) end
			self.m_burrowNextHpRegen = CurTime() +1
		end
	end
	if(IsValid(self.entEnemy) && self.moveSideways && CurTime() < self.moveSideways) then
		local ang = self:GetAngles()
		local yawTgt = (self.entEnemy:GetPos() -self:GetPos()):Angle().y
		ang.y = math.ApproachAngle(ang.y,yawTgt,10)
		self:SetAngles(ang)
		self:NextThink(CurTime())
		return true
	end
	if m_bInJump == false then
		self.IsDoneJumping = true
	else
		self.IsDoneJumping = false
	end
	if(self.m_bInJump) then
		-- self.IsDoneJumping = false
		self:SLVPlayActivity(ACT_RANGE_ATTACK1_LOW)
		if(CurTime() -self.m_tJumpStart >= 0.1 && self:GetVelocity().z <= 0) then
			local pos = self:GetPos()
			local tr = util.TraceHull({
				start = pos,
				endpos = pos -Vector(0,0,50),
				filter = self,
				mask = MASK_NPCWORLDSTATIC,
				mins = self:OBBMins(),
				maxs = self:OBBMaxs()
			})
			if(tr.Hit) then
				self.m_tJumpStart = nil
				self.m_bInJump = false
				self.m_bJumpHit = nil
				self.bInSchedule = false
				self:SLVPlayActivity(ACT_MELEE_ATTACK_SWING,false,self._possfuncJumpEnd)
				self._possfuncJumpEnd = nil
				self:SLVPlayActivity(ACT_RANGE_ATTACK2_LOW)
			end
		end
	-- else
		-- self.IsDoneJumping = true
	end
	local act = self:GetActivity()
	if((act == ACT_RANGE_ATTACK1_LOW) && IsValid(self.entEnemy)) then
		self:TurnToTarget(self.entEnemy,2)
		self:NextThink(CurTime())
		return true
	end
end

function ENT:AttackMelee(ent)
	self:SetTarget(ent)
	self:SLVPlayActivity(ACT_MELEE_ATTACK1,2)
end

function ENT:_PossPrimaryAttack(entPossessor,fcDone)
	self:SLVPlayActivity(ACT_MELEE_ATTACK1,false,fcDone)
end

function ENT:_PossSecondaryAttack(entPossessor,fcDone)
	self:SLVPlayActivity(ACT_RANGE_ATTACK1,false,fcDone)
	-- self:RestartGesture(ACT_RANGE_ATTACK1)// Believe it or not this actually kind of works as long as it's moving
	-- fcDone(true)
end

-- function ENT:_PossJump(entPossessor,fcDone)
	-- self:SLVPlayActivity(ACT_RANGE_ATTACK2,false,fcDone)
	-- timer.Simple(3,function()
		-- if IsValid(self) then
			-- fcDone(self.IsDoneJumping)
		-- end
	-- end)
-- end

function ENT:SelectScheduleHandle(enemy,dist,distPred,disp)
	if(disp == D_HT) then
		if(self:CanSee(self.entEnemy)) then
			if(self.moveSideways) then
				if(CurTime() > self.moveSideways || dist > 120 || dist <= 40) then
					self:SetRunActivity(ACT_RUN)
					self.moveSideways = nil
					self.nextMoveSideways = CurTime() +4
				else
					self:MoveToPosDirect(self:GetPos() +self:GetRight() *(self.moveDir == 0 && 1 || -1) *80,true,true)
					return
				end
			elseif(dist <= 100 && dist > 40) then
				if(CurTime() >= self.nextMoveSideways) then
					if(math.random(1,3) == 1) then
						self.moveSideways = CurTime() +math.Rand(2,4)
						self.moveDir = math.random(0,1)
						self:SetRunActivity(self:GetWalkActivity())
						self:MoveToPosDirect(self:GetPos() +self:GetRight() *(self.moveDir == 0 && 1 || -1) *80,true,true)
						return
					else self.nextMoveSideways = CurTime() +4 end
				end
			end
			if(dist <= self.fMeleeDistance || distPred <= self.fMeleeDistance) then
				self:SLVPlayActivity(ACT_MELEE_ATTACK1,true)
				self:slvPlaySound("Attack",75)
				return
			end
			if(dist >= 160 && math.abs(self:GetForward():DotProduct((enemy:GetPos() -self:GetPos()):GetNormal())) > 0.91) then
				if(dist >= 160 && CurTime() >= self.m_nextJump && dist <= self.fRangeDistanceLeap) then
					self.m_nextJump = CurTime() +math.Rand(3,6)
					self.m_nextSpit = CurTime() +2.5
					if(math.random(1,5) <= 3) then self:SLVPlayActivity(ACT_RANGE_ATTACK2,true) end
					return
				end
			end
			if(self.CanSpit && CurTime() >= self.m_tNextRangeAttack && dist <= self.fRangeDistance) then
				self.m_tNextRangeAttack = CurTime() +math.Rand(3,10)
				-- if(math.random(1,2) == 1) then
					self:SLVPlayActivity(ACT_RANGE_ATTACK1,true)
					self:slvPlaySound("Attack",75)
					-- self:RestartGesture(ACT_RANGE_ATTACK1)
					return
				-- end
			end
		end
		self:ChaseEnemy()
	elseif(disp == D_FR) then
		self:Hide()
	end
end