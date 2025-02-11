-- Setup Movement style to Half-Life 2 ( OG VERSION )
hl2_mov = hl2_mov or {}
hl2_mov.SlowWalkSpeed		= 150		-- How fast to move when slow-walking (+WALK)
hl2_mov.WalkSpeed			= 190		-- How fast to move when not running
hl2_mov.RunSpeed				= 320		-- How fast to move when running
hl2_mov.CrouchedWalkSpeed	= 0.3333		-- Multiply move speed by this when crouching
hl2_mov.DuckSpeed			= 0.3333		-- How fast to go from not ducking, to ducking
hl2_mov.UnDuckSpeed			= 0.3333		-- How fast to go from ducking, to not ducking
hl2_mov.JumpPower			= 200		-- How powerful our jump should be
hl2_mov.author = "iceman_twitch"
hl2_mov.email = "iceman.twitch.contact@gmail.com"
hl2_mov.website = "linktr.ee/iceman_twitch"
hl2_mov.version = "0.72"
hl2_mov.update = "2025-02-11-12:24"

local workshopid = 2876378639

local hl2_bhop_enable = CreateClientConVar( 'hl2_bhop_enable', '0', true, true )
local hl2_mov_enable = CreateClientConVar( 'hl2_mov_enable', '1', true, true )
local hl2_propclimb_enable = CreateClientConVar( 'hl2_propclimb_enable', '1', true, true )
local hl2_auto_accelerate = CreateConVar( 'hl2_auto_accelerate', '0', {FCVAR_NOTIFY}, 'HL2 Movement auto setup accelerate' )

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
hook.Add( 'SetupMove', 'hl2_mov.StartMove', function( ply, mv, cmd )

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
    ["func_physbox"] = true
	
}

hook.Add( 'Move', 'hl2_mov.Move', function( ply, mv )

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
                elseif ply:IsSprinting() and ply:Crouching() then
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
            
                newSpeed = -newSpeed
                
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
            GAMEMODE:SetPlayerSpeed( ply, hl2_mov.WalkSpeed, hl2_mov.RunSpeed )
            ply:SetSlowWalkSpeed( hl2_mov.SlowWalkSpeed )
            ply:SetJumpPower( hl2_mov.JumpPower )
            ply:SetCrouchedWalkSpeed( hl2_mov.CrouchedWalkSpeed )
            ply:SetDuckSpeed( hl2_mov.DuckSpeed )
            ply:SetUnDuckSpeed( hl2_mov.UnDuckSpeed )

            
        end
        if hl2_auto_accelerate:GetBool() then
            game.ConsoleCommand("sv_airaccelerate 99\n")
            game.ConsoleCommand("sv_accelerate 99\n")
        end
    end)

end
