// Fragment shader for glow effect expanding from texture edges
extern vec2 texture_size;
extern number glow_radius;
extern number glow_intensity;
extern vec3 glow_color;
extern number glow_falloff;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 original_pixel = Texel(texture, texture_coords);

    // If the current pixel is opaque, return it as-is
    if (original_pixel.a > 0.0) {
        return original_pixel * color;
    }

    // Calculate texel size for sampling
    vec2 texel_size = 1.0 / texture_size;

    // Find the distance to the nearest opaque pixel
    float min_distance = glow_radius;
    bool found_edge = false;

    // Sample in multiple directions with fixed loops
    // Check 16 directions around the current pixel
    for (int dir = 0; dir < 16; dir++) {
        float angle = float(dir) * 0.39269908; // 2*PI / 16
        vec2 direction = vec2(cos(angle), sin(angle));

        // Sample at increasing distances (fixed loop count)
        for (int step = 1; step <= 32; step++) {
            float dist = float(step);
            if (dist > glow_radius) break;

            vec2 sample_coords = texture_coords + direction * dist * texel_size;
            vec4 sample_pixel = Texel(texture, sample_coords);

            if (sample_pixel.a > 0.0) {
                min_distance = min(min_distance, dist);
                found_edge = true;
                break;
            }
        }
    }

    // If no edge found within glow radius, return transparent
    if (!found_edge) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }

    // Calculate glow intensity based on distance
    float distance_factor = 1.0 - (min_distance / glow_radius);

    // Apply falloff curve for smoother glow
    distance_factor = pow(distance_factor, glow_falloff);

    // Calculate final glow alpha
    float glow_alpha = distance_factor * glow_intensity;

    // Return glow color with calculated alpha
    return vec4(glow_color * glow_alpha, glow_alpha) * color;
}
