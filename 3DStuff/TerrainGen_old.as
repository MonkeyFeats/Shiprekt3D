#include "CustomMap.as";
#include "SR3DLoaderColors.as";
#include "ShapeArrays.as";
#include "Triangle3D.as";

const string sandtex_name = "SandTexture.png";
const string grasstex_name = "grass.png";
const string edgewalltex_name = "NoGoZone.png";
//const float tUnit = 0.5f; //texture unit
const float depthAmp = -10.5;

shared class TerrainChunk
{	
	World@ world;

	int ChunkX, ChunkZ, ChunkSize;
	bool visible, empty;
	BoundingShape@ box;

	SMesh@ TerrainMesh = SMesh();
	SMeshBuffer@ TerrainMeshBuffer = SMeshBuffer();
	SMaterial@ TerrainMat = SMaterial();

	SMesh@ GrassMesh = SMesh();
	SMeshBuffer@ GrassMeshBuffer = SMeshBuffer();
	SMaterial@ GrassMat = SMaterial();

	SMesh@ PalmsMesh = SMesh();
	SMeshBuffer@ PalmsMeshBuffer = SMeshBuffer();
	SMaterial@ PalmsMat = SMaterial();

	Vec3f[] Vertex_Positions;
	Vertex[] ground_Vertices;
	u16[] ground_IDs;

	Vertex[] combined_grassVerts;
	u16[] grass_IDs;

	Vertex[] combined_palmVerts;
	u16[] combined_palmIDs;

	Vec3f[] triangle;

	TerrainChunk(){}

	TerrainChunk(World@ _world, int _ChunkX, int _ChunkZ, int _ChunkSize)
	{
		@world = _world;
		empty = false;
		visible = true;

		ChunkX = _ChunkX;
		ChunkZ = _ChunkZ;
		ChunkSize = _ChunkSize;

		CreateTerrainMesh();

		triangle.set_length(3);
	}

	void SetVisible()
    {
        visible = true;
    }

	void CreateTerrainMesh()
	{
		CMap@ map = getMap();

		Vertex_Positions.clear();
		ground_Vertices.clear();
		ground_IDs.clear();
		combined_grassVerts.clear();
		grass_IDs.clear();
		combined_palmVerts.clear();
		combined_palmIDs.clear();		
				
		const string MapName = map.getMapName();
		if(!Texture::exists(MapName)) { Texture::createFromFile(MapName, MapName); }
		ImageData@ heightmap = Texture::data(MapName);

		const float tScale = 0.75f;
		uint t = 0;
		u16 StartX = (ChunkX*ChunkSize);
		u16 StartZ = (ChunkZ*ChunkSize);

		uint chunksWidth = heightmap.width();
		uint chunksDepth = heightmap.height();
		//print("sx "+StartX+ " sy "+StartZ);
		uint ChunkSizeX = Maths::Min(StartX+ChunkSize,chunksWidth)-StartX;
		uint ChunkSizeZ = Maths::Min(StartZ+ChunkSize,chunksDepth)-StartZ;
		
		ground_Vertices.set_length((ChunkSizeX+1)*(ChunkSizeZ+1));
		ground_IDs.set_length((ChunkSizeX*ChunkSizeZ*6));	

		Vertex[] GrassVertices = getGrassVertices();
		u16[] GrassFaceIDs = getGrassIDs();

		Vertex[] Palm_Vertices = getPalm_Vertices();
		u16[] Palm_IDs = getPalm_IDs();

		@box = BoundingBox(Vec3f(StartZ*16, -8*16, StartX*16), Vec3f((StartZ+ChunkSize)*16, 8*16, (StartX+ChunkSize)*16));

		for (int row = 0; row <= ChunkSizeZ; row++) {
		for (int col = 0; col <= ChunkSizeX; col++) {

				int index = (row*(ChunkSizeX+1))+col;

		    	SColor pixel = heightmap.get(StartX+col,StartZ+row);
		    	float h = getPixelHeight(pixel);

				SColor color = pixel;
		    	switch(pixel.color)
				{			
					case sr3d_map_colors::color_grass:
					case sr3d_map_colors::color_palmtree:
					case sr3d_map_colors::color_sand:
					case sr3d_map_colors::color_rock:
					case sr3d_map_colors::color_station: color = color_white; break;
				}	    	

		    	SColor pixelcolour_u = heightmap.get( StartX+col  ,StartZ+row-1);
		    	SColor pixelcolour_l = heightmap.get( StartX+col-1,StartZ+row);
		    	SColor pixelcolour_d = heightmap.get( StartX+col  ,StartZ+row+1);
		    	SColor pixelcolour_r = heightmap.get( StartX+col+1,StartZ+row);		    	

		    	SColor pixelcolour_ur = pixelcolour_u.getInterpolated(pixelcolour_r , 0.5);
		    	SColor pixelcolour_rd = pixelcolour_r.getInterpolated(pixelcolour_d , 0.5);
		    	SColor pixelcolour_dl = pixelcolour_d.getInterpolated(pixelcolour_r , 0.5);
		    	SColor pixelcolour_lu = pixelcolour_l.getInterpolated(pixelcolour_u , 0.5);
		    	SColor pixelcolour_uldr = pixelcolour_lu.getInterpolated(pixelcolour_rd , 0.5);
		    	SColor pixelcolour_urdl = pixelcolour_ur.getInterpolated(pixelcolour_dl , 0.5);
		    	color = pixelcolour_uldr.getInterpolated(pixelcolour_urdl , 0.5);

		    	float h_u =  getPixelHeight(pixelcolour_u);
		    	float h_l =  getPixelHeight(pixelcolour_l);
		    	float h_d =  getPixelHeight(pixelcolour_d);
		    	float h_r =  getPixelHeight(pixelcolour_r);

				float h_ur =   Maths::Lerp( h_u, h_r , 0.5);
		    	float h_dr =   Maths::Lerp( h_d, h_r , 0.5);		    	
		    	float h_ul =   Maths::Lerp( h_u, h_l , 0.5);
		    	float h_dl =   Maths::Lerp( h_d, h_l , 0.5);
		    	float h_uldr = Maths::Lerp(h_ul,h_dr , 0.5);
		    	float h_urdl = Maths::Lerp(h_ur,h_dl , 0.5);

		    	h = Maths::Lerp(h_uldr, h_urdl, 0.5);

				ground_Vertices[index] = (Vertex((StartX+col)*16, h, (StartZ+row)*16, (StartX+col)*tScale, (StartZ+row)*tScale, color ));

		        if (pixel == sr3d_map_colors::color_grass)
				{
					Vec2f pos(col,row);
					u16 IDstart = combined_grassVerts.length;

					f32 OffPosX = XORRandom(100)*0.01;
					f32 OffPosZ = XORRandom(100)*0.01;
					u8 Rot = XORRandom(255);

					for (uint i = 0; i < GrassVertices.length; i++)
					{
						Vec2f Rotated0 = Vec2f(GrassVertices[i].x,GrassVertices[i].z).RotateBy(Rot);
						combined_grassVerts.push_back(Vertex((StartX+ OffPosX+pos.x+Rotated0.x)*16, GrassVertices[i].y, (StartZ+ OffPosZ+pos.y+Rotated0.y)*16, GrassVertices[i].u, GrassVertices[i].v ));								
					}
					for (uint i = 0; i < GrassFaceIDs.length; ++i)
					{
						grass_IDs.push_back( IDstart+GrassFaceIDs[i]);
					}
					if (combined_grassVerts.length() > 0)
					{
						GrassMeshBuffer.SetVertices(combined_grassVerts);
						GrassMeshBuffer.SetIndices(grass_IDs); 
						//GrassMesh.BuildMesh();
						GrassMeshBuffer.SetDirty(Driver::VERTEX_INDEX);

						GrassMat.SetTexture("GrassTexture.png", 0);
						GrassMat.DisableAllFlags();
						GrassMat.SetFlag(SMaterial::COLOR_MASK, true);
						GrassMat.SetFlag(SMaterial::ZBUFFER, true);
						GrassMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
						GrassMat.SetFlag(SMaterial::BACK_FACE_CULLING, false);
						//GrassMat.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF );
						//GrassMat.SetFlag(SMaterial::WIREFRAME, true);
						GrassMeshBuffer.SetMaterial(GrassMat);
						GrassMesh.AddMeshBuffer( GrassMeshBuffer );
					}
				}
				else if (pixel == sr3d_map_colors::color_palmtree)
				{
					Vec2f pos(col,row);
					u16 IDstart = combined_palmVerts.length;

					f32 OffPosX = XORRandom(100)*0.01;
					f32 OffPosZ = XORRandom(100)*0.01;
					u8 Rot = XORRandom(255);


					for (uint i = 0; i < Palm_Vertices.length; i++)
					{
						Vec2f Rotated0 = Vec2f(Palm_Vertices[i].x,Palm_Vertices[i].z).RotateBy(Rot);
						combined_palmVerts.push_back(Vertex(StartZ+ OffPosX+pos.y+Rotated0.x, Palm_Vertices[i].y,StartX+ OffPosZ+pos.x+Rotated0.y, Palm_Vertices[i].u, Palm_Vertices[i].v ));								
					}
					for (uint i = 0; i < Palm_IDs.length; ++i)
					{
						combined_palmIDs.push_back( IDstart+Palm_IDs[i]);
					}
					if (combined_palmVerts.length() > 0)
					{
						PalmsMeshBuffer.SetVertices(combined_palmVerts);
						PalmsMeshBuffer.SetIndices(combined_palmIDs); 
						//PalmsMesh.BuildMesh();
						PalmsMeshBuffer.SetDirty(Driver::VERTEX_INDEX);

						PalmsMat.SetTexture("PalmTexture.png", 0);
						PalmsMat.DisableAllFlags();
						PalmsMat.SetFlag(SMaterial::COLOR_MASK, true);
						PalmsMat.SetFlag(SMaterial::ZBUFFER, true);
						PalmsMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
						PalmsMat.SetFlag(SMaterial::BACK_FACE_CULLING, false);
						//PalmsMat.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF );
						//PalmsMat.SetFlag(SMaterial::WIREFRAME, true);
						PalmsMeshBuffer.SetMaterial(PalmsMat);
						PalmsMesh.AddMeshBuffer( PalmsMeshBuffer );
					}
				}
		    } 
		}
			
		for (int row = 0; row < ChunkSizeZ; row++) 		
		{
			for (int col = 0; col < ChunkSizeX; col++) 
			{			
	            int index = (row*(ChunkSizeX+1))+col;
	            bool isRotated = getFaceRotation(StartX+col,StartZ+row, Texture::data(MapName));

	            int tl = index;
				int tr = index + 1;
				int bl = index + (ChunkSizeX+1);
				int br = index + (ChunkSizeX+1)+1;
		       	//if (isRotated)
				//{
	            //	ground_IDs[t] =   tl;
				//	ground_IDs[t+1] = tr;
		        //    ground_IDs[t+2] = br;
//
		        //    ground_IDs[t+3] = br;
		        //    ground_IDs[t+4] = bl;
		        //    ground_IDs[t+5] = tl;
				//}
				//else
				{
					ground_IDs[t] =   tl;
					ground_IDs[t+1] = tr;
		            ground_IDs[t+2] = bl;

		            ground_IDs[t+3] = bl;
		            ground_IDs[t+4] = tr;
		            ground_IDs[t+5] = br;		            
				}	
				t+=6;
			}
		}

		if (ground_Vertices.length() > 0)
		{
			TerrainMeshBuffer.SetVertices(ground_Vertices);
			TerrainMeshBuffer.SetIndices(ground_IDs); 
			//TerrainMesh.BuildMesh();
			TerrainMeshBuffer.SetDirty(Driver::VERTEX_INDEX);

			TerrainMat.SetTexture("SandTexture.png", 0);
			TerrainMat.DisableAllFlags();
			TerrainMat.SetFlag(SMaterial::COLOR_MASK, true);
			TerrainMat.SetFlag(SMaterial::ZBUFFER, true);
			TerrainMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
			TerrainMat.SetFlag(SMaterial::BACK_FACE_CULLING, true);
			TerrainMat.SetFlag(SMaterial::GOURAUD_SHADING, true);
			TerrainMat.SetFlag(SMaterial::FOG_ENABLE, true);
			//TerrainMat.SetFlag(SMaterial::WIREFRAME, true);
			TerrainMeshBuffer.SetMaterial(TerrainMat);
			TerrainMesh.AddMeshBuffer( TerrainMeshBuffer );
		}

		if(ground_Vertices.size() == 0)
        {
            empty = true;
        }
	}


	float getPixelHeight(SColor pixel) 
	{
		switch(pixel.color)
		{			
			case sr3d_map_colors::color_grass:
			case sr3d_map_colors::color_palmtree: return 1.2;
			case sr3d_map_colors::color_sand:
			case sr3d_map_colors::color_rock:     return 1.2;
			case sr3d_map_colors::color_station:  return 1.0;
			case sr3d_map_colors::color_water_1:  return depthAmp*1;
			case sr3d_map_colors::color_water_2:  return depthAmp*2;
			case sr3d_map_colors::color_water_3:  return depthAmp*3;
			case sr3d_map_colors::color_water_4:  return depthAmp*4;
			case sr3d_map_colors::color_water_5:  return depthAmp*5;
			case sr3d_map_colors::color_water_6:  return depthAmp*6;
			case sr3d_map_colors::color_water_7:  return depthAmp*7;
			case sr3d_map_colors::color_water_8:  return depthAmp*8;
			case sr3d_map_colors::color_water_9:  return depthAmp*9;
			case sr3d_map_colors::color_water_10: return depthAmp*10;
			case sr3d_map_colors::color_water_11: return depthAmp*11;
			case sr3d_map_colors::color_water_12: return depthAmp*12;
			case sr3d_map_colors::color_water_13: return depthAmp*13;
			case sr3d_map_colors::color_water_14: return depthAmp*14;
			case sr3d_map_colors::color_water_15: return depthAmp*15;
			case sr3d_map_colors::color_water_16: return depthAmp*16;
			case sr3d_map_colors::color_water_17: return depthAmp*17;
			case sr3d_map_colors::color_water_18: return depthAmp*18;
			case sr3d_map_colors::color_water_19: return depthAmp*19;
			case sr3d_map_colors::color_water_20: return depthAmp*20;
			case sr3d_map_colors::color_water_21: return depthAmp*21;
			case sr3d_map_colors::color_water_22: return depthAmp*22;
			case sr3d_map_colors::color_water: return    depthAmp*23;
		}
		return depthAmp*24; //color = SColor(255,255,0,255); 
    }

    bool getFaceRotation(int x, int y, ImageData heightmap) // this needs to be re-done
	{ 
		SColor p_C =  heightmap.get(x, y);
		SColor p_E =  heightmap.get(x+1, y  );
		SColor p_NE = heightmap.get(x+1, y-1);
		SColor p_N =  heightmap.get(x  , y-1);
		SColor p_NW = heightmap.get(x-1, y-1);
		SColor p_W =  heightmap.get(x-1, y  );
		SColor p_SW = heightmap.get(x-1, y+1);
		SColor p_S =  heightmap.get(x  , y+1);
		SColor p_SE = heightmap.get(x+1, y+1);

		bool rotated = false;			

		if ((p_N == sr3d_map_colors::color_sand && p_E == sr3d_map_colors::color_sand && p_S != sr3d_map_colors::color_sand && p_W != sr3d_map_colors::color_sand) || 
			(p_S == sr3d_map_colors::color_sand && p_W == sr3d_map_colors::color_sand && p_N != sr3d_map_colors::color_sand && p_E != sr3d_map_colors::color_sand))
		{
			rotated = true;
		}
		else if ((p_NW == sr3d_map_colors::color_sand && p_SW == sr3d_map_colors::color_sand && p_SE == sr3d_map_colors::color_sand && p_NE != sr3d_map_colors::color_sand) || 
				 (p_SE == sr3d_map_colors::color_sand && p_SE == sr3d_map_colors::color_sand && p_NW == sr3d_map_colors::color_sand && p_SW != sr3d_map_colors::color_sand))
		{
			rotated = true;
		}

		else if ((p_N == sr3d_map_colors::color_shoal && p_E == sr3d_map_colors::color_shoal && p_S != sr3d_map_colors::color_shoal && p_W != sr3d_map_colors::color_shoal) || 
				 (p_S == sr3d_map_colors::color_shoal && p_W == sr3d_map_colors::color_shoal && p_N != sr3d_map_colors::color_shoal && p_E != sr3d_map_colors::color_shoal))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_1 && p_E == sr3d_map_colors::color_water_1 && p_S != sr3d_map_colors::color_water_1 && p_W != sr3d_map_colors::color_water_1) || 
				 (p_S == sr3d_map_colors::color_water_1 && p_W == sr3d_map_colors::color_water_1 && p_N != sr3d_map_colors::color_water_1 && p_E != sr3d_map_colors::color_water_1))
		{
			rotated = true;
		}	
		else if ((p_N == sr3d_map_colors::color_water_2 && p_E == sr3d_map_colors::color_water_2 && p_S != sr3d_map_colors::color_water_2 && p_W != sr3d_map_colors::color_water_2) || 
				 (p_S == sr3d_map_colors::color_water_2 && p_W == sr3d_map_colors::color_water_2 && p_N != sr3d_map_colors::color_water_2 && p_E != sr3d_map_colors::color_water_2))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_3 && p_E == sr3d_map_colors::color_water_3 && p_S != sr3d_map_colors::color_water_3 && p_W != sr3d_map_colors::color_water_3) || 
				 (p_S == sr3d_map_colors::color_water_3 && p_W == sr3d_map_colors::color_water_3 && p_N != sr3d_map_colors::color_water_3 && p_E != sr3d_map_colors::color_water_3))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_4 && p_E == sr3d_map_colors::color_water_4 && p_S != sr3d_map_colors::color_water_4 && p_W != sr3d_map_colors::color_water_4) || 
				 (p_S == sr3d_map_colors::color_water_4 && p_W == sr3d_map_colors::color_water_4 && p_N != sr3d_map_colors::color_water_4 && p_E != sr3d_map_colors::color_water_4))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_5 && p_E == sr3d_map_colors::color_water_5 && p_S != sr3d_map_colors::color_water_5 && p_W != sr3d_map_colors::color_water_5) || 
				 (p_S == sr3d_map_colors::color_water_5 && p_W == sr3d_map_colors::color_water_5 && p_N != sr3d_map_colors::color_water_5 && p_E != sr3d_map_colors::color_water_5))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_6 && p_E == sr3d_map_colors::color_water_6 && p_S != sr3d_map_colors::color_water_6 && p_W != sr3d_map_colors::color_water_6) || 
				 (p_S == sr3d_map_colors::color_water_6 && p_W == sr3d_map_colors::color_water_6 && p_N != sr3d_map_colors::color_water_6 && p_E != sr3d_map_colors::color_water_6))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_7 && p_E == sr3d_map_colors::color_water_7 && p_S != sr3d_map_colors::color_water_7 && p_W != sr3d_map_colors::color_water_7) || 
				 (p_S == sr3d_map_colors::color_water_7 && p_W == sr3d_map_colors::color_water_7 && p_N != sr3d_map_colors::color_water_7 && p_E != sr3d_map_colors::color_water_7))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_8 && p_E == sr3d_map_colors::color_water_8 && p_S != sr3d_map_colors::color_water_8 && p_W != sr3d_map_colors::color_water_8) || 
				 (p_S == sr3d_map_colors::color_water_8 && p_W == sr3d_map_colors::color_water_8 && p_N != sr3d_map_colors::color_water_8 && p_E != sr3d_map_colors::color_water_8))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_9 && p_E == sr3d_map_colors::color_water_9 && p_S != sr3d_map_colors::color_water_9 && p_W != sr3d_map_colors::color_water_9) || 
				 (p_S == sr3d_map_colors::color_water_9 && p_W == sr3d_map_colors::color_water_9 && p_N != sr3d_map_colors::color_water_9 && p_E != sr3d_map_colors::color_water_9))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_10 && p_E == sr3d_map_colors::color_water_10 && p_S != sr3d_map_colors::color_water_10 && p_W != sr3d_map_colors::color_water_10) || 
				 (p_S == sr3d_map_colors::color_water_10 && p_W == sr3d_map_colors::color_water_10 && p_N != sr3d_map_colors::color_water_10 && p_E != sr3d_map_colors::color_water_10))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_11 && p_E == sr3d_map_colors::color_water_11 && p_S != sr3d_map_colors::color_water_11 && p_W != sr3d_map_colors::color_water_11) || 
				 (p_S == sr3d_map_colors::color_water_11 && p_W == sr3d_map_colors::color_water_11 && p_N != sr3d_map_colors::color_water_11 && p_E != sr3d_map_colors::color_water_11))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_12 && p_E == sr3d_map_colors::color_water_12 && p_S != sr3d_map_colors::color_water_12 && p_W != sr3d_map_colors::color_water_12) || 
				 (p_S == sr3d_map_colors::color_water_12 && p_W == sr3d_map_colors::color_water_12 && p_N != sr3d_map_colors::color_water_12 && p_E != sr3d_map_colors::color_water_12))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_13 && p_E == sr3d_map_colors::color_water_13 && p_S != sr3d_map_colors::color_water_13 && p_W != sr3d_map_colors::color_water_13) || 
				 (p_S == sr3d_map_colors::color_water_13 && p_W == sr3d_map_colors::color_water_13 && p_N != sr3d_map_colors::color_water_13 && p_E != sr3d_map_colors::color_water_13))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_14 && p_E == sr3d_map_colors::color_water_14 && p_S != sr3d_map_colors::color_water_14 && p_W != sr3d_map_colors::color_water_14) || 
				 (p_S == sr3d_map_colors::color_water_14 && p_W == sr3d_map_colors::color_water_14 && p_N != sr3d_map_colors::color_water_14 && p_E != sr3d_map_colors::color_water_14))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_15 && p_E == sr3d_map_colors::color_water_15 && p_S != sr3d_map_colors::color_water_15 && p_W != sr3d_map_colors::color_water_15) || 
				 (p_S == sr3d_map_colors::color_water_15 && p_W == sr3d_map_colors::color_water_15 && p_N != sr3d_map_colors::color_water_15 && p_E != sr3d_map_colors::color_water_15))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_16 && p_E == sr3d_map_colors::color_water_16 && p_S != sr3d_map_colors::color_water_16 && p_W != sr3d_map_colors::color_water_16) || 
				 (p_S == sr3d_map_colors::color_water_16 && p_W == sr3d_map_colors::color_water_16 && p_N != sr3d_map_colors::color_water_16 && p_E != sr3d_map_colors::color_water_16))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_17 && p_E == sr3d_map_colors::color_water_17 && p_S != sr3d_map_colors::color_water_17 && p_W != sr3d_map_colors::color_water_17) || 
				 (p_S == sr3d_map_colors::color_water_17 && p_W == sr3d_map_colors::color_water_17 && p_N != sr3d_map_colors::color_water_17 && p_E != sr3d_map_colors::color_water_17))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_18 && p_E == sr3d_map_colors::color_water_18 && p_S != sr3d_map_colors::color_water_18 && p_W != sr3d_map_colors::color_water_18) || 
				 (p_S == sr3d_map_colors::color_water_18 && p_W == sr3d_map_colors::color_water_18 && p_N != sr3d_map_colors::color_water_18 && p_E != sr3d_map_colors::color_water_18))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_19 && p_E == sr3d_map_colors::color_water_19 && p_S != sr3d_map_colors::color_water_19 && p_W != sr3d_map_colors::color_water_19) || 
				 (p_S == sr3d_map_colors::color_water_19 && p_W == sr3d_map_colors::color_water_19 && p_N != sr3d_map_colors::color_water_19 && p_E != sr3d_map_colors::color_water_19))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_20 && p_E == sr3d_map_colors::color_water_20 && p_S != sr3d_map_colors::color_water_20 && p_W != sr3d_map_colors::color_water_20) || 
				 (p_S == sr3d_map_colors::color_water_20 && p_W == sr3d_map_colors::color_water_20 && p_N != sr3d_map_colors::color_water_20 && p_E != sr3d_map_colors::color_water_20))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_21 && p_E == sr3d_map_colors::color_water_21 && p_S != sr3d_map_colors::color_water_21 && p_W != sr3d_map_colors::color_water_21) || 
				 (p_S == sr3d_map_colors::color_water_21 && p_W == sr3d_map_colors::color_water_21 && p_N != sr3d_map_colors::color_water_21 && p_E != sr3d_map_colors::color_water_21))
		{
			rotated = true;
		}
		else if ((p_N == sr3d_map_colors::color_water_22 && p_E == sr3d_map_colors::color_water_22 && p_S != sr3d_map_colors::color_water_22 && p_W != sr3d_map_colors::color_water_22) || 
				 (p_S == sr3d_map_colors::color_water_22 && p_W == sr3d_map_colors::color_water_22 && p_N != sr3d_map_colors::color_water_22 && p_E != sr3d_map_colors::color_water_22))
		{
			rotated = true;
		}

		return rotated;
	}

	Vec3f Cross(Vec3f vec1, Vec3f vec2)
    {
        return Vec3f(vec1.y * vec2.z - vec2.y * vec1.z,
                   -(vec1.x * vec2.z - vec2.x * vec1.z),
                     vec1.x * vec2.y - vec2.x * vec1.y);
    }

	float[] calcNormals(Vertex[] ground_Vertices, int width, int height) 
	{
	    Vec3f v0; Vec3f v1; Vec3f v2; Vec3f v3; Vec3f v4;
	    Vec3f v12; Vec3f v23; Vec3f v34; Vec3f v41;

	    float[] normals;
	    Vec3f normal;
	    for (int row = 0; row < height; row++) {
	        for (int col = 0; col < width; col++) {
	            if (row > 0 && row < height -1 && col > 0 && col < width -1) {
	                int i0 = row*width*3 + col*3;
	                v0.x = ground_Vertices[i0].z;
	                v0.y = ground_Vertices[i0 + 1].y;
	                v0.z = ground_Vertices[i0 + 2].x;

	                int i1 = row*width*3 + (col-1)*3;
	                v1.x = ground_Vertices[i1].z;
	                v1.y = ground_Vertices[i1 + 1].y;
	                v1.z = ground_Vertices[i1 + 2].x;                    
	                v1 = v1.opSub(v0);

	                int i2 = (row+1)*width*3 + col*3;
	                v2.x = ground_Vertices[i2].z;
	                v2.y = ground_Vertices[i2 + 1].y;
	                v2.z = ground_Vertices[i2 + 2].x;
	                v2 = v2.opSub(v0);

	                int i3 = (row)*width*3 + (col+1)*3;
	                v3.x = ground_Vertices[i3].z;
	                v3.y = ground_Vertices[i3 + 1].y;
	                v3.z = ground_Vertices[i3 + 2].x;
	                v3 = v3.opSub(v0);

	                int i4 = (row-1)*width*3 + col*3;
	                v4.x = ground_Vertices[i4].z;
	                v4.y = ground_Vertices[i4 + 1].y;
	                v4.z = ground_Vertices[i4 + 2].x;
	                v4 = v4.opSub(v0);

	                v12 = Cross(v1,v2);
	                v12.normalize();

	                v23 = Cross(v2,v3);
	                v23.normalize();

	                v34 = Cross(v3,v4);
	                v34.normalize();

	                v41 = Cross(v4,v1);
	                v41.normalize();

	                normal = v12.opAdd(v23).opAdd(v34).opAdd(v41);
	                normal.normalize();
	            } else {
	                normal.x = 0;
	                normal.y = 1;
	                normal.z = 0;
	            }

	            normals.push_back(normal.normalize());

	            //for (uint n = 0; n < normals.length; n++)
	            //{
	            //	normals[n]+=normal.x;
	            //	normals[n]+=normal.y;
	            //	normals[n]+=normal.z;
	            //}
	        }
	    }
	    return normals;
	}
	
	float getGroundHeight(Vec3f Pos) 
	{
		int StartX = (ChunkX*ChunkSize);
		int StartZ = (ChunkZ*ChunkSize);
	    int X = (int(Pos.x/16)-(StartX));
	    int Z = (int(Pos.z/16)-(StartZ));

		int index0 = (Z*(ChunkSize+1))+X;
		int index1 = index0+1;
		int index2 = index0+(ChunkSize+1);
		int index3 = index0+(ChunkSize+1)+1;

		triangle[1] = Vec3f( ground_Vertices[index1].x, ground_Vertices[index1].y, ground_Vertices[index1].z);
		triangle[2] = Vec3f( ground_Vertices[index2].x, ground_Vertices[index2].y, ground_Vertices[index2].z);

		float dz = getDiagonalZCoord(triangle[1].x, triangle[1].z, triangle[2].x, triangle[2].z, Pos.x);

		if (Pos.x < dz) triangle[0] = Vec3f( ground_Vertices[index0].x, ground_Vertices[index0].y, ground_Vertices[index0].z);		 
				   else triangle[0] = Vec3f( ground_Vertices[index3].x, ground_Vertices[index3].y, ground_Vertices[index3].z);

		Vertex[] verts = {
			Vertex(triangle[0].x,triangle[0].y,triangle[0].z, 0 , 0, SColor(255,255,0,0)),
			Vertex(triangle[1].x,triangle[1].y,triangle[1].z, 1 , 0, SColor(255,0,255,0)),
			Vertex(triangle[2].x,triangle[2].y,triangle[2].z, 1 , 1, SColor(255,0,0,255))
		};

	    float result = interpolateHeight(triangle[0], triangle[1], triangle[2], Pos);
	    return result;
	}
	
	float getDiagonalZCoord(float x1, float z1, float x2, float z2, float x) {
    	float z = ((z1 - z2) / (x1 - x2)) * (x - x1) + z1;
    	return z;
	}

	float interpolateHeight(Vec3f pA, Vec3f pB, Vec3f pC, Vec3f Pos) //gets the y pos at the xz pos of the triangle plane we're on
	{
	    // Plane equation ax+by+cz+d=0
	    float a = (pB.y - pA.y) * (pC.z - pA.z) - (pC.y - pA.y) * (pB.z - pA.z);
	    float b = (pB.z - pA.z) * (pC.x - pA.x) - (pC.z - pA.z) * (pB.x - pA.x);
	    float c = (pB.x - pA.x) * (pC.y - pA.y) - (pC.x - pA.x) * (pB.y - pA.y);
	    float d = -(a * pA.x + b * pA.y + c * pA.z);
	    // y = (-d -ax -cz) / b
	    if (b == 0) return Pos.y;

	    return ((-d - a * Pos.x - c * Pos.z)/b);
	}

	void onRend() // draws the triangle we are in, 2d
	{
		Vec2f v1 = Vec2f(triangle[0].x,triangle[0].z);
		Vec2f v2 = Vec2f(triangle[1].x,triangle[1].z);			
		Vec2f v3 = Vec2f(triangle[2].x,triangle[2].z);

		GUI::DrawLine(v1, v2, color_white);
		GUI::DrawLine(v2, v3, color_white);
		GUI::DrawLine(v3, v1, color_white);
	}	
}