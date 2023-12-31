// damages stuff if they are left alone (no team member nearby and no base)

#include "DecayCommon.as";
#include "IslandsCommon.as"

#define SERVER_ONLY

const f32 SCREENSIZE = 300.0f;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 500; // opt
}

void onTick(CBlob@ this)
{
	if (dissalowDecaying(this))
		return;

	const u8 team = this.getTeamNum();
	CBlob@[] blobsInRadius;
	if (this.getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + SCREENSIZE, @blobsInRadius))
	{
		this.set_u32( "addedTime", getGameTime() );
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			Island@ isle = getIsland( this.getShape().getVars().customData );
			CBlob @b = blobsInRadius[i];
			if (getNet().isClient() && getGameTime() > this.get_u32( "addedTime" ) + 450 && b.hasTag( "player" ) || b.hasTag( "mothership" ) ||  b.hasTag( "station" ))
			{
				return;
			}
		}
	}

	if (DECAY_DEBUG)
		printf(this.getName() + " left alone ");
	SelfDamage(this);
}
