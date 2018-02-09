AddCSLuaFile()

// If gamemode isn't TTT then do not run this script
if (engine.ActiveGamemode() != "terrortown") then return end

SWEP.HoldType   = "pistol"

if CLIENT then
    SWEP.PrintName = "Dart Gun"
    SWEP.Author  = "Axspeo"
    SWEP.Slot = 6

    SWEP.EquipMenuData = {
      type = "Poison",
      desc = [[The Dart Gun is a Poison type Gun. 
	It has 3 Types of darts, 
	Poison, Muteness and Blindness.
	You can change dart type by clicking on the 
	right mouse button (aka SecondaryFire).]]
    };

    SWEP.Icon = "vgui/ttt/icon_fon_dartgun"
end

// Init
SWEP.Base = "weapon_tttbase"
SWEP.Primary.Recoil	= 4
SWEP.Primary.Damage = DartGun.BaseDamage
SWEP.Primary.Delay = 0.80
SWEP.Primary.Cone = 0.01
SWEP.Primary.ClipSize = 5
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = 5
SWEP.Primary.ClipMax = 5

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.IsSilent = true

// Draw World Model -----------------------------------------------
SWEP.Offset = {
	// Position
    Pos = {
		Up = -0.18896484375,
		Right = 0,
        Forward = 0,
    },
	// Angles
    Ang = {
        Up = 180,
		Right = 180,
        Forward = 0,
    }
}

function SWEP:DrawWorldModel( )
	if ( SERVER ) then return end
    local ply = self:GetOwner()

    if IsValid( ply ) then
        local bone_rh = ply:LookupBone( "ValveBiped.Bip01_R_Hand" )
        if bone_rh then
            local pos, ang = ply:GetBonePosition( bone_rh )
            pos = pos + ang:Forward() * self.Offset.Pos.Forward + ang:Right() * self.Offset.Pos.Right + ang:Up() * self.Offset.Pos.Up

            ang:RotateAroundAxis( ang:Up(), self.Offset.Ang.Up)
            ang:RotateAroundAxis( ang:Right(), self.Offset.Ang.Right )
            ang:RotateAroundAxis( ang:Forward(),  self.Offset.Ang.Forward )

            self:SetRenderOrigin( pos )
            self:SetRenderAngles( ang )
            self:DrawModel()
        end
    else
        self:SetRenderOrigin( nil )
        self:SetRenderAngles( nil )
        self:DrawModel()
    end
end
// ----------------------------------------------------------------

// Draw if target is poisoned/muted/blinded to Traitors ----------------------------
// Effect Icons
local poison_effect_icon = Material("vgui/fon/icon_poison")
local muteness_effect_icon = Material("vgui/fon/icon_muteness")
local blindness_effect_icon = Material("vgui/fon/icon_blindness")
local transparency_icons = Color(255, 255, 255, 140)

// Draw Effects above the targets head
function WarnTraitorsIcons()
    client = LocalPlayer()
    players = player.GetAll()

    if client:GetTraitor() then
        normal = client:GetForward() * -1
		render.SetMaterial(poison_effect_icon)
		
        for i=1, #players do
            ply = players[i]
			
            if (ply:GetNWInt("fon_poison") == 1) and ply != client then
				pos_p = ply:GetPos()
				pos_p.z = pos_p.z + 72

				render.DrawQuadEasy(pos_p, normal, 8, 8, transparency_icons, 180)
			end
		end
	
		render.SetMaterial(muteness_effect_icon)
		
        for i=1, #players do
            ply = players[i]
			
            if (ply:GetNWInt("fon_muteness") == 1) and ply != client then
				pos_m = ply:GetPos()
				pos_m.z = pos_m.z + 72
				pos_m.x = pos_m.x + 10

				render.DrawQuadEasy(pos_m, normal, 8, 8, transparency_icons, 180)
			end
		end
	
		render.SetMaterial(blindness_effect_icon)
		
        for i=1, #players do
            ply = players[i]
			
            if (ply:GetNWInt("fon_blindness") == 1) and ply != client then
				pos_b = ply:GetPos()
				pos_b.z = pos_b.z + 72
				pos_b.x = pos_b.x - 10

				render.DrawQuadEasy(pos_b, normal, 8, 8, transparency_icons, 180)
			end
		end
	end
end
hook.Add("PostDrawTranslucentRenderables", "DartGunIconsEffects", WarnTraitorsIcons)
//----------------------------------------------------------------------------------

// Makes the target go boom (aka Combo with Poison and Flare Gun)
function yesthisisthesecret(ply, att, infl)
	local k, v
	
	local ex = ents.Create( "env_explosion" )
		ex:SetPos( ply:GetPos() )
		ex:SetOwner( att )
		ex:Spawn()
		ex:SetKeyValue( "iMagnitude", "100" )
		ex:Fire( "Explode", 0, 0 )
		ex:EmitSound( "siege/big_explosion.wav", 500, 500 )
		
		ply:TakeDamage(200, att, infl)
		
		sound.Play( "siege/big_explosion.wav", ex:GetPos() )

end

// Tell Player wich dart he is going to shoot
function SendMessage(ply)
	if CLIENT then return end
	if (ply:GetNWInt("dart_type") == 1) then
		ply:DartGunChat("50 215 50 255", "Poison")
	elseif (ply:GetNWInt("dart_type") == 2) then
		ply:DartGunChat("10 145 255 255", "Muteness")
	else
		ply:DartGunChat("194 0 0 255", "Blindness")
	end
end


// Verify wich dart should we call
function VerifyCallback(att, path, dmginfo, dmg)
	if (att:GetNWInt("dart_type") == 1) then
		DamageTarget(att, path, dmginfo, dmg)
	elseif (att:GetNWInt("dart_type") == 2) then
		MuteTarget(path)
	else
		BlindTarget(path)
	end
end

// Poison
function DamageTarget(att, path, dmginfo, dmg)
   local ply = path.Entity
   local dmg = DamageInfo()
   
   if not IsValid(ply) then return end
   
   if SERVER then
        ply.takedamage_info = {att=dmginfo:GetAttacker(), infl="weapon_ttt_dartgun"}
		
		local tn = "Poison".. math.random(1, 99999999)
		local timeneeded_poison = math.ceil(DartGun.PoisonEffectSeconds*DartGun.PoisonTakeDmgRepetitions)

        timer.Create(tn,
        DartGun.PoisonEffectSeconds,
        DartGun.PoisonTakeDmgRepetitions,
        function()
            local poison_damage = math.random(DartGun.PoisonMIN, DartGun.PoisonMAX)
			
            if !(IsValid(ply)) then return end

            ply:SetNWInt("fon_poison", 1)			
            ply:TakeDamage(poison_damage, att, infl)

			if ply:IsOnFire() then
				local effectdata = EffectData()
				effectdata:SetOrigin( ply:GetPos() )
				effectdata:SetNormal( ply:GetPos() )
				effectdata:SetMagnitude( 8 )
				effectdata:SetScale( 1 )
				effectdata:SetRadius( 16 )
				util.Effect( "Sparks", effectdata )
		        
				if (SERVER) then
					timer.Simple(0.25, function() yesthisisthesecret(ply, att, infl) end )
				end
			end
			
			// If Target dies Poison Screen effect stops
			if ply:Health() <= 0 then
				timer.Destroy(tn)
				ply:SetNWInt("fon_poison", 0)
			end
		end)
		
		timer.Simple(timeneeded_poison, function() ply:SetNWInt("fon_poison", 0) end)
		
	end
end
//-----------------------------------------------------------------------------
// Mute
function MuteTarget(path)
   local ply = path.Entity
   
   if not IsValid(ply) then return end
   
   if SERVER then
		
        if !(IsValid(ply)) then return end

        ply:SetNWInt("fon_muteness", 1)
			
		// If Target dies he is able to talk again
		if ply:Health() <= 0 then
			ply:SetNWInt("fon_muteness", 0)   
		end
			
		timer.Simple(DartGun.MuteTime, function() ply:SetNWInt("fon_muteness", 0) end)
		
	end
	
end

// Doesn't allow Target to speak in voice chat
hook.Add("PlayerCanHearPlayersVoice", "FonMutenessVoice", function(listener, talker)
	if (talker:GetNWInt("fon_muteness") == 1) then return false end
end)
	
// Doesn't allow Target to type in text chat
hook.Add("PlayerSay", "FonMutenessText", function(talker, msg, ply_team)
	if (talker:GetNWInt("fon_muteness") == 1) then return false end
end)

//-----------------------------------------------------------------------------
// Blindness
function BlindTarget(path)
   local ply = path.Entity
   
   if not IsValid(ply) then return end
   
   if SERVER then
		
        if !(IsValid(ply)) then return end

        ply:SetNWInt("fon_blindness", 1)
			
		// If Target dies he is able to see again
		if ply:Health() <= 0 then
			ply:SetNWInt("fon_blindness", 0)   
		end
			
		if IsValid(ply) then
			timer.Simple(DartGun.BlindTime, function() ply:SetNWInt("fon_blindness", 0) end)
		end
		
	end
	
end
//-----------------------------------------------------------------------------

function SWEP:Poison()
	local cone = self.Primary.Cone
	local pwn = {}
	pwn.Num       = 1
	pwn.Src       = self.Owner:GetShootPos()
	pwn.Dir       = self.Owner:GetAimVector()
	pwn.Spread    = Vector( cone, cone, 0 )
	pwn.Tracer    = 1
	pwn.Force     = 2
	pwn.Damage    = self.Primary.Damage
	pwn.TracerName = self.Tracer
	pwn.Callback = VerifyCallback

	self.Owner:FireBullets(pwn)
	   
	local dmg = DamageInfo()
	dmg:SetAttacker(self.Owner)
	dmg:SetInflictor(self.Weapon)
end

// Models
SWEP.ViewModel			= "models/dartgun/v_fon_dartgun.mdl"
SWEP.WorldModel			= "models/dartgun/w_fon_dartgun.mdl"

// Shot Sound
SWEP.Primary.Sound = Sound( "weapons/usp/usp1.wav" )
SWEP.Primary.SoundLevel = 50

function SWEP:Deploy()
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
	self.Owner:SetNWInt("dart_type", DartGun.DartType)
	return true
end

// Shoots Dart
function SWEP:PrimaryAttack()
    self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

    if not self:CanPrimaryAttack() then return end

    self.Weapon:EmitSound( self.Primary.Sound )

    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_SILENCED)
   
	self:Poison()

    self:TakePrimaryAmmo( 1 )

    if IsValid(self.Owner) then
		self.Owner:SetAnimation( PLAYER_ATTACK1 )

		self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
    end

    self.Weapon:SetNWFloat( "LastShootTime", CurTime() )
end

// SecondaryAttack changes dart type
function SWEP:SecondaryAttack()
	local ply = self.Owner
	local dart_types = {2,3,1}
	
	// Change dart type
	for i=1, 3 do
		if (ply:GetNWInt("dart_type") == i) then
			ply:SetNWInt("dart_type", dart_types[i])
			SendMessage(ply)
			break
		end
	end
end

// Screen Effects
hook.Add("Think", "poisononthinkscreen", function()
    if CLIENT then
		if (LocalPlayer():GetNWInt("fon_poison") == 1) then
			hook.Add("RenderScreenspaceEffects", "FonPoison", function()
				local tab = {
					["$pp_colour_addr"] = 0,
					["$pp_colour_addg"] = 0,
					["$pp_colour_addb"] = 0,
					["$pp_colour_brightness"] = -0.03,
					["$pp_colour_contrast"] = 0.8,
					["$pp_colour_colour"] = 2.5,
					["$pp_colour_mulr"] = 0,
					["$pp_colour_mulg"] = 0,
					["$pp_colour_mulb"] = 0
				}	
				DrawColorModify( tab ) // Draws Color Modify effect
				DrawSobel( 0.5 ) // Draws Sobel effect
	
				DrawMaterialOverlay( "effects/water_warp01", 0.45 )
			end)
		end
		
		if (LocalPlayer():GetNWInt("fon_blindness") == 1) then
            hook.Add("RenderScreenspaceEffects", "FonBlindness", function()
				DrawSobel( 0 ) // Draws Sobel effect (0 = Black Screen)
    	    end)
        end
		
		// Cleans Poison Screen Effect
        if (LocalPlayer():GetNWInt("fon_poison") == 0) then
            hook.Add("RenderScreenspaceEffects", "FonPoison", function()
	        	DrawMaterialOverlay( "", 0 )
    	    end)
        end
		
		// Cleans Blindness Screen Effect
		if (LocalPlayer():GetNWInt("fon_blindness") == 0) then
            hook.Add("RenderScreenspaceEffects", "FonBlindness", function()
	        	DrawMaterialOverlay( "", 0 )
    	    end)
        end
		
    end
end)

// Remove Poison/Muteness/Blindness on Round Start
hook.Add("TTTPrepareRound", "StopPoison1", function()
    for k, v in pairs( player.GetAll() ) do
        v:SetNWInt("fon_poison", 0)
		v:SetNWInt("fon_muteness", 0)
		v:SetNWInt("fon_blindness", 0)
		v:SetNWInt("dart_type", DartGun.DartType)
    end
end)
// ----------------------------