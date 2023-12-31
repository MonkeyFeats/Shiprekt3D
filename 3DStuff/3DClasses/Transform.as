
shared class RigidTransform
{
    Vec3f Position;
    Quaternion Orientation;
    //Vec3f Scale;

    RigidTransform(Vec3f position, Quaternion orientation)
    {
        Position = position;
        Orientation = orientation;
    }

    RigidTransform(Vec3f position)
    {
        Position = position;
        Orientation = Quaternion();
    }

    RigidTransform(Quaternion orienation)
    {
        Position = Vec3f();
        Orientation = orienation;
    }

    /// Gets the orientation matrix created from the orientation of the rigid transform.
    MatrixR OrientationMatrix
    {
        get
        {
            MatrixR toReturn;
            toReturn.CreateFromQuaternion(Orientation);
            return toReturn;
        }
    }

    /// Gets the 4x4 matrix created from the rigid transform.
    MatrixR Matrix
    {
        get
        {
            MatrixR toReturn;
            toReturn.CreateFromQuaternion(Orientation);
            toReturn.Translation = Position;
            return toReturn;
        }
    }  

    /// Gets the identity rigid transform.
    RigidTransform Identity 
    {
        get
        {
            RigidTransform t = RigidTransform(Position, Orientation);
            return t;
        }
    }

    /// Inverts a rigid transform.
    void Invert(RigidTransform transform, RigidTransform &out inverse)
    {
        Vec3f pos;
        inverse.Orientation.Conjugate(transform.Orientation);
        inverse.Orientation.Transform(transform.Position, pos);
        inverse.Position = -pos;
    }

    /// Concatenates a rigid transform with another rigid transform.
    void Multiply(RigidTransform a, RigidTransform b, RigidTransform &out combined)
    {
        Vec3f intermediate;
        b.Orientation.Transform(a.Position, intermediate);
        combined.Position += (intermediate+b.Position);
        a.Orientation.Concatenate(b.Orientation, combined.Orientation);

    }

    /// Concatenates a rigid transform with another rigid transform's inverse.
    void MultiplyByInverse(RigidTransform a, RigidTransform b, RigidTransform &out combinedTransform)
    {
        Invert(b, combinedTransform);
        Multiply(a, combinedTransform, combinedTransform);
    }

    /// Transforms a position by a rigid transform.
    void Transform(Vec3f position, RigidTransform transform, Vec3f &out result)
    {
        Vec3f intermediate = transform.Orientation.Transform(position);
        result = intermediate+transform.Position;
    }
    /// Transforms a position by a rigid transform's inverse.
    void TransformByInverse(Vec3f position, RigidTransform transform, Vec3f &out result)
    {
        Quaternion orientation;
        orientation.Conjugate(transform.Orientation);
        Vec3f intermediate = position-transform.Position;
        orientation.Transform(intermediate, result);
    }

    Vec3f Transform(Vec3f position)
    {
        Vec3f intermediate = this.Orientation.Transform(position);
        return intermediate + this.Position;
    }
    Vec3f TransformByInverse(Vec3f position)
    {
        Quaternion orientation();
        Vec3f intermediate = position-this.Position;
        orientation.Conjugate(this.Orientation);
        return orientation.Transform(intermediate);
    }
}
