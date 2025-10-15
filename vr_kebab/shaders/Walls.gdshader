shader_type spatial;

uniform sampler2D brick_texture : source_color; // front texture
uniform sampler2D pink_texture : source_color;  // back texture

// Direction of the "front" face in local space
uniform vec3 front_direction = vec3(0, 0, 1);

void fragment() {
    // NORMAL is already in local space
    vec3 local_normal = normalize(NORMAL);

    float alignment = dot(local_normal, normalize(front_direction));

    if (alignment > 0.9) {
        // Front face → brick
        ALBEDO = texture(brick_texture, UV).rgb;
    } else if (alignment < -0.9) {
        // Back face → pink
        ALBEDO = texture(pink_texture, UV).rgb;
    } else {
        // Other faces → optional side color
        ALBEDO = vec3(0.8, 0.8, 0.8);
    }
}
