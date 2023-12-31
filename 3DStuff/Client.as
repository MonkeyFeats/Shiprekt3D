
//#define CLIENT_ONLY

//#include "Vec4f.as"
//#include "Ray.as"

#include "RenderConsts.as"
#include "CustomMap.as"
#include "LoadMapShapes.as"
#include "World.as"
#include "IslandsCommon.as"
#include "Blob3D.as"
#include "Camera3D.as"
#include "Tree.as"
#include "RenderHUDstuff.as"
#include "OceanWater.as"

#include "Matrix.as";

const string sync_id = "mapvote: sync";

f32 wave1  = -0.15;
f32 wave2 = -0.15;

SMesh@ SkyMesh = SMesh::loadObjIntoMesh("skydome.obj");
SMeshBuffer@ SkyMeshBuffer = SMeshBuffer();

World@ world;
Root@ tree;

Tool@ tool; 
Telescope@ scope; 
Compass@ compass; 
OceanWater@ Ocean;

Matrix4 worldMat = Matrix4();

void onInit(CRules@ this)
{
	worldMat.makeIdentity();
	Render::addScript(Render::layer_objects, "Client.as", "threedee", 0.0f);
	Render::addScript(Render::layer_prehud, "Client.as", "hud", 2.0f);
	if(tool !is null)
		tool = Tool();
	
	this.addCommandID(sync_id);

	//SkyMeshBuffer.SetHardwareMapping(Driver::STATIC);	
	SMaterial@ SkyMeshBufferMaterial = SkyMeshBuffer.getMaterial();
	SkyMeshBufferMaterial.SetFlag(SMaterial::LIGHTING, false);
	//SkyMesh.RecalculateBoundingBox();
	SkyMesh.AddMeshBuffer( SkyMeshBuffer );

 	@compass = Compass(); 
 	@Ocean = OceanWater();
}

void onTick(CRules@ this)
{
	this.set_f32("interGameTime", getGameTime());
	this.set_f32("interFrameTime", 0);

	Ocean.Update();

	CPlayer@ p = getLocalPlayer();
	if(p !is null)
	{
		Camera3D@ camera;
		p.get("Camera3D", @camera);
		if (camera is null) { return; }
	   	    
		// CCam, for sounds
		getCamera().setPosition(Vec2f(camera.getPosition().z,camera.getPosition().x));
		//getCamera().setRotation(90+camera.getRotation().x);

	    compass.SetAngle(camera.getRotation().x/360);
	}

	//if (tree is null) return;
	//tree.CheckChunkVisibillty();	
}

const Vertex[] underwater_plane = 
{
	Vertex(-1,-5,  0.011f, 0,0,	SColor(130, 3, 30, 80)),
	Vertex( 1,-5,  0.011f, 1,0,	SColor(130, 3, 30, 80)),
	Vertex( 1, 0,  0.011f, 1,1,	SColor(130, 3, 30, 80)),
	Vertex(-1, 0,  0.011f, 0,1,	SColor(130, 3, 30, 80))
};


void hud(int id)
{
	CPlayer@ p = getLocalPlayer();
	if(p !is null)
	{
		Render::SetTransformScreenspace();	
		compass.RenderCompass();

		//CBlob@ b = p.getBlob();
		//if(b !is null)
		//{	
		//	string currentTool = b.get_string( "current tool" );	
//
	   // 	if (currentTool == "telescope" )
	   // 	{
	   // 		if ( (b.getSprite().getFrame() - 22) == 2)  
		//    	{
		//    		scope.DrawScope();		    		
		//    	} 
	   // 		else
	   // 		{
	   // 			tool.DrawTool(b.getTeamNum(), false);
	   // 		}
	   // 		 
	   // 	}
	   // 	else
	   // 	{
	   //     	tool.DrawTool(b.getTeamNum(), true);	        	
	   // 	}
		//}
	}
}

void threedee(int id)
{
	CRules@ rules = getRules();

	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());	

	CPlayer@ p = getLocalPlayer();
	if(p !is null)
	{		
		Camera3D@ camera;
		p.get("Camera3D", @camera);
		if (camera is null) { return; }
		if (world is null) { return; }			

		camera.render_update();		
			
		Render::SetAlphaBlend(false);
		Render::SetZBuffer(true, true);
		Render::ClearZ();
		Render::SetBackfaceCull(true);

		f32[] worldarray; worldMat.getArray(worldarray);
        f32[] projarray; camera.projection.getArray(projarray);
        f32[] viewarray; camera.view.getArray(viewarray);

        //worldMat.setbyproduct(model, camera.projection);

		Render::SetTransform(worldarray, viewarray, projarray);
		Render::SetFog(SColor(0xff3c4455), Driver::LINEAR, 500.0, 800.0, 0.0, false, true);

		SkyMesh.DrawWithMaterial();
		world.Render();
		RocksMesh.DrawWithMaterial();
		Ocean.Render();

		//for(int i = 0; i < world.Chunks.size(); i++)
		{
			//TerrainChunk@ chunk = world.Chunks[i];
			//chunk.box.Render();

			//tree.shape.Render();
			//tree.BRxz.shape.Render();
			//tree.BRx1z.shape.Render();
			//tree.BRxz1.shape.Render();
			//tree.BRx1z1.shape.Render();
		}

		//for(int i = 0; i < world.Chunks.size(); i++)
		//{
		//	TerrainChunk@ chunk = world.Chunks[i];
		//	world.Chunks[i].shape.Render();
		//}	

		Island[]@ islands;
		if ( getRules().get("islands", @islands ) )
		{				
			for ( uint i = 0; i < islands.length(); ++i )
			{
				Island @isle = islands[i];
				if ( isle.isMothership && isle.centerBlock !is null )
				{
					isle.RenderIslands(camera.getPosition(), wave1);
				}
				else
				{
					isle.RenderIslands(camera.getPosition(), wave1);
				}
			}
		}

		Matrix::MakeIdentity(model);
        Render::SetModelTransform(model);
		RenderProps(camera.getRotation().x, camera.getRotation().z, wave1);
		RenderPlayers(camera.getPosition(), model);	

		CBlob@[] palms;
		getBlobsByName( "palmtree", @palms );
		for ( u8 i = 0; i < palms.length; i++ )
		{
			CBlob@ palm = palms[i];

			Blob3D@ pblob3d;			
			if (!palm.get("blob3d", @pblob3d)) { return; }
			pblob3d.shape.Render();
		}	

	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	CBitStream params;
	u16 id = player.getNetworkID();
	params.write_u16(id);
	this.SendCommand(this.getCommandID(sync_id), params);	
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{		
	if (cmd == this.getCommandID(sync_id))
	{	
		u16 id = params.read_u16();
		CPlayer@ player = getPlayerByNetworkId(id);
		if (player.isMyPlayer())
		{				
			LoadMapShapes(getMap());

			World@ _world;
			if (getMap().get("terrainInfo", @_world))
			@world = _world;

			Root _tree(world.mapWidth, world.mapHeight, world.mapDepth);
			if ( _tree !is null )
			{
				@tree = _tree;
			}
			//SetUpTree();
			//for(int i = 0; i < world.Chunks.size(); i++)
			//{
			//	DrawHitbox(world.Chunks[i].shape, 0xffffffff);
			//}
		}
	}
}
