// Shiprekt3D Movement

//#include "HumanCommon.as"
#include "HumanMovementCommon.as"
#include "FallDamageCommon.as"
#include "IslandsCommon.as"
//#include "BlockCommon.as"
#include "SAT_Shapes.as"
#include "World.as"

void onInit(CMovement@ this)
{
	//Movement Vars
	{
		HumanMoveVars moveVars;
		//walking vars
		moveVars.walkSpeed = 8.6f;
		moveVars.walkSpeedInAir = 0.4f;
		//jumping vars
		moveVars.jumpVel = 300.0f;
		moveVars.jumpState = 0;
		moveVars.canJump = false;
		//swimming
		moveVars.swimspeed = 0.2;
		//stopping forces
		moveVars.stoppingForce = 0.80f; //function of mass
		moveVars.stoppingForceAir = 0.30f; //function of mass
		
		this.getBlob().set("moveVars", moveVars);
		this.getBlob().getShape().getVars().waterDragScale = 30.0f;
		this.getBlob().getShape().getConsts().collideWhenAttached = false;
	}

	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	Blob3D@ blob3d; if (!blob.get("blob3d", @blob3d)) { return; }	
	BoundingShape@ shape = blob3d.shape; if (shape is null) { return; }
	World@ world; if (!getMap().get("terrainInfo", @world)) { return; }
	HumanMoveVars@ moveVars; if (!blob.get("moveVars", @moveVars)) { return; }

	if (blob.getTickSinceCreated() < 10) return;		

	const bool left		= blob.isKeyPressed(key_left);
	const bool right	= blob.isKeyPressed(key_right);
	const bool up		= blob.isKeyPressed(key_up);
	const bool down		= blob.isKeyPressed(key_down);
	const bool spacebar	= blob.isKeyJustPressed(key_action3);
	const bool shift	= getControls().isKeyPressed( KEY_LSHIFT );
	const bool is_client = getNet().isClient();
	const float time = getGameTime();

	CMap@ map = blob.getMap();
	Vec3f Vel = blob3d.Velocity;
	Vec3f Pos = blob3d.getPosition();

    CControls@ c = getControls();
    Driver@ d = getDriver();

	Vec3f moveForce;

    if( isWindowActive() && isWindowFocused() && Menu::getMainMenu() is null && !block_menu  && !getHUD().hasButtons() && !blob.get_bool( "build menu open" ))
    {
        Vec2f ScrMid = d.getScreenCenterPos();//Vec2f(float(getScreenWidth()) / 2.0f, float(getScreenHeight()) / 2.0f);
        Vec2f dir = (c.getMouseScreenPos() - ScrMid);
        
        blob3d.transform.Orientation.x += dir.x*0.15;
        if(blob3d.transform.Orientation.x < 0) blob3d.transform.Orientation.x += 360;
        blob3d.transform.Orientation.x = blob3d.transform.Orientation.x % 360;
        blob3d.transform.Orientation.y = Maths::Clamp(blob3d.transform.Orientation.y-(dir.y*0.15),-90,90);
        
        Vec2f asuREEEEEE = /*Vec2f(3,26);*/Vec2f(0,0);
       // c.setMousePosition(ScrMid-asuREEEEEE);

		//if (onship)
		//{
		//	moveForce.y += 1.6; //swim up
		//}	
		//else if (inwater)
		//{
		//	if (spacebar && !onwater)
		//	{
		//		moveForce.y += 1.6; //swim up
		//	}
		//	else if (shift)
		//	{
		//		moveForce.y -= 1.6f; //swim down
		//	}
		//	else
		//	{
		//		moveForce.y += 0.2; //float up
		//	}
//
		//	bool BoatAbove = (Pos.y > -20.0 && Pos.y < -18.0);
		//	if (BoatAbove)
		//	{
		//		moveForce.y = Maths::Min(Vel.y, 0); //stop going up
		//	}
		//}

		//else 
		//if (inAir) // falling
		{
			//if (TerrainHeight < -2.0f) //water plane below
			//{
			//	moveForce.y -= Maths::Max(Maths::Abs(Pos.y - -2.0f), 0.2f);
			//}
			//else if (moveForce.y < 0)
			//{
			//	moveForce.y -= Maths::Max(Maths::Abs(Pos.y - TerrainHeight), 0.2f);
			//}
			//else 
			//moveForce.y -= 0.981f*2;
		}

		// move		
		if (up)		  moveForce.z = -moveVars.walkSpeed; 
		if (down)	  moveForce.z =  moveVars.walkSpeed; 		
		if (left)	  moveForce.x = -moveVars.walkSpeed; 
		if (right)	  moveForce.x =  moveVars.walkSpeed; 
		//if (shift)	  moveForce.y = -moveVars.walkSpeed;

		//	//if ( blob.wasOnGround() && time - blob.get_u32( "lastSplash" ) > 45 )
		//	//{
		//	//	//directionalSoundPlay( "SplashFast", pos );
		//	//	blob.set_u32( "lastSplash", time );
		//	//}
		//}
		
		//jumping
		if (shape.onGround)
		{			
		    if (spacebar) 
		    {
		    	moveForce.y += moveVars.jumpVel;

				if (is_client)
				{	
					blob.getSprite().PlayRandomSound("/EarthJump");
				}
			}
			else if (moveForce.length() > 0.3f)
			{
				if (is_client)
				{	
					if (time % (10) == 0)
					{						
						//if (onshoal)
						//{
						//	blob.getSprite().PlayRandomSound("/wetfall", 0.6f, 0.85f );
						//}
						//else
						{
							blob.getSprite().PlayRandomSound("/EarthStep", 0.6f, 0.75f );
						} 
					}
				}
			}
		}
		else if (is_client && shape.inWater)
		{
			//if (spacebar)
			//{
			//	moveForce.y += 0.8;
			//}
			blob.getSprite().SetEmitSound("/WaterRunning.ogg");
			blob.getSprite().SetEmitSoundSpeed(0.1f);
			blob.getSprite().SetEmitSoundVolume(0.4f);
			blob.getSprite().SetEmitSoundPaused(false);
//
			if (time % 45 == 0)
			{
				blob.getSprite().PlayRandomSound("/WaterBubble", 0.6f, 0.85f );
			}
//
			if (time % 160 == 0)
			{
				blob.getSprite().PlayRandomSound("/Gurgle", 0.8f, 0.85f );
			}
		}
		//else if (shape.hitWater)
		//{			
		//	blob.getSprite().PlayRandomSound("/SplashSlow");
		//}
		else
		{
			blob.getSprite().SetEmitSoundPaused(true);
		}
	}

	//canmove check
	//if ( !getRules().get_bool( "whirlpool" ))
	{
		moveForce.rotateXZ(blob3d.transform.Orientation.x);
		//shape.setAngleDegreesXZ(blob3d.look_dir.x );
		shape.addForce(moveForce);
	}

}


