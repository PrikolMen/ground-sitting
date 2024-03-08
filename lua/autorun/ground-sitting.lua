local addonName = "Ground Sitting"
local PLAYER, ENTITY = FindMetaTable("Player"), FindMetaTable("Entity")
local Length2DSqr = FindMetaTable("Vector").Length2DSqr
local GetMoveType, IsOnGround = ENTITY.GetMoveType, ENTITY.IsOnGround
local MOVETYPE_WALK = MOVETYPE_WALK
local Alive, InVehicle = PLAYER.Alive, PLAYER.InVehicle
local SERVER = SERVER
local Add = hook.Add
local isSittingOnGround = nil
do
	local GetNW2Bool = ENTITY.GetNW2Bool
	isSittingOnGround = function(self)
		return GetNW2Bool(self, addonName)
	end
	PLAYER.IsSittingOnGround = isSittingOnGround
end
do
	local mp_sitting_on_ground_attack = CreateConVar("mp_sitting_on_ground_attack", "0", bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE), "Allows players to attack while sitting on the ground.", 0, 1)
	local KeyDown, AddKey, RemoveKey, ClearMovement
	do
		local _obj_0 = FindMetaTable("CUserCmd")
		KeyDown, AddKey, RemoveKey, ClearMovement = _obj_0.KeyDown, _obj_0.AddKey, _obj_0.RemoveKey, _obj_0.ClearMovement
	end
	local IN_ATTACK, IN_ATTACK2 = IN_ATTACK, IN_ATTACK2
	local GetVelocity = ENTITY.GetVelocity
	local IN_SPEED = IN_SPEED
	local IN_DUCK = IN_DUCK
	Add("StartCommand", addonName, function(self, cmd)
		if not isSittingOnGround(self) then
			return
		end
		if SERVER and (not Alive(self) or not IsOnGround(self) or GetMoveType(self) ~= MOVETYPE_WALK or InVehicle(self)) then
			self:RequestSittingOnGround(false)
			return
		end
		if Length2DSqr(GetVelocity(self)) < 1 then
			if KeyDown(cmd, IN_ATTACK) and not mp_sitting_on_ground_attack:GetBool() then
				RemoveKey(cmd, IN_ATTACK)
			end
			if KeyDown(cmd, IN_ATTACK2) and not mp_sitting_on_ground_attack:GetBool() then
				RemoveKey(cmd, IN_ATTACK2)
			end
		end
		if KeyDown(cmd, IN_DUCK) then
			if KeyDown(cmd, IN_SPEED) then
				RemoveKey(cmd, IN_SPEED)
			end
			return
		end
		AddKey(cmd, IN_DUCK)
		ClearMovement(cmd)
		return
	end)
end
do
	local ACT_HL2MP_IDLE = ACT_HL2MP_IDLE
	local LookupSequence = ENTITY.LookupSequence
	Add("CalcMainActivity", addonName, function(self, velocity)
		if isSittingOnGround(self) and Length2DSqr(velocity) < 1 then
			return ACT_HL2MP_IDLE, LookupSequence(self, "pose_ducking_02")
		end
	end)
end
if not SERVER then
	return
end
Add("CanPlayerGroundSit", addonName, function(self, reqested)
	if not reqested then
		return
	end
	if not (Alive(self) and IsOnGround(self)) then
		return false
	end
	if GetMoveType(self) ~= MOVETYPE_WALK or InVehicle(self) then
		return false
	end
end)
local requestSittingOnGround = nil
do
	local Call = hook.Call
	requestSittingOnGround = function(self, reqested, force)
		if isSittingOnGround(self) == reqested or (not force and Call("CanPlayerGroundSit", nil, self, reqested) == false) then
			return false
		end
		self:SetNW2Bool(addonName, reqested)
		Call("PlayerGroundSit", nil, self, reqested)
		return true
	end
	PLAYER.RequestSittingOnGround = requestSittingOnGround
end
do
	local TraceLine = util.TraceLine
	local IN_WALK = IN_WALK
	local IN_JUMP = IN_JUMP
	local IN_USE = IN_USE
	local traceResult = { }
	local trace = {
		output = traceResult
	}
	Add("KeyPress", addonName, function(self, key)
		if IN_USE == key then
			if not (self:KeyDown(IN_WALK) and self:Crouching()) then
				return
			end
			trace.start = self:GetShootPos()
			trace.endpos = trace.start + self:GetAimVector() * 72
			trace.filter = self
			TraceLine(trace)
			if not traceResult.Hit or self:EyeAngles()[1] < 80 then
				return false
			end
			requestSittingOnGround(self, true)
			return
		elseif IN_JUMP == key then
			requestSittingOnGround(self, false)
			return
		end
	end)
end
Add("PlayerShouldTaunt", addonName, function(self)
	if isSittingOnGround(self) then
		return false
	end
end)
Add("PlayerGroundSit", addonName, function(self, isEntered)
	self.m_bNextGroundSit = CurTime() + (isEntered and 0.5 or 1)
end)
return concommand.Add("ground_sit", function(self)
	if (self.m_bNextGroundSit or 0) > CurTime() then
		return
	end
	return requestSittingOnGround(self, not isSittingOnGround(self))
end)
