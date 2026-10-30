//
//  Module.hpp
//  Carbide
//
//  Created by John Millard on 19/3/19.
//  Copyright © 2019 John Millard. All rights reserved.
//

#ifndef Module_hpp
#define Module_hpp

#import <LuaKit/LuaLibraries.h>

#include <vector>
#include <memory>
#include <map>

#include <glm/vec2.hpp>
#include <glm/vec3.hpp>
#include <glm/vec4.hpp>
#include <glm/gtc/quaternion.hpp>
#include "Color.hpp"

template <unsigned int N>
struct DynamicFloatArguments
{
public:
    
    DynamicFloatArguments() {}
    
    DynamicFloatArguments(sol::variadic_args& args)
    {
        int offset = 0;
        for (auto v : args)
        {
            if (v.is<float>())
            {
                offset += append(v.as<float>()) ? 1 : 0;
            }
            else if (v.is<glm::vec2>())
            {
                auto v2 = v.as<glm::vec2>();
                if (append(v2.x))
                {
                    append(v2.y);
                    offset++;
                }
            }
            else if (v.is<glm::vec3>())
            {
                auto v3 = v.as<glm::vec3>();
                if (append(v3.x))
                {
                    append(v3.y);
                    append(v3.z);
                    offset++;
                }
            }
            else if (v.is<glm::vec4>())
            {
                auto v4 = v.as<glm::vec4>();
                if (append(v4.x))
                {
                    append(v4.y);
                    append(v4.z);
                    append(v4.w);
                    offset++;
                }
            }
            else if (v.is<glm::quat>())
            {
                auto v4 = v.as<glm::quat>();
                if (append(v4.x))
                {
                    append(v4.y);
                    append(v4.z);
                    append(v4.w);
                    offset++;
                }
            }
            else if (v.is<Carbide::Color>())
            {
                auto c = v.as<Carbide::Color>();
                if (append(c.r))
                {
                    append(c.g);
                    append(c.b);
                    append(c.a);
                    offset++;
                }
            }
        }
        args = sol::variadic_args(args.lua_state(), args.stack_index() + offset);
    }
    
    bool append(float value)
    {
        if (m_count == N) return false;
        m_args[m_count++] = value;
        return true;
    }
    
    float get(size_t index, float opt = 0.0) const
    {
        return m_count < index ? opt : m_args[index-1];
    }
    
    size_t count() { return m_count; }
            
    const float operator[] (size_t i) const { return get(i); }
    
    void incrementStackOffset() { m_stackOffset++; }
    uint8_t stackOffset() { return m_stackOffset; }

private:
    float m_args[N];
    size_t m_count {0};
    uint8_t m_stackOffset {0};
};


template <unsigned int N, typename Handler>
bool sol_lua_check(sol::types<DynamicFloatArguments<N>>, lua_State* L, int index, Handler&& handler, sol::stack::record& tracking)
{
    int absolute_index = lua_absindex(L, index);
    int n = lua_gettop(L);

    unsigned int count = 0;
    for (int i = 0; i <= n; i++)
    {
        sol::object thing = sol::stack::get<sol::object>(L, absolute_index + i);
        int found = thing.is<float>() ? 1 : 0;
        found += thing.is<glm::vec2>() ? 2 : 0;
        found += thing.is<glm::vec3>() ? 3 : 0;
        found += thing.is<glm::vec4>() ? 4 : 0;
        found += thing.is<Carbide::Color>() ? 4 : 0;
        if (found > 0) tracking.use(found); else return false;
        count += found;
    }
    
    return count <= N;
}


template <unsigned int N>
DynamicFloatArguments<N> sol_lua_get(sol::types<DynamicFloatArguments<N>>, lua_State* L, int index, sol::stack::record& tracking)
{
    DynamicFloatArguments<N> args;
    int absolute_index = lua_absindex(L, index);
    int n = lua_gettop(L);

    for (int i = 0; i <= n; i++)
    {
        sol::object thing = sol::stack::get<sol::object>(L, absolute_index + i);
        if (thing.is<float>())
        {
            float v = thing.as<float>();
            args.append(v);
            tracking.use(1);
        }
        else if (thing.is<glm::vec2>())
        {
            glm::vec2 v = thing.as<glm::vec2>();
            args.append(v.x); args.append(v.y);
            tracking.use(1);
        }
        else if (thing.is<glm::vec3>())
        {
            glm::vec3 v = thing.as<glm::vec3>();
            args.append(v.x); args.append(v.y); args.append(v.z);
            tracking.use(1);
        }
        else if (thing.is<glm::vec4>())
        {
            glm::vec4 v = thing.as<glm::vec4>();
            args.append(v.x); args.append(v.y); args.append(v.z); args.append(v.w);
            tracking.use(1);
        }
        else if (thing.is<Carbide::Color>())
        {
            Carbide::Color v = thing.as<Carbide::Color>();
            args.append(v.r); args.append(v.g); args.append(v.b); args.append(v.a );
            tracking.use(1);
        }

    }

    return args;
}

#define CARBIDE_NO_IMPLEMENTATION(FEATURE) runtime.parameter().warning( (std::string((FEATURE)) + " is not implemented on this platform").c_str() );

namespace Carbide
{

    class Runtime;

    class Module
    {
    public:
        
        virtual ~Module() {}
        
        virtual void didRegister(Runtime& runtime) {}
        virtual void didShutdown(Runtime& runtime) {}
        virtual void willDraw(Runtime& runtime) {}
        virtual void didDraw(Runtime& runtime) {}
        
    private:
        
    };
    
}

#endif /* Module_hpp */
