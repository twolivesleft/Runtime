//
//  Runtime.hpp
//  Carbide
//
//  Created by John Millard on 19/3/19.
//  Copyright © 2019 John Millard. All rights reserved.
//

#ifndef Runtime_hpp
#define Runtime_hpp

#include <vector>
#include <optional>

#include "Forward.hpp"

#include "RenderModule.hpp"
#include "SoundModule.hpp"
#include "TimeModule.hpp"
#include "PhysicsModule.hpp"
#include "SceneModule.hpp"
#include "ImguiModule.hpp"
#include "ParameterModule.hpp"
#include "InspectorModule.hpp"
#include "OutputModule.hpp"
#include "InputModule.hpp"
#include "AssetModule.hpp"
#include "SensorModule.hpp"
#include "MotionModule.hpp"
#include "VoxelModule.hpp"

#include <fmt/core.h>

#include <LuaKit/LuaLibraries.h>

namespace Carbide
{
    
    class Runtime
    {
    public:
        
        static constexpr const uint32_t VersionMajor = 4;
        static constexpr const uint32_t VersionMinor = 0;
        
        static std::optional<std::reference_wrapper<Runtime>> instance(lua_State* L);
        
        Runtime();
        ~Runtime();
        
        void init();
        bool hasInitialized() { return m_initCalled; }
        void setup();
        bool draw();
        void shutdown();
        void reset();
        bool isShutdown() const { return m_modules.empty(); }
        
        template<typename... Args>
        std::optional<sol::protected_function_result> callGlobalLuaFunction(const char* name, Args&&... args)
        {
            sol::protected_function func = lua()[name];
            if (!func.valid())
            {
                return std::nullopt;
            }
            
            sol::protected_function_result result;
            
            // Prefix with __ as the trampolineName
            std::string trampolineName = std::string("__") + name;
            sol::protected_function trampoline = lua()[trampolineName];
            
            if (trampoline.valid())
            {
                result = trampoline(std::forward<Args>(args)...);
            }
            else
            {
#if DEBUG
                output().error(fmt::format("Missing trampoline for global Lua function {}", name).c_str());
#endif
                result = func(std::forward<Args>(args)...);
            }
            
            checkFunctionResult(name, result);
            
            return result;
        }
        
        void checkFunctionResult(const char* name, const sol::protected_function_result& result);
        bool loadString(const char* code, std::string* errors = nullptr);
        bool loadString(const char* code, const char* bufferName, std::string* errors = nullptr);
        bool loadFile(const char* path, std::string* errors = nullptr);
        bool require(const char* package, std::string* errors = nullptr);
        
        template<typename T>
        T* registerModule(std::unique_ptr<T> module) {
            T* raw = module.get();
            m_modules.push_back(std::move(module));
            raw->didRegister(*this);
            return raw;
        }
        
        template<typename T, typename... Args>
        T* makeModule(Args&&... args) {
            return registerModule(std::make_unique<T>(std::forward<Args>(args)...));
        }
        
        template <typename T>
        T* getModule() const {
            for (const auto& mod : m_modules) {
                if (auto* casted = dynamic_cast<T*>(mod.get())) {
                    return casted;
                }
            }
            return nullptr;
        }
                
        RenderModule& render() {
            auto* r = getModule<RenderModule>();
            assert(r && "Render module not initialized");
            return *r;
        }

        SoundModule& sound() {
            auto* r = getModule<SoundModule>();
            assert(r && "Sound module not initialized");
            return *r;
        }

        TimeModule& time() {
            auto* r = getModule<TimeModule>();
            assert(r && "Time module not initialized");
            return *r;
        }

        PhysicsModule& physics() {
            auto* r = getModule<PhysicsModule>();
            assert(r && "Physics module not initialized");
            return *r;
        }

        SceneModule& scene() {
            auto* r = getModule<SceneModule>();
            assert(r && "Scene module not initialized");
            return *r;
        }

        ImguiModule& imgui() {
            auto* r = getModule<ImguiModule>();
            assert(r && "Imgui module not initialized");
            return *r;
        }

        ParameterModule& parameter() {
            auto* r = getModule<ParameterModule>();
            assert(r && "Parameter module not initialized");
            return *r;
        }

        InspectorModule& inspector() {
            auto* r = getModule<InspectorModule>();
            assert(r && "Inspector module not initialized");
            return *r;
        }

        OutputModule& output() {
            auto* r = getModule<OutputModule>();
            assert(r && "Output module not initialized");
            return *r;
        }

        InputModule& input() {
            auto* r = getModule<InputModule>();
            assert(r && "Input module not initialized");
            return *r;
        }

        AssetModule& assets() {
            auto* r = getModule<AssetModule>();
            assert(r && "Asset module not initialized");
            return *r;
        }

        SensorModule& sensor() {
            auto* r = getModule<SensorModule>();
            assert(r && "Sensor module not initialized");
            return *r;
        }

        MotionModule& motion() {
            auto* r = getModule<MotionModule>();
            assert(r && "Motion module not initialized");
            return *r;
        }
                
        sol::state& lua() { return m_luaState; }
        
    private:
        void setupLua();
        void shutdownLua();
        void drawStatsOverlay();
        void pollDebuggee();
        
        std::vector<std::unique_ptr<Module>> m_modules;
                
        bool m_initCalled { false };
        int m_frameCount {0};
            
        sol::state m_luaState;
        sol::protected_function m_legacyWillDraw;
    };
    
}

#endif /* Runtime_hpp */
