#include "IslandsCommon.as";
#include "HumanCommon.as";
#include "ShapeArrays.as";
#include "RunnerTextures.as";

SColor col = color_white;
float[] model;

void RenderProps(float dirX, float dirY, f32 waterheight)
{	
	u16 angle;
	//if (angle < 180)
	{
		angle+=0.00002;
	}
	//else {angle = 0;}

	CBlob@[] props;
	getBlobsByTag("prop", @props);
	for(int i = 0; i < props.length; i++)
	{
		CBlob@ prop = props[i];
		if(prop !is null)
		{
			//Render::RawTrianglesIndexed(this.texture, this.v_raw, this.v_i);
			int id = prop.get_u8("ID");
			Matrix::MakeIdentity(model);						

			switch (id)
			{
				case 14:	// flak topper
				{					
					Matrix::SetTranslation(model, prop.getInterpolatedPosition().x, 0.45+waterheight, prop.getInterpolatedPosition().y);
					Matrix::SetRotationDegrees(model, 0 , prop.get_f32("angle") , 0);
					Render::SetModelTransform(model);
					Render::RawTrianglesIndexed("BlockTextures.png", FlakCannon_Vertices, FlakCannon_IDs);
					break;
				}
//				case 9:	// engine blades || 8
//				{					
//					Vec2f pivot(0.0, 0.9);
//					pivot.RotateBy(prop.getAngleDegrees());
//
//					float ang = prop.get_f32("blade angle");
//					float power = prop.get_f32("power");
//					bool on = prop.get_bool("on");
//
//					Matrix::SetTranslation(model, pivot.x+prop.getInterpolatedPosition().x, -0.55, pivot.x+prop.getInterpolatedPosition().y);
//					Matrix::SetRotationDegrees(model, ang , prop.getAngleDegrees() , 0);
//					Render::SetModelTransform(model);
//					Render::RawTrianglesIndexed("BlockTextures.png", Propellerblades_Vertices, Propellerblades_IDs);
//
//					if (on)
//					{
//						Render::SetBackfaceCull(false);
//						Matrix::SetTranslation(model, pivot.x+prop.getInterpolatedPosition().x, -0.55, pivot.x+prop.getInterpolatedPosition().y);
//						Matrix::SetRotationDegrees(model, 0 , prop.getAngleDegrees() , 0);
//						Render::SetModelTransform(model);
//						Render::RawTrianglesIndexed("water_wake.png", WakePlane_Vertices, Square_IDs());
//						Render::SetBackfaceCull(true);
//					}
//					break;
//				}

				case 48: // bullet
				{					
					Matrix::SetTranslation(model, prop.getInterpolatedPosition().x, 0, prop.getInterpolatedPosition().y);
					Matrix::SetRotationDegrees(model, -dirY, dirX, 0);
					Render::SetModelTransform(model);
					Render::RawTrianglesIndexed("Bullet.png", BulletVertices, DefaultTriangleFace);

					Blob3D@ blob3d;
					if (!prop.get("blob3d", @blob3d)) { return; }
					{
						blob3d.mesh.DrawWithMaterial();
						blob3d.shape.Render();
					}

					break;
				}
				case 56:	// Sunken Treasure
				{
					Matrix::SetTranslation(model, prop.getInterpolatedPosition().x, 0.03, prop.getInterpolatedPosition().y);
					Matrix::SetRotationDegrees(model, 0, prop.getAngleDegrees(), 0);
					Matrix::SetScale(model, 5.0, 1.0, 5.0);
					Render::SetModelTransform(model);
					Render::RawTrianglesIndexed("SunkShip.png", Floor_Vertices, Square_IDs());					
					break;
				}

				case 57:	// Sharky
				{
					Matrix::SetTranslation(model, prop.getInterpolatedPosition().x, -0.85, prop.getInterpolatedPosition().y);
					Matrix::SetRotationDegrees(model, 0, prop.getAngleDegrees(), 0);
					Render::SetModelTransform(model);
					Render::RawTrianglesIndexed("SharkTex.png", shark_bod_Vertices, shark_bod_IDs);

					Vec2f jaw_pivot(0.72, 0);
					jaw_pivot.RotateBy(prop.getAngleDegrees());

					Matrix::SetTranslation(model, jaw_pivot.x+prop.getInterpolatedPosition().x, -0.85-0.21, jaw_pivot.y+prop.getInterpolatedPosition().y);
					Render::SetModelTransform(model);
					Render::RawTrianglesIndexed("SharkTex.png", shark_jaw_Vertices, shark_jaw_IDs);	

					Vec2f tail_pivot(-0.5, 0);
					tail_pivot.RotateBy(prop.getAngleDegrees());

					Matrix::SetTranslation(model, tail_pivot.x+prop.getInterpolatedPosition().x, -0.85, tail_pivot.y+prop.getInterpolatedPosition().y);
					Matrix::SetRotationDegrees(model, 0, prop.getAngleDegrees()+ (Maths::Sin(getGameTime() * 0.15f) * 12), 0);
					Render::SetModelTransform(model);
					Render::RawTrianglesIndexed("SharkTex.png", shark_tail_Vertices, shark_tail_IDs);
					break;
				}
			}
			/*if (objects[id].billboard)
			{
				Matrix::SetTranslation(model, (prop.getInterpolatedPosition().y+prop.getHeight()/2), , (prop.getInterpolatedPosition().x+prop.getWidth()/2));
				Matrix::SetRotationDegrees(model, 0, dir, 0);
			}
			else
			{
				Matrix::SetTranslation(model, prop.getInterpolatedPosition().y, , prop.getInterpolatedPosition().x);
				Matrix::SetRotationDegrees(model, 0, prop.getAngleDegrees(), 0);
			}
			
			Render::SetModelTransform(model);
			objects[id].Draw(prop);
			
			if (id == 0)
			{
				Matrix::MakeIdentity(model);
				Matrix::SetTranslation(model, (prop.getInterpolatedPosition().y+prop.getHeight()/2), , (prop.getInterpolatedPosition().x+prop.getWidth()/2));
				Matrix::SetRotationDegrees(model, 0, prop.get_f32("dir_x")-45, 0);
				Render::SetModelTransform(model);
				Render::RawTrianglesIndexed("look.png", lookV, lookID);
			}*/
		}
	}
}

void RenderPlayers(Vec3f pos, float[] model)
{
	CBlob@[] blobs;
	getBlobsByName("human", @blobs);
	for(int i = 0; i < blobs.size(); i++)
	{
		CBlob@ blob = blobs[i];
		if(blob !is null)
		{
			Blob3D@ blob3d;
			if (!blob.get("blob3d", @blob3d)) { return; }
			Matrix::MakeIdentity(model);

			//Matrix::SetTranslation(model, blob3d.getPosition().x, blob3d.getPosition().y, blob3d.getPosition().z);
			//Matrix::SetRotationDegrees(model, 0, blob3d.look_dir.x, 0);
			Render::SetModelTransform(model);
			blob3d.shape.Render();	

			//if(blob.isMyPlayer()) continue;	
					
			//Matrix::MakeIdentity(model);
			//Matrix::SetTranslation(model, blob3d.getPosition().x, blob3d.getPosition().y, blob3d.getPosition().z);	
			////Matrix::SetRotationDegrees(model, 0, -blob3d.look_dir.x%360, 0);
			//Matrix::SetScale(model, 0.128, 0.128, 0.128);
			//Render::SetModelTransform(model);
			//blob3d.mesh.DrawWithMaterial();
		}
	}
}