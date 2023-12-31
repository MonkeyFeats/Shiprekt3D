
#include "TypeEnums.as"
#include "BoundingBox.as"
#include "BoundingFrustum.as"
#include "Matrix.as"
#include "Plane.as"
#include "Ray.as"
#include "Shapes3D.as"

#include "ShapeArrays.as"

shared class BoundingSphere : BoundingShape
{
    double Radius;

    SMesh@ SphereMesh = SMesh();
    SMeshBuffer@ SphereMeshBuffer = SMeshBuffer();
    SMaterial@ SphereMat = SMaterial();
    BoundingShape@ hitsphere;    

    BoundingSphere(){}

    BoundingSphere(double _radius)
    {
        this.Radius = _radius;
        UpdateAttributes(SColor(150, 0, 255, 0));

        @hitsphere = BoundingSphere(this.transform.Position, 1.0);
        model.makeIdentity(); 
    }

    BoundingSphere(Vec3f _Position, double _radius)
    {
        super(_Position);
        this.Radius = _radius;
        UpdateAttributes(SColor(150, 0, 255, 0));
        model.makeIdentity(); 
    }    

    void UpdateAttributes(SColor col) override
    {
        Vertex[] _Verts = Sphere_Vertices();

        for(uint i = 0; i < _Verts.size(); i++)
        {
            Vertex sv = _Verts[i];
            _Verts[i] = Vertex( (sv.x*Radius), (sv.y*Radius), (sv.z*Radius), sv.u, sv.v, col);
        }

        u16[] ids = Sphere_IDs();

        SphereMeshBuffer.SetVertices(_Verts);
        SphereMeshBuffer.SetIndices(ids); 
        //SphereMesh.BuildMesh();
        SphereMeshBuffer.SetDirty(Driver::VERTEX_INDEX);

        SphereMat.DisableAllFlags();
        SphereMat.SetFlag(SMaterial::COLOR_MASK, true);
        SphereMat.SetFlag(SMaterial::ZBUFFER, true);
        SphereMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
        SphereMat.SetFlag(SMaterial::BACK_FACE_CULLING, false);
        //SphereMat.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA );
        SphereMat.SetFlag(SMaterial::WIREFRAME, true);
        //SphereMat.SetFlag(SMaterial::LIGHTING, true);
        //SphereMat.SetEmissiveColor(SColor(255,255,0,180));
        SphereMeshBuffer.SetMaterial(SphereMat);
        SphereMesh.AddMeshBuffer( SphereMeshBuffer );
    }

    void setPosition(Vec3f &in pos) override {model.setTranslation(pos);}
    Vec3f getPosition() override {return model.getTranslation();}

    void Render() override
    { 
        f32[] marray; model.getArray(marray);
        Render::SetModelTransform(marray);
        SphereMesh.DrawWithMaterial();  

        if (hitsphere !is null)
        hitsphere.Render(); 
    }


    BoundingSphere Transform(MatrixR matrix)
    {
        BoundingSphere sphere();
        sphere.setPosition(this.getPosition());
        sphere.Radius = this.Radius * double(Maths::Sqrt(double(Maths::Max(((matrix.Array[0] * matrix.Array[0]) + (matrix.Array[1] * matrix.Array[1])) + (matrix.Array[2] * matrix.Array[2]), Maths::Max(((matrix.Array[4] * matrix.Array[4]) + (matrix.Array[5] * matrix.Array[5])) + (matrix.Array[6] * matrix.Array[6]), ((matrix.Array[8] * matrix.Array[8]) + (matrix.Array[9] * matrix.Array[9])) + (matrix.Array[10] * matrix.Array[10]))))));
        return sphere;
    }

    void Transform(MatrixR matrix, BoundingSphere &out result)
    {
        result.setPosition(this.getPosition());
        result.Radius = this.Radius * double(Maths::Sqrt(double(Maths::Max(((matrix.Array[0] * matrix.Array[0]) + (matrix.Array[1] * matrix.Array[1])) + (matrix.Array[2] * matrix.Array[2]), Maths::Max(((matrix.Array[4] * matrix.Array[4]) + (matrix.Array[5] * matrix.Array[5])) + (matrix.Array[6] * matrix.Array[6]), ((matrix.Array[8] * matrix.Array[8]) + (matrix.Array[9] * matrix.Array[9])) + (matrix.Array[10] * matrix.Array[10]))))));
    }

//    ContainmentType Contains(BoundingBox@ box, Vec3f Vel, Vec3f &out MTV) override
//    {
//        Vec3f omin = (box.Position+box.Min);
//        Vec3f omax = (box.Position+box.Max);
//
//        //check if all corner is in sphere
//        bool inside = true;
//        Vec3f[] corners = box.GetCorners();
//
//        //for(int i = 0; i < corners.length(); i++)
//        //{
//        //    Vec3f corner = corners[i];
//        //    if (this.Contains(corner) == ContainmentType::None)
//        //    {
//        //        inside = false;
//        //        break;
//        //    }
//        //}
//
//        //if (inside)
//        //    return ContainmentType::Contains;
//
//        //check if the distance from sphere Position to cube face < radius
//        double dmin = 0;          
//
//        if (Position.x < omin.x)
//        {
//			dmin += (Position.x - omin.x)*(Position.x - omin.x);
//        }
//		else if (Position.x > omax.x)
//        {
//			dmin += (Position.x - omax.x)*(Position.x - omax.x);
//        }
//
//		if (Position.y < omin.y)
//        {
//			dmin += (Position.y - omin.y)*(Position.y - omin.y);
//        }
//		else if (Position.y > omax.y)
//        {
//			dmin += (Position.y - omax.y)*(Position.y - omax.y);
//        }
//
//		if (Position.z < omin.z)
//        {
//			dmin += (Position.z - omin.z)*(Position.z - omin.z);
//        }
//		else if (Position.z > omax.z)
//        {
//			dmin += (Position.z - omax.z)*(Position.z - omax.z);
//        }
//
//		if (dmin <= (Radius*Radius))
//        {
//            double overlap = ((Radius*Radius)-(dmin));
//            print("overlap "+overlap);
//            Vec3f mtvAxis = (Position-box.Position).Normalize(); 
//            //mtvAxis.Normalize();
//            mtvAxis.Print();
//            MTV = mtvAxis*overlap;
//
//            return ContainmentType::Intersects;
//        }
//        
//        //else null
//        return ContainmentType::None;
//
//    }

       //Vec3f localPosition = box.transform.TransformByInverse(this.getPosition());
       //Vec3f localClosestPoint = localPosition.clamp(box.Min, box.Max); // ContactPosition
       //Vec3f ContactPosition = box.transform.Transform(localClosestPoint);
       //hitsphere.transform.Position = ContactPosition;
       //Vec3f offset = this.getPosition() - ContactPosition;


//  these should be in matrix
//   Vec3f rotateVect( Vec3f vect, Matrix4 mod ) const
//   {
//       f32[] marray; mod.getArray(marray);
//       Vec3f tmp = vect;
//       vect.x = tmp.x*mod[0] + tmp.y*mod[4] + tmp.z*mod[8];
//       vect.y = tmp.x*mod[1] + tmp.y*mod[5] + tmp.z*mod[9];
//       vect.z = tmp.x*mod[2] + tmp.y*mod[6] + tmp.z*mod[10];
//       return vect;
//   }
//   Vec3f rotateVectInv( Vec3f vect, Matrix4 mod ) const
//   {
//       f32[] marray; mod.getArray(marray);
//       Vec3f tmp = vect;
//        vect.x = tmp.x*mod[0] + tmp.y*mod[1] + tmp.z*mod[2];
//        vect.y = tmp.x*mod[4] + tmp.y*mod[5] + tmp.z*mod[6];
//        vect.z = tmp.x*mod[8] + tmp.y*mod[9] + tmp.z*mod[10];
//       return vect;
//   }

    ContainmentType Contains(BoundingBox@ box, Vec3f Vel, Vec3f &out MTV) override
    {
        Vec3f localPosition = this.model.getTranslation()-box.model.getTranslation();
        localPosition = Vec3f(localPosition.x*box.model[0] + localPosition.y*box.model[1] + localPosition.z*box.model[2],   //inverseRotateVect to matrix rotation
                              localPosition.x*box.model[4] + localPosition.y*box.model[5] + localPosition.z*box.model[6], 
                              localPosition.x*box.model[8] + localPosition.y*box.model[9] + localPosition.z*box.model[10]);  

        Vec3f localClosestPoint = localPosition.clamp(box.Min, box.Max); 
        localClosestPoint = Vec3f(localClosestPoint.x*box.model[0] + localClosestPoint.y*box.model[4] + localClosestPoint.z*box.model[8], //RotateVect to matrix rotation
                                  localClosestPoint.x*box.model[1] + localClosestPoint.y*box.model[5] + localClosestPoint.z*box.model[9],
                                  localClosestPoint.x*box.model[2] + localClosestPoint.y*box.model[6] + localClosestPoint.z*box.model[10]); 

        Vec3f ContactPosition = box.getPosition()+localClosestPoint;        
        hitsphere.model.setTranslation(ContactPosition);

        Vec3f offset = this.getPosition() - ContactPosition;

        float offsetLength = offset.lengthSquared();

        if (offsetLength > (Radius*Radius))
        {
            return ContainmentType::None;
        }

        //intersecting the box.
        if (offsetLength > MathsHelper::Epsilon)
        {            
            offsetLength = float(Maths::Sqrt(offsetLength));

            Vec3f Normal = offset/offsetLength;
            double depth = Radius - offsetLength;
            Normal.normalize();
            MTV = Normal*depth;
            return ContainmentType::Intersects;
        }
        // else //Inside of the box.
        //{
            
            Vec3f Normal;
            double depth;
            Vec3f penetrationDepths;
            penetrationDepths.x = localClosestPoint.x < 0 ? localClosestPoint.x + box.Min.x : box.Max.x - localClosestPoint.x;
            penetrationDepths.y = localClosestPoint.y < 0 ? localClosestPoint.y + box.Min.y : box.Max.y - localClosestPoint.y;
            penetrationDepths.z = localClosestPoint.z < 0 ? localClosestPoint.z + box.Min.z : box.Max.z - localClosestPoint.z;
            if (penetrationDepths.x < penetrationDepths.y && penetrationDepths.x < penetrationDepths.z)
            {
                Normal = localClosestPoint.x > 0 ? Vec3f(1,0,0) : Vec3f(-1,0,0); 
                depth = penetrationDepths.x;
            }
            else if (penetrationDepths.y < penetrationDepths.z)
            {
                Normal = localClosestPoint.y > 0 ? Vec3f(0,1,0) : Vec3f(0,-1,0); 
                depth = penetrationDepths.y;
            }
            else
            {
                Normal = localClosestPoint.z > 0 ? Vec3f(0,0,-1) : Vec3f(0,0,1); 
                depth = penetrationDepths.x;
            }
            Quaternion orientation = QuaternionFromEuler(box.model.getRotationDegrees());
            Normal = orientation.Transform(Normal);
            depth += Radius;
            MTV = Normal*depth;
            return ContainmentType::Contains;
        //}
        //return ContainmentType::None;
    }

//void sphereCollisionResponse(Sphere *a, Sphere *b)
//{
//    Vector3 U1x,U1y,U2x,U2y,V1x,V1y,V2x,V2y;
//
//
//    float m1, m2, x1, x2;
//    Vector3 v1temp, v1, v2, v1x, v2x, v1y, v2y, x(a->pos - b->pos);
//
//    x.normalize();
//    v1 = a->vel;
//    x1 = x.dot(v1);
//    v1x = x * x1;
//    v1y = v1 - v1x;
//    m1 = a->mass;
//
//    x = x*-1;
//    v2 = b->vel;
//    x2 = x.dot(v2);
//    v2x = x * x2;
//    v2y = v2 - v2x;
//    m2 = b->mass;
//
//    a->vel = Vector3( v1x*(m1-m2)/(m1+m2) + v2x*(2*m2)/(m1+m2) + v1y );
//    b->vel = Vector3( v1x*(2*m1)/(m1+m2) + v2x*(m2-m1)/(m1+m2) + v2y );
//}
//
    ContainmentType Contains(BoundingFrustum frustum)
    {
        //check if all corner is in sphere
        bool inside = true;

        Vec3f[] corners = frustum.corners;

        for(int i = 0; i < corners.length(); i++)
        {
            Vec3f corner = corners[i];
            if (this.Contains(corner) == ContainmentType::None)
            {
                inside = false;
                break;
            }
        }
        if (inside)
            return ContainmentType::Contains;

        //check if the distance from sphere Position to frustrum face < radius
        double dmin = 0;
        //TODO : calcul dmin

        if (dmin <= Radius * Radius)
            return ContainmentType::Intersects;

        //else null
        return ContainmentType::None;
    }

    ContainmentType Contains(BoundingSphere sphere)
    {
        double val = (sphere.getPosition()-getPosition()).length();

        if (val > sphere.Radius + Radius)
            return ContainmentType::None;

        else if (val <= Radius - sphere.Radius)
            return ContainmentType::Contains;

        else
            return ContainmentType::Intersects;
    }

    void Contains(BoundingSphere@ sphere, int &out result)
    {
        result = Contains(sphere);
    }

    ContainmentType Contains(Vec3f point)
    {
        double distance = (point-getPosition()).length();

        if (distance > this.Radius)
            return ContainmentType::None;

        else if (distance < this.Radius)
            return ContainmentType::Contains;

        return ContainmentType::Intersects;
    }

    void Contains(Vec3f point, ContainmentType &out result)
    {
        result = Contains(point);
    }    

    //int GetHashCode()
    //{
    //    return this.Position.GetHashCode() + this.Radius.GetHashCode();
    //}

    bool Intersects(BoundingBox box)
    {
		return box.Intersects(this);
    }

    //bool Intersects(BoundingFrustum frustum)
    //{
    //    if (frustum is null)
    //        throw NullReferenceException();
    //    throw NotImplementedException();
    //}

    //bool Intersects(BoundingSphere sphere)
    //{
    //    double val = (sphere.Position-Position).Length();
	//	if (val > sphere.Radius + Radius)
	//		return false;
	//	return true;
    //}

    //bool Intersects(BoundingSphere sphere)
    //{
	//	return Intersects(sphere);
    //}

    PlaneIntersectionType Intersects(Plane plane)
    {
		double distance = plane.Normal.opMul(this.getPosition()) + plane.D;
		if (distance > this.Radius)
			return PlaneIntersectionType::Front;
		if (distance < -this.Radius)
			return PlaneIntersectionType::Back;
		//else it intersect
		return PlaneIntersectionType::Intersecting;
    }

    void Intersects(Plane plane, PlaneIntersectionType &out result)
    { result = Intersects(plane); }

    bool Intersects(Ray ray)
    { return ray.Intersects(this); }

    void Intersects(Ray ray, bool &out result)
    { result = this.Intersects(ray); }

    bool Equals(BoundingSphere other)
    { return this.getPosition() == other.getPosition() && this.Radius == other.Radius; }
    
    bool opEquals(BoundingSphere a, BoundingSphere b)
    { return a.Equals(b); }

    bool opNotEquals(BoundingSphere a, BoundingSphere b)
    { return !a.Equals(b); }

}

BoundingSphere CreateFromBoundingBox(BoundingBox@ box)
{
    // Find the Position of the box.
    Vec3f Position = Vec3f((box.Min.x + box.Max.x) / 2.0f,
                           (box.Min.y + box.Max.y) / 2.0f,
                           (box.Min.z + box.Max.z) / 2.0f);

    // Find the distance between the Position and one of the corners of the box.
    double radius = (Position-box.Max).length();
    return BoundingSphere(Position, radius);
}

//BoundingSphere CreateFromFrustum(BoundingFrustum@ frustum)
//{
//    return CreateFromPoints(frustum.GetCorners());
//}

BoundingSphere CreateFromPoints(Vec3f[] points)
{
    if (points.size() < 8)
    {
        warn("CreateFromPoints, needs more points");
    }

    float radius = 0;
    Vec3f Position = Vec3f();
    // First, we'll find the Position of gravity for the point 'cloud'.
    int num_points = points.size(); // The number of points (there MUST be a better way to get this instead of counting the number of points one by one?)
    
    for (int i = 0; i < num_points; ++i)
    {
        Vec3f v = points[i];
        Position += v;    // If we actually kthe number of points, we'd get better accuracy by adding v / num_points.
    }
    
    Position /= num_points;

    // Calculate the radius of the needed sphere (it equals the distance between the Position and the point further away).
    for (int i = 0; i < num_points; ++i)
    {
        Vec3f v  = points[i];
        float distance = (v - Position).length();
        
        if (distance > radius)
            radius = distance;
    }

    return BoundingSphere(Position, radius);
}

BoundingSphere CreateMerged(BoundingSphere original, BoundingSphere additional)
{
    Vec3f oPositionToaPosition = (additional.getPosition() - original.getPosition());
    float distance = oPositionToaPosition.length();
    if (distance <= original.Radius + additional.Radius)//intersect
    {
        if (distance <= original.Radius - additional.Radius)//original contain additional
            return original;
        if (distance <= additional.Radius - original.Radius)//additional contain original
            return additional;
    }

    //else find Position of sphere and radius
    double leftRadius = Maths::Max(original.Radius - distance, additional.Radius);
    double Rightradius = Maths::Max(original.Radius + distance, additional.Radius);
    oPositionToaPosition += (oPositionToaPosition * (2 * distance)) / (leftRadius - Rightradius);//oPositionToResultPosition
    
    BoundingSphere result = BoundingSphere();
    result.transform.Position = original.getPosition() + oPositionToaPosition;
    result.Radius = (leftRadius + Rightradius) / 2;
    return result;
}
