
#define CLIENT_ONLY

float alpha = 0;

u16[] IDs = {0, 1, 2, 0, 2, 3};

void onInit(CBlob@ this)
{
	Render::addScript(Render::layer_prehud, "RedFlash.as", "flash", 10.0f);
	Render::SetTransformScreenspace();
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (this.isMyPlayer())
    {
        SetScreenFlash( 0, 255, 255, 255 );
		alpha += 160;
    }
    return damage;
}

void flash(int id)
{
	if(alpha > 0.3)
	{
		Vertex[] Vertices = {
			Vertex(0,0,0,0,0,SColor(Maths::Clamp(alpha, 0, 255), 255, 255, 255)),
			Vertex(getScreenWidth(),0,0,1,0,SColor(Maths::Clamp(alpha, 0, 255), 255, 255, 255)),
			Vertex(getScreenWidth(),getScreenHeight(),0,1,1,SColor(Maths::Clamp(alpha, 0, 255), 255, 255, 255)),
			Vertex(0,getScreenHeight(),0,0,1,SColor(Maths::Clamp(alpha, 0, 255), 255, 255, 255))
		};
		Render::SetTransformScreenspace();
		Render::RawTrianglesIndexed("hit.png", Vertices, IDs);
		Render::SetTransformScreenspace();
		alpha -= getRenderApproximateCorrectionFactor()*3;
	}
	else if (alpha != 0)
	{
		alpha = 0;
	}
}