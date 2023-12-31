
//#define SERVER_ONLY
#include "ShapeArrays.as";
//#include "OctTree.as";
//#include "BoundingSphere.as";

void onInit(CRules@ this)
{
	//server_CreateBlob3D("BlockTest", Vec3f(48, 16, 48));
}

void onCommand(CRules@ this, uint8 cmd, CBitStream@ params)
{
	//if(cmd == this.getCommandID("CreateBlob3D"))
	//{
	//}	
}

Blob3D[]@ b3ds;

void server_CreateBlob3D(string name, Vec3f Pos, int Team = -1)
{
	string filename = name+".cfg";
	ConfigFile cfg;

	bool loaded = false;
	if (CFileMatcher(filename).getFirst() == filename && cfg.loadFile(filename)) { loaded = true; }
	else if (cfg.loadFile(filename)) { loaded = true; }
	if (!loaded) { return; }

	string blobname = cfg.read_string("$name");
	string texturename = cfg.read_string("$sprite_texture");

	string mesh_vertices = cfg.read_string("$mesh_vertices");
	string mesh_ids = cfg.read_string("$mesh_ids");

	Mesh mesh = Mesh(texturename, GrassVertices, GrassFace_IDs, true);
	SAT_Shape shape = SAT_Shape(null, square_Shape, Pos, false, 0, 10, true, 0);

	Blob3D newBlob = Blob3D(Pos, 0, 2.0f, mesh, shape);
	if ( newBlob !is null )
	{
		b3ds.push_back(newBlob);
	}
}