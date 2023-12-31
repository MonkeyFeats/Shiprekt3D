
#include "Transform.as"
#include "Shapes3D.as"

const float acceleration = 0.5f;
const float jump_acceleration = 0.35f;
const float friction = 0.3f;
const float air_friction = 0.1f;
const float eye_height = 1.7f;
const float player_height = 1.85f;
const float player_radius = 0.35f;
const float player_diameter = player_radius*2;
bool fly = false;
//bool hold_frustum = false;

float max_dig_time = 100;
bool block_menu = false;
bool block_menu_created = false;

shared class Blob3D
{
    u16 netID;
    CBlob@ ownerBlob;
    CPlayer@ player;
    BoundingShape@ shape;
    SMesh@ mesh = SMesh();
    SMeshBuffer@ meshbuffer = SMeshBuffer();
    RigidTransform transform;
    Vec3f Velocity, old_Velocity, AngularVel;

    int Team;
    bool Crouching = false;
    bool onGround = false;
    bool Frozen = false;
    bool Attached = false;
    float Health; float MaxHealth = 2.0f;

    int CustomData; //island color in shiprekt

    //Blob3D(){}

    Blob3D(Vec3f _Pos, int _team, float _maxhealth)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth;   
        @player = null;     
    }

    Blob3D(CBlob@ _owner, Vec3f _Pos, int _team, float _maxhealth)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth; 
        @ownerBlob = _owner;
    }

    Blob3D(CBlob@ _owner, Vec3f _Pos, int _team, float _maxhealth, BoundingShape@ _shape)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth; 
        @ownerBlob = _owner;
        @_shape.ownerBlob = this;
        @shape = _shape;

    }

    Blob3D(CBlob@ _owner, CPlayer@ _player, Vec3f _Pos, int _team, float _maxhealth, BoundingShape@ _shape)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth; 
        @ownerBlob = _owner;
        @player = _player;
        @_shape.ownerBlob = this;
        @shape = _shape;
    }

    Blob3D(CBlob@ _owner, CPlayer@ _player, Vec3f _Pos, int _team, float _maxhealth)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth; 
        @ownerBlob = _owner;
        @player = _player;
    }

    Blob3D(Vec3f _Pos, int _team, float _maxhealth, SMesh@ _mesh, SMeshBuffer@ _meshbuffer, BoundingShape@ _shape)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth;
        @mesh = _mesh;
        @meshbuffer = _meshbuffer;
        @shape = _shape;
    }

    Blob3D(CPlayer@ _player, Vec3f _Pos, int _team, float _maxhealth)
    {
        Team = _team;
        transform.Position = _Pos;
        MaxHealth = Health = _maxhealth;
        @player = _player;
    }

    Blob3D(Vec3f _Pos, int _team, float _maxhealth, BoundingShape@ _shape)
    {
        transform.Position = _Pos;
        Team = _team;
        MaxHealth = Health = _maxhealth;
        @shape = _shape;
    }

    void SetPlayer(CPlayer@ _player) {@player = @_player;}
    void SetShape(BoundingShape@ _shape) {@shape = @_shape;}

    int getTeamNum() {return this.Team;}
    CPlayer@ getPlayer() {return this.player;};
    void setPlayer(CPlayer@ _player) {@this.player = _player;}
   
    float getDistanceTo( Vec3f &in otherPos ) {return (transform.Position - otherPos).length();}

    void setPosition(Vec3f &in pos) {transform.Position = pos;}
    Vec3f getPosition() {return transform.Position;}
    //Vec3f getInterpolatedPosition(float amount = 0.5f) {return old_Position.Lerp(transform.Position, amount);}

    void setDirection(Vec3f &in dir) { transform.Orientation.Transform(dir); }
    //void addDirection(Vec3f &in dir) {transform.Orientation +=   transform.Orientation.Transform(dir); }
    //void addDirectionX(float &in x)  {transform.Orientation.x += transform.Orientation.TransformX(x);  }
    //void addDirectionY(float &in y)  {transform.Orientation.y += transform.Orientation.TransformY(y); }
    //void addDirectionZ(float &in z)  {transform.Orientation.z += transform.Orientation.TransformZ(z); }
    void setAngleDegrees(float angle) {transform.Orientation.TransformX(angle);}
    float getAngleDegrees() {return transform.Orientation.x;}

    Vec3f getDirection() {return transform.Orientation.getXYZ();}
    Vec3f getInterpolatedDirection(float amount = 0.5f) {return transform.Orientation.getXYZ();}

    Vec3f getVelocity() {return Velocity;}
    Vec3f getOldVelocity() {return old_Velocity;}
    void setVelocity(Vec3f &in vel) {Velocity = vel;}
    void AddForce(Vec3f &in force) {Velocity += force;}
    //void AddForceAtPosition(Vec3f force, Vec3f pos) {}

    void AddTorque(float torque) {AngularVel += torque;}    
    void setAngularVelocity(Vec3f vel) {AngularVel = vel;}
    Vec3f getAngularVelocity() {return AngularVel;}
    void Damage(float amount /*, Blob3D@ damager*/) {Health -= amount;}
    void server_Heal(float amount) {Health += amount; if (Health > MaxHealth) Health = MaxHealth;}
    void server_SetHealth(float amount) {Health = amount; if (Health > MaxHealth) Health = MaxHealth;}
    void server_Die() {Health = 0;}
    bool isAttached() {return this.Attached;}

    //void onInit() {}

    void onTick() 
    {
        if (shape is null) return;

//        Vec3f vec = Vec3f(0,0,99999999);
//        vec.yzRotateBy(-look_dir.y);
//        vec.xzRotateBy( look_dir.x);  
//        Ray ray(Position, Position+vec);
//
//
//      Island[]@ islands;
//      if ( getRules().get("islands", @islands ) )
//      {               
//          for ( uint i = 0; i < islands.size(); ++i )
//          {
//              Island @isle = islands[i];
//
//              for (uint b_iter = 0; b_iter < isle.blocks.length; ++b_iter)
//              {
//                  IslandBlock@ isle_block = isle.blocks[b_iter];
//                  CBlob@ b = getBlobByNetworkID( isle_block.blobID );
//                  if (b !is null)
//                  {
//                      Blob3D@ block;
//                      if (!b.get("blob3d", @block)) { continue; } 
//
//                      if(block.shape !is null)                  
//
//                      if (block.shape.Intersects(ray))//, overlap))
//                      {
//                          block.shape.UpdateAttributes(SColor(255,255,0,0));
//                      }
//                      else
//                      {
//                          block.shape.UpdateAttributes(SColor(150,0,255,0));
//                      }                       
//                  }
//              }
//          }
//      }


        if (shape.isStatic()) 
        {
            shape.setPosition(this.transform.Position);
            shape.UpdateAttributes(SColor(255,255,0,255));
            //return;
        }
        else
        {
            shape.onTick();
            this.setVelocity(shape.Velocity);
            this.setPosition(shape.getPosition());
        }

        //if (getControls().isKeyPressed(KEY_KEY_E))
        //this.shape.Position = this.Position;//

       // if (this.getVelocity().Length() > 0.1 )
       // {
       //     this.old_Position = this.Position;
       //     
//
       //     //this.Velocity *= 0.75;
       // }
       // else
       // {
       //     this.setVelocity(Vec3f(0));
       // }
    }
};

class PhysicalParticle
{
    Vec3f position;
    Vec3f velocity;
    Vec3f acceleration;
    Vec3f rotation; //Angle class?
    float mass;

    bool IsStatic = true;

    void Update()
    {
        if (!IsStatic)
        {
            float t = getGameTime();
            velocity += acceleration * t;
            position += velocity * t;
        }
    }
}
