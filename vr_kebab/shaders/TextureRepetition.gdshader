shader_type spatial;

uniform sampler2D albedo_tex : source_color;
uniform sampler2D macro_noise_tex;
uniform float triplanar_scale : hint_range(0.1, 10.0) = 2.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.3;
uniform float macro_scale : hint_range(0.01, 1.0) = 0.1;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

vec3 triplanar_texture(sampler2D tex, vec3 pos, vec3 normal, float scale) {
    vec3 blending = abs(normal);
    blending = normalize(max(blending, 0.00001));
    blending /= (blending.x + blending.y + blending.z);
    
    vec3 xaxis = texture(tex, pos.yz * scale).rgb;
    vec3 yaxis = texture(tex, pos.xz * scale).rgb;
    vec3 zaxis = texture(tex, pos.xy * scale).rgb;
    
    return xaxis * blending.x + yaxis * blending.y + zaxis * blending.z;
}

void fragment() {
    vec3 n = normalize(world_normal);
    
    // Base triplanar color
    vec3 base = triplanar_texture(albedo_tex, world_pos, n, triplanar_scale);
    
    // Macro noise to break up repetition
    float macro = texture(macro_noise_tex, world_pos.xz * macro_scale).r;
    base *= mix(1.0, macro, noise_strength);
    
    ALBEDO = base;
}
