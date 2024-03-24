#version 450 core

layout(location=0) in uint ligne ;
layout(location=1) in uint aOcclusion ;
// layout(location=1) in float texture ;

out vec2 TexCoord;
out float occlusion;

uniform mat4 camMatrix;
uniform vec2 chunkPos;


vec3 getcoord(float key) {
    float x = floor( key / 4369 );
    float y = floor( (key - x * 4369)/17 );
    float z = key - y*17 - x *4369;

    return vec3(x+chunkPos.x*16,y,z+chunkPos.y*16);
}

vec2 idToTexCoord[4] = {
    vec2(0,0),
    vec2(0,1),
    vec2(1,1),
    vec2(1,0),
};

void main() {
    gl_Position = camMatrix * vec4( getcoord(ligne) , 1.0 );
    TexCoord = idToTexCoord[gl_VertexID % 4];
    occlusion = aOcclusion;
}