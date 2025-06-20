-- Setup Movement style to Half-Life 2 ( OG VERSION )

-- hl1 data
-- running = 320
-- walking = 100
-- crouching = 106,67
-- crouching walking = 5
-- running jump can reach almost 400
-- walking jump can reach 200
-- crouching jump can reach 250 maybe
-- crouching walking jump can reach somehow 200
-- fast speeding from standing to 320
-- stopping from run slowly slow down to 0 from 320

hl2_mov = hl2_mov or {}
hl2_mov.SlowWalkSpeed		= 150		-- How fast to move when slow-walking (+WALK)
hl2_mov.SlowWalkSpeed_hl1		= 100		-- How fast to move when slow-walking (+WALK)
hl2_mov.WalkSpeed			= 190		-- How fast to move when not running
hl2_mov.WalkSpeed_hl1			= 320		-- How fast to move when not running
hl2_mov.RunSpeed				= 320		-- How fast to move when running
hl2_mov.RunSpeed_hl1				= 100		-- How fast to move when running
hl2_mov.CrouchedWalkSpeed	= 0.3333		-- Multiply move speed by this when crouching
hl2_mov.CrouchedWalkSpeed_hl1	= 0.1		-- Multiply move speed by this when crouching

hl2_mov.DuckSpeed			= 0.3333		-- How fast to go from not ducking, to ducking
hl2_mov.DuckSpeed_hl1			= 0.4		-- How fast to go from not ducking, to ducking
hl2_mov.UnDuckSpeed			= 0.3333		-- How fast to go from ducking, to not ducking
hl2_mov.UnDuckSpeed_hl1			= 0.15		-- How fast to go from ducking, to not ducking
hl2_mov.JumpPower			= 200		-- How powerful our jump should be
hl2_mov.author = "iceman_twitch"
hl2_mov.email = "iceman.twitch.contact@gmail.com"
hl2_mov.website = "linktr.ee/iceman_twitch"
hl2_mov.version = "0.77"
hl2_mov.update = "2025-02-22-15:11"

local workshopid = 2876378639

local hl2_mov_mode = CreateClientConVar( 'hl2_mov_mode', '1', {FCVAR_NOTIFY}, 'HL2 Movement Mode HL 2: 1 / HL1 : 0'  )
local hl2_bhop_enable = CreateClientConVar( 'hl2_bhop_enable', '0', true, true )
local hl2_mov_enable = CreateClientConVar( 'hl2_mov_enable', '1', true, true )
local hl2_propclimb_enable = CreateClientConVar( 'hl2_propclimb_enable', '1', true, true )
local hl2_auto_accelerate = CreateConVar( 'hl2_auto_accelerate', '0', {FCVAR_NOTIFY}, 'HL2 Movement Auto Setup Accelerate' )
local hl2_backward_jumping = CreateConVar( 'hl2_backward_jumping', '0', {FCVAR_NOTIFY}, 'HL2 Movement Backward Jumping' )

local meta = FindMetaTable('Player')

function meta:hl2_GetIsJumping()

    return self:GetNWBool( "hl2_IsJumping", false )
	
end

function meta:hl2_SetIsJumping( val )

    self:SetNWBool( "hl2_IsJumping", val )
	
end
function meta:hl2_GetIsNoClipping()

    return self:GetNWBool( "hl2_IsNoClipping", false )
	
end

function meta:hl2_SetIsNoClip( val )

    self:SetNWBool( "hl2_IsNoClipping", val )
	
end

local function hl2_mov_print( str )
    local hl2_mov_tag = "[hl2_mov]: "
    local str = str
    print( hl2_mov_tag .. str )
end

hook.Add( "Initialize", "hl2_mov.Initialize", function()
    
	hl2_mov_print( "[hl2-movement]: Initialized" )
    hl2_mov_print( "[hl2-movement]: Build Version - " .. hl2_mov.version )
    hl2_mov_print( "[hl2-movement]: Build Update - " .. hl2_mov.update )
    hl2_mov_print( "[hl2-movement]: Author - " .. hl2_mov.author )
	hl2_mov_print( "[hl2-movement]: Email - " .. hl2_mov.email )
	hl2_mov_print( "[hl2-movement]: Website - " .. hl2_mov.website )

end )

if SERVER then
    hook.Add( "PlayerNoClip", "hl2_mov.PlayerNoClip", function( ply, desiredState )
        if ( desiredState ) then -- wants to enter NoClip
            ply:hl2_SetIsNoClip( true )
        else
            ply:hl2_SetIsNoClip( false )
        end
    end )
end

-- TFA Compatibility Fix
local function TFA_MOVE(self, movedata)
	local weapon = self:GetActiveWeapon()

	if IsValid(weapon) and weapon.IsTFAWeapon then
		weapon:TFAMove(self, movedata)
	end
end
local function TFA_FINISHMOVE(plyv)
	if SERVER and not game.SinglePlayer() then
		local wepv = plyv:GetActiveWeapon()
	
		if IsValid(wepv) and wepv.IsTFAWeapon and wepv.PlayerThink then
			wepv:PlayerThink(plyv, not IsFirstTimePredicted())
		end
	end

	if CLIENT then
		if IsFirstTimePredicted() then
			TFA.Ballistics.Bullets:Update(plyv)
		end
	end
end
local function TFA_SETUPMOVE(plyv, movedata, commanddata)
	local wepv = plyv:GetActiveWeapon()

	if IsValid(wepv) and wepv.IsTFAWeapon then
		local speedmult = Lerp(wepv:GetIronSightsProgress(), GetConVar("sv_tfa_weapon_weight"):GetBool() and wepv:GetStatL("RegularMoveSpeedMultiplier", 1), wepv:GetStatL("AimingDownSightsSpeedMultiplier", 1))
		movedata:SetMaxClientSpeed(movedata:GetMaxClientSpeed() * speedmult)
		commanddata:SetForwardMove(commanddata:GetForwardMove() * speedmult)
		commanddata:SetSideMove(commanddata:GetSideMove() * speedmult)
	end
end

local function DoCrouchTrace(origin, endpos)
	endpos = endpos or Vector()
	local plyTable = player.GetAll()
	local tr = util.TraceHull({
		start = origin,
		endpos = origin + endpos,
		filter = plyTable,
		mask = MASK_PLAYERSOLID,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72)
	})
	return tr
end
hook.Add( 'SetupMove', 'hl2_mov.StartMove', function( ply, mv, cmd )

	if TFA then TFA_SETUPMOVE(ply, mv, cmd) end
    if ply:GetInfo('hl2_mov_mode') == '0' and ply:Alive() and cmd:KeyDown(IN_DUCK) and cmd:KeyDown(IN_WALK) and ply:GetCrouchedWalkSpeed() > 0.05 then
        ply:SetCrouchedWalkSpeed(0.08)
    end
    if ply:GetInfo('hl2_mov_mode') == '0' and ply:Alive() and cmd:KeyDown(IN_DUCK) and !cmd:KeyDown(IN_WALK) and ply:GetCrouchedWalkSpeed() < 0.3 then 
        ply:SetCrouchedWalkSpeed(0.33333)
    end
    if ply:GetInfo('hl2_mov_mode') == '0' and ply:Alive() and ply:GetMoveType() == MOVETYPE_WALK and !ply:OnGround() and ply:WaterLevel() < 1 then
		local tr = DoCrouchTrace(mv:GetOrigin())
		if !tr.Hit then
			local crouchOffset = Vector(0,0,16)
			if !ply:Crouching() and cmd:KeyDown(IN_DUCK) then
				tr = DoCrouchTrace(mv:GetOrigin(), -crouchOffset)
				mv:SetOrigin(tr.HitPos)
				if tr.Hit then
					mv:SetOrigin(mv:GetOrigin() - crouchOffset)
				end
			end
			if ply:Crouching() and mv:KeyReleased(IN_DUCK) then
				tr = DoCrouchTrace(mv:GetOrigin(), crouchOffset)
				mv:SetOrigin(tr.HitPos)
			end
		end
	end
    
    if bit.band(mv:GetButtons(), IN_JUMP) ~= 0 and bit.band(mv:GetOldButtons(), IN_JUMP) == 0 and ( ply:OnGround() or ply:WaterLevel() == 3 or ply:WaterLevel() == 2 or ply:hl2_GetIsNoClipping() ) then

		ply:hl2_SetIsJumping( true )

        if ply:GetInfo('hl2_bhop_enable') == '1' then

		mv:SetButtons( bit.bor( mv:GetButtons(), IN_JUMP ) )

        end

	else

        if ply:GetInfo('hl2_bhop_enable') == '1' then

		mv:SetButtons( bit.band( mv:GetButtons(), bit.bnot( IN_JUMP ) ) )

        end

    end

end )

local props = {

    ["prop_physics"] = true,
    ["prop_physics_respawnable"] = true,
    ["func_physbox"] = true,
    ["func_pushable"] = true,
	
}

hook.Add( 'Move', 'hl2_mov.Move', function( ply, mv )
	if TFA then TFA_MOVE(ply, mv) end
    if ply:GetInfo('hl2_propclimb_enable') == '1' then

        if ( drive.Move( ply, mv ) ) then return true end

        if SERVER then

            local groundEnt = ply:GetGroundEntity()

            if mv:KeyDown(IN_JUMP) and 
            groundEnt ~= NULL and 
            IsValid(groundEnt) then
            
                local class = groundEnt:GetClass()
                
                if props[ class ] then
                
                    local phys = groundEnt:GetPhysicsObject()
                    
                    if IsValid( phys ) and phys:IsMotionEnabled() == true then
                    
                        local pos = groundEnt:GetPos()
                        local ang = groundEnt:GetAngles()
                        local currentVel = phys:GetVelocity()
                        phys:EnableMotion(false)
                        groundEnt:SetAbsVelocity( Vector(0,0,0) )
                        ply:SetPos(ply:GetPos() + Vector(0, 0, 1))
                        -- phys:SetVelocity( Vector(0,0,0) )
                        -- Enable it back next frame
                        
                        timer.Simple(0.05,function()
                        
                            if IsValid( groundEnt ) then
                            
                                local phys = groundEnt:GetPhysicsObject()
                                
                                if IsValid( phys ) then
                                
                                    -- print("called?")
                                    phys:EnableMotion(true)
                                    phys:SetVelocity(currentVel)
                                    -- phys:SetVelocity( Vector(0,0,0) )
                                    
                                end
                                
                                groundEnt:SetAbsVelocity( Vector(0,0,0) )
                                groundEnt:SetPos(pos)
                                groundEnt:SetAngles(ang)
                                
                            end
                            
                        end)
                        
                    end
                    
                end
                
            end

        end
    end

end)

hook.Add( 'FinishMove', 'hl2_mov.StartMove', function( ply, mv, cmd )
	if TFA then TFA_FINISHMOVE(ply) end
    if ply:GetInfo('hl2_mov_enable') == '1' then
        if ply:hl2_GetIsJumping() then
            local currentSpeed = mv:GetVelocity():Length2D()
            local forward = mv:GetAngles()
            forward.p = 0
            forward = forward:Forward()
            
            local speedBoostPerc = 0
            if ply:GetInfo('hl2_bhop_enable') == '0' then
                if ply:Crouching() and not ply:IsSprinting() then
                    speedBoostPerc = 0.41
                    if currentSpeed > 410 then
                        speedBoostPerc = 0.25
                    end
                elseif ply:IsSprinting() and not ply:Crouching() then
                    speedBoostPerc = 0.2
                    if currentSpeed > 410 then
                        speedBoostPerc = 0.12
                    end
                elseif ply:IsSprinting() and ply:Crouching() and ply:GetInfo('hl2_mov_mode') == '1' then
                    speedBoostPerc = 0.2
                    if currentSpeed > 410 then
                        speedBoostPerc = 0.12
                    end
                else
                    speedBoostPerc = 0.41
                    if currentSpeed > 410 then
                        speedBoostPerc = 0.25
                    end
                end
            else
                speedBoostPerc = 0.08
            end
            local speedAddition = math.abs( ( mv:GetForwardSpeed() + mv:GetSideSpeed() ) * speedBoostPerc )
            local newSpeed = speedAddition --+ ( mv:GetVelocity():Length2D() / 8 )

            if mv:GetVelocity():Dot( forward ) < 0 then
                if hl2_backward_jumping:GetBool() then 
                    newSpeed = -( newSpeed * 2 )
                else
                    newSpeed = -newSpeed
                end
            end

            -- Apply the speed boost
            mv:SetVelocity( ( forward * newSpeed ) + mv:GetVelocity() )

        end
    end
    ply:hl2_SetIsJumping( false )

    if ply:GetInfo('hl2_mov_enable') == '1' then
        return false 
    end
end)

if SERVER then

    hook.Add('PlayerLoadout', 'hl2_mov.setupspeed', function( ply)
        ply:hl2_SetIsNoClip( false )
        ply:hl2_SetIsJumping( false )
        if ply:GetInfo('hl2_mov_enable') == '1' then 
            if ply:GetInfo('hl2_mov_mode') == '0' then
                local gravity = GetConVarNumber("sv_gravity")
                local jumppower = math.sqrt(2 * gravity * 45.0)
                GAMEMODE:SetPlayerSpeed( ply, 320, 320 )
                ply:SetWalkSpeed( 320 )
                ply:SetRunSpeed( 320 )
                ply:SetSlowWalkSpeed( 100 )
                ply:SetJumpPower( jumppower )
                ply:SetCrouchedWalkSpeed( 0.33333 )
                ply:SetDuckSpeed( 0.33333 )
                ply:SetUnDuckSpeed( 0.33333 )
            else
                GAMEMODE:SetPlayerSpeed( ply, hl2_mov.WalkSpeed, hl2_mov.RunSpeed )
                ply:SetSlowWalkSpeed( hl2_mov.SlowWalkSpeed )
                ply:SetJumpPower( hl2_mov.JumpPower )
                ply:SetCrouchedWalkSpeed( hl2_mov.CrouchedWalkSpeed )
                ply:SetDuckSpeed( hl2_mov.DuckSpeed )
                ply:SetUnDuckSpeed( hl2_mov.UnDuckSpeed )
            end
        end
        if hl2_auto_accelerate:GetBool() then
            game.ConsoleCommand("sv_wateraccelerate 999\n")
            game.ConsoleCommand("sv_airaccelerate 999\n")
            game.ConsoleCommand("sv_accelerate 999\n")
        end
    end)
else
    hook.Add("CreateMove", "hl2_mov.CreateMove", function(cmd)
        if LocalPlayer():GetInfo('hl2_mov_mode') == '0' then
            if cmd:KeyDown(IN_SPEED) then
                cmd:RemoveKey(IN_SPEED)
                cmd:AddKey(IN_WALK)
            end
        end
    end)
end
