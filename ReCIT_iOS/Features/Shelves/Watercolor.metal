//
//  Watercolor.metal
//  ReCIT_iOS
//
//  Procedural watercolour paint for book spines, applied via SwiftUI `.colorEffect`.
//  The shape is filled with the base tint (the cover's dominant colour); this shader
//  mottles the lightness with fbm noise and darkens the edges to mimic pigment
//  pooling. Rendered statically (no time uniform). See ADR 0003.
//

#include <metal_stdlib>
using namespace metal;

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float fbm(float2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        v += amp * valueNoise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

// SwiftUI colorEffect entry point: (position, currentColor, args...) -> color.
[[ stitchable ]] half4 watercolorSpine(float2 pos, half4 color, float2 size, float seed) {
    if (size.x <= 0.0 || size.y <= 0.0) {
        return color;
    }
    float2 uv = pos / size;

    // Anisotropic noise: more variation along the spine's long axis.
    float n = fbm(uv * float2(6.0, 15.0) + seed * 13.0);

    // Pigment pooling: darker near the four edges.
    float ex = min(uv.x, 1.0 - uv.x);
    float ey = min(uv.y, 1.0 - uv.y);
    float edge = smoothstep(0.0, 0.14, ex) * smoothstep(0.0, 0.05, ey);

    float lift = mix(0.80, 1.12, n);   // uneven wash lightness
    float pool = mix(0.74, 1.0, edge); // edge darkening

    half3 rgb = color.rgb * half(lift * pool);
    rgb += half3(half((n - 0.5) * 0.05)); // faint paper grain
    rgb = clamp(rgb, half3(0.0), half3(1.0));

    return half4(rgb * color.a, color.a);
}
