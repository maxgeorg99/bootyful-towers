#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;

// Simple noise function
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D noise with smoother interpolation
float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Use world coordinates (screen_coords) for continuous noise across all tiles
    // Scale down the world coordinates to get appropriate noise frequency
    vec2 world_noise_coords = screen_coords / 20.0; // Larger scale to create bigger coherent patches
    world_noise_coords.x += u_time * 1.5; // Pan from left to right over time
    
    // Get noise value based on world position
    float noise_value = smooth_noise(world_noise_coords);
    
    // Only show displacement in the top 10% of noise values
    // This creates a much more subtle, sparse wave effect
    float threshold_low = 0.85;
    float threshold_high = 0.9;
    
    // Use step function to only activate in top 10% of noise range
    float stepped_noise = step(threshold_high, noise_value);
    
    // Step function: offset texture coordinates when noise > threshold
    vec2 displaced_coords = texture_coords;
    if (stepped_noise > 0.5) {
        // Offset by exactly 1 texel in texture space
        // This creates actual texture displacement, not just a color change
        displaced_coords.x += 1.0 / 48.0; // 1 texel offset to the right
    }
    
    // Wrap coordinates to handle displacement at edges
    displaced_coords = fract(displaced_coords);
    
    // Sample the texture with the displaced coordinates
    vec4 final_color = Texel(texture, displaced_coords);
    
    return final_color * color;
}
