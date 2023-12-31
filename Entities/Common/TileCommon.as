//Tile Common
#include "CustomBlocks.as";

bool isTouchingLand( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;
	return tileType < CMap::water_1;
}

bool isTouchingRock( Vec2f pos )
{	
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;

	return tileType >= CMap::rock && tileType <= CMap::rock_shoal_border_diagonal_L1;
}

bool isTouchingShoal( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;
	return tileType >= CMap::water_1 && tileType <= CMap::water_2;
}

bool isInWater( Vec2f pos )
{
	CMap@ map = getMap();
	u16 tileType = map.getTile( pos ).type;

	return tileType > CMap::water_4 && tileType <= CMap::water;
}