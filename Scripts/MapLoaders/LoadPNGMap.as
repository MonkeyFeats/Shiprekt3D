#include "CustomMap.as";

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING PNG MAP " + fileName);

	PNGLoader loader();

	return loader.loadMap(map, fileName);
}