#include "HumanCommon.as"
#include "EmotesCommon.as"
#include "MakeBlock.as"
#include "WaterEffects.as"
#include "IslandsCommon.as"
#include "BlockCommon.as"
#include "Booty.as"
#include "AccurateSoundPlay.as"
#include "TileCommon.as"
#include "Blob3D.as"

int useClickTime = 0;
const int PUNCH_RATE = 15;
const int FIRE_RATE = 40;
const int CONSTRUCT_RATE = 14;
const int CONSTRUCT_VALUE = 5;
const int CONSTRUCT_RANGE = 48;
const f32 BULLET_SPREAD = 0.2f;
const f32 BULLET_SPEED = 9.0f;
const f32 BULLET_RANGE = 350.0f;
Random _shotspreadrandom(0x11598); //clientside
string menu_selected = "build_menu";

void onInit( CBlob@ this )
{	
	this.Tag("player");	 

	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.addCommandID("get out");
	this.addCommandID("shoot");
	this.addCommandID("construct");
	this.addCommandID("punch");
	this.addCommandID("giveBooty");
	this.addCommandID("releaseOwnership");
	this.addCommandID("swap tool");
	this.addCommandID(camera_sync_cmd);
	this.addCommandID("cycle");

	Blob3D@ blob3d;
	if (!this.get("blob3d", @blob3d))  
	{
		Blob3D@ blob3d = Blob3D(this, Vec3f(this.getPosition().x, 0, this.getPosition().y), 6, 2.0f);
		if ( blob3d !is null )
		{
			@blob3d.shape = BoundingBox( Vec3f(-3.3, -0.0, -3.3), Vec3f(3.3, 18.0, 3.3));
			//blob3d.shape.ownerBlob = blob3d;
			blob3d.shape.SetStatic(false);
			blob3d.shape.setPosition(Vec3f(this.getPosition().x, 0, this.getPosition().y));

			//blob3d.mesh.LoadObjIntoMesh("buckeneer.obj");
			//blob3d.meshbuffer.SetHardwareMappingHint(Driver::STATIC);	
			SMaterial@ meshMaterial = blob3d.meshbuffer.getMaterial();
			meshMaterial.SetFlag(SMaterial::LIGHTING, false);
			//blob3d.mesh.BuildMesh();

			this.set("blob3d", @blob3d);
		}
	}

	if ( getNet().isClient() )
	{
		CBlob@ core = getMothership( this.getTeamNum() );
		if (core !is null) 
		{
//
			this.setPosition( core.getPosition() );
			this.set_u16( "shipID", core.getNetworkID() );
			this.set_s8( "stay count", 3 );		
			blob3d.setPosition(Vec3f(core.getPosition().x, 0, core.getPosition().y));
//
			//BuildShopMenu( this, core, "mCore Block Transmitter", Vec2f(0,0) );
		}
	}
	
	this.SetMapEdgeFlags( u8(CBlob::map_collide_up) |
		u8(CBlob::map_collide_down) |
		u8(CBlob::map_collide_sides) );
	
	this.set_u32("menu time", 0);
	this.set_bool( "build menu open", false );
	this.set_string("last buy", "coupling");
	this.set_string("current tool", "fists");
	this.set_u32("fire time", 0);
	this.set_u32("punch time", 0);
	this.set_u32("groundTouch time", 0);
	this.set_bool( "onGround", true );//for syncing
	this.getShape().getVars().onground = true;
	directionalSoundPlay( "Respawn", this.getInterpolatedPosition(), 2.5f );


	if (!Texture::exists("pixel"))
	{
		Texture::createFromFile("pixel", "pixel.png");
	}
}

Vec3f myPos(CBlob@ this)
{
	f32 x = this.get_f32("pos_x");
	f32 y =	this.get_f32("pos_y");
	f32 z =	this.get_f32("pos_z");
	return Vec3f(x,y,z);
}

void onTick( CBlob@ this )
{	
	Blob3D@ blob3d;
	if (!this.get("blob3d", @blob3d)) { return; }

	this.setPosition(Vec2f(blob3d.getPosition().x,blob3d.getPosition().z));

	blob3d.onTick();

	Vec3f look_dir = blob3d.transform.Orientation.getXYZ();

	f32 rayheight = look_dir.y/Maths::Pi;
	Vec2f rayaim = this.getPosition()+Vec2f(45/1+look_dir.y/2,0).RotateBy(look_dir.x);

	f32 raydist = Maths::Max(1,Maths::Min(32,90/1+look_dir.y-32));
	f32 closestdist = 999999;

	Vec2f tilepos = this.getPosition()+Vec2f(raydist,0).RotateBy(look_dir.x);
	Vec2f hitpos;
	
	HitInfo@[] hitInfos;
	if (getMap().getHitInfosFromRay( this.getPosition(), look_dir.x, raydist, this, @hitInfos ))
	{
		if ( hitInfos.length > 0 )
		{
			uint closesthit;
			//HitInfo objects are sorted, first come closest hits
			for ( uint i = 0; i < hitInfos.length; i++ )
			{
				HitInfo@ hi = hitInfos[i];
				f32 len = hi.distance;
				CBlob@ b = hi.blob;	  
				if( b !is null)
				{
					const int blockType = b.getSprite().getFrame(); 
					if ( !Block::isSolid( blockType ) || b is this || b.isAttached()) 
					continue;

					if (len < closestdist)
					{
						closestdist = len;
						closesthit = i;				
						this.set_Vec2f("aim_pos", b.getPosition());
					}
				}
				else if (len < closestdist)
				{
					closestdist = len;
					closesthit = i;				
					this.set_Vec2f("aim_pos", hitInfos[i].hitpos);
				}
			}
		}
	}
	if (closestdist >= 56)
	{
		this.set_Vec2f("aim_pos", tilepos);
	}	

	Update( this );

	u32 gameTime = getGameTime();

	if (this.isMyPlayer())
	{
		PlayerControls( this );

		if ( gameTime % 10 == 0 )
		{
			this.set_bool( "onGround", this.isOnGround() );
			this.Sync( "onGround", false );
		}	
	}

	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ laser = sprite.getSpriteLayer( "laser" );

	//kill laser after a certain time
	if ( laser !is null && !this.isKeyPressed(key_action2) && this.get_u32("fire time") + CONSTRUCT_RATE < gameTime )
	{
		sprite.RemoveSpriteLayer("laser");
	}
	
	// stop reclaim effects
	if (this.isKeyJustReleased(key_action2) || this.isAttached())
	{
		this.set_bool( "reclaimPropertyWarn", false );
		if ( sprite.getEmitSoundPaused() == false )
		{
			sprite.SetEmitSoundPaused(true);
		}
		sprite.RemoveSpriteLayer("laser");
	}
}

void Update( CBlob@ this )
{
	Blob3D@ blob3d;
	if (!this.get("blob3d", @blob3d)) { return; }

	const bool myPlayer = this.isMyPlayer();
	const f32 camRotation = blob3d.transform.Orientation.x; //change to cam3d dirx
	const bool attached = this.isAttached();

	Vec2f pos = this.getPosition();//sat_shape.Pos;	
	Vec2f aimpos = this.getAimPos();
	Vec2f forward = aimpos - pos;
	CShape@ shape = this.getShape();
	CSprite@ sprite = this.getSprite();
	
	string currentTool = this.get_string( "current tool" );
	
	if (!attached)
	{
		const bool up = this.isKeyPressed( key_up );
		const bool down = this.isKeyPressed( key_down );
		const bool left = this.isKeyPressed( key_left);
		const bool right = this.isKeyPressed( key_right );	
		const bool action1 = this.isKeyPressed( key_action1 );
		const bool action2 = this.isKeyPressed( key_action2 );
		const u32 time = getGameTime();
		const f32 vellen = shape.vellen;
		Island@ isle = getIsland( this );
		CMap@ map = this.getMap();
		const bool solidGround = shape.getVars().onground = attached || isle !is null || isTouchingLand( pos );
		if ( !this.wasOnGround() && solidGround )
			this.set_u32("groundTouch time", time);//used on collisions
		
		//tool actions
		if (!Human::isHoldingBlocks(this))
		{
			if (action1)
			{
				if (currentTool == "fists" && canPunch(this))
				{
					Punch( this );
					sprite.SetAnimation("punch");				
				}
				else if ( currentTool == "pistol" && canShootPistol( this ) ) // shoot
				{
					ShootPistol( this );
					sprite.SetAnimation("shoot");
				}
				else if ( currentTool == "deconstructor" ) //repair
				{
					this.set_string("current tool", "reconstructor");
					sprite.SetAnimation("repair");
				}
				else if ( currentTool == "reconstructor" ) //repair
				{
					Construct( this );
					sprite.SetAnimation("repair");
				}
			}
			else if (action2)
			{
				if (currentTool == "fists" && canPunch(this))
				{
					Punch( this );
					sprite.SetAnimation("punch");
				}
				else if ( currentTool == "pistol" && canShootPistol( this ) ) // shoot
				{
					ShootPistol( this );
					sprite.SetAnimation("shoot");
				}
				else if ( currentTool == "telescope") // shoot
				{
					sprite.SetAnimation("scopein");
				}
				else if ( currentTool == "reconstructor" ) //repair
				{
					this.set_string("current tool", "deconstructor");
					sprite.SetAnimation("reclaim");
				}
				else if ( currentTool == "deconstructor" ) //reclaim
				{
					Construct( this );
					sprite.SetAnimation("reclaim");
				}
			}
			else if ( currentTool == "telescope") // shoot
			{

				sprite.animation.frame = 24;
				sprite.SetAnimation("scopeout");
			}
		}			

		// artificial stay on ship
		if ( myPlayer )
		{
			CBlob@ islandBlob = getIslandBlob( this );
			if (islandBlob !is null)
			{
				this.set_u16( "shipID", islandBlob.getNetworkID() );	
				this.set_s8( "stay count", 3 );
			}
			else
			{
				CBlob@ shipBlob = getBlobByNetworkID( this.get_u16( "shipID" ) );
				if (shipBlob !is null)
				{
					s8 count = this.get_s8( "stay count" );		
					count--;
					if (count <= 0){
						this.set_u16( "shipID", 0 );	
					}
					else if ( !Block::isSolid( Block::getType( shipBlob ) ) && !up && !left && !right && !down )
					{
						Island@ isle = getIsland( shipBlob.getShape().getVars().customData );
						if ( isle !is null && isle.vel.Length() > 1.0f )
							blob3d.transform.Position.opAdd(Vec3f(shipBlob.getPosition().x,0,shipBlob.getPosition().y));
					}
					this.set_s8( "stay count", count );
				}
			}
		}
	}
	else
	{
		shape.getVars().onground = true;
	}
}

//void onRender(CSprite@ this)
//{
//	Blob3D@ blob3d;
//	if (!this.getBlob().get("blob3d", @blob3d)) return;
//
//	if (blob3d.shape !is null)
// 	blob3d.shape.Render();	
//
//	//Vec2f aimPos = this.getBlob().get_Vec2f("aim_pos");
//    //GUI::DrawLine(this.getBlob().getPosition(), aimPos, SColor(255,0,255,255));
//}

void PlayerControls( CBlob@ this )
{
	CHUD@ hud = getHUD();
	CControls@ controls = getControls();
	bool toolsKey = controls.isKeyJustPressed( controls.getActionKeyKey( AK_PARTY ) );
	CSprite@ sprite = this.getSprite();
	
	// bubble menu
	if (this.isKeyJustPressed(key_bubbles))
	{
		this.CreateBubbleMenu();
	}

	if (this.isAttached())
	{
	    // get out of seat
		if (this.isKeyJustPressed(key_use))
		{
			CBitStream params;
			this.SendCommand( this.getCommandID("get out"), params );
		}			
	}
	else
	{
		// use menu
	    if (this.isKeyJustPressed(key_use))
	    {
	        useClickTime = getGameTime();
	    }
	    if (this.isKeyPressed(key_use))
	    {
	        this.ClearMenus();
			this.ClearButtons();
	        this.ShowInteractButtons();
	    }
	    else if (this.isKeyJustReleased(key_use))
	    {
	    	bool tapped = (getGameTime() - useClickTime) < 10; 
			this.ClickClosestInteractButton( tapped ? this.getPosition() : this.getAimPos(), this.getRadius()*2 );

	        this.ClearButtons();
	    }	  
	}

	//// click action1 to click buttons
	//if (hud.hasButtons() && this.isKeyPressed(key_action1) && !this.ClickClosestInteractButton( this.getAimPos(), 2.0f ))
	//{
	//}

	// click grid menus

    if (hud.hasButtons())
    {
        if (this.isKeyJustPressed(key_action1))
        {
		    CGridMenu @gmenu;
		    CGridButton @gbutton;
		    this.ClickGridMenu(0, gmenu, gbutton); 
	    }
	}

	//tools menu
	if ( toolsKey && !this.isAttached() )
	{
		if ( !hud.hasButtons() )
		{	
			this.set_bool( "build menu open", false );
		
			CBitStream params;
			params.write_u16( this.getNetworkID() );
			
			Sound::Play( "buttonclick.ogg" );
			BuildToolsMenu( this, "Tools Menu", Vec2f(0,0) );
			
		} else if ( hud.hasMenus() )
		{
			this.ClearMenus();
			Sound::Play( "buttonclick.ogg" );
		}
	}
}


void Punch( CBlob@ this )
{
	Vec2f pos = this.getPosition();
	Vec2f aimVector = Vec2f(1,0).RotateBy(this.get_f32("dir_x"));
	
    HitInfo@[] hitInfos;
    if ( this.getMap().getHitInfosFromCircle( pos, this.getRadius()*4.0f, this, @hitInfos) )
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			CBlob @b = hitInfos[i].blob;
			if (b is null)
				continue;
			//dirty fix: get occupier if seat
			if( b.hasTag( "seat" ) )
			{
				AttachmentPoint@ seat = b.getAttachmentPoint(0);
				@b = seat.getOccupied();
			}
			if (b !is null && b.getName() == "human" && b.getTeamNum() != this.getTeamNum())
			{
				if (this.isMyPlayer())
				{
					CBitStream params;
					params.write_u16( b.getNetworkID() );
					this.SendCommand( this.getCommandID("punch"), params );
				}
				return;
			}
		}
	}

	// miss
	directionalSoundPlay( "throw", pos );
	this.set_u32("punch time", getGameTime());	
}

void ShootPistol( CBlob@ this )
{
	if ( !this.isMyPlayer() )
		return;

	Vec2f pos = this.getPosition();
	Vec2f aimVector = Vec2f(1,0).RotateBy(this.get_f32("dir_x"));
	const f32 aimdist = aimVector.Normalize();

	Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
	
	Vec2f vel = (aimVector * BULLET_SPEED) + offset;

	f32 lifetime = Maths::Min( 0.05f + BULLET_RANGE/BULLET_SPEED/32.0f, 1.35f);

	CBitStream params;
	params.write_Vec2f( vel );
	params.write_f32( lifetime );

	Island@ island = getIsland( this );
	if ( island !is null && island.centerBlock !is null )//relative positioning
	{
		params.write_bool( true );
		Vec2f rPos = ( pos + aimVector*3 ) - island.centerBlock.getPosition();
		params.write_Vec2f( rPos );
		u32 islandColor = island.centerBlock.getShape().getVars().customData;
		params.write_u32( islandColor );
	} else//absolute positioning
	{
		params.write_bool( false );
		Vec2f aPos = pos + aimVector*9;
		params.write_Vec2f( aPos );
	}
	
	this.SendCommand( this.getCommandID("shoot"), params );
}

void Construct( CBlob@ this )
{
	Vec2f pos = this.getPosition();
    Vec2f aimPos = this.get_Vec2f("aim_pos");    
    f32 aim_height = this.get_f32("aim_height");

	CBlob@ mBlob = getMap().getBlobAtPosition( aimPos );
	Vec2f aimVector = aimPos - pos;

	Vec2f offset(_shotspreadrandom.NextFloat() * BULLET_SPREAD,0);
	offset.RotateBy(_shotspreadrandom.NextFloat() * 360.0f, Vec2f());
	CSprite@ sprite = this.getSprite();
	
	string currentTool = this.get_string( "current tool" );

	if (mBlob !is null && aimVector.getLength() <= CONSTRUCT_RANGE)
	{
		if ( this.isMyPlayer() )
		{
			CBitStream params;
			params.write_Vec2f( pos );
			params.write_Vec2f( aimPos );
			params.write_netid( mBlob.getNetworkID() );
			
			this.SendCommand( this.getCommandID("construct"), params );
		}
		if ( sprite.getEmitSoundPaused() == true )
		{
			sprite.SetEmitSoundPaused(false);
		}	
	}
	else
	{
		if ( sprite.getEmitSoundPaused() == false )
		{
			sprite.SetEmitSoundPaused(true);
		}
	}
}

bool canPunch( CBlob@ this )
{
	return !this.hasTag( "dead" ) && this.get_u32("punch time") + PUNCH_RATE < getGameTime();
}

bool canShootPistol( CBlob@ this )
{
	return !this.hasTag( "dead" ) && this.get_string( "current tool" ) == "pistol" && this.get_u32("fire time") + FIRE_RATE < getGameTime();
}

bool canConstruct( CBlob@ this )
{
	return !this.hasTag( "dead" ) && (this.get_string( "current tool" ) == "deconstructor" || this.get_string( "current tool" ) == "reconstructor")
				&& this.get_u32("fire time") + CONSTRUCT_RATE < getGameTime();
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID(camera_sync_cmd))
	{
		HandleCamera(this, params, !canSend(this));
	}

	if (getNet().isServer() && this.getCommandID("get out") == cmd){
		this.server_DetachFromAll();
	}
	else if (this.getCommandID("punch") == cmd  && canPunch( this ) )
	{
		CBlob@ b = getBlobByNetworkID( params.read_u16() );
		if (b !is null && b.getName() == "human" && b.getDistanceTo( this ) < 100.0f)
		{
			Vec2f pos = b.getPosition();
			this.set_u32("punch time", getGameTime());
			directionalSoundPlay( "Kick.ogg", pos );
			ParticleBloodSplat( pos, false );

			if ( getNet().isServer() )
				this.server_Hit( b, pos, Vec2f_zero, 0.25f, 0, false );
		}
	}
	else if (this.getCommandID("shoot") == cmd && canShootPistol( this ) )
	{
		Vec2f velocity = params.read_Vec2f();
		f32 lifetime = params.read_f32();
		Vec2f pos;
		
		if ( params.read_bool() )//relative positioning
		{
			Vec2f rPos = params.read_Vec2f();
			int islandColor = params.read_u32();
			Island@ island = getIsland( islandColor );
			if ( island !is null && island.centerBlock !is null )
			{
				pos = rPos + island.centerBlock.getPosition();
				velocity += island.vel;
			}
			else
			{
				warn( "BulletSpawn: island or centerBlock is null" );
				Vec2f pos = this.getPosition();//failsafe (bullet will spawn lagging behind player)
			}
		}
		else
			pos = params.read_Vec2f();
		
		if (getNet().isServer())
		{
            CBlob@ bullet = server_CreateBlob( "bullet", this.getTeamNum(), pos );
            if (bullet !is null)
            {
            	if (this.getPlayer() !is null){
                	bullet.SetDamageOwnerPlayer( this.getPlayer() );
                } 

                bullet.setVelocity( velocity );
                bullet.server_SetTimeToDie( lifetime );
            }
    	}
		
		this.set_u32("fire time", getGameTime());	
		shotParticles(pos + Vec2f(1,0).RotateBy(-velocity.Angle())*6.0f, velocity.Angle());
		directionalSoundPlay( "Gunshot.ogg", pos, 0.75f );
	}
	else if (this.getCommandID("construct") == cmd && canConstruct( this ) )
	{
		Vec2f pos = params.read_Vec2f();
		Vec2f aimPos = params.read_Vec2f();
		CBlob@ mBlob = getBlobByNetworkID( params.read_netid() );
		
		CPlayer@ thisPlayer = this.getPlayer();						
		if ( thisPlayer is null ) 
			return;		
		
		string currentTool = this.get_string( "current tool" );
		Vec2f aimVector = aimPos - pos;	 
		
		if (mBlob !is null)
		{		
			CRules@ rules = getRules();
			const int blockType = mBlob.getSprite().getFrame();
			Island@ island = getIsland( mBlob.getShape().getVars().customData );
				
			const f32 mBlobCost = mBlob.get_u32("cost");
			f32 mBlobHealth = mBlob.getHealth();
			f32 mBlobInitHealth = mBlob.getInitialHealth();
			const f32 initialReclaim = mBlob.get_f32("initial reclaim");
			f32 currentReclaim = mBlob.get_f32("current reclaim");
			
			f32 fullConstructAmount;
			if ( mBlobCost > 0 )
				fullConstructAmount = (CONSTRUCT_VALUE/mBlobCost)*initialReclaim;
			else if ( blockType == Block::SHIPCORE )
				fullConstructAmount = (0.01f)*mBlobInitHealth;
			else
				fullConstructAmount = 0.0f;
							
			if ( island !is null)
			{
				string islandOwnerName = island.owner;
				CBlob@ mBlobOwnerBlob = getBlobByNetworkID(mBlob.get_u16( "ownerID" ));
				
				if ( currentTool == "deconstructor" && !(blockType == Block::SHIPCORE) && mBlobCost > 0 )
				{
					f32 deconstructAmount = 0;
					if ( islandOwnerName == "" 
						|| (islandOwnerName == "" && mBlob.get_string( "playerOwner" ) == "")
						|| islandOwnerName == thisPlayer.getUsername() 
						|| mBlob.get_string( "playerOwner" ) == thisPlayer.getUsername()
						|| blockType == Block::STATION)
					{
						deconstructAmount = fullConstructAmount; 
					}
					else
					{
						deconstructAmount = (1.0f/mBlobCost)*initialReclaim; 
						this.set_bool( "reclaimPropertyWarn", true );
					}
					
					if ( blockType != Block::STATION && island.isStation && mBlob.getTeamNum() != this.getTeamNum() )
					{
						deconstructAmount = (1.0f/mBlobCost)*initialReclaim; 
						this.set_bool( "reclaimPropertyWarn", true );					
					}
					
					if ( (currentReclaim - deconstructAmount) <=0 )
					{		
						if ( blockType == Block::STATION )
						{
							if ( mBlob.getTeamNum() != this.getTeamNum() && mBlob.getTeamNum() != 255 )
							{
								mBlob.server_setTeamNum( 255 );
								mBlob.getSprite().SetFrame( Block::STATION );
							}
						}
						else
						{
							string cName = thisPlayer.getUsername();
							u16 cBooty = server_getPlayerBooty( cName );

							server_setPlayerBooty( cName, cBooty + mBlobCost*(mBlobHealth/mBlobInitHealth) );
							directionalSoundPlay( "/ChaChing.ogg", pos );
							mBlob.Tag( "disabled" );
							mBlob.server_Die();
						}
					}
					else
						mBlob.set_f32("current reclaim", currentReclaim - deconstructAmount);
				}
				else if ( currentTool == "reconstructor" )
				{			
					f32 reconstructAmount = 0;
					u16 reconstructCost = 0;
					string cName = thisPlayer.getUsername();
					u16 cBooty = server_getPlayerBooty( cName );
					
					if ( blockType == Block::SHIPCORE )
					{
						const f32 motherInitHealth = 8.0f;
						if ( (mBlobHealth + reconstructAmount) <= motherInitHealth  )
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ( (mBlobHealth + reconstructAmount) > motherInitHealth  )
						{
							reconstructAmount = motherInitHealth - mBlobHealth;
							reconstructCost = (CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount));
						}
						
						if ( cBooty >= reconstructCost && mBlobHealth < motherInitHealth )
						{
							mBlob.server_SetHealth( mBlobHealth + reconstructAmount );
							server_setPlayerBooty( cName, cBooty - reconstructCost );
						}
					}
					else if ( blockType == Block::STATION )
					{							
						if ( (currentReclaim + reconstructAmount) <= initialReclaim )
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ( (currentReclaim + reconstructAmount) > initialReclaim  )
						{
							reconstructAmount = initialReclaim - currentReclaim;
							reconstructCost = CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount);
							
							if ( mBlob.getTeamNum() == 255 ) //neutral
							{
								mBlob.server_setTeamNum( this.getTeamNum() );
								mBlob.getSprite().SetFrame( Block::STATION );
							}
						}
						
						mBlob.set_f32("current reclaim", currentReclaim + reconstructAmount);
					}
					else if ( currentReclaim < initialReclaim )
					{					
						if ( (currentReclaim + reconstructAmount) <= initialReclaim )
						{
							reconstructAmount = fullConstructAmount;
							reconstructCost = CONSTRUCT_VALUE;
						}
						else if ( (currentReclaim + reconstructAmount) > initialReclaim  )
						{
							reconstructAmount = initialReclaim - currentReclaim;
							reconstructCost = CONSTRUCT_VALUE - CONSTRUCT_VALUE*(reconstructAmount/fullConstructAmount);
						}
						
						if ( (currentReclaim + reconstructAmount > mBlobHealth) && cBooty >= reconstructCost)
						{
							mBlob.server_SetHealth( mBlobHealth + reconstructAmount );
							mBlob.set_f32("current reclaim", currentReclaim + reconstructAmount);
							server_setPlayerBooty( cName, cBooty - reconstructCost );
						}
						else if ( (currentReclaim + reconstructAmount) < mBlobHealth )
							mBlob.set_f32("current reclaim", currentReclaim + reconstructAmount);
					}
					
					if ( currentReclaim >= initialReclaim*0.75f )	//visually repair block
					{
						CSprite@ mBlobSprite = mBlob.getSprite();
						for (uint frame = 0; frame < 11; ++frame)
						{
							mBlobSprite.RemoveSpriteLayer("dmg"+frame);
						}
					}
				}
			}
		}
		
		this.set_u32("fire time", getGameTime());
	}
	else if ( getNet().isServer() && this.getCommandID( "releaseOwnership" ) == cmd )
	{
		CPlayer@ player = this.getPlayer();
		CBlob@ seat = getBlobByNetworkID( params.read_u16() );
		
		if ( player is null || seat is null ) return;
	
		string owner;
		seat.get( "playerOwner", owner );
		if ( owner == player.getUsername() )
		{
			print( "$ " + owner + " released seat" );
			owner = "";
			seat.set( "playerOwner", owner );
			seat.set_string( "playerOwner", "" );
			seat.Sync( "playerOwner", true );
		}
	}
	else if ( getNet().isServer() && this.getCommandID( "giveBooty" ) == cmd )//transfer booty
	{
		CRules@ rules = getRules();
		if ( getGameTime() < rules.get_u16( "warmup_time" ) )	return;
			
		u8 teamNum = this.getTeamNum();
		CPlayer@ player = this.getPlayer();
		string cName = getCaptainName( teamNum );		
		CPlayer@ captain = getPlayerByUsername( cName );
		
		if ( captain is null || player is null ) return;
		
		u16 transfer = rules.get_u16( "booty_transfer" );
		u16 fee = Maths::Round( transfer * rules.get_f32( "booty_transfer_fee" ) );		
		string pName = player.getUsername();
		u16 playerBooty = server_getPlayerBooty( pName );
		if ( playerBooty < transfer + fee )	return;
			
		if ( player !is captain )
		{
			print( "$ " + pName + " transfers Booty to captain " + cName );
			u16 captainBooty = server_getPlayerBooty( cName );
			server_setPlayerBooty( pName, playerBooty - transfer - fee );
			server_setPlayerBooty( cName, captainBooty + transfer );
		} else
		{
			CBlob@ core = getMothership( teamNum );
			if ( core !is null )
			{
				int coreColor = core.getShape().getVars().customData;
				CBlob@[] crew;
				CBlob@[] humans;
				getBlobsByName( "human", @humans );
				for ( u8 i = 0; i < humans.length; i++ )
					if ( humans[i].getTeamNum() == teamNum && humans[i] !is this )
					{
						CBlob@ islandBlob = getIslandBlob( humans[i] );
						if ( islandBlob !is null && islandBlob.getShape().getVars().customData == coreColor )
							crew.push_back( humans[i] );
					}
				
				if ( crew.length > 0 )
				{
					print( "$ " + pName + " transfers Booty to crew" );
					server_setPlayerBooty( pName, playerBooty - transfer - fee );
					u16 shareBooty = Maths::Floor( transfer/crew.length );
					for ( u8 i = 0; i < crew.length; i++ )
					{
						CPlayer@ crewPlayer = crew[i].getPlayer();						
						if ( player is null ) continue;
						
						string cName = crewPlayer.getUsername();
						u16 cBooty = server_getPlayerBooty( cName );

						server_setPlayerBooty( cName, cBooty + shareBooty );
					}
				}
			}
		}
	}
	else if ( this.getCommandID( "swap tool" ) == cmd )
	{
		u16 netID = params.read_u16();
		string tool = params.read_string();
		CPlayer@ player = this.getPlayer();
		
		if ( player is null ) return;

		if (tool == "fists")
		{
			this.getSprite().SetEmitSound("/ReclaimSound.ogg");
			this.getSprite().SetEmitSoundVolume(0.5f);
			this.getSprite().SetEmitSoundPaused(true);
		}		
		if (tool == "pistol")
		{
			this.getSprite().SetEmitSound("/ReclaimSound.ogg");
			this.getSprite().SetEmitSoundVolume(0.5f);
			this.getSprite().SetEmitSoundPaused(true);
		}
		if (tool == "constructor")
		{
			this.getSprite().SetEmitSound("/ReclaimSound.ogg");
			this.getSprite().SetEmitSoundVolume(0.5f);
			this.getSprite().SetEmitSoundPaused(true);
		}

		if (tool == "telescope")
		{
			this.getSprite().SetAnimation("scopeout");
			this.getSprite().SetFrameIndex(2);
			//this.getSprite().animation.frame = 0;
		}
		
		this.set_string("current tool", tool);
	}
}

void onAttached( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	this.ClearMenus();
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint )
{
	this.set_u16( "shipID", detached.getNetworkID() );
	this.set_s8( "stay count", 3 );
}

void onDie( CBlob@ this )
{
	CSprite@ sprite = this.getSprite();
	Vec2f pos = this.getPosition();
	
	ParticleBloodSplat( pos, true );
	directionalSoundPlay( "BodyGibFall", pos );
	
	if (!sprite.getVars().gibbed) 
	{
		directionalSoundPlay( "SR_ManDeath" + ( XORRandom(4) + 1 ), pos, 0.75f );
		sprite.Gib();
	}
	
	//return held blocks
	CRules@ rules = getRules();
	CBlob@[]@ blocks;
	if (this.get( "blocks", @blocks ) && blocks.size() > 0)                 
	{
		if ( getNet().isServer() )
		{
			CPlayer@ player = this.getPlayer();
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
		Human::clearHeldBlocks( this );
		this.set_bool( "blockPlacementWarn", false );
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	//when killed: reward hitterBlob if this was boarding his mothership
	if ( hitterBlob.getName() == "human" && hitterBlob !is this && this.getHealth() - damage <= 0 )
	{
		Island@ pIsle = getIsland( this );
		CPlayer@ hitterPlayer = hitterBlob.getPlayer();
		u8 teamNum = hitterBlob.getTeamNum();
		if ( hitterPlayer !is null && pIsle !is null && pIsle.isMothership && pIsle.centerBlock !is null && pIsle.centerBlock.getTeamNum() == teamNum )
		{
			if ( hitterPlayer.isMyPlayer() )
				Sound::Play( "snes_coin.ogg" );

			if ( getNet().isServer() )
			{
				string attackerName = hitterPlayer.getUsername();
				u16 reward = 50;
				if ( getRules().get_bool( "whirlpool" ) ) reward *= 3;
				
				server_setPlayerBooty( attackerName, server_getPlayerBooty( attackerName ) + reward );
				server_updateTotalBooty( teamNum, reward );
			}
		}
	}
	
	if ( this.getTickSinceCreated() > 60 )
		return damage;
	else
		return 0.0f;
}

void onHealthChange( CBlob@ this, f32 oldHealth )
{
	if ( this.getHealth() > oldHealth )
		directionalSoundPlay( "Heal.ogg", this.getPosition(), 2.0f );
}

Random _shotrandom(0x15125); //clientside
void shotParticles(Vec2f pos, float angle)
{
	//muzzle flash
	{
		CParticle@ p = ParticleAnimated( "Entities/Block/turret_muzzle_flash.png",
												  pos, Vec2f(),
												  -angle, //angle
												  1.0f, //scale
												  3, //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 540.0f;
	}

	Vec2f shot_vel = Vec2f(0.5f,0);
	shot_vel.RotateBy(-angle);

	//smoke
	for(int i = 0; i < 5; i++)
	{
		//random velocity direction
		Vec2f vel(0.03f + _shotrandom.NextFloat()*0.03f, 0);
		vel.RotateBy(_shotrandom.NextFloat() * 360.0f);
		vel += shot_vel * i;

		CParticle@ p = ParticleAnimated( "Entities/Block/turret_smoke.png",
												  pos, vel,
												  _shotrandom.NextFloat() * 360.0f, //angle
												  0.6f, //scale
												  3+_shotrandom.NextRanged(4), //animtime
												  0.0f, //gravity
												  true ); //selflit
		if(p !is null)
			p.Z = 550.0f;
	}
}

