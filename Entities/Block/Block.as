#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "MakeDustParticle.as"
#include "AccurateSoundPlay.as"
#include "SAT_Shapes.as"

u8 DAMAGE_FRAMES = 3;
// onInit: called from engine after blob is created with server_CreateBlob()

void onInit( CBlob@ this )
{
	CSprite @sprite = this.getSprite();
	CShape @shape = this.getShape();
	sprite.asLayer().SetLighting( false );
	sprite.SetZ(510.0f);
	//shape.getConsts().net_threshold_multiplier = -1.0f;
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) );

	Blob3D blob3d(Vec3f(this.getPosition().x, 0, this.getPosition().y), 6, 2.0f);
	if ( blob3d !is null )
	{	
		this.set("blob3d", @blob3d);
	}
}

//void onRender(CSprite@ this)
//{
//	Blob3D@ blob3d;
//	if (!this.get("blob3d", @blob3d)) { return; }
//	SAT_Shape@ sat_shape;
//	if (this.getBlob().get("SAT_Info", @sat_shape))
// 	sat_shape.Render();
//}

void onTick ( CBlob@ this )
{
	Blob3D@ blob3d;
	if (!this.get("blob3d", @blob3d)) { return; }

	//blob3d.onTick();

	CSprite@ thisSprite = this.getSprite();	

	if (this.getTickSinceCreated() < 1) //accounts for time after block production
	{
		CRules@ rules = getRules();
		const int blockType = thisSprite.getFrame();
		const bool solid = Block::isSolid(blockType);

		switch (blockType)
		{
			case Block::DOOR:
			case Block::PLATFORM:
			case Block::PLATFORM2:
			case Block::SEAT:
			case Block::SHIPCORE:
			case Block::STATION:
			case Block::COUPLING:
			{
				@blob3d.shape = BoundingBox(Vec3f(-8, -6.8, -8), Vec3f(8, 0, 8), blob3d.transform.Position);
				break;
			}
			case Block::SOLID:
			case Block::RAM:
			case Block::REPULSOR:
			case Block::PROPELLER:
			case Block::RAMENGINE:
			{
				@blob3d.shape = BoundingBox(Vec3f(-8, -6.8, -8), Vec3f(8, 16, 8), blob3d.transform.Position);
				break;
			}			
			//case BOMB:
			//case POINTDEFENSE:
			//case HARVESTER:
			//case HARPOON:
			//case FLAK:
			//case MACHINEGUN:
			//case CANNON:
			//case LAUNCHER:
			//case PROPBLADES1:
			//case PROPBLADES2:
		}

		//if (Block::isCore(blockType))
		//{
		//	@blob3d.shape = SAT_Shape(this, 8, Vec3f(this.getPosition().x,0,this.getPosition().y), true, this.getMass(), true, this.getTeamNum());
		//}
		//else
		//{
		//	@blob3d.shape = SAT_Shape(this, square_Shape, Vec3f(this.getPosition().x,0,this.getPosition().y), true, 0, this.getMass(), solid, this.getTeamNum());
		//}

		u16 cost = Block::getCost( blockType );
				
		this.set_u8("ID", blockType);
		this.Tag("prop");				
		this.set_u32("cost", cost);
		
		this.set_f32("initial reclaim", this.getHealth());		
		if ( blockType == Block::STATION )
		{
			this.set_f32("current reclaim", 0.0f);
		}
		else
		{
			this.set_f32("current reclaim", this.getHealth());
		}
		
		//Set Owner
		if ( getNet().isServer() )
		{
			CBlob@ owner = getBlobByNetworkID( this.get_u16( "ownerID" ) );    
			if ( owner !is null )
			{
				this.set_string( "playerOwner", owner.getPlayer().getUsername() );
				this.Sync( "playerOwner", true );
			}
		}
	}
	
	//path predicted collisions
	const int color = this.getShape().getVars().customData;
	if ( color > 0 )
	{
		Island@ island = getIsland(color);
		if ( island !is null && !island.isStation )
		{
			//Vec2f vel = this.getVelocity();
			//if (vel.Length() > 0)
			//{
			//	Vec2f pos = this.getPosition();
			//	Vec2f MTV;
	        //    if (sat_shape.checkCollision(vel, MTV))
	        //    {
	        //        this.setPosition((pos + vel)-MTV);
	        //        sat_shape.Pos = V2toV3((pos + vel)-MTV);
	        //    }
	        //    else
	        //    {
	        //        this.setPosition(pos + vel);
	        //        sat_shape.Pos = V2toV3(pos + vel);
	        //    }
			//}			

			//shape.setAngle(-this.getAngleDegrees());

//			Vec2f velnorm = island.vel; 
//			const f32 vellen = velnorm.Normalize();				
//									
//				bool dontHitMore = false;
//			
//				//if( sat_shape.Overlapping )
//				{			
//					CBlob@ o = sat_shape.OtherBlob;
//					if (o !is null)
//					{
//						const int other_color = o.getShape().getVars().customData;
//							
//						if ( color != other_color )
//						{
//							if ( other_color > 0 )
//							{
//								Island@ other_island = getIsland(other_color);
//							
//								if ( other_island !is null )
//								{	
//									//CollisionResponse1( island, other_island, sat_shape);	
//								}
//							}
//						}						
//					}							
//				}
		}
	}
	
 	// push merged ships away from each other
	if ( this.get_bool( "colliding" ) == true )
		this.set_bool( "colliding", false ); 

	if ( !getNet().isServer() )	//awkward fix for blob team changes wiping up the frame state (rest on islands.as)
	{
		u8 frame = this.get_u8( "frame" );
		if ( thisSprite.getFrame() == 0 && frame != 0 )
			thisSprite.SetFrame( frame );
	}
}

// onCollision: called once from the engine when a collision happens; 
// blob is null when it is a tilemap collision

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
	if ( blob is null || this.hasTag( "noCollide" ) || blob.hasTag( "noCollide" ) )	return;

//	SAT_Shape@ sat_shape;
//	if (!this.get("SAT_Info", @sat_shape))
//	return;
//
	f32 this_health = this.getHealth();
	f32 other_health = blob.getHealth();
	f32 this_initialHealth = this.getInitialHealth();
	f32 other_initialHealth = blob.getInitialHealth();
	const int color = this.getShape().getVars().customData;
	const int other_color = blob.getShape().getVars().customData;
	if (color > 0 && other_color > 0 && color != other_color) // block vs block
	{
		Island@ island = getIsland(color);
		Island@ other_island = getIsland(other_color);
	
		const int blockType = this.getSprite().getFrame();
		const bool solid = Block::isSolid(blockType);
		const int other_blockType = blob.getSprite().getFrame();
		const bool other_solid = Block::isSolid(other_blockType);
		bool docking;
		bool ramming;
		
		if ( island !is null && other_island !is null )
		{
			if ( island.vel.Length() < 0.01f && other_island.vel.Length() < 0.01f )
				return;
				
			docking = ( blockType == Block::COUPLING || other_blockType == Block::COUPLING ) 
								&& ( ( island.isMothership || other_island.isMothership ) || ( island.isStation || other_island.isStation ) )
								&& this.getTeamNum() == blob.getTeamNum()
								&& ( ( !island.isMothership && island.owner != "" ) || ( !other_island.isMothership && other_island.owner != "" ) );
								
			ramming = ( blockType == Block::RAM || other_blockType == Block::RAM
							|| blockType == Block::RAMENGINE || other_blockType == Block::RAMENGINE
							|| blockType == Block::SEAT || other_blockType == Block::SEAT
							|| blockType == Block::DOOR || other_blockType == Block::DOOR 
							|| blockType == Block::COUPLING || other_blockType == Block::COUPLING );
		}
		else
			docking = false;
			
		if ( island !is null && !docking && !ramming )
		{
			bool shouldCollide = true;
			for (uint b_iter = 0; b_iter < island.blocks.length; ++b_iter)
			{
				IslandBlock@ isle_block = island.blocks[b_iter];
				if(isle_block is null) continue;
//
				CBlob@ block = getBlobByNetworkID( isle_block.blobID );
				if(block is null) continue;
				
				if ( block.get_bool( "colliding" ) == true )
					shouldCollide = false;
			}
			
			if ( shouldCollide )
				this.set_bool( "colliding", true );		
			
			if ( this.get_bool( "colliding" ) == true )
			{
				//CollisionResponse1( island, other_island, sat_shape);
			}
		}		
		
		if (getNet().isServer() && !(blockType == Block::STATION || other_blockType == Block::STATION) )
		{
			if ( docking )//force island merge
				getRules().set_bool("dirty islands", true);
			else if ( blockType == Block::COUPLING || other_blockType == Block::COUPLING )//couplings don't deal damage
			{
				if ( blockType == Block::COUPLING )
					Die( this );
				
				if ( other_blockType == Block::COUPLING )
					Die( blob );
			}
			else if ( Block::isRepulsor( blockType ) || Block::isRepulsor( other_blockType ) )//repulsors don't deal damage
			{
				if ( Block::isRepulsor( blockType ) )
					Die( this );
				
				if ( Block::isRepulsor( other_blockType ) )
					Die( blob );
			}
			else
			{
				if ( blockType == Block::RAMENGINE )//ram engines deal slight damage
				{
					if ( blob.hasTag( "weapon" ) ) 
					{
						this.server_Hit( blob, point1, Vec2f_zero, 1.1f, 0, true );
						Die( this );
					}
					else if ( other_blockType == Block::PROPELLER || other_blockType == Block::SOLID )
					{
						this.server_Hit( blob, point1, Vec2f_zero, 2.1, 0, true );
						Die( this );
					}	
					else if ( other_blockType == Block::PLATFORM )
					{
						Die( blob );
						Die( this );
					}				
					else
					{
						this.server_Hit( blob, point1, Vec2f_zero, 1.1f, 0, true );
						Die( this );
					}
				}
				
				if ( blockType == Block::DOOR || other_blockType == Block::DOOR )//seats don't deal damage
				{
					if ( blockType == Block::DOOR )
						Die( this );
					
					if ( other_blockType == Block::DOOR )
						Die( blob );
				}
				
				if ( blockType == Block::SEAT || other_blockType == Block::SEAT )//seats don't deal damage
				{
					if ( blockType == Block::SEAT )
						Die( this );
					
					if ( other_blockType == Block::SEAT )
						Die( blob );
				}
//
				
				if ( Block::isBomb( blockType ) || Block::isBomb( other_blockType ) ) //bombs annihilate all
				{
					Die( this );
					Die( blob );
				}
				
				if ( blockType == Block::RAM )//Ram vs all
				{
					if ( other_blockType == Block::SHIPCORE)
					{
						blob.server_Hit( this, point1, Vec2f_zero, other_solid ? 0.75f : 0.37f, 0, true );
						Die( this );
					}
					else if ( other_blockType == Block::PROPELLER )
					{
						this.server_Hit( this, point1, Vec2f_zero, 2.2f, 0, true );
						Die( blob );
					}
					else if ( other_blockType == Block::RAMENGINE )
					{
						this.server_Hit( this, point1, Vec2f_zero, 1.1f, 0, true );
						Die( blob );
					}
					else if ( other_blockType == Block::SOLID || other_blockType == Block::RAM )
					{
						Die( this );
						Die( blob );
					}
					else if ( blob.hasTag( "weapon" ) )
					{
						if ( other_health >= this_health )
						{
							Die( this );
							this.server_Hit( blob, point1, Vec2f_zero, solid ? this_health : this_health/2.0f, 0, true );
						}
						else
						{
							Die( blob );
							blob.server_Hit( this, point1, Vec2f_zero, 2.0f, 0, true );
						}
					}
					else if (!other_solid && other_island !is null)
					{
						this.server_Hit( this, point1, Vec2f_zero, 1.1f, 0, true );
						Die( blob );
					}
					else 
						Die( blob );
				}
			}
		}
	}
	else if (other_color == 0 && color > 0)
	{
		int blockType = this.getSprite().getFrame();
		// solid block vs player
		if (Block::isSolid(blockType))
		{
			Vec2f pos = blob.getPosition();
			
			if ( getNet().isClient() && !blob.isAttached() && blob.getName() == "human" && blob.isMyPlayer() )
			{
				//kill by impact
				Island@ island = getIsland(color);
				if ( island !is null && this.getTeamNum() != blob.getTeamNum() && ( getGameTime() - blob.get_u32( "groundTouch time" ) < 15 )/*longer wasOnGround*/
					&& ( island.vel.LengthSquared() > 4.0f || Maths::Abs(island.angle_vel) > 1.75f || blob.getOldVelocity().LengthSquared() > 9.0f ) )
				{
//
					CPlayer@ player = blob.getPlayer();
					if ( player !is null )
					{
						player.client_ChangeTeam(44);//this makes the sv kill the playerblob (Respawning.as)
						blob.Tag( "dead" );
						CSprite@ sprite = blob.getSprite();
						if ( sprite !is null && !sprite.getVars().gibbed )//to mask the latency a bit
						{
							directionalSoundPlay( "SR_ManDeath" + ( XORRandom(4) + 1 ), pos );
							sprite.Gib();
						}
					}
				}
				
				//set position collision
				//blob.setPosition( pos + normal * -blob.getRadius() * 0.55f );
			}
		}
	}
}

void CollisionResponse1( Island@ island, Island@ other_island, BoundingShape@ shape)
{
	if ( island is null || other_island is null )
		return;
		
	if ( island.mass <= 0 || other_island.mass <= 0 )
		return;
	
	Vec2f velnorm = island.vel; 
	const f32 vellen = velnorm.Normalize();
	Vec2f other_velnorm = other_island.vel; 
	const f32 other_vellen = other_velnorm.Normalize();
	
	Vec2f colvec1 = Vec2f(shape.getPosition().x, shape.getPosition().z) - island.pos;
	Vec2f colvec2 = Vec2f(shape.getPosition().x, shape.getPosition().z) - other_island.pos;
	colvec1.Normalize();
	colvec2.Normalize();

	const f32 veltransfer = 1.0f;
	const f32 veldamp = 1.0f;
	const f32 dirscale = 1.0f;
	f32 reactionScale1 = 1.0f;
	if ( other_island.beached )
		reactionScale1 *= 2;
	f32 reactionScale2 = 1.0f;
	if ( island.beached )
		reactionScale2 *= 2;
	const f32 massratio1 = other_island.mass/(island.mass+other_island.mass);
	const f32 massratio2 = island.mass/(island.mass+other_island.mass);
	island.vel *= veldamp;
	other_island.vel *= veldamp;
	
	if ( other_island.isStation )
	{
		if ( island.beached )
			island.vel += colvec1 * -vellen * dirscale * veltransfer - colvec1*1.0f;
		else
			island.vel += colvec1 * -vellen * dirscale * veltransfer - colvec1*0.4f;
	}
	else
	{
		island.vel += colvec1 * -other_vellen * dirscale * massratio1 * veltransfer * reactionScale1 - colvec1*0.2f;
		other_island.vel += colvec2 * -vellen * dirscale * massratio2 * veltransfer * reactionScale2 - colvec2*0.2f;
	}
}

void onDie(CBlob@ this)
{
	//gib the sprite
	if (this.getShape().getVars().customData > 0)
		this.getSprite().Gib();

	if ( getNet().isClient() )
	{
		//kill humans standing on top. done locally because lag makes server unable to catch the overlapping playerblobs
		int type = this.getSprite().getFrame();
		if ( type != Block::COUPLING && !Block::isRepulsor( type ) )
		{
			CBlob@ localBlob = getLocalPlayerBlob();
			if ( localBlob !is null && localBlob.get_u16( "shipID" ) == this.getNetworkID() )
			{
				CPlayer@ player = localBlob.getPlayer();
				if ( player !is null && localBlob.getDistanceTo( this ) < 6.5f )
				{
					player.client_ChangeTeam(44);//this makes the sv kill the playerblob (Respawning.as)
					localBlob.Tag( "dead" );
					CSprite@ sprite = localBlob.getSprite();
					if ( sprite !is null && !sprite.getVars().gibbed )//to mask the latency a bit
					{
						directionalSoundPlay( "SR_ManDeath" + ( XORRandom(4) + 1 ), localBlob.getPosition() );
						sprite.Gib();
					}
				}
			}
		}
	}
	
	if ( getNet().isServer() && this.hasTag( "seat" ) )
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ b = seat.getOccupied();
		if ( b !is null )
			b.server_Die();
	}
}

void Die( CBlob@ this )
{
	if(!getNet().isServer()) return;
	
	this.Tag( "noCollide" );
	this.server_Die();
}

//mothership damage alerts
f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if ( this.getTeamNum() != hitterBlob.getTeamNum() && isMothership( this ) )
	{
		int teamNum = this.getTeamNum();
		CRules@ rules = getRules();
		
		f32 msDMG = rules.get_f32( "msDMG" + teamNum );
		if ( msDMG < 8.0f )
			getRules().set_f32( "msDMG" + teamNum, msDMG + ( this.hasTag( "mothership" ) ? 5.0f : 1.0f ) * damage );
	}
	
	return damage;
}

//damage layers
void onHealthChange( CBlob@ this, f32 oldHealth )
{
	if ( this.hasTag( "mothership" ) ) return;//has own code
	
	int blockType = this.getSprite().getFrame();
	const f32 hp = this.getHealth();
	const f32 initHealth = this.getInitialHealth();

	if (hp < 0.0f)
		this.server_Die();
	else
	{
		//update reclaim status
		if ( hp < this.get_f32("current reclaim") )
		{
			this.set_f32("current reclaim", hp);
		}
	
		//add damage layers
		f32 step = initHealth / ( DAMAGE_FRAMES + 1 );
		f32 currentStep = Maths::Floor( oldHealth/step ) * step;
		
		if ( hp < currentStep && hp <= initHealth - step && Block::isSolid( blockType ) )
		{
			if ( blockType == Block::RAM )
			{
				const int frame = (oldHealth > initHealth * 0.5f) ? 9 : 10;	
				CSprite@ sprite = this.getSprite();
				CSpriteLayer@ layer = sprite.addSpriteLayer( "dmg"+frame );
				if (layer !is null)
				{
					layer.SetRelativeZ(1+frame);
					layer.SetLighting( false );
					layer.SetFrame(frame);
					layer.RotateBy( XORRandom(4) * 90, Vec2f_zero );
				}
			}
			else if ( blockType != Block::RAMENGINE && blockType != Block::POINTDEFENSE )
			{
				const int frame = (oldHealth > initHealth * 0.5f) ? 5 : 6;	
				CSprite@ sprite = this.getSprite();
				CSpriteLayer@ layer = sprite.addSpriteLayer( "dmg"+frame );
				if (layer !is null)
				{
					layer.SetRelativeZ(1+frame);
					layer.SetLighting( false );
					layer.SetFrame(frame);
					layer.RotateBy( XORRandom(4) * 90, Vec2f_zero );
				}
			}

		    MakeDustParticle( this.getPosition(), "/dust2.png");
	    }
		if ( oldHealth >= initHealth*0.80f )
		{
			CSprite@ sprite = this.getSprite();
			for (uint frame = 0; frame < 11; ++frame)
			{
				sprite.RemoveSpriteLayer("dmg"+frame);
			}
		}
	}
}

void onGib(CSprite@ this)
{
	Vec2f pos = this.getBlob().getPosition();
	MakeDustParticle( pos, "/DustSmall.png");
	directionalSoundPlay( "destroy_wood", pos );
}
// network

void onSendCreateData( CBlob@ this, CBitStream@ stream )
{
	stream.write_u8( Block::getType(this) );
	stream.write_netid( this.get_u16("ownerID") );
}

bool onReceiveCreateData( CBlob@ this, CBitStream@ stream )
{
	u8 type = 0;
	u16 ownerID = 0;

	if (!stream.saferead_u8(type)){
		warn("Block::onReceiveCreateData - missing type");
		return false;	
	}
	if (!stream.saferead_u16(ownerID)){
		warn("Block::onReceiveCreateData - missing ownerID");
		return false;	
	}

	this.getSprite().SetFrame( type );

	CBlob@ owner = getBlobByNetworkID(ownerID);
	if (owner !is null)
	{
	    owner.push( "blocks", @this );
		this.getShape().getVars().customData = -1; // don't push on island
	}

	return true;
}