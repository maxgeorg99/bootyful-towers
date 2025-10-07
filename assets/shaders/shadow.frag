 uniform vec2 shadow_offset;
        uniform vec4 shadow_color;
        uniform float shadow_blur;
        uniform float shadow_intensity;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 text_pixel = Texel(texture, texture_coords);

            if (text_pixel.a > 0.0) {
                return text_pixel * color;
            }

            // Better sampling pattern
            float shadow_alpha = 0.0;
            vec2 texel_size = vec2(1.0) / love_ScreenSize.xy;

            // 16-point sampling in a circle
            for (int i = 0; i < 16; i++) {
                float angle = float(i) * 6.28318 / 16.0;  // 2*PI / 16

                for (float r = 1.0; r <= shadow_blur; r += 1.0) {
                    vec2 offset = vec2(cos(angle), sin(angle)) * r * texel_size * 20.0;
                    vec2 sample_coords = texture_coords + shadow_offset * texel_size * 20.0 + offset;

                    if (sample_coords.x >= 0.0 && sample_coords.y >= 0.0 &&
                        sample_coords.x <= 1.0 && sample_coords.y <= 1.0) {
                        vec4 sample_pixel = Texel(texture, sample_coords);

                        // Distance-based falloff
                        float falloff = 1.0 / (1.0 + r * 0.5);
                        shadow_alpha += sample_pixel.a * falloff;
                    }
                }
            }

            shadow_alpha *= shadow_intensity / (16.0 * shadow_blur);
            return shadow_color * shadow_alpha;
        }
