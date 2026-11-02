            float hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = hash(i);
                float b = hash(i + vec2(1.0, 0.0));
                float c = hash(i + vec2(0.0, 1.0));
                float d = hash(i + vec2(1.0, 1.0));
                return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
            }

            float fbm(vec2 p) {
                float v = 0.0;
                float amp = 0.5;
                for (int i = 0; i < 4; i++) {
                    v += amp * noise(p);
                    p *= 2.0;
                    amp *= 0.5;
                }
                return v;
            }

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;
                float seed = niri_random_seed * 100.0;

                float rp = 1.0 - p;

                float particle_noise = fbm(uv * 8.0 + seed);
                float fine_noise = hash(floor(uv * 60.0) + seed);

                float direction_bias = (1.0 - uv.x) * 0.4 + uv.y * 0.4;
                float dissolve_threshold = particle_noise * 0.5 + fine_noise * 0.2 + direction_bias;

                float reveal = smoothstep(dissolve_threshold - 0.15, dissolve_threshold + 0.15, p * 1.6);

                float drift = rp * rp;
                vec2 drift_dir = normalize(vec2(1.0, -1.0));
                float drift_amount = drift * 0.08 * (particle_noise + fine_noise * 0.5);
                vec2 displaced_uv = uv + drift_dir * drift_amount * (1.0 - reveal);

                vec3 tex_coords = niri_geo_to_tex * vec3(displaced_uv, 1.0);
                vec4 color = texture2D(niri_tex, tex_coords.st);

                float alpha = smoothstep(0.0, 0.1, p);

                return color * reveal * alpha;
            }
