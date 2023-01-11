class M_Unipsycho extends tk_Monster 
	config(tk_Monsters);

#EXEC OBJ LOAD FILE="Resources/tk_UniPsycho_rc.u" PACKAGE="tk_UniPsycho"

var sound FootStep[2];
var name DeathAnim[4];
var config float fMeleeDamage;
var float MeleeDamage;

function PlayVictory()
{
	Controller.bPreparingMove = true;
	Acceleration = vect(0,0,0);
	bShotAnim = true;
    PlaySound(Sound'horn',SLOT_Interact);	
	SetAnimAction('ThroatCut');
	Controller.Destination = Location;
	Controller.GotoState('TacticalMove','WaitForAnim');
}

function bool SameSpeciesAs(Pawn P)
{
	If (P.isA('M_Unipsycho') || P.isA('M_Krypt')) return True;
	Else return ( (Monster(P) != None) && (ClassIsChildOf(Class,P.Class) || ClassIsChildOf(P.Class,Class)) );
}

function vector GetFireStart(vector X, vector Y, vector Z)
{
    return Location + 0.9 * CollisionRadius * X + 0.9 * CollisionRadius * Y + 0.4 * CollisionHeight * Z;
}

function FireProjectile()
{	
	local vector FireStart,X,Y,Z;
	
	if ( Controller != None )
	{
		GetAxes(Rotation,X,Y,Z);
		FireStart = GetFireStart(X,Y,Z);
		if ( !SavedFireProperties.bInitialized )
		{
			SavedFireProperties.AmmoClass = MyAmmo.Class;
			SavedFireProperties.ProjectileClass = MyAmmo.ProjectileClass;
			SavedFireProperties.WarnTargetPct = MyAmmo.WarnTargetPct;
			SavedFireProperties.MaxRange = MyAmmo.MaxRange;
			SavedFireProperties.bTossed = MyAmmo.bTossed;
			SavedFireProperties.bTrySplash = MyAmmo.bTrySplash;
			SavedFireProperties.bLeadTarget = MyAmmo.bLeadTarget;
			SavedFireProperties.bInstantHit = MyAmmo.bInstantHit;
			SavedFireProperties.bInitialized = true;
		}

		Spawn(MyAmmo.ProjectileClass,,,FireStart,Controller.AdjustAim(SavedFireProperties,FireStart,600));
		PlaySound(FireSound,SLOT_Interact);
	}
}

simulated function AnimEnd(int Channel)
{
	local name Anim;
	local float frame,rate;
	
	if ( Channel == 0 )
	{
		GetAnimParams(0, Anim,frame,rate);
		if ( Anim == 'Idle_Rest' )
			IdleWeaponAnim = 'Idle_Chat';
		else if ( (Anim == 'Idle_Chat') && (FRand() < 0.5) )
			IdleWeaponAnim = 'Idle_Rest';
	}
	Super.AnimEnd(Channel);
}

function RunStep()
{
	PlaySound(FootStep[Rand(2)], SLOT_Interact);
}

function WalkStep()
{
	PlaySound(FootStep[Rand(2)], SLOT_Interact,0.2);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	AmbientSound = None;
    bCanTeleport = false; 
    bReplicateMovement = false;
    bTearOff = true;
    bPlayedDeath = true;
		
	LifeSpan = RagdollLifeSpan;

    GotoState('Dying');
		
	Velocity += TearOffMomentum;
    BaseEyeHeight = Default.BaseEyeHeight;
    SetPhysics(PHYS_Falling);
    
    if ( (DamageType == class'DamTypeSniperHeadShot')
		|| ((HitLoc.Z > Location.Z + 0.75 * CollisionHeight) && (FRand() > 0.5) 
			&& (DamageType != class'DamTypeAssaultBullet') && (DamageType != class'DamTypeMinigunBullet') && (DamageType != class'DamTypeFlakChunk')) )
    {
		PlayAnim('DeathB',1,0.05);  
		CreateGib('head',DamageType,Rotation);
		return;
	}
	if ( Velocity.Z > 300 )
	{
		if ( FRand() < 0.5 )
			PlayAnim('DeathF',1.2,0.05);
		else
			PlayAnim('DeathF',1.2,0.05);
		return;
	}
	PlayAnim(DeathAnim[Rand(4)],1.2,0.05);		
}

function RangedAttack(Actor A)
{
	local name Anim;
	local float frame,rate;
	
	if ( bShotAnim )
		return;
	bShotAnim = true;
	if ( Physics == PHYS_Swimming )
		SetAnimAction('SwimFire');
	else if ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius )
	{
		if ( FRand() < 0.7 )
		{
			SetAnimAction('SwimF');
                        MeleeDamageTarget(fMeleeDamage, vect(0,0,0));
			PlaySound(Sound'WeaponSounds.Misc.ball_bounce_v3a', SLOT_Interact);
			Acceleration = AccelRate * Normal(A.Location - Location);
			return;
		}
		SetAnimAction('WallDodgeF');	
		MeleeDamageTarget(fMeleeDamage, vect(0,0,0));
		PlaySound(Sound'WeaponSounds.Misc.ball_bounce_v3a', SLOT_Interact);
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
		
	}	
	else if ( Velocity == vect(0,0,0) )
	{
		SetAnimAction('gesture_halt');  
		FireProjectile();
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
	else
	{
		GetAnimParams(0,Anim,frame,rate);
		if ( Anim == 'RunL' )
			SetAnimAction('DoubleJumpL'); 
		else if ( Anim == 'RunR' )
			SetAnimAction('DoubleJumpR'); 
		else
			SetAnimAction('gesture_halt'); 
			FireProjectile();
	}
}

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
    PlayDirectionalHit(HitLocation);

    if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
        return;

    LastPainSound = Level.TimeSeconds;
    PlaySound(HitSound[Rand(4)], SLOT_Pain,2*TransientSoundVolume,,400); 
}

function PlayDyingSound()
{
	if ( bGibbed )
	{
        PlaySound(GibGroupClass.static.GibSound(), SLOT_Pain,2.5*TransientSoundVolume,true,500);
		return;
	}

	PlaySound(DeathSound[Rand(4)], SLOT_Pain,2.5*TransientSoundVolume, true,500);
}

defaultproperties
{
     Footstep(0)=Sound'2K4MenuSounds.MainMenu.CharFade'
     Footstep(1)=Sound'2K4MenuSounds.MainMenu.CharFade'
     DeathAnim(0)="DeathB"
     DeathAnim(1)="DeathF"
     DeathAnim(2)="DeathR"
     DeathAnim(3)="DeathL"
     MeleeDamage=20.000000
     Health=150.000000
     HitSound(0)=Sound'NewDeath.FemaleNightmare.fn_hit07'
     HitSound(1)=Sound'NewDeath.FemaleNightmare.fn_hit03'
     HitSound(2)=Sound'NewDeath.FemaleNightmare.fn_hit05'
     HitSound(3)=Sound'NewDeath.FemaleNightmare.fn_hit02'
     DeathSound(0)=Sound'NewDeath.FemaleNightmare.fn_death04'
     DeathSound(1)=Sound'NewDeath.FemaleNightmare.fn_death03'
     DeathSound(2)=Sound'NewDeath.FemaleNightmare.fn_death02'
     DeathSound(3)=Sound'NewDeath.FemaleNightmare.fn_death01'
     ChallengeSound(0)=Sound'tk_UniPsycho.UniPsycho.horn'
     ChallengeSound(1)=Sound'tk_UniPsycho.UniPsycho.horn'
     ChallengeSound(2)=Sound'tk_UniPsycho.UniPsycho.horn'
     ChallengeSound(3)=Sound'tk_UniPsycho.UniPsycho.horn'
     AmmunitionClass=Class'tk_UniPsycho.UnipsychoAmmo'
     ScoringValue=10
     MeleeRange=80.000000
     JumpZ=550.000000
     MovementAnims(2)="RunR"
     MovementAnims(3)="RunL"
     TurnLeftAnim="RunF"
     TurnRightAnim="RunF"
     SwimAnims(2)="SwimR"
     SwimAnims(3)="SwimL"
     WalkAnims(1)="WalkF"
     WalkAnims(2)="WalkF"
     WalkAnims(3)="WalkF"
     AirAnims(0)="Jump_Mid"
     AirAnims(1)="Jump_Mid"
     AirAnims(2)="Jump_Mid"
     AirAnims(3)="Jump_Mid"
     TakeoffAnims(0)="Jump_Takeoff"
     TakeoffAnims(1)="Jump_Takeoff"
     TakeoffAnims(2)="Jump_Takeoff"
     TakeoffAnims(3)="Jump_Takeoff"
     LandAnims(0)="Jump_Land"
     LandAnims(1)="Jump_Land"
     LandAnims(2)="Jump_Land"
     LandAnims(3)="Jump_Land"
     DoubleJumpAnims(0)="DoubleJumpF"
     DoubleJumpAnims(1)="DoubleJumpB"
     DoubleJumpAnims(2)="DoubleJumpR"
     DoubleJumpAnims(3)="DoubleJumpL"
     DodgeAnims(0)="DodgeF"
     DodgeAnims(1)="DodgeB"
     DodgeAnims(2)="DodgeL"
     DodgeAnims(3)="DodgeR"
     AirStillAnim="Jump_Mid"
     TakeoffStillAnim="Jump_Takeoff"
     IdleWeaponAnim="idle_chat"
     Mesh=SkeletalMesh'tk_UniPsycho.UniPsycho.AntixMesh'
     Skins(0)=Texture'tk_UniPsycho.UniPsycho.antix_bodyTex'
     Skins(1)=Texture'tk_UniPsycho.UniPsycho.antix_headTex'
     Skins(2)=Texture'tk_UniPsycho.UniPsycho.antix_unicycleTex'
     Mass=150.000000
     Buoyancy=150.000000
     RotationRate=(Yaw=60000)
}
