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

// MARK: - Layer Compositing Shaders

struct CompositeVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Full-screen quad vertex shader for layer compositing
vertex CompositeVertexOut composite_vertex(uint vertexID [[vertex_id]]) {
    // Full-screen quad vertices
    constant float2 positions[6] = {
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
