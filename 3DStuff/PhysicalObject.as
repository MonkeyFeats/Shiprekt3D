
namespace EricsLib.Engine
{
    public enum PhysicalType
    {
        Nothing = 0,
        Pawn = 1,           //pawns are ...something
        Terrain = 2,        //the ground!
        Character = 4,      //characters are creatures of some sort
        Actor = 8,          //actors are objects which can be interacted with
        Item = 16,          //pick up items
        Projectile = 32,    //arrows, flying rocks, etc
        Ethereal = 64,      //stuff can go through this, not affected by most forces such as gravity
        Building = 128,     //houses, gates, walls, etc.
        Obstacle = 256,     //trees, rocks, and other static impassables
        SOLID = Nothing | Pawn | Terrain | Character | Actor | Item | Projectile | Building | Obstacle,
        ALL = 511
    }

    /// <summary>
    /// Indicates whether the object should be not drawn, drawn, or drawn as an invisible object
    /// </summary>
    public enum Visibility
    {
        NoDraw = 1,             //The object is never drawn
        Visible = 2,            //the object is completely visible, so it is drawn
        Invisible = 4           //the object is invisible, but needs to be drawn to represent an invisible object  (ie, an outline)
    }

    public class PhysicalParticle
    {
        public Vector3 position;
        public Vector3 velocity;
        public Vector3 acceleration;
        public float mass;
        public Angle rotation;

        public bool IsStatic = true;

        public void Update(coreTime worldTime)
        {
            if (!IsStatic)
            {
                velocity += acceleration * (float)(worldTime.ElapsedWorldTime.TotalSeconds);
                position += velocity * (float)(worldTime.ElapsedWorldTime.TotalSeconds);
            }
        }
    }

    /// <summary>
    /// A physical object has all of the physical properties and behaviors you'd expect a physical object to have.
    /// 
    /// </summary>
    public class Physical : GenericGameObject, IRenderable
    {

        #region Bounding volume areas
        //Note: A model may have a bounding volume for its meshes which is different from the bounding
        //volumes of the actual physical bounds. A tree would have a long narrow trunk and a large canopy,
        //which should have very different physical boundary areas than that whole bounding area for the 
        //whole tree mesh.

        /// <summary>
        /// This is the broad phase bounding sphere. This should enclose the whole object!
        /// Use this first for any collision detection since it is the fastest to calculate.
        /// Note: Use length squared to avoid a square root calculation!
        /// </summary>
        private BoundingSphere m_boundingSphere;

        /// <summary>
        /// This is the broad phase bounding sphere for physical collisions.
        /// </summary>
        private BoundingSphere m_hitSphere;
        private Vector3 m_hitSphereOffset = Vector3.Zero;

        /// <summary>
        /// this is a coarse bounding box for the entire object. If this bounding box doesn't intersect with another coarse bounding box, 
        /// then there isn't a need for any further collision checks.
        /// </summary>
        private BoundingBox m_boundingBox;

        /// <summary>
        /// This is the physical hit box for the object
        /// </summary>
        private BoundingBox m_hitBox;
        #endregion

        #region Physical properties
        protected float m_mass;                 //measured in Kg
        private Vector3 m_position;             //current position of the object
        protected Vector3 m_lastPosition;       //position last frame
        protected Vector3 m_velocity;           //change in position over time -- note that velocity may be distinct from orientation (ie. facing forwards but moving backwards)
        protected Vector3 m_acceleration;       //change in velocity over time
        protected Range<float> m_topAccelleration;     //this is the top accelleration
        protected Range<float> m_topSpeed;             //maximum speed for velocity   -- note: using a range in case you want to temporarily reduce the top speed
        private Vector3 m_steerForce;         //These are all of the forces acting on the object accelleration (thrust, gravity, drag, etc) 
        protected float m_scale = 1.0f;         //this is the scale factor for the object
        protected Vector3 m_gravityForce = Vector3.Zero;

        /// <summary>
        /// In some cases, you want to attach a physical property to another object via composition instead of inheritance. This gives the physical
        /// property a reference to the object its attached to, so that when the physical object updates, it will call the update of the attached object
        /// as well.
        /// </summary>
        protected GenericGameObject m_pAttachment = null;
        protected Quaternion m_orientation;     //orientation in 3D space

        /// <summary>
        /// This is the current rotation in 2D
        /// </summary>
        protected Angle m_rotation;
        /// <summary>
        /// The rotation velocity is how fast the rotation angle can change over time. Set to Pi for instantaneous rotation.
        /// </summary>
        protected Range<float> m_rotationVelocity;

        /// <summary>
        /// This sets the fastest an object can rotate
        /// </summary>
        protected float m_rotationSpeed;
        #endregion

        #region Meta properties
        protected PhysicalType m_type = PhysicalType.Nothing;

        /// <summary>
        /// These are all of the categories of objects this physical object can collide with.
        /// If this object intersects with any of these objects, a collision event is raised and it is up
        /// to the implementer to decide how they want to handle that event.
        /// </summary>
        protected PhysicalType m_colliders = PhysicalType.Nothing;

        protected Effect m_effect;
        protected Visibility m_visible;

        /// <summary>
        /// This indicates that the object doesn't actually move (such as terrain)
        /// </summary>
        protected bool m_stationary = true;

        /// <summary>
        /// This is the current level of detail used to draw the object based on its distance from the active camera.
        /// <para>0 - Highest level of detail</para>
        /// <para>1 - medium level of detail</para>
        /// <para>2 - low level of detail</para>
        /// <para>3 - no draw</para>
        /// </summary>
        protected int m_activeLOD = 0;

        //because you don't want to go hunting around an octree for an object just to see its update loop.
        bool m_breakOnUpdate = false;
        public bool BreakOnUpdate { set { m_breakOnUpdate = value; } }
        #endregion

        #region Constructors
        /// <summary>
        /// Creates a new physical object with default properties
        /// </summary>
        public Physical() : base()
        {
            m_mass = 1.0f;
            m_position = Vector3.Zero;
            m_lastPosition = Vector3.Zero;
            m_velocity = Vector3.Zero;
            m_acceleration = Vector3.Zero;
            m_topAccelleration = new Range<float>(0, 1);
            m_topSpeed = new Range<float>(-1, -1);
            m_orientation = Quaternion.Identity;
            m_rotation = new Angle();
            m_rotationSpeed = MathHelper.TwoPi * 4;
            m_rotationVelocity = new Range<float>(-m_rotationSpeed, m_rotationSpeed, 0);

            m_boundingSphere = new BoundingSphere(m_position, 1f);

            m_steerForce = Vector3.Zero;
            m_visible = Visibility.Visible;
        }

        /// <summary>
        /// Creates a deep copy of the physical object
        /// </summary>
        /// <param name="copy">The object to duplicate</param>
        public Physical(Physical copy) : base(copy)
        {
            copy.SanityCheck();

            if (copy.m_boundingBox != null)
                m_boundingBox = new BoundingBox(copy.m_boundingBox.Min, copy.m_boundingBox.Max);
            if (copy.m_boundingSphere != null)
                m_boundingSphere = new BoundingSphere(copy.m_boundingSphere.Center, copy.m_boundingSphere.Radius);
            if (copy.m_hitBox != null)
                m_hitBox = new BoundingBox(copy.m_hitBox.Min, copy.m_hitBox.Max);
            if (copy.m_hitSphere != null)
                m_hitSphere = new BoundingSphere(copy.m_hitSphere.Center, copy.m_hitSphere.Radius);
            
            m_mass = copy.m_mass;
            m_position = new Vector3(copy.m_position.X, copy.m_position.Y, copy.m_position.Z);
            m_lastPosition = new Vector3(copy.m_lastPosition.X, copy.m_lastPosition.Y, copy.m_lastPosition.Z);
            m_velocity = new Vector3(copy.m_velocity.X, copy.m_velocity.Y, copy.m_velocity.Z);
            m_acceleration = new Vector3(copy.m_acceleration.X, copy.m_acceleration.Y, copy.m_acceleration.Z);
            m_topAccelleration = new Range<float>(copy.m_topAccelleration);
            m_topSpeed = new Range<float>(copy.m_topSpeed);
            m_orientation = copy.m_orientation;
            m_rotation = new Angle(copy.m_rotation);
            m_rotationVelocity = new Range<float>(copy.m_rotationVelocity);
            m_steerForce = new Vector3(copy.m_steerForce.X, copy.m_steerForce.Y, copy.m_steerForce.Z);
            

            m_stationary = copy.m_stationary;
            m_type = copy.m_type;
            if (copy.m_effect != null)
                m_effect = copy.m_effect.Clone();
            m_activeLOD = copy.m_activeLOD;
            
        }
        #endregion

        
        /// <summary>
        /// Moves an object according to its position, velocity and acceleration and the change in game time
        /// </summary>
        /// <param name="worldTime">The change in world time since last update</param>
        /// <returns>
        /// 0 = The object did not move.
        /// 1 = the object was moved.
        /// 2 = the object just died.
        ///</returns>
        public override int Update(coreTime worldTime)
        {
            if (m_breakOnUpdate)
            {
                string myName = Name;
            }

            if (m_alive == false)
                return 2;

            if (m_pAttachment != null)
            {
                m_pAttachment.Update(worldTime);
            }

            if (!m_stationary)
            {
                SanityCheck();

                m_lastPosition = Position;
                m_rotation += m_rotationVelocity.Current * (float)(worldTime.ElapsedWorldTime.TotalSeconds);
                m_acceleration = (m_steerForce / m_mass) + (m_gravityForce * (float)(worldTime.ElapsedWorldTime.TotalSeconds));           //F = ma -> a = F/m
                m_velocity += m_acceleration;                         //velocity is the change in acceleration over time

                //don't move faster than our top speed
                if (m_velocity != Vector3.Zero && m_topSpeed.Current != -1)
                {
                    //we're constraining the object to a top speed.
                    if (m_velocity.Length() > m_topSpeed.Current)
                    {
                        m_velocity.Normalize();
                        m_velocity *= m_topSpeed.Current;
                    }
                }

                Vector3 moveStep = m_velocity * (float)worldTime.ElapsedWorldTime.TotalSeconds;
                Position += moveStep;      //position is the change in velocity over time

                if(m_boundingSphere != null)
                    m_boundingSphere.Center += moveStep;
                if (m_hitSphere != null)
                    m_hitSphere.Center += moveStep;
                if (m_boundingBox != null)
                {
                    m_boundingBox.Max += moveStep;
                    m_boundingBox.Min += moveStep;
                }
                if (m_hitBox != null)
                {
                    m_hitBox.Max += moveStep;
                    m_hitBox.Min += moveStep;
                }

                if (m_lastPosition != Position) return 1;
            }

            

            return 0;
        }

        /// <summary>
        /// Detect value corruption before it spreads!
        /// </summary>
        private void SanityCheck()
        {
            

            if (float.IsNaN(Position.X) || float.IsNaN(Position.Y) || float.IsNaN(Position.Z))
                throw new Exception("Object position data is corrupted.");
            if (float.IsNaN(m_rotationVelocity.Current))
                throw new Exception("Rotation velocity data is corrupted.");
            if (float.IsNaN(m_steerForce.X) || float.IsNaN(m_steerForce.Y) || float.IsNaN(m_steerForce.Z))
                throw new Exception("Steer force data has been corrupted.");
            if (float.IsNaN(m_acceleration.X) || float.IsNaN(m_acceleration.Y) || float.IsNaN(m_acceleration.Z))
                throw new Exception("accelleration data has been corrupted.");
            if (float.IsNaN(m_velocity.X) || float.IsNaN(m_velocity.Y) || float.IsNaN(m_velocity.Z))
                throw new Exception("velocity data has been corrupted.");
            if (float.IsNaN(m_topSpeed.Current))
                throw new Exception("top speed current value has been corrupted.");
            if (m_mass == 0)
                throw new Exception("A massless object has been detected. Impossibru!");
        }

        /// <summary>
        /// In some cases, you want to attach a physical property to another object via composition instead of inheritance. This gives the physical
        /// property a reference to the object its attached to, so that when the physical object updates, it will call the update of the attached object
        /// as well.
        /// </summary>
        /// <param name="parentObject">This is the object which contains the physical object.</param>
        public void AttachTo(GenericGameObject parentObject)
        {
            m_pAttachment = parentObject;
        }

        /// <summary>
        /// Applies a change in accelleration by accellerating in the direction of the current orientation
        /// </summary>
        /// <param name="force">A scalar amount of force to thrust with</param>
        /// <remarks>This is automatically truncated to the max speed.</remarks>
        protected void Thrust(float force)
        {
            Vector3 thrustVec = new Vector3(m_rotation.Vector2, 0);
            //already normalized...

            thrustVec *= force;

            ApplyForce(thrustVec);
        }

        /// <summary>
        /// Changes the accelleration of the whole object by the given force vector.
        /// Note that this has no bearing on the orientation of the object!
        /// </summary>
        /// <param name="forceVec">the force vector to change accelleration by</param>
        public void ApplyForce(Vector3 forceVec)
        {
            if (float.IsNaN(forceVec.X) || float.IsNaN(forceVec.Y) || float.IsNaN(forceVec.Z))
                throw new Exception("The input parameter was corrupted!");

            Vector3 truncatedDirection = forceVec;

            //make sure we're not moving faster than our top speed
            if (truncatedDirection.Length() > m_topSpeed.Current)
            {
                truncatedDirection = Calc.Normalize(truncatedDirection);
                truncatedDirection *= m_topSpeed.Current;
            }

            if (float.IsNaN(truncatedDirection.X) || float.IsNaN(truncatedDirection.Y) || float.IsNaN(truncatedDirection.Z))
                throw new Exception("truncated direction was invalid.");

            m_steerForce = truncatedDirection;
        }

        //TODO: Write a function to apply a non-centered force impulse, causing the object to spin around and move

        /// <summary>
        /// Renders the physical object
        /// </summary>
        /// <param name="worldtime">This is the current world time. It is used for animation and key frames.</param>
        /// <param name="viewProjection">This is the camera view projection matrix</param>
        /// <returns> 0 if it was not drawn, 1 if drawn.</returns>
        public virtual int Render(coreTime worldtime, Matrix viewProjection)
        {
            //the object isn't visible, so skip drawing
            if (m_visible == Visibility.NoDraw) return 0;
            return 1;
        }

        /// <summary>
        /// Every physical object can draw itself
        /// </summary>
        /// <param name="time"></param>
        public virtual void Draw(coreTime time)
        {
            //the object isn't visible, so skip drawing
            if (m_visible == Visibility.NoDraw) return;
        }

        public virtual void UpdateLOD(Camera3D currentCamera)
        {
            float dist = (currentCamera.Position - Position).LengthSquared();

            if (dist <= 2500)
                m_activeLOD = 0;
            else if (dist <= 15000)
                m_activeLOD = 1;
            else if (dist <= 50000)
                m_activeLOD = 2;
            else
                m_activeLOD = 3;
        }

        public virtual IntersectionRecord Intersects(Ray intersectionRay)
        {
            
            float? f = null;
            if (m_boundingBox != null && m_boundingBox.Min != m_boundingBox.Max)
            {
                f = m_boundingBox.Intersects(intersectionRay);           
            }
            else if (m_boundingSphere.Radius != 0)
            {
                f = m_boundingSphere.Intersects(intersectionRay);
            }
            
            if (f != null)
            {
                return new IntersectionRecord.Builder() 
                { 
                    Distance = f.Value, 
                    Object1 = this, 
                    hitRay = intersectionRay,
                    Position = intersectionRay.Position + (intersectionRay.Direction * f.Value)
                }
                .Build();
            }
            return null;
        }

        public virtual void SetDirectionalLight(Vector3 direction, Color color)
        {
            m_effect.Parameters["xLightDirection0"].SetValue(direction);
            m_effect.Parameters["xLightColor0"].SetValue(color.ToVector3());
            m_effect.Parameters["xEnableLighting"].SetValue(true);
        }


        #region Intersection
        /// <summary>
        /// Tells you if the bounding regions for this object [intersect or are contained within] the bounding frustum
        /// </summary>
        /// <param name="intersectionFrustum">The frustum to do bounds checking against</param>
        /// <returns>An intersection record containing any intersection information, or null if there isn't any
        /// </returns>
        public virtual IntersectionRecord Intersects(BoundingFrustum intersectionFrustum)
        {
            if (m_boundingSphere == null && m_boundingBox == null)
            {
                throw new Exception("no bounding area for this object!");
            }
            if (m_boundingBox != null && m_boundingBox.Max - m_boundingBox.Min != Vector3.Zero)
            {
                ContainmentType ct = intersectionFrustum.Contains(m_boundingBox);
                if (ct != ContainmentType::None)
                {
                    return new IntersectionRecord.Builder() { Object1 = this }.Build();
                    //return new IntersectionRecord(this);
                }
            }
            else if (m_boundingSphere != null && m_boundingSphere.Radius != 0f)
            {
                ContainmentType ct = intersectionFrustum.Contains(m_boundingSphere);
                if (ct != ContainmentType::None)
                {
                    return new IntersectionRecord.Builder() { Object1 = this }.Build();
                }
            }

            return null;
        }

        /// <summary>
        /// Coarse collision check: Tells you if this object intersects with the given intersection sphere.
        /// </summary>
        /// <param name="intersectionSphere">The intersection sphere to check against</param>
        /// <returns>An intersection record containing this object</returns>
        /// <remarks>You'll want to override this for granular collision detection</remarks>
        public virtual IntersectionRecord Intersects(BoundingSphere intersectionSphere)
        {
            if (m_boundingBox != null && m_boundingBox.Max != m_boundingBox.Min)
            {
                if (m_boundingBox.Contains(intersectionSphere) != ContainmentType.None)
                    return new IntersectionRecord.Builder() { Object1 = this }.Build();
            }
            else if (m_boundingSphere != null && m_boundingSphere.Radius != 0f)
            {
                if (m_boundingSphere.Contains(intersectionSphere) != ContainmentType.None)
                    return new IntersectionRecord.Builder() { Object1 = this }.Build();
            }

            return null;
        }

        /// <summary>
        /// Coarse collision check: Tells you if this object intersects with the given intersection box.
        /// </summary>
        /// <param name="intersectionBox">The intersection box to check against</param>
        /// <returns>An intersection record containing this object</returns>
        /// <remarks>You'll want to override this for granular collision detection</remarks>
        public virtual IntersectionRecord Intersects(BoundingBox intersectionBox)
        {
            if (m_boundingBox != null && m_boundingBox.Max != m_boundingBox.Min)
            {
                ContainmentType ct = m_boundingBox.Contains(intersectionBox);
                if (ct != ContainmentType.None)
                    return new IntersectionRecord.Builder() { Object1 = this }.Build();
            }
            else if (m_boundingSphere != null && m_boundingSphere.Radius != 0f)
            {
                if (m_boundingSphere.Contains(intersectionBox) != ContainmentType.None)
                    return new IntersectionRecord.Builder() { Object1 = this }.Build();
            }

            return null;
        }

        /// <summary>
        /// Tests for intersection with this object against the other object
        /// </summary>
        /// <param name="otherObj">The other object to test for intersection against</param>
        /// <returns>Null if there isn't an intersection, an intersection record if there is a hit.</returns>
        public virtual IntersectionRecord Intersects(Physical otherObj)
        {
            IntersectionRecord ir;

            if (otherObj.m_boundingBox != null && otherObj.m_boundingBox.Min != otherObj.m_boundingBox.Max)
            {
                ir = Intersects(otherObj.m_boundingBox);
            }
            else if (otherObj.m_boundingSphere != null && otherObj.m_boundingSphere.Radius != 0f)
            {
                ir = Intersects(otherObj.m_boundingSphere);
            }
            else
                return null;

            if (ir != null)
            {
                //ir.PhysicalObject = this;
                //ir.OtherPhysicalObject = otherObj;
            }

            return new IntersectionRecord.Builder() { Object1 = this, Object2 = otherObj }.Build();
        }

        public virtual void HandleIntersection(IntersectionRecord ir)
        {

        }
        #endregion

        #region Overrides
        public override string ToString()
        {
            if (m_pAttachment != null)
                return m_pAttachment.ToString();
            return base.ToString();
        }
        #endregion

        #region helper functions
        public void UndoLastMove()
        {
            Position = m_lastPosition;
        }

        public void SetCollisionRadius(float radius)
        {
            m_boundingSphere.Radius = radius;
        }

        /// <summary>
        /// Gives you the force for a given instantaneous accelleration vector
        /// </summary>
        /// <param name="instantAccelleration">the instantaneous accelleration</param>
        /// <returns>A force vector</returns>
        public Vector3 GetForce(Vector3 instantAccelleration)
        {
            return m_mass * instantAccelleration;
        }

        /// <summary>
        /// Tells you if the point is within this creatures bounding volume
        /// </summary>
        /// <param name="pt">point to test for containment</param>
        /// <returns>a boolean value indicating containment</returns>
        public bool HasPoint(Point pt)
        {
            return HasPoint(pt.X, pt.Y);
        }

        /// <summary>
        /// Tells you if the point is within this creatures bounding volume
        /// </summary>
        /// <param name="X">point X value</param>
        /// <param name="Y">point Y value</param>
        /// <returns>a boolean value indicating containment</returns>
        public bool HasPoint(int X, int Y)
        {
            return m_boundingSphere.Contains(new Vector3(X, Y, 0)) != ContainmentType.None;
        }

        public bool HasPoint(Vector2 point)
        {
            return m_boundingSphere.Contains(new Vector3(point.X, point.Y, 0)) != ContainmentType.None;
        }

        public static void FilterByType<T>(ref List<T> objList, PhysicalType filterOut) where T: Physical
        {
            //UNTESTED
            if (objList == null || objList.Count == 0) return;

            int size = objList.Count;
            for (int a = 0; a < size; a++)
            {
                byte test = (byte)(objList[a].m_type & filterOut);
                if (test != 0)
                {
                    objList.Remove(objList[a--]);
                    size--;
                }
            }
        }

        #endregion

        #region Accessors
        public PhysicalType Type { get { return m_type; } set { m_type = value; } }

        public virtual Vector3 Position
        {
            get
            {
                return m_position;
            }
            set
            {
                if (float.IsNaN(value.X) || float.IsNaN(value.Y)|| float.IsNaN(value.Z))
                    throw new Exception("Invalid position values recieved.");

                m_position = value;
                m_hitSphere.Center = value + m_hitSphereOffset;
                m_boundingSphere.Center = value;
            }
        }

        public Vector3 LastPosition
        {
            get { return m_lastPosition; }
        }

        /// <summary>
        /// This is the creatures current 2D facing direction
        /// </summary>
        public Angle Rotation
        {
            get { return m_rotation; }
            set { m_rotation = value; }
        }

        /// <summary>
        /// This is how much the rotation value changes over time
        /// </summary>
        public Range<float> RotationVelocity
        {
            get { return m_rotationVelocity; }
            set { m_rotationVelocity = value; }
        }

        /// <summary>
        /// This is the maximum speed the object can rotate over time
        /// </summary>
        /// the rotational velocity is a value which normally ranges between its min and max values.
        /// the current value is how much the rotation changes over time.
        /// in some cases, the min and max rotational velocities can change.
        /// example: I'm an object moving very fast. My min/max change in rotation is -15/15 degrees, but my current value is 1 degree.
        /// I slow down, so my min/max change in rotation increases to -45/45.
        /// If I stop, my min/max change in rotation goes all the way up to -180/180 (instantaneous).
        public float MaxRotationVelocity
        {
            get { return m_rotationVelocity.Max; }
            set 
            {
                if (value < m_rotationSpeed)    //cap values to the max rotation speed
                {
                    m_rotationVelocity.Max = value;
                    m_rotationVelocity.Min = -value;
                }
                else if (value > 0)             //cap values above zero
                {
                    m_rotationVelocity.Max = 0;
                    m_rotationVelocity.Min = 0;
                }
                else
                {
                    m_rotationVelocity.Max = m_rotationSpeed;
                    m_rotationVelocity.Min = -m_rotationSpeed;
                }
            }
        }

        public bool IsStationary
        {
            get { return m_stationary; }
            set { m_stationary = value; }
        }

        public BoundingBox EnclosingBox
        {
            get
            {
                return m_boundingBox;
            }
            set
            {
                m_boundingBox = value;
            }
        }

        public BoundingSphere EnclosingSphere
        {
            get
            {
                return m_boundingSphere;
            }
            set
            {
                m_boundingSphere = value;
            }
        }

        public BoundingBox HitBox
        {
            get
            {
                if (m_hitBox == null)
                    return m_boundingBox;
                return m_hitBox;
            }
            set
            {
                m_hitBox = value;
            }
        }

        public BoundingSphere HitSphere
        {
            get
            {
                if (m_hitSphere == null)
                    return m_boundingSphere;
                return m_hitSphere;
            }
            set
            {
                m_hitSphere = value;
                m_hitSphereOffset = m_position - value.Center;
            }
        }

        public Quaternion Orientation
        {
            get
            {
                return m_orientation;
            }
            set
            {
                m_orientation = value;
            }
        }

        //public Range SpeedLimit
        //{
        //    get
        //    {
        //        return SpeedLimit;
        //    }
        //    set
        //    {
        //        SpeedLimit = value;
        //    }
        //}

        public Vector3 Velocity
        {
            get
            {
                return m_velocity;
            }
            set
            {
                m_velocity = value;
            }
        }

        public Vector3 Accelleration
        {
            get { return m_acceleration; }
            set 
            { 
                m_acceleration = value;
                if (m_acceleration.Length() > m_topAccelleration.Current)
                {
                    m_acceleration.Normalize();
                    m_acceleration *= m_topAccelleration.Current;
                }
            }
        }

        public Vector3 GravityForce
        {
            get { return m_gravityForce; }
            set { m_gravityForce = value; }
        }

        /// <summary>
        /// This tells you how fast the object is moving on the velocity vector without using sqrt
        /// </summary>
        public float SpeedSquared
        {
            get { return m_velocity.LengthSquared(); }
        }

        /// <summary>
        /// This tells you how fast the object is moving on the velocity vector
        /// </summary>
        public float Speed
        {
            get { return m_velocity.Length(); }
        }

        /// <summary>
        /// The current value is the current top speed of the object.
        /// <para>The MAX value is the fastest the object can move with any temporary boosts.</para>
        /// <para>The MIN value is the slowest maximum value the object can move. This should always be zero or greater.</para>
        /// <para>Values of -1,-1 are invalid and mean that the object has no top speed, so it can go as fast as you want.</para>
        /// <para>Example: A speedometers maximum value is 150mph. A car just physically cannot exceed this value.</para>
        /// </summary>
        public Range<float> TopSpeed
        {
            get { return m_topSpeed; }
            set { m_topSpeed = value; }
        }

        /// <summary>
        /// Set/get the maximum speed an object is capable of traveling
        /// </summary>
        public float MaxTopSpeed
        {
            get { return m_topSpeed.Max; }
            set { m_topSpeed.Max = value; }
        }

        /// <summary>
        /// This lets you change the maximum top speed.
        /// <para>Example: Changing the speedometer maximum range from 100mph to 150mph</para>
        /// </summary>
        /// <param name="value"></param>
        protected void SetMaxTopSpeed(float value, float currentTopSpeed)
        {
            m_topSpeed.Max = value;
            m_topSpeed.Current = currentTopSpeed;
        }

        /// <summary>
        /// A flag indicating if the object is a visible object. If the object is not visible, it will not be processed for drawing.
        /// </summary>
        public Visibility Visible
        {
            get { return m_visible; }
            set { m_visible = value; }
        }

        public PhysicalType CollidesWith
        {
            get { return m_colliders; }
            set { m_colliders = value; }
        }

        /// <summary>
        /// The mass of the object in Kilograms
        /// </summary>
        public float Mass
        {
            get { return m_mass; }
            set { m_mass = value; }
        }

        /// <summary>
        /// tells you if a valid bounding area encloses the object. Doesn't indicate which kind though.
        /// </summary>
        public bool HasBounds
        {
            get
            {
                if (m_hitSphere == null && m_hitBox == null && m_boundingBox == null && m_boundingSphere == null)
                    return false;
                else
                {
                    //bounding objects exist, so let's return true if either of them are valid.
                    return (m_hitSphere.Radius != 0 || m_hitBox.Min != m_hitBox.Max || m_boundingSphere.Radius != 0 || m_boundingBox.Min != m_boundingBox.Max);
                }
            }
        }

        public Effect Effect
        {
            get { return m_effect; }
            set { m_effect = value; }
        }
        
        #endregion
    }
}