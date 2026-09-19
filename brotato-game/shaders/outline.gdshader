shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    
    // Muestrear los 4 lados para el outline
    float alpha = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a +
                 texture(TEXTURE, UV + vec2(size.x, 0.0)).a +
                 texture(TEXTURE, UV + vec2(0.0, -size.y)).a +
                 texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    
    // Muestrear las esquinas para el glow
    alpha += (texture(TEXTURE, UV + vec2(-size.x, -size.y)).a +
             texture(TEXTURE, UV + vec2(size.x, -size.y)).a +
             texture(TEXTURE, UV + vec2(-size.x, size.y)).a +
             texture(TEXTURE, UV + vec2(size.x, size.y)).a) * 0.5;
    
    // Aplicar el glow y mezclar con el color original
    vec4 glow = vec4(outline_color.rgb, outline_color.a * alpha * glow_intensity);
    COLOR = mix(glow, color, color.a);
} 