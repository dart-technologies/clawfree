#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uAmplitude;  // 0.0 = idle, 1.0 = full listening
uniform vec3 uColor;
uniform float uMood; // 0=idle, 1=thinking, 2=listening, 3=speaking, 4=error

out vec4 fragColor;

// Smooth-minimum for organic metaball merging.
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// SDF circle.
float sdCircle(vec2 p, vec2 center, float radius) {
    return length(p - center) - radius;
}

// Value noise for organic wobble.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = (fragCoord - 0.5 * uResolution) / min(uResolution.x, uResolution.y);

    float t = uTime;
    
    // Mood-based parameters
    float chaotic = 0.0;
    float freq = 1.0;
    float speed = 0.7;
    
    if (uMood == 1.0) { // thinking
        chaotic = 0.05;
        freq = 2.5;
        speed = 1.5;
    } else if (uMood == 2.0) { // listening
        chaotic = 0.02;
        freq = 1.2;
        speed = 1.0;
    } else if (uMood == 3.0) { // speaking
        chaotic = 0.01;
        freq = 0.8;
        speed = 0.5;
    } else if (uMood == 4.0) { // error
        chaotic = 0.1;
        freq = 4.0;
        speed = 2.0;
    }

    float amp = (0.04 + uAmplitude * 0.08) * (1.0 + chaotic);
    float baseR = 0.25 + uAmplitude * 0.05;

    // Per-blob phase offsets
    float p1 = 0.0, p2 = 1.7, p3 = 3.4, p4 = 5.1, p5 = 6.8;

    // Organic wobble
    float w1 = noise(vec2(t * 0.3 * speed + p1, 0.0)) * 0.03;
    float w2 = noise(vec2(t * 0.3 * speed + p2, 1.0)) * 0.03;
    float w3 = noise(vec2(t * 0.3 * speed + p3, 2.0)) * 0.03;
    float w4 = noise(vec2(t * 0.3 * speed + p4, 3.0)) * 0.03;
    float w5 = noise(vec2(t * 0.3 * speed + p5, 4.0)) * 0.03;

    // Wandering circles
    vec2 c1 = vec2(sin(t * speed * freq + p1) * amp + w1, cos(t * speed * 1.2 * freq + p1) * amp + w1);
    vec2 c2 = vec2(cos(t * speed * 1.5 * freq + p2) * amp + w2, sin(t * speed * freq + p2) * amp + w2);
    vec2 c3 = vec2(sin(t * speed * 0.8 * freq + p3) * amp + w3, cos(t * speed * 1.8 * freq + p3) * amp + w3);
    vec2 c4 = vec2(cos(t * speed * 1.1 * freq + p4) * amp + w4, sin(t * speed * 1.4 * freq + p4) * amp + w4);
    vec2 c5 = vec2(sin(t * speed * 1.3 * freq + p5) * amp + w5, cos(t * speed * freq + p5) * amp + w5);

    float r1 = baseR + sin(t * 1.2 + p1) * 0.02;
    float r2 = baseR * 0.85 + cos(t * 0.8 + p2) * 0.02;
    float r3 = baseR * 0.75 + sin(t * 1.5 + p3) * 0.015;
    float r4 = baseR * 0.7 + cos(t * 1.1 + p4) * 0.015;
    float r5 = baseR * 0.65 + sin(t * 0.9 + p5) * 0.015;

    float d1 = sdCircle(uv, c1, r1);
    float d2 = sdCircle(uv, c2, r2);
    float d3 = sdCircle(uv, c3, r3);
    float d4 = sdCircle(uv, c4, r4);
    float d5 = sdCircle(uv, c5, r5);

    float d = smin(d1, d2, 0.15);
    d = smin(d, d3, 0.15);
    d = smin(d, d4, 0.15);
    d = smin(d, d5, 0.15);

    float edge = smoothstep(0.02, -0.03, d);
    float glow = smoothstep(0.12, -0.05, d) * 0.3;

    float coreDist = length(uv);
    float corePulse = 0.3 + uAmplitude * 0.5 * (0.5 + 0.5 * sin(t * 3.0 * freq));
    float coreGlow = smoothstep(0.15, 0.0, coreDist) * corePulse * edge;

    float hueShift = uAmplitude * 0.15 * sin(t * 1.5);
    if (uMood == 1.0) hueShift = 0.1 * sin(t * 5.0); // fast shimmer when thinking
    
    vec3 shiftedColor = uColor + vec3(hueShift, -hueShift * 0.5, -hueShift);
    shiftedColor = clamp(shiftedColor, 0.0, 1.0);

    vec3 col = shiftedColor * (edge + glow) + vec3(1.0) * coreGlow;
    float alpha = edge + glow + coreGlow * 0.5;

    fragColor = vec4(col, alpha);
}
