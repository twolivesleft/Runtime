//
//  Forward.hpp
//  Carbide
//
//  Created by John Millard on 22/7/21.
//  Copyright © 2021 John Millard. All rights reserved.
//

#ifndef Forward_h
#define Forward_h

#include <memory>

#include "Typedefs.hpp"

namespace Carbide
{
    // Runtime and Modules
    class Runtime;
 
    class Module;
    class RenderModule;
    class SoundModule;
    class TimeModule;
    class PhysicsModule;
    class SceneModule;
    class ParameterModule;
    class InspectorModule;
    class OutputModule;
    class InputModule;
    class AssetModule;
    class ImguiModule;
    class SensorModule;
    class MotionModule;

    // Assets
    class Shader;
    typedef std::shared_ptr<Shader> ShaderPtr;

    class Camera;
    typedef std::shared_ptr<Camera> CameraPtr;

    class Light;
    typedef std::shared_ptr<Light> LightPtr;

    class Image;
    typedef std::shared_ptr<Image> ImagePtr;

    class Atlas;
    typedef std::shared_ptr<Atlas> AtlasPtr;

    class Font;
    typedef std::shared_ptr<Font> FontPtr;

    class SoundSource;
    typedef std::shared_ptr<SoundSource> SoundSourcePtr;

    class Mesh;
    typedef std::shared_ptr<Mesh> MeshPtr;

    class Animation;
    typedef std::shared_ptr<Animation> AnimationPtr;

    class Material;
    typedef std::shared_ptr<Material> MaterialPtr;

    class SpriteSlice;
    typedef std::shared_ptr<SpriteSlice> SpriteSlicePtr;

    class Tween;
    typedef std::shared_ptr<Tween> TweenPtr;

    class Inspector;

    namespace ECS
    {
        class Scene;
        typedef std::shared_ptr<Scene> ScenePtr;
    
        class Canvas;
        typedef std::shared_ptr<Canvas> CanvasPtr;
    }

    namespace Physics2D
    {
        class World;
        typedef std::shared_ptr<World> WorldPtr;

        class Body;
        typedef std::shared_ptr<Body> BodyPtr;

        class Collider;
        typedef std::shared_ptr<Collider> ColliderPtr;

        class Joint;
        typedef std::shared_ptr<Joint> JointPtr;
    }

    namespace Physics3D
    {
        class World;
        typedef std::shared_ptr<World> WorldPtr;

        class Body;
        typedef std::shared_ptr<Body> BodyPtr;

        class Collider;
        typedef std::shared_ptr<Collider> ColliderPtr;

        class Joint;
        typedef std::shared_ptr<Joint> JointPtr;
    }

}

#endif /* Forward_h */
