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
