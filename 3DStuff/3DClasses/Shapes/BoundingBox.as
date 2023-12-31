#include "TypeEnums.as"
#include "MathsHelper.as"
#include "Vec4f.as"
#include "Shapes3D.as"

shared class BoundingBox : BoundingShape
{
    Vec3f Min, Max;
    bool inside = false;

    SMesh@ BoxMesh = SMesh();
    SMeshBuffer@ BoxMeshBuffer = SMeshBuffer();
    SMaterial@ BoxMat = SMaterial();

    BoundingBox() {}

    void setPosition(Vec3f &in pos) override {model.setTranslation(pos);}
    Vec3f getPosition() override {return model.getTranslation();}

    void setDirection(Vec3f &in dir) override {model.setRotationDegrees(dir); }
    float getAngleDegrees() override {return model.getRotationDegrees().x;}
    Vec3f getDirection() override {return model.getRotationDegrees();}

    BoundingBox(Vec3f min, Vec3f max)
    {
        //super();
        this.Min = min;
        this.Max = max;
        UpdateAttributes(SColor(150, 10, 10, 10));
        model.makeIdentity(); 
    }

    BoundingBox(Vec3f min, Vec3f max, Vec3f Pos)
    {
        //super();
        this.Min = min;
        this.Max = max;
        this.transform.Position = Pos;
        UpdateAttributes(SColor(150, 10, 120, 10));

        f32[] test = {1,0,0,0,
                      0,1,0,0,
                      0,0,1,0,
                      0,0,0,1};

        model.makeIdentity(); 
    }

    void UpdateAttributes(SColor col) override
    {

        const Vertex[] _Verts = {
        Vertex( Max.x, Min.y, Min.z,  0, 0, col),
        Vertex( Max.x, Min.y, Max.z,  1, 0, col),
        Vertex( Min.x, Min.y, Max.z,  1, 1, col),
        Vertex( Min.x, Min.y, Min.z,  0, 1, col),
        Vertex( Max.x, Max.y, Min.z,  0, 1, col),
        Vertex( Max.x, Max.y, Max.z,  0, 0, col),
        Vertex( Min.x, Max.y, Max.z,  1, 0, col),
        Vertex( Min.x, Max.y, Min.z,  1, 1, col)
        };

        const u16[] _IDs = {0,1,3,1,2,3,
                            4,7,5,7,6,5,
                            0,4,1,4,5,1,
                            1,5,2,5,6,2,
                            2,6,3,6,7,3,
                            4,0,7,0,3,7};

        BoxMeshBuffer.SetVertices(_Verts);
        BoxMeshBuffer.SetIndices(_IDs); 
        //BoxMeshBuffer.BuildMesh();
        BoxMeshBuffer.SetDirty(Driver::VERTEX_INDEX);

        BoxMat.DisableAllFlags();
        BoxMat.SetFlag(SMaterial::COLOR_MASK, true);
        BoxMat.SetFlag(SMaterial::ZBUFFER, true);
        BoxMat.SetFlag(SMaterial::ZWRITE_ENABLE, true);
        BoxMat.SetFlag(SMaterial::BACK_FACE_CULLING, false);
        //BoxMat.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA );
        BoxMat.Thickness = 3.0f;
        BoxMat.SetFlag(SMaterial::WIREFRAME, true);
        //BoxMat.SetFlag(SMaterial::LIGHTING, true);
        //BoxMat.SetEmissiveColor(SColor(255,255,0,180));
        BoxMeshBuffer.SetMaterial(BoxMat);          
        BoxMesh.AddMeshBuffer( BoxMeshBuffer );      
    }

    void Render() override
    { 
       f32[] marray; model.getArray(marray);
       Render::SetModelTransform(marray);
       BoxMesh.DrawWithMaterial();
    }

    ContainmentType Contains(BoundingBox@ box, Vec3f Vel, Vec3f &out MTV) override //AABB
    {
        f32 mtvDistance = 9999999.9f;
        Vec3f mtvAxis = Vec3f();
        Vec3f b1p = this.getPosition();
        Vec3f b2p = box.getPosition();

        Vec3f VelPos = ((Vel+b1p));
        Vec3f min =  (b1p+Min);
        Vec3f max =  (b1p+Max);
        Vec3f omin = (b2p+box.Min);
        Vec3f omax = (b2p+box.Max);

        if ( min.x > omax.x || max.x < omin.x ) {return ContainmentType::None;}
        if ( min.z > omax.z || max.z < omin.z ) {return ContainmentType::None;}
        if ( min.y > omax.y || max.y < omin.y ) {return ContainmentType::None;}

        // Seperating Axis Theorum, find the smallest overlapped axis normal and return it multiplied by the overlap
        //xAxis
        {
            Vec3f axis(1,0,0);
            f32 d0x = (omax.x - min.x);   // 'Left' side
            f32 d1x = (max.x - omin.x);   // 'Right' side
            f32 overlap = (d0x < d1x) ? d0x : -d1x; //signed
            Vec3f sep = (axis * overlap); //
            f32 sepLengthSquared = sep.lengthSquared();   
         
            if (sepLengthSquared < mtvDistance)
            {
                mtvDistance = sepLengthSquared;
                mtvAxis = sep;
            }            
        }
        //yAxis
        {            
            Vec3f axis(0,1,0);
            f32 d0y = (omax.y - min.y);   // 'Left' side
            f32 d1y = (max.y - omin.y);   // 'Right' side
            f32 overlap = (d0y < d1y) ? d0y : -d1y;
            Vec3f sep = (axis * overlap);
            f32 sepLengthSquared = sep.lengthSquared();            
            if (sepLengthSquared < mtvDistance)
            {
                mtvDistance = sepLengthSquared;
                mtvAxis = sep;
            }
        }
        //zAxis
        {
            Vec3f axis(0,0,1);
            f32 d0z = (omax.z - min.z);   // 'Left' side
            f32 d1z = (max.z - omin.z);   // 'Right' side            
            f32 overlap = (d0z < d1z) ? d0z : -d1z;
            Vec3f sep = (axis * overlap);
            f32 sepLengthSquared = sep.lengthSquared();            
            if (sepLengthSquared < mtvDistance)
            {
                mtvDistance = sepLengthSquared;
                mtvAxis = sep;
            }
        }
        mtvAxis.normalize();
        mtvDistance = Maths::Sqrt(mtvDistance) * 1.001f;
        MTV = mtvAxis*mtvDistance;
        return ContainmentType::Intersects;
    }

    bool TestAxis(Vec3f axis, f32 minA, f32 maxA, f32 minB, f32 maxB, string axe, f32 mtvDistance_in, f32 &out mtvDistance_out, Vec3f &out mtvAxis)
    {
        mtvDistance_out = mtvDistance_in;
        f32 axisLengthSquared = axis.lengthSquared();

        f32 d0 = (maxB - minA);   // 'Left' side
        f32 d1 = (maxA - minB);   // 'Right' side

        if (d0 <= 0.0f || d1 <= 0.0f)
        {
            return false;
        }

        f32 overlap = (d0 < d1) ? d0 : -d1;
        Vec3f sep = (axis * (overlap / axisLengthSquared));
        f32 sepLengthSquared = sep.lengthSquared();
        
        if (sepLengthSquared < mtvDistance_in)
        {
            mtvDistance_out = sepLengthSquared;
            mtvAxis = sep;
        }

        print(axe+mtvDistance_out);

        return true;
    }

   // void Contains(BoundingBox box, ContainmentType &out result)
   // {
   //     result = Contains(box);
   // }

    ContainmentType Contains(BoundingFrustum@ frustum)
    {
        //TODO: bad done here need a fix. 
        //Because question is not frustum contain box but reverse and this is not the same
        int i;
        ContainmentType contained;
        Vec3f[] corners = frustum.corners;

        // First we check if frustum is in box
        for (i = 0; i < corners.size(); i++)
        {
            this.Contains(corners[i], contained);
            if (contained == ContainmentType::None)
                break;
        }

        if (i == corners.size()) // This means we checked all the corners and they were all contain or instersect
            return ContainmentType::Contains;

        if (i != 0)             // if i is not equal to zero, we can fastpath and say that this box intersects
            return ContainmentType::Intersects;


        // If we get here, it means the first (and only) point we checked was actually contained in the frustum.
        // So we assume that all other points will also be contained. If one of the points is null, we can
        // exit immediately saying that the result is Intersects
        i++;
        for (; i < corners.size(); i++)
        {
            this.Contains(corners[i], contained);
            if (contained != ContainmentType::Contains)
                return ContainmentType::Intersects;

        }

        // If we get here, then we know all the points were actually contained, therefore result is Contains
        return ContainmentType::Contains;
    }

    ContainmentType Contains(BoundingSphere sphere)
    {
        Vec3f sphereCenter = sphere.getPosition();
           if (sphereCenter.x - Min.x > sphere.Radius
            && sphereCenter.y - Min.y > sphere.Radius
            && sphereCenter.z - Min.z > sphere.Radius
            && Max.x - sphereCenter.x > sphere.Radius
            && Max.y - sphereCenter.y > sphere.Radius
            && Max.z - sphereCenter.z > sphere.Radius)
            return ContainmentType::Contains;

        double dMin = 0;

        if (sphereCenter.x - Min.x <= sphere.Radius)      dMin += (sphereCenter.x - Min.x) * (sphereCenter.x - Min.x);
        else if (Max.x - sphereCenter.x <= sphere.Radius) dMin += (sphereCenter.x - Max.x) * (sphereCenter.x - Max.x);
        if (sphereCenter.y - Min.y <= sphere.Radius)      dMin += (sphereCenter.y - Min.y) * (sphereCenter.y - Min.y);
        else if (Max.y - sphereCenter.y <= sphere.Radius) dMin += (sphereCenter.y - Max.y) * (sphereCenter.y - Max.y);
        if (sphereCenter.z - Min.z <= sphere.Radius)      dMin += (sphereCenter.z - Min.z) * (sphereCenter.z - Min.z);
        else if (Max.z - sphereCenter.z <= sphere.Radius) dMin += (sphereCenter.z - Max.z) * (sphereCenter.z - Max.z);

        if (dMin <= sphere.Radius * sphere.Radius)
            return ContainmentType::Intersects;

        return ContainmentType::None;
    }

    void Contains(BoundingSphere sphere, ContainmentType &out result)
    {
        result = this.Contains(sphere);
    }

    ContainmentType Contains(Vec3f point)
    {
        ContainmentType result;
        this.Contains(point, result);
        return result;
    }

    void Contains(Vec3f point, ContainmentType &out result)
    {
        //first we get if point is of box
        if (point.x < this.Min.x || point.x > this.Max.x || point.y < this.Min.y || point.y > this.Max.y || point.z < this.Min.z || point.z > this.Max.z)
        {
            result = ContainmentType::None;
        }//or if point is on box because coordonate of point is lesser or equal
        else if (point.x == this.Min.x || point.x == this.Max.x || point.y == this.Min.y || point.y == this.Max.y || point.z == this.Min.z || point.z == this.Max.z)
            result = ContainmentType::Intersects;
        else
            result = ContainmentType::Contains;
    }

    BoundingBox CreateFromPoints(Vec3f[] points)
    {
        //if (points.size() == 0) {warn("No Points! ~ BoundingBox.as ~ CreateFromPoints(Vec3f points)");}
        bool empty = true;
        Vec3f vector2 = Vec3f(MathsHelper::MaxValue32,MathsHelper::MaxValue32,MathsHelper::MaxValue32);
        Vec3f vector1 = Vec3f(MathsHelper::MinValue32,MathsHelper::MinValue32,MathsHelper::MinValue32);
        for( int i = 0; i < points.size(); i++)
        {
            Vec3f vector3;
            vector2.min(vector3);
            vector1.max(vector3);
            empty = false;
        }

        return BoundingBox(vector2, vector1);
    }

    BoundingBox CreateFromSphere(BoundingSphere sphere)
    {
        Vec3f vector1 = Vec3f(sphere.Radius,sphere.Radius,sphere.Radius);
        return BoundingBox(sphere.transform.Position - vector1, sphere.transform.Position + vector1);
    }

    BoundingBox CreateMerged(BoundingBox original, BoundingBox additional)
    {
        return BoundingBox( original.Min.min(additional.Min), original.Max.max(additional.Max));
    }

    bool Equals(BoundingBox other)
    {
        return (this.Min == other.Min) && (this.Max == other.Max);
    }

    Vec3f[] GetCorners()
    {
         Vec3f[] boxcorners = {
            Vec3f(this.Min.x, this.Max.y, this.Max.z), 
            Vec3f(this.Max.x, this.Max.y, this.Max.z),
            Vec3f(this.Max.x, this.Min.y, this.Max.z), 
            Vec3f(this.Min.x, this.Min.y, this.Max.z), 
            Vec3f(this.Min.x, this.Max.y, this.Min.z),
            Vec3f(this.Max.x, this.Max.y, this.Min.z),
            Vec3f(this.Max.x, this.Min.y, this.Min.z),
            Vec3f(this.Min.x, this.Min.y, this.Min.z)
        };
        return boxcorners;
    }

    //int GetHashCode()
    //{
    //    return this.Min.GetHashCode() + this.Max.GetHashCode();
    //}

    bool Intersects(BoundingBox box)
    {
        return this.Intersects(box);
    }

    bool Intersects(BoundingFrustum frustum)
    {
        return frustum.Intersects(this);
    }

    PlaneIntersectionType Intersects(Plane plane)
    {
        return this.Intersects(plane);
    }

    bool Intersects(Ray@ ray)
    { return ray.Intersects(this); }

    //void Intersects(Ray ray, double &out result)
    //{ result = Intersects(ray); }

    bool opEquals(BoundingBox a, BoundingBox b)
    { return a.Equals(b); }

    bool opNotEquals(BoundingBox a, BoundingBox b)
    { return !a.Equals(b); }

    //string ToString()
    //{
    //    return string.Format("{{Min:{0} Max:{1}}}", this.Min.ToString(), this.Max.ToString());
    //}

    void  Intersects(Plane plane, PlaneIntersectionType &out result)
    {
        // See http://zach.in.tu-clausthal.de/teaching/cg_literatur/lighthouse3d_view_frustum_culling/index.html
        Vec3f positiveVertex;
        Vec3f negativeVertex;

        if (plane.Normal.x >= 0)
        {
            positiveVertex.x = Max.x;
            negativeVertex.x = Min.x;
        }
        else
        {
            positiveVertex.x = Min.x;
            negativeVertex.x = Max.x;
        }

        if (plane.Normal.y >= 0)
        {
            positiveVertex.y = Max.y;
            negativeVertex.y = Min.y;
        }
        else
        {
            positiveVertex.y = Min.y;
            negativeVertex.y = Max.y;
        }

        if (plane.Normal.z >= 0)
        {
            positiveVertex.z = Max.z;
            negativeVertex.z = Min.z;
        }
        else
        {
            positiveVertex.z = Min.z;
            negativeVertex.z = Max.z;
        }

        float distance = plane.Normal.opMul(negativeVertex) + plane.D;
        if (distance > 0)
        {
            result = PlaneIntersectionType::Front;
            return;
        }

        distance = plane.Normal.opMul(positiveVertex) + plane.D;
        if (distance < 0)
        {
            result = PlaneIntersectionType::Back;
            return;
        }
       
        result = PlaneIntersectionType::Intersecting;
    }

}

BoundingBox CreateMerged(BoundingBox original, BoundingBox additional)
{
    return CreateMerged(original, additional);
}