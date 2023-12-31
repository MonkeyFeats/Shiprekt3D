#include "Ray.as"
#include "Plane.as"
#include "Matrix.as"
#include "Blob3D.as"
#include "Transform.as"
//#include "Tree.as";
//#include "World.as"
//#include "BoundingFrustum.as"

shared class Camera3D
{
	//u16 ownerPlayerID
	Matrix4 view;
	Matrix4 projection;

	float fov;
	float z_near;
	float z_far;

    RigidTransform transform();

	Blob3D@ targetBlob;
	float mouseSensitivity;
	float posLag;
	bool locked;
	
	Vec3f pos_offset;

	//BoundingFrustum frustum;	
	
	Camera3D()
	{
		//Matrix::MakeIdentity(view);
		Matrix4 view = Matrix4();
		
		//pos_offset = Vec3f(0, 24, 20);
		pos_offset = Vec3f(0, 6, 20);
		
		fov = 1.745329;
		z_near = 0.01f;
		z_far = 10000.0f;
		f64 AspectRatio = f64(getDriver().getScreenWidth()) / f64(getDriver().getScreenHeight());

		projection.buildProjectionMatrixPerspectiveFovRH(fov, AspectRatio, z_near, z_far);
	}

	Blob3D@ getTarget() {return @this.targetBlob;}
	void setTarget(Blob3D@ _blob) {@this.targetBlob = _blob; }
	void setLocked(bool _locked) {this.locked = _locked;}

	void setPosition(Vec3f _pos) {this.transform.Position = _pos;}
	Vec3f getPosition() {return this.transform.Position;}

	//Vec3f getInterpolatedPosition() {return this.old_pos.Lerp(this.pos, getRenderApproximateCorrectionFactor());}

	void setRotation(Vec3f _dir) {this.transform.Orientation.Transform(_dir);}
	void setRotation(float x, float y, float z) {this.transform.Orientation.Transform(Vec3f(x,y,z));}
	Vec3f getRotation() {return this.transform.Orientation.getXYZ();}

	void onTick() {}
	
	void render_update()
	{
		updateViewMatrix();
	}

	void updateViewMatrix()
	{
		if (this.targetBlob !is null)
		{
			view.buildCameraLookAtMatrixRH(this.getPosition(), this.targetBlob.getPosition()+Vec3f(0,pos_offset.y,0), Vec3f(0,1,0));
		}
		else
		{
			//Matrix4 temp_mat = Matrix4();
			//Matrix4 temp_mat2 = Matrix4();
//
			////temp_mat.SetRotationXDegrees( getRotation().x );
			////temp_mat2.SetRotationYDegrees( -getRotation().y );
			////temp_mat.Multiply(MatrixR(temp_mat2));
//
			//temp_mat.setRotationDegrees(getRotation()); //temp_mat.CreateFromYawPitchRoll(getRotation());
//
			//Matrix4 trans_mat = Matrix4();
			//trans_mat.setInverseTranslation(getPosition());
			//trans_mat.opMulAssign(temp_mat);
//
			//view = trans_mat;

			view.buildCameraLookAtMatrixRH(this.getPosition(), this.getPosition()+Vec3f(5,pos_offset.y,5), Vec3f(0,1,0));
		}	
	}

//	Ray GetRayFromScreenPoint(float screenX, float screenY)
//    {
//    	Driver@ driver = getDriver();
//        const f32 Width = driver.getScreenWidth(); 
//		const f32 Height = driver.getScreenHeight();
//		const f32 ScaleFactorX = driver.getScreenWidthRatio();
//		const f32 ScaleFactorY = driver.getScreenHeightRatio();
//
//        // Normalized Device Coordinates Top-Left (-1, 1) to Bottom-Right (1, -1)
//        float x = (2.0f * screenX) / (Width / ScaleFactorX) - 1.0f;
//        float y = 1.0f - (2.0f * screenY) / (Height / ScaleFactorY);
//        float z = 1.0f;
//        Vec3f deviceCoords = Vec3f(x, y, z);
//
//        // Clip Coordinates
//        Vec4f clipCoords = Vec4f(deviceCoords.x, deviceCoords.y, -1.0f, 1.0f);
//
//        // View Coordinates
//        MatrixR invProj = this.projection.Invert();
//        Vec4f viewCoords = invProj.Transform(clipCoords);
//        viewCoords.z = -1.0f;
//        viewCoords.w = 0.0f;
//
//        MatrixR invView = view.Invert();
//        Vec3f worldCoords = invView.Transform(viewCoords).getXYZ();
//        worldCoords.normalize();
//
//        return Ray(this.transform.Position, worldCoords);
//    }
}

float getInterGameTime()
{
	return getRules().get_f32("interGameTime");
}

float getInterFrameTime()
{
	return getRules().get_f32("interFrameTime");
}