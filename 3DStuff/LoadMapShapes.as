#include "SAT_Shapes.as";

Vertex[] mountain_Vertices;
u16[] mountain_IDs;

SMesh@ RocksMesh = SMesh();
SMeshBuffer@ RocksMeshBuffer = SMeshBuffer();
SMaterial@ RockMat = SMaterial();

void LoadMapShapes(CMap@ map)
{
	Map_SAT_Shapes shapes();
	map.set("Map_SAT_Info", @shapes);	

	Map_SAT_Shapes map_shapes();

	const uint tileCount = map.tilemapwidth * map.tilemapheight;

    //RocksMeshBuffer.SetHardwareMapping(Driver::DYNAMIC);  

	u16 lastID = 0;

	for (u32 offset = 0; offset < tileCount; ++offset)
	{
		TileType tile = map.getTile(offset).type;
		Vec2f pos_off = map.getTileWorldPosition(offset);
		Vec2f tile_center = pos_off;
		pos_off /= 16;

		switch (tile)
		{
			case CMap::rock_sand_border_island1: 
			{
				for (uint i = 0; i < Rock_island_Vertices.length; i++) {
					Vertex v = Rock_island_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_island_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_island_IDs[i] ); }

				lastID += Rock_island_Vertices.length;
				map_shapes.PushAShape(island_Shape, tile_center, offset, 0);
			}break;

			//four way crossing
			case CMap::rock_sand_border_cross1:
			{				
				for (uint i = 0; i < Rock_cross_Vertices.length; i++) {
					Vertex v = Rock_cross_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_cross_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_cross_IDs[i] ); }
										
				lastID += Rock_cross_Vertices.length;				
				map_shapes.PushAShape(cross_Shape, tile_center, offset, 0);
			}break;		
		
			//peninsula shorelines
			case CMap::rock_sand_border_peninsula_R1:
			{				
				for (uint i = 0; i < Rock_peninsula_Vertices.length; i++) {
					Vertex v = Rock_peninsula_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_peninsula_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_peninsula_IDs[i] ); }
										
				lastID += Rock_peninsula_Vertices.length;
				map_shapes.PushAShape(peninsula_Shape, tile_center, offset, 270);
			}break;	

			case CMap::rock_sand_border_peninsula_U1:
			{				
				for (uint i = 0; i < Rock_peninsula_Vertices.length; i++) {
					Vertex v = Rock_peninsula_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_peninsula_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_peninsula_IDs[i] ); }
										
				lastID += Rock_peninsula_Vertices.length;
				map_shapes.PushAShape(peninsula_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_peninsula_L1:
			{				
				for (uint i = 0; i < Rock_peninsula_Vertices.length; i++) {
					Vertex v = Rock_peninsula_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_peninsula_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_peninsula_IDs[i] ); }
										
				lastID += Rock_peninsula_Vertices.length;
				map_shapes.PushAShape(peninsula_Shape, tile_center, offset,90);
			}break;

			case CMap::rock_sand_border_peninsula_D1: 
			{				
				for (uint i = 0; i < Rock_peninsula_Vertices.length; i++) {
					Vertex v = Rock_peninsula_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_peninsula_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_peninsula_IDs[i] ); }
										
				lastID += Rock_peninsula_Vertices.length;				
				map_shapes.PushAShape(peninsula_Shape, tile_center, offset, 180);
			}break;	
				
			//three way T crossings	
			case CMap::rock_sand_border_T_D1:
			{				
				for (uint i = 0; i < Rock_tee_Vertices.length; i++) {
					Vertex v = Rock_tee_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }//
				for (uint i = 0; i < Rock_tee_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_tee_IDs[i] ); }

					lastID += Rock_tee_Vertices.length;
				map_shapes.PushAShape(tee_Shape, tile_center, offset, 180);
			}break;

			case CMap::rock_sand_border_T_L1:
			{				
				for (uint i = 0; i < Rock_tee_Vertices.length; i++) {
					Vertex v = Rock_tee_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }//
				for (uint i = 0; i < Rock_tee_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_tee_IDs[i] ); }

				lastID += Rock_tee_Vertices.length;
				map_shapes.PushAShape(tee_Shape, tile_center, offset, 90);
			}	break;

			case CMap::rock_sand_border_T_U1:
			{				
				for (uint i = 0; i < Rock_tee_Vertices.length; i++) {
					Vertex v = Rock_tee_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }//
				for (uint i = 0; i < Rock_tee_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_tee_IDs[i] ); }	

				lastID += Rock_tee_Vertices.length;
				map_shapes.PushAShape(tee_Shape, tile_center, offset);
			}break;

			case CMap::rock_sand_border_T_R1:
			{				
				for (uint i = 0; i < Rock_tee_Vertices.length; i++) {
					Vertex v = Rock_tee_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }//
				for (uint i = 0; i < Rock_tee_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_tee_IDs[i] ); }	

				lastID += Rock_tee_Vertices.length;
				map_shapes.PushAShape(tee_Shape, tile_center, offset, 270);
			}break;
				
			//left handed panhandle
			case CMap::rock_sand_border_panhandleL_R1:
			{		
				for (uint i = 0; i < Rock_panhandle_L_Vertices.length; i++) {
					Vertex v = Rock_panhandle_L_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_panhandle_L_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_panhandle_L_IDs[i] ); }
//
				lastID += Rock_panhandle_L_Vertices.length;
				map_shapes.PushAShape(panhandle_l_Shape, tile_center, offset, 270);
			}break;	

			case CMap::rock_sand_border_panhandleL_U1:
			{				
				for (uint i = 0; i < Rock_panhandle_L_Vertices.length; i++) {
					Vertex v = Rock_panhandle_L_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_panhandle_L_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_panhandle_L_IDs[i] ); }

				lastID += Rock_panhandle_L_Vertices.length;
				map_shapes.PushAShape(panhandle_l_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_panhandleL_L1:
			{				
				for (uint i = 0; i < Rock_panhandle_L_Vertices.length; i++) {
					Vertex v = Rock_panhandle_L_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_panhandle_L_IDs.length; i++) {			
					mountain_IDs.push_back( lastID+Rock_panhandle_L_IDs[i] ); }

					lastID += Rock_panhandle_L_Vertices.length;
				map_shapes.PushAShape(panhandle_l_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_panhandleL_D1:
			{				
				for (uint i = 0; i < Rock_panhandle_L_Vertices.length; i++) {
					Vertex v = Rock_panhandle_L_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	
//
				for (uint i = 0; i < Rock_panhandle_L_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_panhandle_L_IDs[i] ); }

					lastID += Rock_panhandle_L_Vertices.length;
				map_shapes.PushAShape(panhandle_l_Shape, tile_center, offset, 180);
			}break;
				
			//right handed panhandle
			case CMap::rock_sand_border_panhandleR_R1:
			{	
					for (uint i = 0; i < Rock_panhandle_R_Vertices.length; i++) {
					Vertex v = Rock_panhandle_R_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_panhandle_R_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_panhandle_R_IDs[i] ); }

					lastID += Rock_panhandle_R_Vertices.length;
				map_shapes.PushAShape(panhandle_r_Shape, tile_center, offset, 270);
			}break;

			case CMap::rock_sand_border_panhandleR_U1:
			{				
					for (uint i = 0; i < Rock_panhandle_R_Vertices.length; i++) {
					Vertex v = Rock_panhandle_R_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_panhandle_R_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_panhandle_R_IDs[i] ); }

					lastID += Rock_panhandle_R_Vertices.length;				
				map_shapes.PushAShape(panhandle_r_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_panhandleR_L1:
			{				
					for (uint i = 0; i < Rock_panhandle_R_Vertices.length; i++) {
					Vertex v = Rock_panhandle_R_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_panhandle_R_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_panhandle_R_IDs[i] ); }

					lastID += Rock_panhandle_R_Vertices.length;
				map_shapes.PushAShape(panhandle_r_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_panhandleR_D1:
			{				
					for (uint i = 0; i < Rock_panhandle_R_Vertices.length; i++) {
					Vertex v = Rock_panhandle_R_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_panhandle_R_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_panhandle_R_IDs[i] ); }

					lastID += Rock_panhandle_R_Vertices.length;
				map_shapes.PushAShape(panhandle_r_Shape, tile_center, offset, 180);
			}break;
				
			//splitting strips
			case CMap::rock_sand_border_split_RU1:
			{	
				for (uint i = 0; i < Rock_split_Vertices.length; i++) {
					Vertex v = Rock_split_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_split_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_split_IDs[i] ); }

					lastID += Rock_split_Vertices.length;
				map_shapes.PushAShape(split_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_split_LU1:
			{			
				for (uint i = 0; i < Rock_split_Vertices.length; i++) {
					Vertex v = Rock_split_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_split_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_split_IDs[i] ); }

					lastID += Rock_split_Vertices.length;
				map_shapes.PushAShape(split_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_split_LD1:
			{
				for (uint i = 0; i < Rock_split_Vertices.length; i++) {
					Vertex v = Rock_split_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_split_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_split_IDs[i] ); }

					lastID += Rock_split_Vertices.length;
				map_shapes.PushAShape(split_Shape, tile_center, offset, 180);
			}break;

			case CMap::rock_sand_border_split_RD1:
			{
				for (uint i = 0; i < Rock_split_Vertices.length; i++) {
					Vertex v = Rock_split_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_split_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_split_IDs[i] ); }

					lastID += Rock_split_Vertices.length;
				map_shapes.PushAShape(split_Shape, tile_center, offset, 270);
			}break;
				
			//choke points
			case CMap::rock_sand_border_choke_R1:
			{
				for (uint i = 0; i < Rock_choke_Vertices.length; i++) {
					Vertex v = Rock_choke_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_choke_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_choke_IDs[i] ); }

					lastID += Rock_choke_Vertices.length;
				map_shapes.PushAShape(choke_Shape, tile_center, offset, 270);
			}break;
			case CMap::rock_sand_border_choke_U1:
			{
				for (uint i = 0; i < Rock_choke_Vertices.length; i++) {
					Vertex v = Rock_choke_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_choke_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_choke_IDs[i] ); }

					lastID += Rock_choke_Vertices.length;
				map_shapes.PushAShape(choke_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_choke_L1:
			{
				for (uint i = 0; i < Rock_choke_Vertices.length; i++) {
					Vertex v = Rock_choke_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_choke_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_choke_IDs[i] ); }

					lastID += Rock_choke_Vertices.length;
				map_shapes.PushAShape(choke_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_choke_D1:
			{
				for (uint i = 0; i < Rock_choke_Vertices.length; i++) {
					Vertex v = Rock_choke_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_choke_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_choke_IDs[i] ); }

					lastID += Rock_choke_Vertices.length;
				map_shapes.PushAShape(choke_Shape, tile_center, offset, 180);
			}break;
				
			//strip shorelines
			case CMap::rock_sand_border_strip_H1:
			{

				for (uint i = 0; i < Rock_strip_Vertices.length; i++) {
					Vertex v = Rock_strip_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_strip_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_strip_IDs[i] ); }

					lastID += Rock_strip_Vertices.length;
				map_shapes.PushAShape(strip_Shape, tile_center, offset, 0);
			}break;
			case CMap::rock_sand_border_strip_V1:
			{
				for (uint i = 0; i < Rock_strip_Vertices.length; i++) {
					Vertex v = Rock_strip_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_strip_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_strip_IDs[i] ); }

					lastID += Rock_strip_Vertices.length;
				map_shapes.PushAShape(strip_Shape, tile_center, offset, 90);
			}break;

			//bend shorelines
			case CMap::rock_sand_border_bend_LU1:
			{
				for (uint i = 0; i < Rock_bend_Vertices.length; i++) {
					Vertex v = Rock_bend_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_bend_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_bend_IDs[i] ); }

				lastID += Rock_bend_Vertices.length;
				map_shapes.PushAShape(bend_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_bend_RU1:
			{
				for (uint i = 0; i < Rock_bend_Vertices.length; i++) {
					Vertex v = Rock_bend_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_bend_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_bend_IDs[i] ); }

					lastID += Rock_bend_Vertices.length;
				map_shapes.PushAShape(bend_Shape, tile_center, offset);
			}break;

			case CMap::rock_sand_border_bend_RD1:
			{
				for (uint i = 0; i < Rock_bend_Vertices.length; i++) {
					Vertex v = Rock_bend_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_bend_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_bend_IDs[i] ); }

					lastID += Rock_bend_Vertices.length;
				map_shapes.PushAShape(bend_Shape, tile_center, offset,270);	
			}break;

			case CMap::rock_sand_border_bend_LD1:
			{
				for (uint i = 0; i < Rock_bend_Vertices.length; i++) {
					Vertex v = Rock_bend_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_bend_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_bend_IDs[i] ); }

					lastID += Rock_bend_Vertices.length;
				map_shapes.PushAShape(bend_Shape, tile_center, offset,180);
			}break;

			//diagonal choke points
			case CMap::rock_sand_border_diagonal_R1:
			{
				for (uint i = 0; i < Rock_diagonal_Vertices.length; i++) {
					Vertex v = Rock_diagonal_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_diagonal_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_diagonal_IDs[i] ); }

				lastID += Rock_diagonal_Vertices.length;				
				map_shapes.PushAShape(diagonal_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_diagonal_L1:
			{
				for (uint i = 0; i < Rock_diagonal_Vertices.length; i++) {
					Vertex v = Rock_diagonal_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_diagonal_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_diagonal_IDs[i] ); }

				lastID += Rock_diagonal_Vertices.length;
				map_shapes.PushAShape(diagonal_Shape, tile_center, offset, 90);	
			}break;

			//straight edge shorelines
			case CMap::rock_sand_border_straight_R1:
			{
				for (uint i = 0; i < Rock_straight_Vertices.length; i++) {
					Vertex v = Rock_straight_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_straight_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_straight_IDs[i] ); }

				lastID += Rock_straight_Vertices.length;
				map_shapes.PushAShape(straight_Shape, tile_center, offset, 270);
			}break;

			case CMap::rock_sand_border_straight_U1:
			{
				for (uint i = 0; i < Rock_straight_Vertices.length; i++) {
					Vertex v = Rock_straight_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_straight_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_straight_IDs[i] ); }

				lastID += Rock_straight_Vertices.length;
				map_shapes.PushAShape(straight_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_straight_L1:
			{
				for (uint i = 0; i < Rock_straight_Vertices.length; i++) {
					Vertex v = Rock_straight_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_straight_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_straight_IDs[i] ); }

				lastID += Rock_straight_Vertices.length;
				map_shapes.PushAShape(straight_Shape, tile_center, offset,90);
			}break;

			case CMap::rock_sand_border_straight_D1:
			{
				for (uint i = 0; i < Rock_straight_Vertices.length; i++) {
					Vertex v = Rock_straight_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_straight_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_straight_IDs[i] ); }

				lastID += Rock_straight_Vertices.length;
				map_shapes.PushAShape(straight_Shape, tile_center, offset,180);
			}break;
				
			//convex shorelines
			case CMap::rock_sand_border_convex_LU1:
			{
				//RocksMeshBuffer.LoadObjIntoMesh("RockCorner1.obj");

				for (uint i = 0; i < Rock_Corner_Vertices.length; i++) {
					Vertex v = Rock_Corner_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); 
				}

				for (uint i = 0; i < Rock_Corner_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_Corner_IDs[i] );
            	}

					lastID += Rock_Corner_Vertices.length;
					map_shapes.PushAShape(corner_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_convex_RU1:
			{	
				for (uint i = 0; i < Rock_Corner_Vertices.length; i++) {
					Vertex v = Rock_Corner_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_Corner_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_Corner_IDs[i] ); }

				lastID += Rock_Corner_Vertices.length;
				map_shapes.PushAShape(corner_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_convex_RD1:
			{
				for (uint i = 0; i < Rock_Corner_Vertices.length; i++) {
					Vertex v = Rock_Corner_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_Corner_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_Corner_IDs[i] ); }

				lastID += Rock_Corner_Vertices.length;
				map_shapes.PushAShape(corner_Shape, tile_center, offset, 270);
			}break;

			case CMap::rock_sand_border_convex_LD1:
			{
				for (uint i = 0; i < Rock_Corner_Vertices.length; i++) {
					Vertex v = Rock_Corner_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_Corner_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_Corner_IDs[i] ); }

				lastID += Rock_Corner_Vertices.length;
				map_shapes.PushAShape(corner_Shape, tile_center, offset, 180);
			}break;
				
			//concave shorelines		
			case CMap::rock_sand_border_concave_RU1:
			{
				for (uint i = 0; i < Rock_concave_Vertices.length; i++) {
					Vertex v = Rock_concave_Vertices[i];
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_concave_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_concave_IDs[i] ); }

				lastID += Rock_concave_Vertices.length;
				map_shapes.PushAShape(concave_Shape, tile_center, offset, 0);
			}break;

			case CMap::rock_sand_border_concave_LU1:
			{
				for (uint i = 0; i < Rock_concave_Vertices.length; i++) {
					Vertex v = Rock_concave_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(90);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_concave_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_concave_IDs[i] ); }

				lastID += Rock_concave_Vertices.length;
				map_shapes.PushAShape(concave_Shape, tile_center, offset, 90);
			}break;

			case CMap::rock_sand_border_concave_LD1:
			{
				for (uint i = 0; i < Rock_concave_Vertices.length; i++) {
					Vertex v = Rock_concave_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(180);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_concave_IDs.length; i++) {			
					mountain_IDs.push_back(lastID+Rock_concave_IDs[i] ); }

				lastID += Rock_concave_Vertices.length;
				map_shapes.PushAShape(concave_Shape, tile_center, offset, 180);
			}break;

			case CMap::rock_sand_border_concave_RD1:
			{
				for (uint i = 0; i < Rock_concave_Vertices.length(); i++) {
					Vertex v = Rock_concave_Vertices[i];
					Vec2f np(v.x,v.z);
					np.RotateBy(270);
					v.x = np.x; v.z = np.y;
					v.x += pos_off.y; v.z += pos_off.x;
					mountain_Vertices.push_back( v ); }	

				for (uint i = 0; i < Rock_concave_IDs.length(); i++) {			
					mountain_IDs.push_back(lastID+Rock_concave_IDs[i] ); }

				lastID += Rock_concave_Vertices.length();
				map_shapes.PushAShape(concave_Shape, tile_center, offset, 270);
			}break;

		}	
	}
	map.set("Map_SAT_Info", @map_shapes);
 
 	if (mountain_Vertices.length() > 0)
 	{	 		
		RocksMeshBuffer.SetVertices(mountain_Vertices);
	    RocksMeshBuffer.SetIndices(mountain_IDs); 
 
	   	//RocksMesh.BuildMesh();
	    RocksMeshBuffer.SetDirty(Driver::VERTEX_INDEX);

	    RockMat.SetTexture("StoneTexture.png", 0);

	    RockMat.DisableAllFlags();
	    RockMat.SetFlag(SMaterial::COLOR_MASK, true);
	    RockMat.SetFlag(SMaterial::ZBUFFER, true);
	    RockMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
	    RockMat.SetFlag(SMaterial::BACK_FACE_CULLING, true);
	    //RockMat.SetMaterialType(SMaterial::SOLID);
	    //RockMat.SetFlag(SMaterial::LIGHTING, true);
	    //RockMat.SetEmissiveColor(SColor(255,255,0,180));
	    RocksMeshBuffer.SetMaterial(RockMat);
	}
}

const Vec2f[] peninsula_Shape =  
  { Vec2f(-4.0f,  8.0f),
	Vec2f(-4.0f, -2.0f),
	Vec2f(-2.0f, -4.0f),
	Vec2f( 2.0f, -4.0f),
	Vec2f( 4.0f, -2.0f),
	Vec2f( 4.0f,  8.0f)};

const Vec2f[] concave_Shape = 
{  Vec2f(-8.0f,-8.0f),
   Vec2f( 4.0f,-8.0f),
   Vec2f( 8.0f,-4.0f),
   Vec2f( 8.0f, 8.0f),
   Vec2f(-8.0f, 8.0f)};

const Vec2f[] corner_Shape = 
{   
	Vec2f(-8.0f, 8.0f),
	Vec2f(-8.0f,-4.0f),
	Vec2f(-1.0f,-3.0f),
	Vec2f( 3.0f, 1.0f),
	Vec2f( 4.0f, 8.0f)};

const Vec2f[] straight_Shape = 
{	Vec2f(-8.0f,-4.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 8.0f),
	Vec2f(-8.0f, 8.0f)};

const Vec2f[] diagonal_Shape =
{	Vec2f(-8.0f,-8.0f),
	Vec2f( 4.0f,-8.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 8.0f),
	Vec2f(-4.0f, 8.0f),
	Vec2f(-8.0f, 4.0f)};

const Vec2f[] bend_Shape = 
{   Vec2f(-4.0f, 8.0f),
	Vec2f(-8.0f, 4.0f),
	Vec2f(-8.0f,-4.0f),
	Vec2f(-1.0f,-3.0f),
	Vec2f( 3.0f, 1.0f),
	Vec2f( 4.0f, 8.0f)};

const Vec2f[] strip_Shape = 
{	Vec2f(-8.0f,-4.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 4.0f),
	Vec2f(-8.0f, 4.0f)};

const Vec2f[] choke_Shape = 
{	Vec2f(-8.0f,-4.0f),
 	Vec2f(-4.0f,-8.0f),
	Vec2f( 4.0f,-8.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 8.0f),
	Vec2f(-8.0f, 8.0f)};

const Vec2f[] split_Shape = 
{	Vec2f(-8.0f,-4.0f),
	Vec2f(-4.0f,-8.0f),
	Vec2f( 4.0f,-8.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 4.0f),
	Vec2f( 4.0f, 8.0f),
	Vec2f(-8.0f, 8.0f)};

const Vec2f[] panhandle_r_Shape = 
{	Vec2f(-8.0f, 8.0f),
	Vec2f(-8.0f,-4.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 4.0f),
	Vec2f( 4.0f, 8.0f)};

const Vec2f[] panhandle_l_Shape = 
{	Vec2f(-4.0f, 8.0f),
	Vec2f(-8.0f, 4.0f),
	Vec2f(-8.0f,-4.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 8.0f)};

const Vec2f[] cross_Shape = 
{	Vec2f(-8.0f,-4.0f),
	Vec2f(-4.0f,-8.0f),
	Vec2f( 4.0f,-8.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 4.0f),
	Vec2f( 4.0f, 8.0f),
	Vec2f(-4.0f, 8.0f),
	Vec2f(-8.0f, 4.0f)};

const Vec2f[] island_Shape = 
{	Vec2f(-6.0f, -3.0f),
	 Vec2f(-3.0f, -6.0f),
	 Vec2f( 3.0f, -6.0f),
	 Vec2f( 6.0f, -3.0f),
	 Vec2f( 6.0f,  3.0f),
	 Vec2f( 3.0f,  6.0f),
	 Vec2f(-3.0f,  6.0f),
	 Vec2f(-6.0f,  3.0f)};

const Vec2f[] tee_Shape = 
{	Vec2f(-8.0f,-4.0f),
	Vec2f( 8.0f,-4.0f),
	Vec2f( 8.0f, 4.0f),
	Vec2f( 4.0f, 8.0f),
	Vec2f(-4.0f, 8.0f),
	Vec2f(-8.0f, 4.0f)};

