-- Setup Movement style to Half-Life 2: Deathmatch ( OG VERSION )
hl2mp_mov = hl2mp_mov or {}
hl2mp_mov.SlowWalkSpeed		= 150		-- How fast to move when slow-walking (+WALK)
hl2mp_mov.WalkSpeed			= 190		-- How fast to move when not running
hl2mp_mov.RunSpeed				= 320		-- How fast to move when running
hl2mp_mov.CrouchedWalkSpeed	= 0.3335		-- Multiply move speed by this when crouching
hl2mp_mov.DuckSpeed			= 0.3335		-- How fast to go from not ducking, to ducking
hl2mp_mov.UnDuckSpeed			= 0.3335		-- How fast to go from ducking, to not ducking
hl2mp_mov.JumpPower			= 200		-- How powerful our jump should be




CreateClientConVar( 'hl2mp_bhop_enable', '0', true, true )
CreateClientConVar( 'hl2mp_mov_enable', '1', true, true )
CreateClientConVar( 'hl2mp_propclimb_enable', '1', true, true )

local meta = FindMetaTable('Player')

function meta:HL2MP_GetIsJumping()

    return self:GetNWBool( "HL2MP_IsJumping", false )
	
end

function meta:HL2MP_SetIsJumping( val )

    self:SetNWBool( "HL2MP_IsJumping", val )
	
end

hook.Add( 'SetupMove', 'hl2mp.StartMove', function( ply, mv, cmd )

    if bit.band(mv:GetButtons(), IN_JUMP) ~= 0 and bit.band(mv:GetOldButtons(), IN_JUMP) == 0 and ply:OnGround() then

		ply:HL2MP_SetIsJumping( true )

        if ply:GetInfo('hl2mp_bhop_enable') == '1' then

		mv:SetButtons( bit.bor( mv:GetButtons(), IN_JUMP ) )

        end

	else

        if ply:GetInfo('hl2mp_bhop_enable') == '1' then

		mv:SetButtons( bit.band( mv:GetButtons(), bit.bnot( IN_JUMP ) ) )

        end

    end

end )

local props = {

    ["prop_physics"] = true,
    ["prop_physics_respawnable"] = true,
    ["func_physbox"] = true
	
}

hook.Add( 'Move', 'hl2mp.Move', function( ply, mv )

    if ply:GetInfo('hl2mp_propclimb_enable') == '1' then

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

hook.Add( 'FinishMove', 'hl2mp.StartMove', function( ply, mv, cmd )
    if ply:GetInfo('hl2mp_mov_enable') == '1' then
        if ply:HL2MP_GetIsJumping() then
            local currentSpeed = mv:GetVelocity():Length2D()
            local forward = mv:GetAngles()
            forward.p = 0
            forward = forward:Forward()
            
            local speedBoostPerc = 0
            if ply:GetInfo('hl2mp_bhop_enable') == '0' then
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
    ply:HL2MP_SetIsJumping( false )

    if ply:GetInfo('hl2mp_mov_enable') == '1' then
        return false 
    end
end)

if SERVER then

    hook.Add('PlayerLoadout', 'hl2mp.setupspeed', function( ply)

        if ply:GetInfo('hl2mp_mov_enable') == '1' then 
            GAMEMODE:SetPlayerSpeed( ply, hl2mp_mov.WalkSpeed, hl2mp_mov.RunSpeed )
            ply:SetSlowWalkSpeed( hl2mp_mov.SlowWalkSpeed )
            ply:SetJumpPower( hl2mp_mov.JumpPower )
            ply:SetCrouchedWalkSpeed( hl2mp_mov.CrouchedWalkSpeed )
            ply:SetDuckSpeed( hl2mp_mov.DuckSpeed )
            ply:SetUnDuckSpeed( hl2mp_mov.UnDuckSpeed )

            game.ConsoleCommand("sv_airaccelerate 99\n")
            game.ConsoleCommand("sv_accelerate 99\n")
        end

    end)

end