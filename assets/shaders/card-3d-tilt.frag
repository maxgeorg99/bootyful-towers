// Card 3D Tilt Fragment Shader
// Creates a 3D tilting effect using simple coordinate transformation

extern vec2 u_mouse;       // Mouse position relative to card (0-1 range)
extern float u_tilt_strength; // How strong the tilt effect is (default: 0.2)

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Normalize mouse position to -1 to 1 range
    vec2 mouse_norm = (u_mouse * 2.0) - 1.0;
    
    // Calculate distance from center to mouse
    float distance_from_center = length(mouse_norm);
    
    // Only apply tilt if mouse is within reasonable distance
    float tilt_factor = smoothstep(0.0, 0.8, distance_from_center);
    
    // Create a simple tilt effect by shifting texture coordinates
    // This simulates 3D rotation without complex perspective math
    vec2 center_offset = texture_coords - 0.5;
    
    // Calculate tilt offsets based on mouse position
    float tilt_x = mouse_norm.x * u_tilt_strength * tilt_factor * 0.1;
    float tilt_y = mouse_norm.y * u_tilt_strength * tilt_factor * 0.1;
    
    // Apply tilt transformation
    vec2 tilted_coords = vec2(
        center_offset.x + tilt_x * center_offset.y,
        center_offset.y + tilt_y * center_offset.x
    );
    
    // Convert back to texture coordinates
    vec2 final_tex_coords = tilted_coords + 0.5;
    
    // Clamp texture coordinates to prevent sampling outside the texture
    final_tex_coords = clamp(final_tex_coords, 0.0, 1.0);
    
    // Sample the texture with the transformed coordinates
    vec4 tex_color = Texel(texture, final_tex_coords);
    
    // Add subtle edge darkening based on distance from center
    float edge_darken = 1.0 - (distance_from_center * 0.15);
    edge_darken = clamp(edge_darken, 0.85, 1.0);
    
    // Apply edge darkening and original color
    tex_color.rgb *= edge_darken;
    tex_color *= color;
    
    // Add subtle highlight based on mouse position
    float highlight = max(0.0, (1.0 - distance_from_center) * 0.08);
    tex_color.rgb += highlight * vec3(0.05, 0.05, 0.08);
    
    return tex_color;
}
