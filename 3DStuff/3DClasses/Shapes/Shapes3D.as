#include "TypeEnums.as"
#include "MathsHelper.as"
#include "Vec4f.as"
#include "Quaternion.as"
#include "BoundingSphere.as"
#include "BoundingFrustum.as"
#include "BoundingBox.as"
#include "Ray.as"
#include "Blob3D.as"
#include "World.as"

shared class BoundingShape
{
    u16 netID;
    Blob3D@ ownerBlob;
    RigidTransform transform;

    Matrix4 model = Matrix4();

    Vec3f Velocity, oldVelocity;
    Vec3f AngularVel;
    Vec3f CenterOfMass;

    f32 Mass 			= 80.0;
	f32 Friction 		= 0.2;
	f32 Elasticity 		= 0.0;
	f32 Buoyancy 		= 0.5;
	f32 Drag 			= 0.92;
	f32 GravityScale 	= 1.0;
	f32 waterDragScale 	= 0.2;

    int  Team 		= -1;
    bool Crouching 	= false;
    bool onGround 	= false;
	bool onMap 		= false;
	bool inWater 	= false; //bool old_inwater = false;	
    bool Frozen 	= false;
    bool Attached 	= false;
    bool Collides 	= true;
    bool Static 	= true;
    bool Rotates 	= false;
	//bool onladder;
	//bool onwall;
	//bool onceiling;
	//Vec3f groundNormal;

	int customData; //island color in shiprekt

    BoundingShape(){}
    BoundingShape(Vec3f _pos) 
    { 
        model.setTranslation(_pos);       
    }

    void setBlob(Blob3D@ _blob) {@ownerBlob = @_blob;}
    Blob3D@ getBlob() {return @ownerBlob;}

    void setTeamNum(int _team) {Team = _team;}
    int getTeamNum() {return Team;}

	void setPosition(Vec3f &in pos) {model.setTranslation(pos);}
    Vec3f getPosition() {return model.getTranslation();}
    //Vec3f getInterpolatedPosition(float amount = 0.5f) {return old_Position.Lerp(transform.Position, amount);}

    void setDirection(Vec3f &in dir) {model.setRotationDegrees(dir); }
    //void addDirection(Vec3f &in dir) {transform.Orientation +=   transform.Orientation.Transform(dir); }
    void setAngleDegreesX(float &in x)  { model.setRotationDegrees(Vec3f(x,model.getRotationDegrees().y,model.getRotationDegrees().z)); }
    void setAngleDegreesY(float &in y)  { model.setRotationDegrees(Vec3f(model.getRotationDegrees().x,y,model.getRotationDegrees().z)); }
    void setAngleDegreesZ(float &in z)  { model.setRotationDegrees(Vec3f(model.getRotationDegrees().x,model.getRotationDegrees().y,z)); }

    //void setAngleDegrees(float angle) {transform.Orientation.TransformX(angle);}
    float getAngleDegrees() {return model.getRotationDegrees().x;}
    Vec3f getDirection() {return model.getRotationDegrees();}

    void setVelocity(Vec3f &in vel) {Velocity = vel;}
    void addForce(Vec3f &in force) {Velocity += force;}
    //void addVelocityAtPosition(Vec3f force, Vec3f pos) {}
    Vec3f getVelocity() {return Velocity;}
    Vec3f getOldVelocity() {return oldVelocity;}

    //void setRotation(Vec3f _dir) {this.Angle = _dir;}
    //void setRotationsAllowed(bool _does_rotate) {Rotates = _does_rotate;}
	//bool getRotationsAllowed() {return Rotates;}
    //void addTorque(Vec3f torque) {if (Rotates) AngularVel += torque;}
//
    //void setAngleDegrees(Vec3f angle) {Angle = angle;}
    //void setAngleDegreesXZ(float angle, Vec3f offset = Vec3f()) {Rotation = Quaternion(0.5, 0, 0.5, angle);}
    //Vec3f getAngleDegrees() {return Angle;}    
    //void setAngularVelocity(Vec3f vel) {AngularVel = vel;}
    //Vec3f getAngularVelocity() {return AngularVel;}

	//void SetOffset(Vec3f _shape_offset)
	//Vec3f getOffset()
	void setMass(float _mass) {Mass = _mass;}
	float getMass(){return Mass;}
    float getFriction() {return Friction;}
	float getElasticity() {return Elasticity;}
	float getDrag() {return Drag;}
	void setFriction(float _friction) {Friction = _friction;}
	void setElasticity(float _elasticity) {Elasticity = _elasticity;}
	void setDrag(float _drag) {Drag = _drag;}

	void SetGravityScale(float _scale) {GravityScale = _scale;}
	float getGravityScale() {return GravityScale;}
	void SetCenterOfMassOffset(Vec3f _COM) {CenterOfMass = _COM;}

	void SetStatic(bool _static) {Static = _static;}
	bool isStatic() {return Static;}

	void setCollides(bool _collides) {Collides = _collides;}
	bool doesCollide() {return Collides;}

    bool isAttached() {return Attached;}

	//void getBoundingRect(Vec2f&out topLeft, Vec2f&out bottomRight)
	//void getBoundingBox(Vec3f&out Min, Vec3f&out Max)
    //void PutOnGround(){}
    //void ResolveInsideMapCollision(){}

    void onTick() 
    {
        if (this.isStatic()) return;
        World@ world; if (!getMap().get("terrainInfo", @world)) { return; }       

        TerrainChunk@ chunk = world.getChunkWorldPos(this.getPosition()/16);
        float TerrainHeight = chunk !is null ? chunk.getGroundHeight(this.getPosition()) : -9999; 

        float time = getGameTime()/getTicksASecond();   

        inWater = (this.getPosition().y <  -16.0);

        //this.oldPosition = this.getPosition();
        //if (inWater)
        //{
        //    this.Velocity.y += 1.0*Buoyancy;
        //}  


        //if (this.getVelocity().Length() > 0.1 || !onGround )
        
            //this.Velocity.x = Maths::Clamp(this.Velocity.x, -8.0, 8.0);
            //this.Velocity.y = Maths::Clamp(this.Velocity.y, -8.0, 8.0);
            //this.Velocity.z = Maths::Clamp(this.Velocity.z, -8.0, 8.0);   

            //if (inWater)
            //{
            //    bool onshoal = TerrainHeight > 16.0f;
            //    if ( onshoal )
            //    {
            //        this.Velocity *= (0.75f);
            //    }
            //    else
            //    {
            //        this.Velocity *= (0.6f);
            //    }
            //}       

            //Angle += AngularVel;                    

         if (Maths::Abs(Velocity.x) < 0.01) this.Velocity.x = 0;
         if (Maths::Abs(Velocity.y) < 0.01) this.Velocity.y = 0;
         if (Maths::Abs(Velocity.z) < 0.01) this.Velocity.z = 0;
                 

        this.Velocity *= 1.0-(this.Drag/this.Mass); 
        this.setPosition(this.getPosition() + (this.Velocity/this.Mass)); 

        onGround = false;
        ResolveCollisions();

        if ((this.getPosition().y) > Maths::Round(TerrainHeight)+9.81 && !onGround)
        {
            this.Velocity.y -= 9.81 * 1.0-(this.Drag/this.Mass);
            onGround = false;             
        }
        else if ((this.getPosition().y) < TerrainHeight)
        {
            onGround = false;
            this.Velocity.y = 0;
            Vec3f add(0, this.getPosition().y-TerrainHeight, 0 );
            this.setPosition(this.getPosition() - add);
        }
        else
        {
            onGround = true;            
        }  


    }

    void ResolveCollisions()
    {
        bool inside = false;

        CBlob@[] sorted;
        CBlob@[] blobsInRadius;
        if (getMap().getBlobsInRadius( Vec2f(this.getPosition().x, this.getPosition().z), 48, @blobsInRadius ))
        {
            Vec3f mtv;
            sorted.clear();
            sorted = getSorted(blobsInRadius, Vec2f(this.getPosition().x, this.getPosition().z));
            if (!sorted.empty())
            for (int i = 0; i < sorted.length; i++)
            {
                CBlob@ b = sorted[i];
                if (b !is null)
                {                  
                    Blob3D@ bblob3d;
                    if (b.get("blob3d", @bblob3d) && bblob3d.shape !is this)
                    {         
                        if (this.Contains(bblob3d.shape, this.getVelocity(), mtv) > 0)
                        {
                            inside = true;

                            //if (Maths::Abs(mtv.x) > 0) 
                            //{
                            //    this.Velocity.x = 0;
                            //}
                            
                            if (mtv.y > 0) 
                            {
                                onGround = true;
                                //this.Velocity.y = 0;
                            }

                            //if (Maths::Abs(mtv.z) > 0) 
                            //{
                            //    this.Velocity.z = 0;
                            //}
                            //if (!bblob3d.shape.isStatic())
                            //this.Velocity += mtv/2;
                            //else
                            this.setPosition(this.getPosition() + mtv);
                            this.Velocity += mtv;

                            //break;

                        }
                    }                        
                }
            }
        }            
        if (inside)
            this.UpdateAttributes(SColor(150,255,0,0));
        else
            this.UpdateAttributes(SColor(150,0,255,0));
    }

    CBlob@[] getSorted( CBlob@[] potentials, Vec2f Pos)
    {
        CBlob@[] sorted;
        if (potentials.length > 0)
        {
            while (potentials.size() > 0)
            {
                f32 closestDist = 999999.9f;
                uint closestIndex = 999;

                for (uint i = 0; i < potentials.length; i++)
                {
                    CBlob @b = potentials[i];
                    Vec2f bpos = b.getPosition();
                    f32 dist = (bpos - Pos).getLength();
                    if (dist < closestDist)
                    {
                        closestDist = dist;
                        closestIndex = i;
                    }
                }               
                if (closestIndex >= 999)
                {
                    break;
                }
                sorted.push_back(potentials[closestIndex]);
                potentials.erase(closestIndex);
            }
        }
        return sorted;
    }

    void Render() {}

    ContainmentType Contains(BoundingShape@ other, Vec3f Vel, Vec3f &out MTV) 
    {
        BoundingBox@ box = cast<BoundingBox@>(other);
        BoundingSphere@ sphere = cast<BoundingSphere@>(other);
        if (box !is null)
        {
            return this.Contains(box, Vel, MTV);
        }
        //else if (sphere !is null)
        //{
        //    return this.Contains(sphere);
        //}
        return ContainmentType::None;
    }

    ContainmentType Contains(BoundingBox@ box, Vec3f Vel, Vec3f &out MTV) {return ContainmentType::None;} //overridden

    void UpdateAttributes(SColor){};
    bool Intersects(BoundingShape@ ray) {return ray.Intersects(this); }

}