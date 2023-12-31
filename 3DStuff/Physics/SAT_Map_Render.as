//just for testing, draws map shapes with lines
#include "SAT_Shapes.as"

void onRender(CRules@ this)
{
	Map_SAT_Shapes@ map_shapes;
	if (getMap().get("Map_SAT_Info", @map_shapes))
	{
		map_shapes.Render();
	}	
}