#include "WaterEffects.as"
#include "Booty.as"
#include "AccurateSoundPlay.as"
#include "HumanCommon.as"

const f32 SHARK_SPEED = 0.75f;

void onInit( CBlob@ this )
{
	//find target to swim towards
	this.set_Vec2f("target", getTargetVel( this ) * 0.5f);
	
	this.set_bool("retreating", false);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-10.0f);
	sprite.ReloadSprites(0,0); //always blue
	sprite.SetAnimation("out");

	this.set_u8("ID", 57);
	this.Tag("prop");

	this.addCommandID(camera_sync_cmd);
	this.set_f32("dir_x", 0.0f);
	this.set_f32("dir_y", 0.0f);
	this.set_f32("eye height", -0.15f);
	this.set_f32("FOV", 12.0f);
	
	this.SetMapEdgeFlags( u8(CBlob::map_collide_up) |
	u8(CBlob::map_collide_down) |
	u8(CBlob::map_collide_sides) );
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID(camera_sync_cmd))
	{
		HandleCamera(this, params, !canSend(this));
	}
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void onTick( CBlob@ this )
{
	Vec2f pos = this.getPosition();	
	CMap@ map = getMap();
	Tile tile = map.getTile( pos );
	bool onLand = map.isTileBackgroundNonEmpty( tile ) || map.isTileSolid( tile );
	
	if ( onLand )
		this.set_bool("retreating", true);

	if (this.getPlayer() is null)
	{
		u32 ticktime = (getGameTime() + this.getNetworkID());

		if(ticktime % 5 == 0 && //check each 5 ticks
			this.hasTag("vanish") && //read tag
			getGameTime() > this.get_u32("vanishtime")) //compare time
		{
			this.Tag("no gib");
			this.server_Die();
			return;
		}
		if( ticktime % 40 == 0 )
		{
			this.set_Vec2f("target", getTargetVel( this ));
		}
		
		if ( !this.get_bool("retreating") )
			MoveTo( this, this.get_Vec2f("target") );
		else
		{
			MoveTo( this, -this.get_Vec2f("target") );
			this.Tag("vanish");
		}
	}
	else
	{		
		// player
		const f32 speed = SHARK_SPEED * 0.5f;
		Vec2f vel = Vec2f(0, -10);
		f32 blobAngle = this.getAngleDegrees();
		f32 aimAngle = this.get_f32("dir_x");

		//if (this.isKeyPressed(key_up)){
		//	vel.y -= speed;
		//}

		if (this.isKeyPressed(key_right))
		{
			blobAngle+=3.0;
		}
		else if (this.isKeyPressed(key_left))
		{
			blobAngle-=3.0;
		}

		vel *= SHARK_SPEED;
		vel.y = speed;
		vel.RotateBy( blobAngle-90 );
		this.setVelocity( vel );

		this.setAngleDegrees( blobAngle );	

		//Vec2f pos = this.getPosition();	
		// water effect
		//if( (getGameTime() + this.getNetworkID()) % 9 == 0){
		//	MakeWaterWave(pos, Vec2f_zero, -angle + (_anglerandom.NextRanged(100) > 50 ? 180 : 0)); 
		//}

		//MoveTo( this, vel );

		if (this.isMyPlayer())
		{
			ManageCamera(this);	

		    if (getHUD().hasButtons())
		    {
		        if (this.isKeyJustPressed(key_action1))
		        {
				    CGridMenu @gmenu;
				    CGridButton @gbutton;
				    this.ClickGridMenu(0, gmenu, gbutton); 
			    }
			}
		}
		this.getSprite().SetAnimation("default");
	}
	
}

void ManageCamera(CBlob@ this)
{
	//if(this.isMyPlayer() && getNet().isClient())
	//{
		CControls@ c = getControls();
		Driver@ d = getDriver();
		bool ctrl = c.isKeyJustPressed(KEY_LCONTROL);
		if(ctrl){ this.set_bool("stuck", !this.get_bool("stuck")); this.Sync("stuck", true);}
		if(!this.get_bool("stuck") && d !is null && c !is null && !c.isMenuOpened() && !getHUD().hasButtons() && !getHUD().hasMenus())
		{
			Vec2f ScrMid = Vec2f(f32(d.getScreenWidth()) / 2, f32(d.getScreenHeight()) / 2);
			Vec2f dir = (c.getMouseScreenPos() - ScrMid)/10;
			float dirX = this.get_f32("dir_x");
			float dirY = this.get_f32("dir_y");
			dirX += dir.x;
			dirY = Maths::Clamp(dirY-dir.y,-90,90);

			this.set_f32("dir_x", dirX);
			this.set_f32("dir_y", dirY);
			c.setMousePosition(ScrMid);

			//Vec2f dir2 =  Vec2f((1080.0f/((1+dirY)%360))+8.0f,0); // i cant do math dont judge
    		//Vec2f aimPos = this.getPosition() - dir2.RotateBy(dirX);	
    		//this.set_Vec2f("aim_pos", aimPos);
		}
		if(getGameTime() % 2 == 0)
		{
			SyncCamera(this);
		}
	//}
}

//sprite update
void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();

	if(this.isAnimation("out") && this.isAnimationEnded())
		this.SetAnimation("default");

	if( blob.hasTag("vanish"))
		this.SetAnimation("in");
}

Random _anglerandom(0x9090); //clientside

void MoveTo( CBlob@ this, Vec2f moveVel )
{	
	
}

Vec2f getTargetVel( CBlob@ this )
{
	CBlob@[] blobsInRadius;
	Vec2f pos = this.getPosition();
	Vec2f target = this.getVelocity();
	int humansInWater = 0;
	if (getMap().getBlobsInRadius( pos, 150.0f, @blobsInRadius ))
	{
		f32 maxDistance = 9999999.9f;
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (!b.isOnGround() && b.getName() == "human")
			{
				humansInWater++;
				f32 dist = (pos - b.getPosition()).getLength();
				if (dist < maxDistance)
				{
					target = b.getPosition() - pos;
					maxDistance = dist;
				}
			}
		}
	}

	if (humansInWater == 0)
	{
		this.Tag("vanish");
		this.set_u32("vanishtime", getGameTime() + 15);
	}

	target.Normalize();
	return target;
}

void onDie( CBlob@ this )
{
	MakeWaterParticle(this.getPosition(), Vec2f_zero); 
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
	if (blob is null) {
		return;
	}

	if ( blob.getName() == "human" && !blob.get_bool( "onGround" ) )
	{
		MakeWaterParticle(point1, Vec2f_zero); 
		directionalSoundPlay( "ZombieBite", point1 );		
		blob.server_Die();
		this.server_Die();
	}
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	this.Untag( "vanish" );
	if (player !is null && player.isMyPlayer()) // setup camera to follow
	{
		CCamera@ camera = getCamera();
		camera.setRotation(0);
		camera.mousecamstyle = 1; // follow
		camera.targetDistance = 1.0f; // zoom factor
		camera.posLag = 5; // lag/smoothen the movement of the camera
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 0, Vec2f(8,8));
		client_AddToChat( "You are a shark now." );
	}
}


f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if ( this.getHealth() - damage <= 0 && hitterBlob.getName() == "bullet" )
	{
		CPlayer@ owner = hitterBlob.getDamageOwnerPlayer();
		if ( owner !is null )
		{
			string pName = owner.getUsername();
			if ( owner.isMyPlayer() )
				directionalSoundPlay( "coinpick.ogg", worldPoint, 0.75f );

			if ( getNet().isServer() )
				server_setPlayerBooty( pName, server_getPlayerBooty( pName ) + 10 );
		}
	}
	
	return damage;
}