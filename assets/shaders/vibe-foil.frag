// PREMIUM ULTRA-HOLOGRAPHIC FOIL CARD SHADER
uniform vec2 u_mouse;      // Mouse position relative to texture (0.0 to 1.0)
uniform float u_time;      // Time for animation

// Customizable parameters (with defaults)
uniform float u_rainbow_intensity = 1.5;      // Rainbow color intensity [1.0-2.0]
uniform float u_rainbow_speed = 0.3;          // Speed of rainbow color cycling [0.1-0.5]
uniform float u_pattern_density = 28.0;       // Density of holographic patterns [15.0-40.0]
uniform float u_effect_intensity = 1.2;       // Overall effect intensity [0.8-1.5]
uniform float u_flash_intensity = 0.4;        // Intensity of flashy highlights [0.2-0.6]
uniform float u_metallic_feel = 0.7;          // Metallic reflectiveness [0.5-1.0]

// GLSL utility functions
float noise(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texColor = Texel(tex, texture_coords);
    
    // Skip transparent pixels
    if (texColor.a < 0.1) {
        return texColor * color;
    }
    
    vec2 uv = texture_coords;
    vec2 center = vec2(0.5, 0.5);
    
    // Mouse-based view angle with dynamic range
    vec2 viewAngle = (u_mouse - center) * 2.0;
    float viewDist = length(viewAngle);
    
    // Time-based movement for autonomous animation even when mouse is still
    float autoTime = u_time * 0.15;
    vec2 timeShift = vec2(sin(autoTime * 0.7) * 0.1, cos(autoTime * 0.5) * 0.1);
    
    // PREMIUM HOLOGRAPHIC PATTERNS
    
    // Primary light streak pattern based on viewing angle
    float pattern1 = sin(dot(uv - center, normalize(viewAngle + timeShift)) * u_pattern_density + u_time * 0.4) * 0.5 + 0.5;
    
    // Secondary crossing pattern with different frequency
    vec2 perpDir = vec2(viewAngle.y, -viewAngle.x);
    float pattern2 = sin(dot(uv - center, normalize(perpDir + timeShift * 0.8)) * (u_pattern_density * 0.8) - u_time * 0.3) * 0.5 + 0.5;
    
    // Circular wave pattern for depth
    float dist = length(uv - center);
    float pattern3 = sin((dist * 15.0 - u_time * 0.2) * 2.0) * 0.5 + 0.5;
    
    // High-frequency detail pattern for premium look
    float pattern4 = sin(dot(uv, vec2(sin(autoTime), cos(autoTime))) * u_pattern_density * 2.0) * 0.25 + 0.75;
    
    // Dynamic swirl pattern for luxury feel
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    float pattern5 = sin((angle * 3.0 + dist * 10.0 + u_time * 0.2) * 2.0) * 0.25 + 0.75;
    
    // Combine patterns with dramatic weights
    float basePattern = pattern1 * 0.4 + pattern2 * 0.3 + pattern3 * 0.15 + pattern4 * 0.1 + pattern5 * 0.05;
    
    // Apply contrast curve for more dramatic effect
    float combinedPattern = pow(basePattern, 1.3) * 1.1;
    
    // Calculate dramatic light falloff from viewing angle
    float baseFalloff = 1.0 - smoothstep(0.0, 0.7, length(uv - (center + viewAngle * 0.25 + timeShift)));
    float falloff = pow(baseFalloff, 1.2) * (0.6 + viewDist * 0.5) * u_metallic_feel;
    
    // SPECTACULAR COLOR GENERATION
    
    // Base rainbow hue with extra modulation for variability
    float hue = combinedPattern * 5.0 + u_time * u_rainbow_speed;
    hue += sin(uv.x * 10.0 + u_time * 0.2) * 0.1 + cos(uv.y * 8.0 - u_time * 0.3) * 0.1;
    
    // Premium color palette - rich and vibrant
    vec3 red    = vec3(1.00, 0.10, 0.10);
    vec3 orange = vec3(1.00, 0.50, 0.10);
    vec3 yellow = vec3(1.00, 0.93, 0.10);
    vec3 green  = vec3(0.12, 0.95, 0.10);
    vec3 cyan   = vec3(0.10, 0.93, 0.90);
    vec3 blue   = vec3(0.15, 0.32, 1.00);
    vec3 purple = vec3(0.70, 0.10, 0.95);
    vec3 pink   = vec3(0.95, 0.30, 0.65);
    vec3 gold   = vec3(1.00, 0.84, 0.20);
    
    // Dynamic rainbow mixing - smoother and more varied across the card
    vec3 rainbowColor = 
        red    * (0.5 + 0.5 * sin(hue)) +
        orange * (0.5 + 0.5 * sin(hue + 0.7)) +
        yellow * (0.5 + 0.5 * sin(hue + 1.4)) +
        green  * (0.5 + 0.5 * sin(hue + 2.1)) +
        cyan   * (0.5 + 0.5 * sin(hue + 2.8)) +
        blue   * (0.5 + 0.5 * sin(hue + 3.5)) +
        purple * (0.5 + 0.5 * sin(hue + 4.2)) +
        pink   * (0.5 + 0.5 * sin(hue + 4.9)) +
        gold   * (0.5 + 0.5 * sin(hue + 5.6) * sin(dist * 10.0 + u_time * 0.2));
    
    // Color normalization that preserves vibrance
    float colorSum = max(length(rainbowColor), 1.0);
    rainbowColor = rainbowColor * (1.2 / colorSum) * u_rainbow_intensity;
    
    // Apply our pattern to the rainbow color with dramatic intensity
    vec3 finalHighlight = rainbowColor * combinedPattern * falloff * u_effect_intensity;
    
    // Add flashy highlight at grazing angles
    float flash = pow(max(0.0, 1.0 - abs(dot(normalize(viewAngle + timeShift), normalize(uv - center)))), 3.0) * u_flash_intensity;
    finalHighlight += vec3(flash, flash, flash) * falloff * gold;
    
    // Edge handling with dynamic border emphasis
    float edgeDist = min(min(uv.x, 1.0-uv.x), min(uv.y, 1.0-uv.y)) * 4.0;
    float edgeFactor = smoothstep(0.0, 0.4, edgeDist);
    
    // Dramatic edge highlighting (more pronounced at edges)
    float edgeGlow = (1.0 - edgeFactor) * 0.5 * (sin(u_time * 0.5) * 0.5 + 0.5);
    finalHighlight += vec3(edgeGlow * falloff * 0.5);
    
    // Apply the final highlight color to the original texture with dynamic contrast
    float blendAmount = min(edgeFactor * 0.9 + flash * 0.2, 0.95);
    vec3 finalColor = mix(texColor.rgb * 0.85, texColor.rgb * 0.6 + finalHighlight, blendAmount);
    
    // Add subtle metallic sheen across the whole card
    float sheen = (sin(uv.x * 20.0 + uv.y * 15.0 + u_time * 0.2) * 0.5 + 0.5) * 0.05 * u_metallic_feel;
    finalColor += sheen * gold * falloff;
    
    // Ensure we don't blow out to pure white by capping at 0.97
    finalColor = min(finalColor, 0.97);
    
    // Preserve original alpha
    return vec4(finalColor, texColor.a) * color;
} 