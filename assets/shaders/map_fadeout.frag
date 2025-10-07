uniform float fadeEdge = 0.3; // Size of fade edge (0.0 to 0.5)
uniform vec4 fadeColor = vec4(0.1, 0.1, 0.15, 1.0); // Color to fade to (dark gray/blue)
uniform float fadeTime = 0.0; // Animation progress (0.0 to 1.0)
uniform float time = 0.0; // Global time for animations

// Deterministic pattern function using sine waves
float pattern(vec2 st) {
    return 0.5 + 0.5 * sin(st.x * 10.0) * sin(st.y * 10.0);
}

// More complex wave pattern using multiple sine/cosine functions
float wavePattern(vec2 st) {
    float wave1 = 0.5 + 0.5 * sin(st.x * 12.0 + time * 0.3) * sin(st.y * 12.0 + time * 0.2);
    float wave2 = 0.5 + 0.5 * cos(st.x * 8.0 - time * 0.2) * cos(st.y * 8.0 + time * 0.4);
    return mix(wave1, wave2, 0.5 + 0.5 * sin(time * 0.1));
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Create distortion in texture coordinates using sine waves instead of noise
    float distortionAmount = 0.015 * sin(time * 0.5);
    vec2 distortion = vec2(
        sin(texture_coords.x * 15.0 + time * 0.2) * cos(texture_coords.y * 10.0 + time * 0.3) * distortionAmount,
        cos(texture_coords.x * 12.0 - time * 0.15) * sin(texture_coords.y * 14.0 + time * 0.25) * distortionAmount
    );
    
    // Apply distortion to texture coordinates
    vec2 distortedCoords = texture_coords + distortion;
    
    // Sample the texture with distorted coordinates
    vec4 texColor = Texel(texture, distortedCoords) * color;
    
    // Calculate breathing effect
    float breathingEffect = 0.15 * sin(time * 0.4) + 0.85;
    
    // Calculate distance from center with slight variation
    vec2 center = vec2(0.5 + 0.02 * sin(time * 0.3), 0.5 + 0.02 * cos(time * 0.27));
    float dist = length(texture_coords - center) * 1.414 * breathingEffect;
    
    // Add edge variation using sine patterns instead of noise
    float edgeVariation = 0.05 * sin(texture_coords.x * 20.0 + time) * sin(texture_coords.y * 20.0 + time * 1.3);
    
    // Calculate fade factor based on distance from center with wave pattern
    float fadeAmount = fadeEdge + fadeTime * 0.2 + edgeVariation;
    float fadeFactor = smoothstep(1.0 - fadeAmount, 1.0, dist);
    
    // Create a slight color variation based on time
    vec4 dynamicFadeColor = fadeColor;
    dynamicFadeColor.r += 0.05 * sin(time * 0.7);
    dynamicFadeColor.g += 0.05 * sin(time * 0.5);
    dynamicFadeColor.b += 0.08 * sin(time * 0.3);
    
    // Add a shimmer effect using sine waves instead of random
    float shimmerWave = sin(texture_coords.x * 30.0 + time * 2.0) * cos(texture_coords.y * 30.0 + time * 1.7);
    float shimmer = pow(0.5 + 0.5 * shimmerWave, 4.0) * fadeFactor * fadeFactor * 0.5;
    vec4 shimmerColor = vec4(0.3, 0.4, 0.6, 1.0) * shimmer;
    
    // Mix between the texture color and the fade color with shimmer
    vec4 finalColor = mix(texColor, dynamicFadeColor, fadeFactor) + shimmerColor;
    
    return finalColor;
} 