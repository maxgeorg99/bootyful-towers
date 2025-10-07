extern vec4 spriteRectPx;  // (x, y, width, height) of the sprite in screen pixels
extern float fillAmount;   // 0.0 .. 1.0, fills from bottom to top
extern vec4 fillColor;     // RGBA color of the fill
extern vec2 spriteTexSize; // (width, height) in texels of the source sprite

vec4 effect(vec4 color, Image texture, vec2 texCoords, vec2 screenCoords) {
    // Sample the canvas to get the sprite's mask (alpha)
    vec4 base = Texel(texture, texCoords) * color;
    float mask = base.a;

    // Sprite rectangle in pixel space
    vec2 rectMin = spriteRectPx.xy;
    vec2 rectSize = spriteRectPx.zw;
    vec2 rectMax = rectMin + rectSize;

    // Early reject: outside sprite rect
    float insideRect = step(rectMin.x, screenCoords.x) * step(rectMin.y, screenCoords.y) *
                       step(screenCoords.x, rectMax.x) * step(screenCoords.y, rectMax.y);

    // Threshold Y measured from bottom of rect, quantized to sprite texel rows
    float clampedFill = clamp(fillAmount, 0.0, 1.0);
    float texRows = max(0.0, floor(clampedFill * spriteTexSize.y + 1e-6));
    float rowStepPx = rectSize.y / spriteTexSize.y; // screen pixels per sprite texel row
    float thresholdY = rectMax.y - texRows * rowStepPx;
    float isFill = insideRect * step(thresholdY, screenCoords.y);

    // Output either original sprite or the filled color, both masked by sprite alpha
    vec4 filled = vec4(fillColor.rgb, fillColor.a * mask);
    vec4 original = base; // already premultiplied by the sprite alpha from the canvas
    return mix(original, filled, isFill);
}

