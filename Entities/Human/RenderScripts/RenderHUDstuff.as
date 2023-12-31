
class Telescope
{
	Vertex[] v_raw;
	u16[] v_i;
	
	Telescope(){}
	
	Telescope()
	{
		Vec2f ScS = Vec2f(getDriver().getScreenWidth(), getDriver().getScreenHeight());

		Vertex[] _v_raw = {
			Vertex(0,0,0,0,0,									SColor(255, 0, 0, 0)),
			Vertex(getScreenWidth(),0,0,1,0,					SColor(255, 0, 0, 0)),
			Vertex(getScreenWidth(),getScreenHeight(),0,1,1,	SColor(255, 0, 0, 0)),
			Vertex(0,getScreenHeight(),0,0,1,					SColor(255, 0, 0, 0))
		};
		Render::SetTransformScreenspace();

		u16[] _v_i = {
			0,1,2,
			0,2,3
		};

		this.v_raw = _v_raw;
		this.v_i = _v_i;
	}	

    void DrawScope()
    {    	
        Render::RawTrianglesIndexed("LookingGlass.png", this.v_raw, this.v_i);
    }
};

class Compass
{
	Vertex[] v_raw;
	u16[] v_i;
	
	Compass(){}
	
	Compass()
	{
		float hSw = getDriver().getScreenWidth()/2;
		float hSh = getDriver().getScreenHeight()/2;

		Vertex[] _v_raw = {
			Vertex( hSw-(hSw/2), 16,  0,   0.0,  0.0, SColor(10,255,255,255)),
			Vertex( hSw-(hSw/2), 64,  0,   0.0,  1.0, SColor(10,255,255,255)),
			Vertex( hSw    , 16,  0,   0.5,  0.0, color_white),
			Vertex( hSw    , 64,  0,   0.5,  1.0, color_white),
			Vertex( hSw+(hSw/2), 16,  0,   1.0,  0.0, SColor(10,255,255,255)),
			Vertex( hSw+(hSw/2), 64,  0,   1.0,  1.0, SColor(10,255,255,255))
		};
		Render::SetTransformScreenspace();

		u16[] _v_i = {
			0,1,2,
			1,2,3,
			2,3,4,
			3,4,5
		};

		this.v_raw = _v_raw;
		this.v_i = _v_i;
	}	

	void SetAngle(f32 angle)
	{
		v_raw[0].u = angle;
		v_raw[1].u = angle;
		v_raw[2].u = angle+0.5f;
		v_raw[3].u = angle+0.5f;
		v_raw[4].u = angle+1.0f;
		v_raw[5].u = angle+1.0f;
	}

    void RenderCompass()
    {    	
        Render::RawTrianglesIndexed("Compass_3D.png", this.v_raw, this.v_i);
    }
};

class Tool
{
	Vertex[] cursor_raw;
	Vertex[] v_raw;
	u16[] v_i;
	
	Tool(){}
	
	Tool()
	{
		Vec2f ScS = Vec2f(getDriver().getScreenWidth(), getDriver().getScreenHeight());

		Vertex[] _cursor_raw = 
		{
			Vertex( (ScS.x/2)-52,  (ScS.y/2)+52,   0,   0.0,  0.75, color_white),
			Vertex( (ScS.x/2)+52,  (ScS.y/2)+52,   0,   1.0,  0.75, color_white),
			Vertex( (ScS.x/2)+52,  (ScS.y/2)-52,   0,   1.0,  1.0, color_white),
			Vertex( (ScS.x/2)-52,  (ScS.y/2)-52,   0,   0.0,  1.0, color_white)
		};
		Vertex[] _v_raw = 
		{
			Vertex((ScS.x/1.35-(ScS.y-ScS.y/2)/2+(ScS.y-ScS.y/2)/128), ScS.y/2, 0,  0, 		  0),
			Vertex((ScS.x/1.35+(ScS.y-ScS.y/2)/2+(ScS.y-ScS.y/2)/128), ScS.y/2, 0,  1.000f/3, 0),
			Vertex((ScS.x/1.35+(ScS.y-ScS.y/2)/2+(ScS.y-ScS.y/2)/128), ScS.y,   0,  1.000f/3, 1.000f/5),
			Vertex((ScS.x/1.35-(ScS.y-ScS.y/2)/2+(ScS.y-ScS.y/2)/128), ScS.y,   0,  0, 		  1.000f/5)
		};
		u16[] _v_i = {
			0,1,2,
			0,2,3
		};

		this.cursor_raw = _cursor_raw;
		this.v_raw = _v_raw;
		this.v_i = _v_i;
	}	

    void DrawTool(int team, bool drawcursor)
    {    	
        Render::RawTrianglesIndexed("Tools.png", this.v_raw, this.v_i);

        if (drawcursor) 
        Render::RawTrianglesIndexed("Cursors.png", this.cursor_raw, this.v_i); 
    }
	
	void SetFrame(int _index)
	{
		v_raw[0].u = v_raw[3].u = 1.000f/3*_index;
		v_raw[1].u = v_raw[2].u = 1.000f/3*_index+1.000f/3;
	}

	void SetType(int _row)
	{
		v_raw[0].v = v_raw[1].v = 1.000f/5*_row;
		v_raw[2].v = v_raw[3].v = 1.000f/5*_row+1.000f/5;
	}
};


/*
int index = 0;
int row = 0;

void onTick(CBlob@ this)
{
	if(!this.isMyPlayer()) return;

	compass.SetAngle(this.get_f32("dir_x")/360);

	if (this.getSprite().isAnimation("shoot") || this.getSprite().isAnimation("punch") || 
		this.getSprite().isAnimation("reclaim") || this.getSprite().isAnimation("repair") || 
		this.getSprite().isAnimation("scopein") || this.getSprite().isAnimation("scopeout"))
	{
		tool.SetFrame(this.getSprite().getFrame() - 22);
	}

	string currentTool = this.get_string( "current tool" );

	if (currentTool == "pistol")
	{
    	tool.SetType(0);
	}
	else if (currentTool == "fists")
	{
    	tool.SetType(1);
	}
	else if (currentTool == "reconstructor")
	{
    	tool.SetType(2);
	}	
	else if (currentTool == "deconstructor")
	{
    	tool.SetType(3);
	}
	else if (currentTool == "telescope")
	{
    	tool.SetType(4);

    	if ((this.getSprite().getFrame() - 22) > 0)  
    	{
    		f32 FOV = this.get_f32("FOV");
    		if (FOV > 3.0)
    		{
    			FOV -= 2.5f;
    		}
    		this.set_f32("FOV", FOV);		    		
    	} 
		else
		{
			f32 FOV = this.get_f32("FOV");
    		if (FOV < 10.5)
    		{
    			FOV += 2.5f;
    		}
    		this.set_f32("FOV", FOV);
		}
	}
}