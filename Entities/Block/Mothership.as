#include "BlockCommon.as"
#include "IslandsCommon.as"
#include "ExplosionEffects.as";
#include "WaterEffects.as";
#include "Booty.as"
#include "BlockProduction.as"
#include "TeamColour.as"
#include "HumanCommon.as"
#include "AccurateSoundPlay.as"

const u16 bombCDTime = 5 * 20;//cooldown after buying bombs
const u16 BASE_KILL_REWARD = 275;
const f32 HEAL_AMOUNT = 0.1f;
const f32 HEAL_RADIUS = 16.0f;
const f32 INIT_HEALTH = 8.0f;
const u16 SELF_DESTRUCT_TIME = 8 * 30;
const f32 BLAST_RADIUS = 25 * 16.0f;
const u8 MAX_TEAM_FLAKS = 100;
const u8 MAX_TOTAL_FLAKS = 1000;
u8 DAMAGE_FRAMES = 3;

void onInit( CBlob@ this )
{
	this.Tag("mothership");
	this.set( "bombCooldown", 0 );
	this.addCommandID("buyBlock");
	this.addCommandID("returnBlocks");
	this.server_SetHealth( INIT_HEALTH );
	
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer( "damage", 8, 8 );
    if (layer !is null)
    {
    	layer.SetRelativeZ(1);
    	layer.SetLighting( false );
     	Animation@ anim = layer.addAnimation( "state", 0, false );
        anim.AddFrame(1);
        anim.AddFrame(2);
        anim.AddFrame(3);
        anim.AddFrame(4);
        layer.SetAnimation("state");    	
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("buyBlock"))
    {
		CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		if ( caller is null )
			return;
			
		string block = params.read_string();
		caller.set_string( "last buy", block );

		if ( !getNet().isServer() || Human::isHoldingBlocks( caller ) || !this.hasTag( "mothership" ) || this.getTeamNum() != caller.getTeamNum() )
			return;
			
		BuyBlock( this, caller, block );
	}
    if (cmd == this.getCommandID("returnBlocks"))
	{
		CBlob@ caller = getBlobByNetworkID( params.read_u16() );
		if ( caller !is null )
			ReturnBlocks( this, caller );
	}
}

void BuyBlock( CBlob@ this, CBlob@ caller, string btype )
{
	CRules@ rules = getRules();
	Block::Costs@ c = Block::getCosts( rules );
	
	if ( c is null )
	{
		warn( "** Couldn't get Costs!" );
		return;
	}

	u8 teamNum = this.getTeamNum();
	u32 gameTime = getGameTime();
	CPlayer@ player = caller.getPlayer();
	string pName = player !is null ? player.getUsername() : "";
	u16 pBooty = server_getPlayerBooty( pName );
	bool weapon = btype == "cannon" || btype == "machinegun" || btype == "flak" || btype == "pointDefense" || btype == "launcher" || btype == "bomb";
	
	u16 cost = -1;
	u8 amount = 1;
	u8 totalFlaks = 0;
	u8 teamFlaks = 0;
	
	bool coolDown = false;

	Block::Type[] types;
	if ( btype == "wood" )
	{
		types.push_back(Block::PLATFORM);
		cost = c.wood;
	}
	else if ( btype == "solid" )
	{
		types.push_back(Block::SOLID);
		cost = c.solid;
	}

		else if ( btype == "door" )
	{
		types.push_back(Block::DOOR);
		cost = c.door;
	}

	else if ( btype == "ram" )
	{
		types.push_back(Block::RAM);
		cost = c.ram;
	}
	else if ( btype == "propeller" )
	{
		types.push_back(Block::PROPELLER);
		types.push_back(Block::PROPBLADES1);
		cost = c.propeller;
	}
	else if ( btype == "ramEngine" )
	{
		types.push_back(Block::RAMENGINE);
		types.push_back(Block::PROPBLADES2);
		cost = c.ramEngine;
	}
	else if ( btype == "seat" )
	{
		types.push_back(Block::SEAT);
		cost = c.seat;
	}
	else if ( btype == "harvester" )
	{
		types.push_back(Block::HARVESTER);
		cost = c.harvester;
	}
	else if ( btype == "harpoon" )
	{
		types.push_back(Block::HARPOON);
		cost = c.harpoon;
	}
	else if ( btype == "machinegun" )
	{
		types.push_back(Block::MACHINEGUN);
		cost = c.machinegun;
	}
	else if ( btype == "cannon" )
	{
		types.push_back(Block::CANNON);
		cost = c.cannon;
	}
	else if ( btype == "flak" )
	{
		types.push_back(Block::FLAK);
		cost = c.flak;
		//Max turrets to avoid lag
		CBlob@[] turrets;
		getBlobsByTag( "flak", @turrets );
		for ( u16 i = 0; i < turrets.length; i++ ) {
			if ( turrets[i].getTeamNum() == teamNum )
				teamFlaks++;
			totalFlaks++;
		}
	}
	else if ( btype == "pointDefense" )
	{
		types.push_back(Block::POINTDEFENSE);
		cost = c.pointDefense;
	}
	else if ( btype == "launcher" )
	{
		types.push_back(Block::LAUNCHER);
		cost = c.launcher;
	}
	else if ( btype == "bomb" )
	{
		types.push_back(Block::BOMB);
		cost = c.bomb;

		u32 bombCooldown;
		this.get( "bombCooldown", bombCooldown );
		coolDown = gameTime < bombCooldown;
	}
	else if ( btype == "coupling" )
	{
		types.push_back(Block::COUPLING);
		types.push_back(Block::COUPLING);
		cost = c.coupling;
		amount = 2;
	}
	else if ( btype == "repulsor" )
	{
		types.push_back(Block::REPULSOR);
		cost = c.repulsor;
	}
	if ( teamFlaks < MAX_TEAM_FLAKS && totalFlaks < MAX_TOTAL_FLAKS) {
		if ( getPlayersCount() == 1 || rules.get_bool("freebuild"))
			ProduceBlock( getRules(), caller, types );
		else if ( !coolDown && pBooty >= cost )
		{
			server_setPlayerBooty( pName, pBooty - cost );
		
			ProduceBlock( getRules(), caller, types);
				
			if ( btype == "bomb" )
				this.set( "bombCooldown", gameTime + bombCDTime );
		}
		//warning for flaks. We dont check block type since teamFlaks and totalFlaks are equals to 0 if type is not a flak.
		if (MAX_TEAM_FLAKS - teamFlaks <= 3) {
			rules.set_bool("display_flak_team_warn", false);
			rules.SyncToPlayer("display_flak_team_warn", player);
			rules.set_bool("display_flak_team_warn", true);
			rules.SyncToPlayer("display_flak_team_warn", player);
		}
		if (MAX_TOTAL_FLAKS - totalFlaks <= 3) {
				rules.set_bool("display_flak_total_warn", false);
				rules.Sync("display_flak_total_warn", true);
				rules.set_bool("display_flak_total_warn", true);
				rules.Sync("display_flak_total_warn", true);
		}
	} else {
		if (teamFlaks >= MAX_TEAM_FLAKS) {
			rules.set_bool("display_flak_team_max", false);
			rules.SyncToPlayer("display_flak_team_max", player);
			rules.set_bool("display_flak_team_max", true);
			rules.SyncToPlayer("display_flak_team_max", player);
		}
		else {
			rules.set_bool("display_flak_total_max", false);
			rules.SyncToPlayer("display_flak_total_max", player);
			rules.set_bool("display_flak_total_max", true);
			rules.SyncToPlayer("display_flak_total_max", player);
		}
	}
}

void ReturnBlocks( CBlob@ this, CBlob@ caller )
{
	CRules@ rules = getRules();
	CBlob@[]@ blocks;
	if (caller.get( "blocks", @blocks ) && blocks.size() > 0)                 
	{
		if ( getNet().isServer() )
		{
			CPlayer@ player = caller.getPlayer();
			if ( player !is null )
			{
				string pName = player.getUsername();
				u16 pBooty = server_getPlayerBooty( pName );
				u16 returnBooty = 0;
				for (uint i = 0; i < blocks.length; ++i)
				{
					int type = Block::getType( blocks[i] );
					if ( type != Block::COUPLING && blocks[i].getShape().getVars().customData == -1 )
						returnBooty += Block::getCost( type );
				}
				
				if ( returnBooty > 0 && !(getPlayersCount() == 1 || rules.get_bool("freebuild")))
					server_setPlayerBooty( pName, pBooty + returnBooty );
			}
		}
		
		this.getSprite().PlaySound("join.ogg");
		Human::clearHeldBlocks( caller );
		caller.set_bool( "blockPlacementWarn", false );
	} else
		warn("returnBlocks cmd: no blocks");
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if ( hitterBlob is null ) return damage;
	
	u8 thisTeamNum = this.getTeamNum();
	u8 hitterTeamNum = hitterBlob.getTeamNum();
	
	if ( thisTeamNum == hitterTeamNum && hitterBlob.getTickSinceCreated() < 900 && hitterBlob.getName() == "block" )
	{
		CPlayer@ player = getLocalPlayer();
		if ( player !is null && player.isMod() && !getRules().isGameOver() )
		{
			CPlayer@ owner = getPlayerByNetworkId( hitterBlob.get_u16( "playerID" ) );
			if ( owner !is null )
				error( ">Core teamHit (" + hitterTeamNum+ "): " + owner.getUsername() ); 
		}
		
		damage /= 2;
	}
	
	f32 hp = this.getHealth();
	if ( !this.hasTag( "critical" ) && hp - damage > 0.0f )//assign last team hitter
	{
		if ( thisTeamNum != hitterTeamNum && hitterBlob.getName() != "whirlpool" )
		{
			this.set_u8( "lastHitterTeam", hitterTeamNum );
			this.set_u32( "lastHitterTime", getGameTime() );
		}
	}
	else
	{
		if ( !this.hasTag( "critical" ) )//deathHit(once)
		{
			initiateSelfDestruct( this );
			
			//increase captain deaths
			string defeatedCaptainName = getCaptainName( thisTeamNum );
			CPlayer@ defeatedCaptain = getPlayerByUsername( defeatedCaptainName );
			if ( defeatedCaptain !is null )
			{
				defeatedCaptain.setDeaths( defeatedCaptain.getDeaths() + 1 );
				if ( defeatedCaptain.isMyPlayer() )
					client_AddToChat( "You lost your Mothership! A Core Death was added to your Scoreboard." );
			}
			
			//rewards if they apply
			CRules@ rules = getRules();
			if ( thisTeamNum == hitterTeamNum || hitterBlob.getName() == "whirlpool" || hitterBlob.hasTag( "mothership" ) )//suicide. try with last good hitterTeam
				if ( getGameTime() - this.get_u32( "lastHitterTime" ) < 450 )//15 seconds lease
					hitterTeamNum = this.get_u8( "lastHitterTeam" );
				else
					return Maths::Max( 0.0f, hp - 1.0f );//no rewards
					
			//got a possible winner team
			u8 thisPlayers = 0;
			u8 hitterPlayers = 0;
			u8 playersCount = getPlayersCount();
			for( u8 i = 0; i < playersCount; i++ )
			{
				u8 pteam = getPlayer(i).getTeamNum();
				if( pteam == thisTeamNum )
					thisPlayers++;
				else if ( pteam == hitterTeamNum )
					hitterPlayers++;
			}
							
			CBlob@ hitterCore = getMothership( hitterTeamNum );
			if ( hitterPlayers == 0 || hitterCore is null )//in case of suicide against leftover/empty team ship
				return Maths::Max( 0.0f, hp - 1.0f );//no rewards

			//got a winner team
			this.Tag( "cleanDeath" );	
			
			//winSound
			CPlayer@ myPlayer = getLocalPlayer();
			if ( myPlayer !is null && myPlayer.getTeamNum() == hitterTeamNum )
			{
				Sound::Play( "KAGWorldQuickOut.ogg" );
				Sound::Play( "ResearchComplete.ogg" );
			}
			
			//increase winner captain kills
			string captainName = getCaptainName( hitterTeamNum );
			CPlayer@ captain = getPlayerByUsername( captainName );
			if ( captain !is null )
			{
				captain.setKills( captain.getKills() + 1 );
				if ( captain.isMyPlayer() )
					client_AddToChat( "Congratulations! A Core Kill was added to your Scoreboard." );
			}
			
			f32 ratio = Maths::Max( 0.25f, Maths::Min( 1.75f,
							float( rules.get_u16( "bootyTeam_total" + thisTeamNum ) )/float( rules.get_u32( "bootyTeam_median" ) + 1.0f ) ) ); //I added 1.0f as a safety measure against dividing by 0
			
			u16 totalReward = ( thisPlayers + 1 ) * BASE_KILL_REWARD * ratio;
			client_AddToChat( "*** " + rules.getTeam( hitterTeamNum ).getName() + " gets " + ( totalReward + BASE_KILL_REWARD ) + " Booty for destroying " + rules.getTeam( thisTeamNum ).getName() + "! ***" );
			
			//give rewards
			if ( getNet().isServer() )
			{
				u16 reward = Maths::Round( totalReward/hitterPlayers );
				for( u8 i = 0; i < playersCount; i++ )
				{
					CPlayer@ player = getPlayer(i);
					u8 teamNum = player.getTeamNum();
					if ( teamNum == hitterTeamNum )//winning tam
					{
						string name = player.getUsername();
						server_setPlayerBooty( name, server_getPlayerBooty( name ) + ( name == captainName ? 2 * reward : reward ) );
					} else if ( teamNum == thisTeamNum )//losing team consolation money
					{
						string name = player.getUsername();
						u16 booty = server_getPlayerBooty( name );
						u16 rewardHalved = Maths::Round( BASE_KILL_REWARD/2 );
						if ( booty < rewardHalved )
							server_setPlayerBooty( name,  booty + rewardHalved );
					}
				}
				server_updateTotalBooty( hitterTeamNum, totalReward + BASE_KILL_REWARD );
				//print ( "MothershipKill: " + thisPlayers + " players; " + ( ( thisPlayers + 1 ) * BASE_KILL_REWARD ) + " to " + rules.getTeam( hitterTeamNum ).getName() );
			}
		}

		return Maths::Max( 0.0f, hp - 1.0f );
	}
		
	return damage;
}

void onDie( CBlob@ this )
{
	selfDestruct( this );

	if ( !this.hasTag( "cleanDeath" ) )
		client_AddToChat( "*** " + getRules().getTeam( this.getTeamNum() ).getName() + " killed itself! ***" );
}

//healing, repelling, dmgmanaging, selfDestruct, damagesprite
void onTick( CBlob@ this )
{
	f32 hp = this.getHealth();
	Vec2f pos = this.getInterpolatedPosition();
	int color1 = this.getShape().getVars().customData;
	Island@ isle = getIsland( color1 );
	CRules@ rules = getRules();
	
	//repel
/* 	CBlob@[] cores;
	getBlobsByTag( "mothership", @cores );
	for ( u8 i = 0; i < cores.length; i++ )
	{
		f32 distance = cores[i].getDistanceTo( this );
		
		int color2 = cores[i].getShape().getVars().customData;
		if ( cores[i] !is this && color1 != color2 && distance < 125.0f  )
		{
			//sparks in the direction of the island
			if ( isle !is null )
			{
				Vec2f dir = pos - cores[i].getPosition();
				dir.Normalize();
				
				f32 whirlpoolFactor = !getRules().get_bool( "whirlpool" ) ? 2.0f : 1.25f;
				f32 healthFactor = Maths::Max( 0.25f, hp/INIT_HEALTH );
				isle.vel += dir * healthFactor*whirlpoolFactor/distance;
				
				dir.RotateBy( -45.0f );
				dir *= -6.0f * healthFactor;
				for ( int i = 0; i < 5; i++ )
				{
					CParticle@ p = ParticlePixel( pos, dir.RotateBy( 15 ), getTeamColor( this.getTeamNum() ), true );
					if(p !is null)
					{
						p.Z = 10.0f;
						p.timeout = 4;
					}
				}
			}
		}
	} */

	//heal
	if( getGameTime() % 60 == 0 )
	{
		CRules@ rules = getRules();
		u8 coreTeam = this.getTeamNum();
		
		if ( getNet().isServer() )
		{
			CBlob@[] humans;
			getBlobsByName( "human", humans );
			int hNum = humans.length();

			for( int i = 0; i < hNum; i++ )
				if ( humans[i].getTeamNum() == coreTeam && humans[i].getHealth() < humans[i].getInitialHealth() )
				{
					Island@ hIsle = getIsland( humans[i] );
					if ( hIsle !is null && hIsle.centerBlock !is null && color1 == hIsle.centerBlock.getShape().getVars().customData )
						humans[i].server_Heal( HEAL_AMOUNT );
				}
		}

		//dmgmanaging
		f32 msDMG = rules.get_f32( "msDMG" + coreTeam );
		if ( msDMG > 0 )
			rules.set_f32( "msDMG" + coreTeam, Maths::Max( msDMG - 0.75f, 0.0f ) );
			
		//damage Sprite (set here so joining clients are updated)
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ dmg = sprite.getSpriteLayer( "damage" );
		if ( dmg !is null )
		{
			u8 frame = Maths::Floor( ( INIT_HEALTH - hp ) / ( INIT_HEALTH / dmg.animation.getFramesCount() ) );
			dmg.animation.frame = frame;
		}
	}

	//critical Slowdown, selfDestruct and effects
	if ( this.hasTag( "critical" ) )
	{
		isle.vel *= 0.8f;

		if ( getNet().isServer() && getGameTime() > this.get_u32( "dieTime" ) )
			this.server_Die();
		
		//particles
		{
			CParticle@ p = ParticlePixel( pos, getRandomVelocity(90, 4, 360), getTeamColor( this.getTeamNum() ), true );
			if(p !is null)
			{
				p.Z = 10.0f;
				p.timeout = XORRandom(3) + 2;
			}
		}
		
		if ( v_fastrender )
		{
			CParticle@ p = ParticlePixel( pos, getRandomVelocity(90, 4, 360), getTeamColor( this.getTeamNum() ), true );
			if(p !is null)
			{
				p.Z = 10.0f;
				p.timeout = XORRandom(3) + 2;
			}
		}
	}
	//flaks warnings
	if (rules.get_bool("display_flak_team_warn")) {
		client_AddToChat("Beware! You almost reached the limit of flaks allowed for a team.");
		rules.set_bool("display_flak_team_warn", false);
	}
	if (rules.get_bool("display_flak_total_warn")) {
		client_AddToChat("Beware! You almost reached the limit of flaks active at the same time on the server (all teams together).");
		rules.set_bool("display_flak_total_warn", false);
	}
	
	//displayed by ShiprektHUD.as
	if (rules.get_bool("display_flak_team_max")) {
		rules.set_u8("flak_team_max_timer", rules.get_u8("flak_team_max_timer")+1);
		if (rules.get_u8("flak_team_max_timer") == 2)
			client_AddToChat("Sorry but you reached the limit of flaks allowed for a team.");
		if (rules.get_u8("flak_team_max_timer") >= 30*5) {
			rules.set_bool("display_flak_team_max", false);
			rules.set_u8("flak_team_max_timer", 0);
		}
	}
	if (rules.get_bool("display_flak_total_max")) {
		rules.set_u8("flak_total_max_timer", rules.get_u8("flak_total_max_timer")+1);
		if (rules.get_u8("display_flak_total_max") == 2)
			client_AddToChat("Sorry but the limit of active flaks on the server is reached. Try destroying some of them first.");
		if (rules.get_u8("flak_total_max_timer") >= 30*5) {
			rules.set_bool("display_flak_total_max", false);
			rules.set_u8("flak_total_max_timer", 0);
		}
	}
}

//make islandblocks start exploding
void initiateSelfDestruct( CBlob@ this )
{
	Vec2f pos = this.getInterpolatedPosition();
	//set timer for selfDestruct sequence
	this.Tag( "critical" );
	this.set_u32( "dieTime", getGameTime() + SELF_DESTRUCT_TIME );
	
	//effects
	directionalSoundPlay( "ShipExplosion.ogg", pos );
    makeLargeExplosionParticle( pos );

	//add block explosion scripts
	const int color = this.getShape().getVars().customData;
    if ( color == 0 )		return;

	Island@ isle = getIsland(color);
	if ( isle is null || isle.blocks.length < 10 )		return;
		
	this.AddScript( "Block_Explode.as" );
	u8 teamNum = this.getTeamNum();
	for ( uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter )
	{
		IslandBlock@ isle_block = isle.blocks[b_iter];
		CBlob@ b = getBlobByNetworkID( isle_block.blobID );
		if ( b !is null && teamNum == b.getTeamNum() )
		{
			int bType = Block::getType(b);
			if ( b_iter % 4 == 0 && !Block::isCore( bType ) && bType != Block::COUPLING )
				b.AddScript( "Block_Explode.as" );
		}
	}
}

//kill players, turrets and island
void selfDestruct( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	
	//effects
	directionalSoundPlay( "ShipExplosion", pos );
	makeWaveRing( pos, 4.5f, 15 );
    makeHugeExplosionParticle(pos);
    //ShakeScreen( 90, 80, pos );
	if ( this.isOnScreen() )
		SetScreenFlash( 150, 255, 255, 255 );

	if ( !getNet().isServer() ) 
		return;
		
	u8 teamNum = this.getTeamNum();
	//kill team players
	CBlob@[] dieBlobs;
	getBlobsByName( "human", @dieBlobs );
	for ( u16 i = 0; i < dieBlobs.length; i++ )
		if ( dieBlobs[i].getTeamNum() == teamNum )
			dieBlobs[i].server_Die();
	
	//turrets go neutral
	CBlob@[] turrets;
	getBlobsByTag( "weapon", @turrets );
	for ( u16 i = 0; i < turrets.length; i++ )
		if ( turrets[i].getTeamNum() == teamNum )
			turrets[i].server_setTeamNum(-1);
			
	//damage nearby blobs
	CBlob@[] blastBlobs;
	getMap().getBlobsInRadius( pos, BLAST_RADIUS, @blastBlobs );
	for ( u16 i = 0; i < blastBlobs.length; i++ )
		if ( blastBlobs[i] !is this )
		{
			f32 maxHealth = blastBlobs[i].getInitialHealth();
			f32 damage = 1.5f * maxHealth * ( BLAST_RADIUS - this.getDistanceTo( blastBlobs[i] ) )/BLAST_RADIUS;
			this.server_Hit( blastBlobs[i], pos, Vec2f_zero, damage, 0, true );
		}

	//kill island
	const int color = this.getShape().getVars().customData;
    if ( color == 0 )		return;

	Island@ isle = getIsland(color);
	if ( isle is null || isle.blocks.length < 10 )		return;

	for (uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter)
	{
		IslandBlock@ isle_block = isle.blocks[b_iter];
		CBlob@ b = getBlobByNetworkID( isle_block.blobID );
		if ( b !is null && b !is this && teamNum == b.getTeamNum() )
			b.server_Die();
	}
}