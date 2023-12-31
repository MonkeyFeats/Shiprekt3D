#include "Human.as"
#include "HumanCommon.as"
#include "RunnerTextures.as";
#include "TileCommon.as";

Random _punchr(0xfecc);

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	//ensureCorrectRunnerTexture(this, "human", "Player");
}

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();
	Blob3D@ blob3d; if (!blob.get("blob3d", @blob3d)) { return; }
	Vec2f pos = blob.getPosition();

	const bool solidGround = isTouchingLand( pos ) || isTouchingShoal( pos );
	const bool inWater = isInWater( pos );

	if (blob.isAttached())
	{
		this.SetAnimation("default");
	}
	else if(solidGround)
	{	
		//if (this.isAnimationEnded())
			//!(this.isAnimation("punch1") || this.isAnimation("punch2") || this.isAnimation("shoot")) )
		{
			if (blob.isKeyPressed( key_action2 ) && (blob.get_string( "current tool" ) == "pistol") && canShootPistol( blob ) && !blob.isKeyPressed( key_action1 ))
			{
				this.SetAnimation("shoot");
			}
			else if (blob.isKeyPressed( key_action2 ) && (blob.get_string( "current tool" ) == "deconstructor") && !blob.isKeyPressed( key_action1 ))
			{
				this.SetAnimation("reclaimloop");
				//this.animation.frame = 1;
			}
			else if (blob.isKeyPressed( key_action1 ) && (blob.get_string( "current tool" ) == "reconstructor") && !blob.isKeyPressed( key_action2 ))
			{
				//this.animation.frame = 1;
				this.SetAnimation("repairloop");
			}
			else if ((blob.get_string( "current tool" ) == "telescope") && blob.isKeyPressed( key_action2 ))
			{
				this.SetAnimation("scopein");
			}	
			else if ((blob.get_string( "current tool" ) == "telescope") && !blob.isKeyPressed( key_action2 ))
			{
				this.SetAnimation("scopeout");
			}		
			else if ( (blob.isKeyPressed( key_action1 ) || blob.isKeyPressed( key_action2 )) && (blob.get_string( "current tool" ) == "fists") )
			{
				this.SetAnimation("punch");
			}
			else if (blob.getVelocity().Length() > 0.1f) {
				this.SetAnimation("walk");
			}
			else {
				this.animation.frame = 0;
				this.SetAnimation("default");
			}
		}
	}
	else if (inWater)
	{
		//if (this.isAnimationEnded() ||
		//	!(this.isAnimation("shoot")) )
		{
			if (blob.getVelocity().Length() > 0.1f) {
				this.SetAnimation("swim");
			}
			else {
				this.SetAnimation("float");
			}
		}
	}

	this.SetZ( 540.0f );
}