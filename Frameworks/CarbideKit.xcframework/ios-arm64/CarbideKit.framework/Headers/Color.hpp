//
//  Color.hpp
//  Carbide
//
//  Created by John Millard on 20/3/19.
//  Copyright © 2019 John Millard. All rights reserved.
//

#ifndef Color_hpp
#define Color_hpp

#include "bgfx.h"   //Framework header

#include <glm/vec4.hpp>
#include <glm/glm.hpp>
#include <glm/gtc/color_space.hpp>

namespace Carbide
{
    struct Color
    {
        Color();
        Color(const Color& color);
        Color(float c);
        Color(float r, float g, float b, float a = 1.0);
        Color(const glm::vec4& v);
        
        float r, g, b, a;
        
        static uint32_t toIntRGBA(const Color& color)
        {
            uint8_t r = (uint8_t)(255*(color.r < 0 ? 0 : color.r));
            uint8_t g = (uint8_t)(255*(color.g < 0 ? 0 : color.g));
            uint8_t b = (uint8_t)(255*(color.b < 0 ? 0 : color.b));
            uint8_t a = (uint8_t)(255*(color.a < 0 ? 0 : color.a));
            return (r<<24) | (g<<16) | (b<<8) | a;
        }

        static uint32_t toIntABGR(const Color& color)
        {
            uint8_t r = (uint8_t)(255*(color.r < 0 ? 0 : color.r));
            uint8_t g = (uint8_t)(255*(color.g < 0 ? 0 : color.g));
            uint8_t b = (uint8_t)(255*(color.b < 0 ? 0 : color.b));
            uint8_t a = (uint8_t)(255*(color.a < 0 ? 0 : color.a));
            return (a<<24) | (b<<16) | (g<<8) | r;
        }
        
        static Color toColor(uint32_t color)
        {
            Color out;
            out.r = float((color >> 24) & 0xFF) / 255.0f;
            out.g = float((color >> 16) & 0xFF) / 255.0f;
            out.b = float((color >> 8) & 0xFF) / 255.0f;
            out.a = float(color & 0xFF) / 255.0f;
            return out;
        }
        
        bool operator==(const Color& rhs) const
        {
            return (r == rhs.r) && (g == rhs.g) && (b == rhs.b) && (a == rhs.a);
        }
        
        Color operator+(const Color& rhs) const
        {
            return {r + rhs.r, g + rhs.g, b + rhs.b, a + rhs.a};
        }

        Color operator-(const Color& rhs) const
        {
            return {r - rhs.r, g - rhs.g, b - rhs.b, a - rhs.a};
        }

        Color operator*(float rhs) const
        {
            return {r * rhs, g * rhs, b * rhs, a * rhs};
        }

        Color operator/(float rhs) const
        {
            return {r / rhs, g / rhs, b / rhs, a / rhs};
        }
                
        static Color lerp(const Color& lhs, const Color& rhs, float t)
        {
            return lhs * (1 - t) + rhs * t;
        }

        Color linear() { return toLinear(*this); }
        Color gamma() { return toGamma(*this); }
        Color grayscale() { return toGrayscale(*this); }
        glm::vec3 hsv() { return toHSV(*this); }
        
        static Color black() { return Color{0, 0, 0, 1}; }
        static Color white() { return Color{1, 1, 1, 1}; }
        static Color clear() { return Color{0, 0, 0, 0}; }
        static Color cyan() { return Color{0, 1, 1, 1}; }
        static Color gray() { return Color{0.5f, 0.5f, 0.5f, 1}; }
        static Color grey() { return gray(); }
        static Color red() { return Color{1, 0, 0, 1}; }
        static Color green() { return Color{0, 1, 0, 1}; }
        static Color blue() { return Color{0, 0, 1, 1}; }
        static Color magenta() { return Color{1, 0, 1, 1}; }
        static Color yellow() { return Color{1, 0.92f, 0.016f, 1}; }
        
        static Color toGrayscale(const Color& in);                
        static glm::vec3 toHSV(const Color& in);
        static Color fromHSV(const glm::vec3& in);
        static Color fromHSV(float hue, float saturation, float vibrance);
                
        static Color toLinear(const Color& c)
        {                        
            glm::vec3 v = glm::convertSRGBToLinear(glm::vec3(c.r, c.g, c.b));
            return Color{v.r, v.g, v.b, c.a};
        }
                
        static Color toGamma(const Color& c)
        {
            glm::vec3 v = glm::convertLinearToSRGB(glm::vec3(c.r, c.g, c.b));
            return Color{v.r, v.g, v.b, c.a};
        }

    };
}


#endif /* Color_hpp */
