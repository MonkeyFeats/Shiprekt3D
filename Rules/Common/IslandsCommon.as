#include "RenderConsts.as";
#include "Blob3D.as";

class IslandBlock
{
	u16 blobID;
	Vec2f offset;
	f32 angle_offset;

	Vertex[] block_Vertices;
	u16[] block_IDs;

	void setModel(CBlob@ block)
	{
		int id = block.get_u8("ID");
		Vertex[] Vertices;
		u16[] IDs;

		switch (id)
		{
			case 0:	// floor platform1
			{
				Vertices = Floor_Cube_Vertices; 
				IDs = Floor_Cube_IDs; 				
				break;
			}
			case 1:	// floor platform1
			{
				Vertices = Floor_Cube_Vertices; 
				IDs = Floor_Cube_IDs; 				
				break;
			}
			case 2:	// chair
			{
				Vertices = Chair_Vertices; 
				IDs = Chair_IDs; 
				break;
			}
			case 3:	// wood wall
			{					
				Vertices = Wall_Vertices; 
				IDs = Wall_IDs; 
				break;
			}	
			case 4:	// Coupling
			{
				Vertices = Floor_Vertices; 
				IDs = Square_IDs();			
				break;
			}
			case 5:	// ram hull
			{
				Vertices = Wall_Vertices; 
				IDs = Wall_IDs; 
				break;
			}	
			case 14:	// flak base
			{					
				Vertices = TurretBase_Vertices; 
				IDs = TurretBase_IDs; 
				break;
			}
			case 6:	// Door
			{
				Vertices = Wall_Vertices; 
				IDs = Wall_IDs; 
				break;
			}
			case 8:	// engine
			{
				Vertices = Propeller_Vertices; 
				IDs = Propeller_IDs; 
				break;
			}
			case 9:	// ram engine
			{
				Vertices = Propeller_Vertices; 
				IDs = Propeller_IDs; 
				break;
			}
			case 22:	// station
			{				
				Vertices = Station_Vertices; 
				IDs = Station_IDs; 
				break;
			}
			case 23:	// ship core frame
			{
				Vertices = ShipCore_Vertices; 
				IDs = ShipCore_IDs; 								
				break;
			}

							
		}

		block_Vertices = Vertices;
		block_IDs = IDs; 
	}
};

class Island
{	
	u32 id;
	Vec2f pos, vel;
	f32 angle, angle_vel;
	Vec2f old_pos, old_vel;
	f32 old_angle;
	f32 mass, carryMass;
	CBlob@ centerBlock;
	bool initialized;	
	uint soundsPlayed;
	string owner;
	bool isMothership;
	bool isStation;
	bool beached;
	bool slowed;
	Vec2f net_pos, net_vel;
	f32 net_angle, net_angle_vel;

	SMesh@ ShipMesh = SMesh();	
	SMeshBuffer@ ShipMeshBuffer = SMeshBuffer();
	//ShipMesh.AddMeshBuffer( @ShipMeshBuffer );
	Matrix4 model = Matrix4();

	IslandBlock[] blocks;	
	Vertex[] island_Vertices;
	u16[] island_IDs;

	Island(){
		angle = angle_vel = old_angle = mass = carryMass = 0.0f;
		initialized = false;
		isMothership = false;
		isStation = false;
		beached = false;
		slowed = false;
		@centerBlock = null;
		soundsPlayed = 0;
		owner = "";

		SMaterial@ ShipMat = SMaterial();
		ShipMat.SetTexture("BlockTextures.png", 0);
		ShipMat.DisableAllFlags();
		ShipMat.SetFlag(SMaterial::COLOR_MASK, true);
		ShipMat.SetFlag(SMaterial::ZBUFFER, true);
		ShipMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
		ShipMat.SetFlag(SMaterial::BACK_FACE_CULLING, true);
		//ShipMat.SetMaterialType(SMaterial::SOLID );
		ShipMat.SetFlag(SMaterial::FOG_ENABLE, true);
		ShipMat.SetFlag(SMaterial::GOURAUD_SHADING, true);
		ShipMat.SetAsGlobalVideoMaterial();
		ShipMeshBuffer.SetMaterial(ShipMat);
        ShipMesh.AddMeshBuffer( ShipMeshBuffer );

        model.makeIdentity();
	}
	
	void CombineModels()
	{
		island_Vertices.clear();
		island_IDs.clear();
		u16 lastID = 0;
		for (uint i = 0; i < blocks.size(); i++)
		{
			Vec2f offset = (blocks[i].offset);
			for (uint j = 0; j < blocks[i].block_Vertices.size(); j++)
			{
				Vertex v = blocks[i].block_Vertices[j];
				v.x += offset.y;
				v.z += offset.x;
				island_Vertices.push_back(v);
			}
			for (uint j = 0; j < blocks[i].block_IDs.size(); j++)
			{
				island_IDs.push_back(lastID+blocks[i].block_IDs[j]);
			}
			lastID += blocks[i].block_Vertices.size();
		}

		if (island_Vertices.size() > 0)
		{
			ShipMeshBuffer.SetVertices(island_Vertices);
			ShipMeshBuffer.SetIndices(island_IDs); 
			//ShipMesh.BuildMesh();
			ShipMesh.SetDirty(Driver::VERTEX_INDEX);
		}		
	}

	void RenderIslands(Vec3f cpos, f32 waterheight)
	{		
		//f32 waterheight = getRules().get_f32("waterheight");
		//f32 wave2 = getRules().get_f32("waterwave");
		model.setTranslation(Vec3f(pos.x, waterheight, pos.y));
		model.setRotationDegrees(Vec3f(0, -angle, 0));
		f32[] marray; model.getArray(marray);
        Render::SetModelTransform(marray);
		ShipMesh.DrawWithMaterial();

		for (uint i = 0; i < blocks.size(); i++)
		{
			CBlob@ block = getBlobByNetworkID( blocks[i].blobID );

			Blob3D@ blob3d;
			if (!block.get("blob3d", @blob3d)) { return; }

			blob3d.shape.model.setRotationDegrees(Vec3f(0, -angle, 0));
			blob3d.shape.Render();
		}
	}
};

Island@ getIsland( const int colorIndex )
{
	Island[]@ islands;
	if (getRules().get( "islands", @islands ))
		if (colorIndex > 0 && colorIndex <= islands.length){
			return islands[colorIndex-1];
		}
	return null;
}

Island@ getIsland( CBlob@ this )
{
	CBlob@[] blobsInRadius;	   
	if (getMap().getBlobsInRadius( this.getInterpolatedPosition(), 2.0f, @blobsInRadius )) 
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
            const int color = b.getShape().getVars().customData;
            if (color > 0)
            {
            	return getIsland(color);
            }
		}
	}
    return null;
}

CBlob@ getIslandBlob( CBlob@ this )
{
	CBlob@ b = null;
	f32 mDist = 9999;
	CBlob@[] blobsInRadius;	   
	if (getMap().getBlobsInRadius( this.getInterpolatedPosition(), 1.0f, @blobsInRadius ))//custom getIslandBlob();
		for (uint i = 0; i < blobsInRadius.length; i++)
			if (blobsInRadius[i].getShape().getVars().customData > 0)
			{
				f32 dist = this.getDistanceTo( blobsInRadius[i] );
				if ( dist < mDist )
				{
					@b = blobsInRadius[i];
					mDist = dist;
				}
			}
	return b;
}

Island@ getIsland3D( Blob3D@ this )
{
	CBlob@[] blobsInRadius;	   
	if (getMap().getBlobsInRadius( Vec2f(this.getPosition().x, this.getPosition().z), 2.0f, @blobsInRadius )) 
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
            const int color = b.getShape().getVars().customData;
            if (color > 0)
            {
            	return getIsland(color);
            }
		}
	}
    return null;
}

Blob3D@ getIslandBlob3D( Blob3D@ this )
{
	CBlob@ b = null;
	f32 mDist = 9999;
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius( Vec2f(this.getPosition().x, this.getPosition().z), 1.0f, @blobsInRadius ))
		for (uint i = 0; i < blobsInRadius.length; i++)
			if (blobsInRadius[i].getShape().getVars().customData > 0)
			{
				Vec2f p2 = blobsInRadius[i].getPosition();
				Vec3f p3 = Vec3f(p2.x,0,p2.y);

				f32 dist = this.getDistanceTo( p3 );
				if ( dist < mDist )
				{
					@b = blobsInRadius[i];
					mDist = dist;
				}
			}

//	CPlayer@ p = b.getPlayer();
//	if (p !is null)
//	{
//		Blob3D 3db = p.get("blob");
//		if (3db !is null)
//		{
//			return 3db;
//		}
//	}

	return null;
}

Vec2f SnapToGrid( Vec2f pos )
{
    pos.x = Maths::Round(pos.x / 16.0f);
    pos.y = Maths::Round(pos.y / 16.0f);
    pos.x *= 16;
    pos.y *= 16;
    return pos;
}

void SetNextId( CRules@ this, Island@ island )
{
	island.id = this.get_u32("islands id")+1;
	this.set_u32("islands id", island.id);
}

CBlob@ getMothership( const u8 team )
{
    CBlob@[] ships;
    getBlobsByTag( "mothership", @ships );
    for (uint i=0; i < ships.length; i++)
    {
        CBlob@ ship = ships[i];  
        if (ship.getTeamNum() == team)
            return ship;
    }
    return null;
}

CBlob@ getMothership( CBlob@ this )
{
	CBlob@ core = null;
	const int color = this.getShape().getVars().customData;
	if ( color == 0 ) return core;

	CBlob@[] cores;
	getBlobsByTag( "mothership", cores );
	
	for ( int i = 0; i < cores.length; i++ )
		if ( cores[i].getShape().getVars().customData == color )
			@core = cores[i];
	
	return core;
}

bool isMothership( CBlob@ this )
{
	const int color = this.getShape().getVars().customData;
	if ( color == 0 ) return false;
	
	Island@ island = getIsland( color );
	if ( island !is null )
		return island.isMothership;
	else
		return false;
}

bool isStation( CBlob@ this )
{
	const int color = this.getShape().getVars().customData;
	if ( color == 0 ) return false;
	
	Island@ island = getIsland( color );
	if ( island !is null )
		return island.isStation;
	else
		return false;
}

string getCaptainName( u8 team )
{
	CBlob@[] cores;
	getBlobsByTag( "mothership", @cores );
	for ( u8 i = 0; i < cores.length; i++ )
	{
		if ( cores[i].getTeamNum() != team )
			continue;
			
		Island@ isle = getIsland( cores[i].getShape().getVars().customData );
		if ( isle !is null && isle.owner != "" )
			return isle.owner;
	}
	return "";
}

bool blocksOverlappingIsland( CBlob@[]@ blocks )
{
    bool result = false;
    for (uint i = 0; i < blocks.length; ++i)
    {
        CBlob @block = blocks[i];
        if (blockOverlappingIsland( block ))
            result = true;
    }
    return result; 
}

bool blockOverlappingIsland( CBlob@ blob )
{
    CBlob@[] overlapping;
    if ( getMap().getBlobsInRadius( blob.getInterpolatedPosition(), 16.0f, @overlapping ) )
    {
        for (uint i = 0; i < overlapping.length; i++)
        {
            CBlob@ b = overlapping[i];
            int color = b.getShape().getVars().customData;
            if (color > 0)
            {
                if ((b.getInterpolatedPosition() - blob.getInterpolatedPosition()).getLength() < blob.getRadius()*0.2f)
                    return true;
            }
        }
    }
    return false;
}

bool coreLinkedDirectional( CBlob@ this, u16 token, Vec2f corePos )//checks if the block leads up to a core. doesn't follow up couplings/repulsors. accounts for core position
{
	if ( this.hasTag( "mothership" ) )
		return true;

	this.set_u16( "checkToken", token );
	bool childsLinked = false;
	Vec2f thisPos = this.getInterpolatedPosition();
	
	CBlob@[] overlapping;
	if ( this.getOverlapping( @overlapping ) )
	{
		f32 minDist = 99999.0f;
		f32 minDist2;
		CBlob@[] optimal;
		for ( int i = 0; i < overlapping.length; i++ )
		{
			CBlob@ b = overlapping[i];
			Vec2f bPos = b.getInterpolatedPosition();
			
			f32 coreDist = ( bPos - corePos ).LengthSquared();
			if ( b.get_u16( "checkToken" ) != token && ( bPos - thisPos ).LengthSquared() < 264 && !b.hasTag( "removable" ) && b.getName() == "block" )//maybe should do a color > 0 check
			{
				if ( coreDist <= minDist )
				{
					optimal.insertAt( 0, b );
					minDist2 = minDist;	
					minDist = coreDist;
				}
				else	if ( coreDist <= minDist2 )
				{
					optimal.insertAt( 0, b );
					minDist2 = coreDist;
				}
				else
					optimal.push_back(b);
			}
		}
		
		for ( int i = 0; i < optimal.length; i++ )
		{
			//print( ( optimal[i].hasTag( "mothership" ) ? "[>] " : "[o] " ) + optimal[i].getNetworkID() );
			if ( coreLinkedDirectional( optimal[i], token, corePos ) )
			{
				childsLinked = true;
				break;
			}
		}
	}
		
	return childsLinked;
}

bool coreLinked( CBlob@ this, u16 token )//use directional one
{
	if ( this.hasTag( "mothership" ) )
		return true;

	this.set_u16( "checkToken", token );
	bool childsLinked = false;
	CBlob@[] overlapping;
	this.getOverlapping( @overlapping );
	for ( int i = 0; i < overlapping.length; i++ )
	{
		CBlob@ b = overlapping[i];
		//if ( !b.hasTag( "removable" ) && b.get_u16( "checkToken" ) != token && b.getName() == "block" && b.getDistanceTo(this) < 8.8  ) print( ( b.hasTag( "mothership" ) ? "[>] " : "[o] " ) + b.getNetworkID() );
		if ( !b.hasTag( "removable" ) && b.get_u16( "checkToken" ) != token
            && b.getName() == "block"
            && (b.getPosition()-this.getPosition()).Length() < 17.6
			&& coreLinked( b, token ) )
		{
			childsLinked = true;
			break;
		}
	}
	
	return childsLinked;
}