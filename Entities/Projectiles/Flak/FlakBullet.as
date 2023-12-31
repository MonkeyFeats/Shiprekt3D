#include "ExplosionEffects.as";
#include "WaterEffects.as"
#include "BlockCommon.as"
#include "IslandsCommon.as"
#include "Booty.as"
#include "AccurateSoundPlay.as"
#include "TileCommon.as"

const f32 EXPLODE_RADIUS = 30.0f;
const f32 FLAK_REACH = 50.0f;

void onInit( CBlob@ this )
{
	this.Tag("flak shell");
	this.Tag("projectile");

	ShapeConsts@ consts = this.getShape().getConsts();
    consts.mapCollisions = false;	 // weh ave our own map collision
	consts.bullet = true;	

	this.getSprite().SetZ(550.0f);
	
	if( !CustomEmitEffectExists( "FlakEmmit" ) )
		SetupCustomEmitEffect( "FlakEmmit", "FlakBullet.as", "updateFlakParticle", 1, 0, 30 );
		//SetupCustomEmitEffect( STRING name, STRING scriptfile, STRING scriptfunction, u8 hard_freq, u8 chance_freq, u16 timeout )
	

}

void onTick( CBlob@ this )
{
	if ( !getNet().isServer() ) return;
	
	bool killed = false;

	Vec2f pos = this.getPosition();
	const int thisColor = this.get_u32( "color" );
	
	if ( isTouchingRock(pos) )
	{
		this.server_Die();
	}

	CBlob@[] blobs;
	if ( getMap().getBlobsInRadius( pos, Maths::Min( float( 5 + this.getTickSinceCreated() ), EXPLODE_RADIUS ), @blobs ) )
	{
		for ( uint i = 0; i < blobs.length; i++ )
		{
			CBlob@ b = blobs[i];
			if( b is null ) continue;

			const int color = b.getShape().getVars().customData;
			const int blockType = b.getSprite().getFrame();
			const bool isBlock = b.getName() == "block";
			if ( isBlock && color > 0 && color != thisColor && Block::isSolid(blockType) )
				this.server_Die();
		}
	}
}

void flak( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	CBlob@[] blobs;
	map.getBlobsInRadius( pos, FLAK_REACH, @blobs );
	
	if ( blobs.length < 2 )
		return;
		
	f32 angle = XORRandom( 360 );
	CPlayer@ owner = this.getDamageOwnerPlayer();

	for ( u8 s = 0; s < 12; s++ )
	{
		HitInfo@[] hitInfos;
		if ( map.getHitInfosFromRay( pos, angle, FLAK_REACH, this, @hitInfos ) )
		{
			for ( uint i = 0; i < hitInfos.length; i++ )//sharpnel trail
			{
				CBlob@ b = hitInfos[i].blob;	  
				if( b is null || b is this ) continue;
									
				const int blockType = b.getSprite().getFrame();
				const bool sameTeam = b.getTeamNum() == this.getTeamNum();
				if ( Block::isSolid( blockType ) || ( !sameTeam
					&& ( blockType == Block::SEAT || b.hasTag( "weapon" ) || b.hasTag( "rocket" ) || blockType == Block::SHIPCORE || blockType == Block::DOOR || Block::isBomb( blockType ) || ( b.hasTag( "player" ) && !b.isAttached() ) ) ) )
				{
					this.server_Hit( b, hitInfos[i].hitpos, Vec2f_zero, getDamage( b, blockType ), 11, true );
					if ( owner !is null )
					{
						CBlob@ blob = owner.getBlob();
						if ( blob !is null )
							damageBooty( owner, blob, b );
					}
					
					break;
				}
			}
		}
		
		angle = ( angle + 30.0f ) % 360;
	}
}

void onDie( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	
	if (getNet().isClient())
	{
		directionalSoundPlay( "FlakExp"+XORRandom(2), pos, 2.0f );
		for ( u8 i = 0; i < 3; i++ )
				makeSmallExplosionParticle( pos + getRandomVelocity( 90, 12, 360 ) );
	}

	if ( getNet().isServer() ) 	
		flak( this );
}

f32 getDamage( CBlob@ hitBlob, int blockType )
{
	if ( hitBlob.hasTag("rocket") )
		return 2.0f; 

	if ( blockType == Block::PROPELLER )
		return 0.15f;
		
	if ( blockType == Block::RAMENGINE )
		return 0.5f;

	if ( blockType == Block::DOOR )
		return 0.3f;

	if ( hitBlob.getName() == "shark" || hitBlob.getName() == "human" )
		return 0.3f;

	if ( blockType == Block::SEAT || hitBlob.hasTag( "weapon" ) )
		return 0.25f;
	
	if ( blockType == Block::SHIPCORE )
		return 0.25f;
	
	if ( Block::isBomb( blockType ) )
		return 0.1f;
	
	return 0.01f;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{	
	const int blockType = hitBlob.getSprite().getFrame();

	if (hitBlob.getName() == "shark"){
		ParticleBloodSplat( worldPoint, true );
		directionalSoundPlay( "BodyGibFall", worldPoint );		
	}
	else	if (Block::isSolid(blockType) || blockType == Block::SHIPCORE || blockType == Block::DOOR || blockType == Block::SEAT || hitBlob.hasTag( "weapon" ) )
	{
		Vec2f vel = worldPoint - hitBlob.getPosition();//todo: calculate real bounce angles?
		makeSharpnelParticle( worldPoint, vel );
		directionalSoundPlay( "Ricochet" +  ( XORRandom(3) + 1 ) + ".ogg", worldPoint, 0.35f );
	}
}

void updateFlakParticle( CParticle@ p )
{
	p.colour.setGreen( p.colour.getGreen() - 7 );
	p.colour.setBlue( p.colour.getBlue() - 5 );
	p.velocity *= 0.85f;
}

Random _sprk_r;
void makeSharpnelParticle( Vec2f pos, Vec2f vel )
{
	u8 emiteffect = GetCustomEmitEffectID( "FlakEmmit" );
	CParticle@ p = ParticlePixel( pos, vel, SColor( 255, 255, 235, 100 ), true );
	if(p !is null)
	{
		p.timeout = 10 + _sprk_r.NextRanged(5);
		p.scale = 1.5f;
		p.emiteffect = emiteffect;
	}
}

void damageBooty( CPlayer@ attacker, CBlob@ attackerBlob, CBlob@ victim )
{
	if ( victim.getName() == "block" )
	{
		const int blockType = victim.getSprite().getFrame();
		u8 teamNum = attacker.getTeamNum();
		u8 victimTeamNum = victim.getTeamNum();
		string attackerName = attacker.getUsername();
		Island@ victimIsle = getIsland( victim.getShape().getVars().customData );

		if ( victimIsle !is null && victimIsle.blocks.length > 3
			&& ( victimIsle.owner != "" || victimIsle.isMothership )
			&& victimTeamNum != teamNum
			&& ( victim.hasTag("weapon") || blockType == Block::SHIPCORE || blockType == Block::DOOR || Block::isBomb( blockType ) || blockType == Block::SEAT )
			)
		{
			if ( attacker.isMyPlayer() )
				Sound::Play( "Pinball_0", attackerBlob.getPosition(), 0.5f );

			if ( getNet().isServer() )
			{
				CRules@ rules = getRules();
				
				u16 reward = 2;//propellers, seats
				if ( victim.hasTag( "weapon" ) || Block::isBomb( blockType ) )
					reward += 2;
				else if ( blockType == Block::SHIPCORE )
					reward += 5;

				f32 bFactor = ( rules.get_bool( "whirlpool" ) ? 3.0f : 1.0f ) * Maths::Min( 2.5f, Maths::Max( 0.15f,
				( 2.0f * rules.get_u16( "bootyTeam_total" + victimTeamNum ) - rules.get_u16( "bootyTeam_total" + teamNum ) + 1000 )/( rules.get_u32( "bootyTeam_median" ) + 1000 ) ) );
				
				reward = Maths::Round( reward * bFactor );
					
				server_setPlayerBooty( attackerName, server_getPlayerBooty( attackerName ) + reward );
				server_updateTotalBooty( teamNum, reward );
			}
		}
	}
}
