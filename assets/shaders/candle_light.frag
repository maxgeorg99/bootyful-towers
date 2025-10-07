uniform float time;        // Total elapsed time
uniform float flickerSpeed;  // Speed of the candlelight flickering
uniform float flickerStrength; // Intensity of the flickering
uniform vec3 candleColor;    // Warm glow color
uniform float pulseFrequency; // How frequently the glow pulses
uniform float glowRadius;    // Size of the glow effect

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Get the original pixel color
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate distance from center for radial effects
    vec2 center = vec2(0.5, 0.5);
    float dist = length(texture_coords - center);
    
    // Flickering effect using perlin-like noise
    float t = time * flickerSpeed;
    float noise = sin(t) * 0.5 + 0.5 
                + sin(t * 1.7) * 0.25 
                + sin(t * 5.3) * 0.125 
                + sin(t * 13.7) * 0.0625;
    
    noise = (noise * 0.5 + 0.5) * flickerStrength;
    
    // Pulsing warm glow
    float pulse = (sin(time * pulseFrequency) * 0.5 + 0.5) * 0.3 + 0.7;
    
    // Create warm glow vignette effect
    float vignette = smoothstep(glowRadius, 0.1, dist) * pulse;
    
    // Apply the candle glow color
    vec3 warmGlow = mix(pixel.rgb, candleColor, vignette * noise);
    
    // Add subtle moving light spots to simulate candle movement
    float spotIntensity = 0.15 * (
        sin(texture_coords.x * 10.0 + time) * 
        sin(texture_coords.y * 10.0 + time * 0.7)
    );
    spotIntensity = max(0.0, spotIntensity);
    
    // Final color with light spots
    vec3 final = warmGlow + candleColor * spotIntensity * pulse;
    
    // Preserve original alpha
    return vec4(final, pixel.a) * color;
} 