#version 450 core

out vec4 FragColor;
in vec2 TexCoord;
in float occlusion;

uniform sampler2D outTexture;

// float getshade( ){

//     float sqrt2 = pow( 2.0 , 0.5 );
//     float dx = 1 - ( pow( ( pow( (0.0-TexCoord.x) , 2.0) + pow( (0.0-TexCoord.y) , 2.0) ) , 0.5 ) )/sqrt2;
//     float dy = 1 - ( pow( ( pow( (1.0-TexCoord.x) , 2.0) + pow( (0.0-TexCoord.y) , 2.0) ) , 0.5 ) )/sqrt2;
//     float dz = 1 - ( pow( ( pow( (1.0-TexCoord.x) , 2.0) + pow( (1.0-TexCoord.y) , 2.0) ) , 0.5 ) )/sqrt2;
//     float dw = 1 - ( pow( ( pow( (0.0-TexCoord.x) , 2.0) + pow( (1.0-TexCoord.y) , 2.0) ) , 0.5 ) )/sqrt2;

//     float occl = 0.50;

//     return dx * pow( occl, occlusion.x ) + dy * pow( occl, occlusion.y ) + dz * pow( occl, occlusion.z ) + dw * pow( occl, occlusion.w );
// }

void main() {
    float shade = pow(0.75,occlusion);
    FragColor = shade * texture(outTexture, TexCoord);
}