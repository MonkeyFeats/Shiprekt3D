#include "Blob3D.as"
#include "SAT_Shapes.as";
//#include "BoundingShapes.as";

Random rnd(941527533);

void onInit( CBlob@ this )
{
	SAT_Shape shape(this, 5.0f, Vec3f(this.getPosition().x, 0, this.getPosition().y), true, 5.1f, true, -1);
	this.set("SAT_Info", @shape);

    this.set_u8("ID", 55);
	this.Tag("prop");
	this.setAngleDegrees(rnd.NextRanged(360));
    this.getShape().SetStatic(true);
	this.getSprite().SetZ(550.0f);

	//if (getNet().isServer())
	{
		Blob3D blob3d(this, Vec3f(this.getPosition().x, 0, this.getPosition().y), 6, 2.0f);
		if ( blob3d !is null )
		{	
			@blob3d.shape = BoundingBox( Vec3f(-16.0, -16.0, -16.0), Vec3f(16.0, 16.0, 16.0));
			//blob3d.shape.ownerBlob = blob3d;
			blob3d.shape.SetStatic(true);
			blob3d.shape.setPosition(Vec3f(this.getPosition().x, 0, this.getPosition().y));

			this.set("blob3d", @blob3d);
			//blob3d.shape.ownerBlob = @blob3d;
		}
	}	
}

float angle;
void onTick(CBlob@ this)
{
	Blob3D@ blob3d;
	if (!this.get("blob3d", @blob3d)) { return; }

	angle+=0.5;
	if (angle > 360)
	angle = 0;
	blob3d.shape.setDirection(Vec3f(angle, angle, angle));
	//blob3d.onTick();
	//this.setPosition(blob3d.getPosition().xz());
}
//void onTick(CBlob@ this)
//{
//	SAT_Shape@ sat_shape;
//	if (!this.get("SAT_Info", @sat_shape))
//	return;
//	
//	sat_shape.Update(this.getPosition()+this.getVelocity());
//	this.setPosition(sat_shape.Pos.xy());
//}

void onRender(CSprite@ this)
{
	SAT_Shape@ sat_shape;
	if (this.getBlob().get("SAT_Info", @sat_shape))
 	sat_shape.Render();	
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	damage = 0.0f;
	return damage;
}

