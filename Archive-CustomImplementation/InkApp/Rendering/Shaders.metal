//
//  Shaders.metal
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Structures

struct VertexIn {
    float2 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// MARK: - Vertex Shader

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.position * 0.5 + 0.5; // Convert from [-1,1] to [0,1]
    return out;
}

// MARK: - Fragment Shader

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    // Currently just returns white
    // Will be enhanced with texture sampling and pattern rendering
    return float4(1.0, 1.0, 1.0, 1.0);
}

// MARK: - Pattern Rendering Shaders

struct PatternVertexIn {
    float2 position [[attribute(0)]];
};

struct PatternVertexOut {
    float4 position [[position]];
};

// Pattern vertex shader
vertex PatternVertexOut pattern_vertex(
    uint vertexID [[vertex_id]],
    constant float2 *vertices [[buffer(0)]]
) {
    PatternVertexOut out;
    out.position = float4(vertices[vertexID], 0.0, 1.0);
    return out;
}

// Pattern fragment shader
fragment float4 pattern_fragment(
    PatternVertexOut in [[stage_in]],
    constant float4 &color [[buffer(0)]]
) {
    return color;
}

// MARK: - Brush Rendering Shaders (Solid Brush/Marker)

struct BrushVertex {
    float2 position;
    float2 uv;
};

struct BrushVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct BrushUniforms {
    float4 color;      // RGBA
    float hardness;    // 0=soft, 1=hard
};

// Brush vertex shader
vertex BrushVertexOut brush_vertex(
    uint vertexID [[vertex_id]],
    constant BrushVertex *vertices [[buffer(0)]]
) {
    BrushVertexOut out;
    out.position = float4(vertices[vertexID].position, 0.0, 1.0);
    out.uv = vertices[vertexID].uv;
    return out;
}

// Brush fragment shader with circular gradient
fragment float4 brush_fragment(
    BrushVertexOut in [[stage_in]],
    constant BrushUniforms &uniforms [[buffer(0)]]
) {
    // Calculate distance from center (UV coordinates range from 0-1)
    float2 center = float2(0.5, 0.5);
    float dist = distance(in.uv, center) * 2.0; // Scale to 0-1 (radius)

    // Apply hardness to create soft or hard edges
    // hardness=1.0: sharp edge, hardness=0.0: very soft edge
    float edge = smoothstep(uniforms.hardness, 1.0, dist);
    float alpha = 1.0 - edge;

    // Apply alpha to color
    float4 color = uniforms.color;
    color.a *= alpha;

    return color;
}

// MARK: - Layer Compositing Shaders

struct CompositeVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Full-screen quad vertex shader for layer compositing
vertex CompositeVertexOut composite_vertex(uint vertexID [[vertex_id]]) {
    // Full-screen quad vertices
    const float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0),
        float2(-1.0,  1.0)
    };

    CompositeVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = positions[vertexID] * 0.5 + 0.5;
    return out;
}

// Layer compositing fragment shader
fragment float4 composite_fragment(
    CompositeVertexOut in [[stage_in]],
    texture2d<float> baseTexture [[texture(0)]],
    texture2d<float> layerTexture [[texture(1)]],
    texture2d<float> maskTexture [[texture(2)]],
    constant float &opacity [[buffer(0)]]
) {
    constexpr sampler textureSampler(
        mag_filter::linear,
        min_filter::linear,
        address::clamp_to_edge
    );

    float4 baseColor = baseTexture.sample(textureSampler, in.texCoord);
    float4 layerColor = layerTexture.sample(textureSampler, in.texCoord);

    // Sample mask (0 = transparent, 1 = opaque)
    float maskValue = maskTexture.sample(textureSampler, in.texCoord).r;

    // Apply mask and opacity
    float alpha = layerColor.a * maskValue * opacity;

    // Alpha blend
    float4 result;
    result.rgb = baseColor.rgb * (1.0 - alpha) + layerColor.rgb * alpha;
    result.a = baseColor.a;

    return result;
}

// MARK: - Blend Mode Functions

// Multiply blend mode
float3 blendMultiply(float3 base, float3 blend) {
    return base * blend;
}

// Screen blend mode
float3 blendScreen(float3 base, float3 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

// Overlay blend mode
float3 blendOverlay(float3 base, float3 blend) {
    float3 result;
    for (int i = 0; i < 3; i++) {
        if (base[i] < 0.5) {
            result[i] = 2.0 * base[i] * blend[i];
        } else {
            result[i] = 1.0 - 2.0 * (1.0 - base[i]) * (1.0 - blend[i]);
        }
    }
    return result;
}

// Add blend mode (linear dodge)
float3 blendAdd(float3 base, float3 blend) {
    return min(base + blend, float3(1.0));
}

// Darken blend mode
float3 blendDarken(float3 base, float3 blend) {
    return min(base, blend);
}

// Lighten blend mode
float3 blendLighten(float3 base, float3 blend) {
    return max(base, blend);
}

// MARK: - Advanced Layer Compositing Shader

struct CompositeParams {
    float opacity;
    int blendMode; // 0=normal, 1=multiply, 2=screen, 3=overlay, 4=add, 5=darken, 6=lighten
};

// Advanced layer compositing with blend modes and mask support
fragment float4 layer_composite_fragment(
    CompositeVertexOut in [[stage_in]],
    texture2d<float> baseTexture [[texture(0)]],
    texture2d<float> layerTexture [[texture(1)]],
    texture2d<float> maskTexture [[texture(2)]],
    constant CompositeParams &params [[buffer(0)]]
) {
    constexpr sampler textureSampler(
        mag_filter::linear,
        min_filter::linear,
        address::clamp_to_edge
    );

    float4 baseColor = baseTexture.sample(textureSampler, in.texCoord);
    float4 layerColor = layerTexture.sample(textureSampler, in.texCoord);

    // Sample mask texture (white = 1.0 = visible, black = 0.0 = hidden)
    float maskValue = maskTexture.sample(textureSampler, in.texCoord).r;

    // Early exit if layer is fully transparent or masked out
    if (layerColor.a == 0.0 || maskValue == 0.0) {
        return baseColor;
    }

    // Apply blend mode
    float3 blendedColor;
    switch (params.blendMode) {
        case 1: // Multiply
            blendedColor = blendMultiply(baseColor.rgb, layerColor.rgb);
            break;
        case 2: // Screen
            blendedColor = blendScreen(baseColor.rgb, layerColor.rgb);
            break;
        case 3: // Overlay
            blendedColor = blendOverlay(baseColor.rgb, layerColor.rgb);
            break;
        case 4: // Add
            blendedColor = blendAdd(baseColor.rgb, layerColor.rgb);
            break;
        case 5: // Darken
            blendedColor = blendDarken(baseColor.rgb, layerColor.rgb);
            break;
        case 6: // Lighten
            blendedColor = blendLighten(baseColor.rgb, layerColor.rgb);
            break;
        default: // Normal
            blendedColor = layerColor.rgb;
            break;
    }

    // Apply layer opacity, alpha, and mask
    float alpha = layerColor.a * params.opacity * maskValue;

    // Final blend with base
    float4 result;
    result.rgb = mix(baseColor.rgb, blendedColor, alpha);
    result.a = max(baseColor.a, alpha);

    return result;
}

// MARK: - Texture Display Shader

// Simple texture display for rendering composited canvas to screen
fragment float4 texture_display_fragment(
    CompositeVertexOut in [[stage_in]],
    texture2d<float> displayTexture [[texture(0)]]
) {
    constexpr sampler textureSampler(
        mag_filter::linear,
        min_filter::linear,
        address::clamp_to_edge
    );

    return displayTexture.sample(textureSampler, in.texCoord);
}
