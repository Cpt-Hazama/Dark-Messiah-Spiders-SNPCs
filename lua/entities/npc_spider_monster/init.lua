AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:SetupSLVFactions()
	self:SetNPCFaction(NPC_FACTION_SPIDER,CLASS_SPIDER)
end
ENT.sModel = "models/darkmessiah/spider_monster.mdl"
ENT.fMeleeDistance = 84
ENT.fRangeDistance = 2000
ENT.bFlinchOnDamage = true
ENT.m_bForceDeathAnim = true
ENT.UseActivityTranslator = false
ENT.CanSpit = true
ENT.m_bAttackPoison = true
ENT.BoneRagdollMain = "NPC Root [Root]"
ENT.skName = "spider_monster"
ENT.CollisionBounds = Vector(45,45,64)

ENT.DamageScales = {
	[DMG_PARALYZE] = 0,
	[DMG_NERVEGAS] = 0,
	[DMG_POISON] = 0
}

ENT.iBloodType = BLOOD_COLOR_RED
ENT.CollisionBounds = Vector(190,190,220)

ENT.DamageScales = {
	[DMG_PARALYZE] = 0,
	[DMG_NERVEGAS] = 0,
	[DMG_POISON] = 0
}

ENT.iBloodType = BLOOD_COLOR_RED
ENT.sSoundDir = "npc/spidermonster/"

ENT.m_tbSounds = {
	["Attack"] = "spidermonster_striking[0-2].wav",
	["Idle"] = "spidermonster_misc[0-2].wav",
	["Alert"] = "spidermonster_threat[0-2].wav",
	["Death"] = "spidermonster_dying[0-2].wav",
	["Pain"] = "spidermonster_ouch[0-2].wav",
	["Entrance"] = "spidermonster_entrance_end",
	["Miss"] = "spidermonster_whoosh[0-4].wav",
	["Foot"] = "foot/spidermonster_foothit[0-3].wav"
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

function ENT:OnInit()
	self:SetHullType(HULL_WIDE_SHORT)
	self:SetHullSizeNormal()
	self:SetCollisionBounds(self.CollisionBounds,Vector(self.CollisionBounds.x *-1,self.CollisionBounds.y *-1,0))
	
	self:slvCapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_OPEN_DOORS))
	self:slvSetHealth(GetConVarNumber("sk_" .. self.skName .. "_health"))
	
	self.m_tbSummons = {}
	self.m_tNextRangeAttack = 0
	self.m_NextSummonT = 0
end

function ENT:OnThink()
	self:UpdateLastEnemyPositions()
	if(self:slvIsOnFire()) then self:SetIdleActivity(self:GetSequenceActivity(self:LookupSequence("on_fire")))
	else self:SetIdleActivity(ACT_IDLE) end
end

function ENT:SummonCreature(class,pos,ang)
	local ent = ents.Create(class)
	ent:SetAngles(ang)
	ent:SetPos(pos)
	ent:slvFadeIn(1)
	ent:NoCollide(self)
	if(self:GetDTBool(3)) then
		ent:SetDTBool(3,true)
	end
	ent.DigupChance = 1
	ent:Spawn()
	ent:Activate()
	ent:MoveToClearSpot(pos)
	local squad = self:GetSquad()
	if(squad) then ent:SetSquad(squad) end
	table.insert(self.m_tbSummons,ent)
	ent.DigupChance = 1
	return ent
end

function ENT:InitSandbox()
	if !self:GetSquad() then self:SetSquad(self:GetClass() .. "_sbsquad") end
	if #ents.FindByClass("npc_spider_monster") == 1 && math.random(1,5) == 1 then
		local cspSoundtrack
		if math.random(1,2) == 1 then
			cspSoundtrack = CreateSound(self, self.sSoundDir .. "soundtrack.mp3")
		else
			cspSoundtrack = CreateSound(self, self.sSoundDir .. "soundtrack2.mp3")
		end
		cspSoundtrack:SetSoundLevel(0.2)
		cspSoundtrack:Play()
		self:StopSoundOnDeath(cspSoundtrack)
	end
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
		if(atk == "lefta") then
			force = Vector(50,0,0)
			ang = Angle(50,0,0)
		elseif(atk == "leftb") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		elseif(atk == "righta") then
			force = Vector(50,0,0)
			ang = Angle(-50,0,0)
		elseif(atk == "rightb") then
			force = Vector(180,0,20)
			ang = Angle(-80,0,0)
		elseif(atk == "belly") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		elseif(atk == "rightc") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		elseif(atk == "leftc") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		elseif(atk == "belly") then
			force = Vector(50,0,0)
			ang = Angle(80,0,0)
		end
		self:DealMeleeDamage(dist,skDmg,ang,force,DMG_SLASH,nil,true,nil,fcHit)
		return true
	end
	if(event == "rattack") then
		local att = self:GetAttachment(self:LookupAttachment("mm_mouth"))
		if(!att) then return true end
		local vTarget
		if(self:SLV_IsPossesed()) then
			vTarget = self:GetPossessor():GetPossessionEyeTrace().HitPos
			local dir = (vTarget -att.Pos):GetNormal()
			vTarget = att.Pos +dir *math.min(att.Pos:Distance(vTarget),1000)
		else vTarget = self:GetPredictedEnemyPosition(0.8) || (att.Pos +self:GetForward() *500) end
		local entSpit = ents.Create("obj_poisoncloud")
		entSpit:SetPos(att.Pos)
		entSpit:SetAngles(att.Ang)
		entSpit:SetEntityOwner(self)
		-- entSpit:SetDamage(GetConVarNumber("sk_" .. self.skName .. "_dmg_acidcloud"))
		entSpit.OnHit = function(entSpit,ent,dist)
			if(ent:IsPlayer()) then if(ent.AddEffect) then ent:AddEffect("AnimalPoison",true,0.2,24,2,self) end end
		end
		entSpit:DrawShadow(false)
		entSpit:Spawn()
		entSpit:Activate()
		entSpit:SetArcVelocity(att.Pos,vTarget,1000,self:GetForward(),0.75,VectorRand() *0.01)
		return true
	end
	-- if(event == "unburrow") then
		-- self:slvPlaySound("Entrance")
		-- return true
	-- end
end

function ENT:AttackMelee(ent)
	self:SetTarget(ent)
	self:SLVPlayActivity(ACT_MELEE_ATTACK1,2)
end

function ENT:_PossPrimaryAttack(entPossessor,fcDone)
	local atk
	if math.random(1,10) == 1 then
		atk = ACT_MELEE_ATTACK2
	else
		atk = ACT_MELEE_ATTACK1
	end
	self:SLVPlayActivity(atk,false,fcDone)
	self:slvPlaySound("Attack")
end

function ENT:_PossSecondaryAttack(entPossessor,fcDone)
	self:SLVPlayActivity(ACT_RANGE_ATTACK1,false,fcDone)
end

function ENT:SelectScheduleHandle(enemy,dist,distPred,disp)
	if(disp == D_HT) then
		if(self:CanSee(self.entEnemy)) then
			if(dist <= 2000 && CurTime() > self.m_NextSummonT) then
				for i = #self.m_tbSummons,1,-1 do
					local ent = self.m_tbSummons[i]
					if(!ent:IsValid()) then
						table.remove(self.m_tbSummons,i)
					end
				end
				if(math.random(1,3) == 1 && #self.m_tbSummons < 6) then
					local pos = self:GetPos() +self:GetForward() *300 +Vector(0,0,1)
					local ang = self:GetAngles()
					local classes = {"npc_spider"}
					local class = table.Random(classes)
					self:SummonCreature(class,pos,ang)
					self.m_NextSummonT = CurTime() +math.random(8,12)
					return true
				end
			end
			if(dist <= self.fMeleeDistance || distPred <= self.fMeleeDistance) then
				local atk
				if math.random(1,10) == 1 then
					atk = ACT_MELEE_ATTACK2
				else
					atk = ACT_MELEE_ATTACK1
				end
				self:SLVPlayActivity(atk,true)
				self:slvPlaySound("Attack")
				return
			end
			if(self.CanSpit && CurTime() >= self.m_tNextRangeAttack && dist <= self.fRangeDistance) then
				self.m_tNextRangeAttack = CurTime() +math.Rand(3,10)
				-- if(math.random(1,2) == 1) then
					self:SLVPlayActivity(ACT_RANGE_ATTACK1,true)
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