const math = @import("zlm");
const std = @import("std");

pub fn rand(seed:u64,x:usize,z:usize) f32 {
    var prng = std.rand.DefaultPrng.init(seed+x+z*4096);

    return prng.random().float(f32) ;
}

fn perlinInt(block_x:usize, block_y:usize,chunk_x:usize, chunk_y:usize) f32{
    var inter:f32 = 32;
    var uinter:usize = @intFromFloat(inter);
    var value : f32 = 0 ;
    for (0..uinter) |i| {
        for (0..uinter) |j| {

            var seed_x:usize = (chunk_x*16+i+block_x)/16;
            var seed_y:usize = (chunk_y*16+j+block_y)/16;


            value += rand(46546598,seed_x,seed_y);
        }
    }

    return value/inter/inter;
}

fn graduatePerlin(blockx:usize,blockz:usize,chunkx:usize,chunky:usize) f32 {
    var mean = perlinInt(blockx,blockz,chunkx,chunky);

    if ( mean < 0.1 ) {return -70.0/0.1*mean+150.0 ;}
    else if ( mean < 0.35 ) {return 80.0;}
    else if ( mean < 0.4 ) {return 30.0/0.05*mean-130.0 ;}
    else if ( mean < 0.5 ) {return 110.0;}
    else if ( mean < 0.55 ) {return 30.0/0.05*mean-190.0;}
    else {return 10.0/0.45*mean+128.0;}

}

pub fn perlinNoise(chunkx:usize,chunky:usize,blockx:usize,blockz:usize) u8 {

    var mean = graduatePerlin(blockx,blockz,chunkx,chunky);
    var mean_int:u8 = @intFromFloat(mean);

    return mean_int;
}

pub fn keyFromCoord(x:usize,y:usize,z:usize) usize {
    return x + z * 16 + y  * 256;
}

pub fn vecFromKey(chx:usize,chz:usize,key:usize) math.Vec3 {
    var vecRel = vecChunkFromKey(key);

    var fchx : f32 = @floatFromInt(chx);
    var fchz : f32 = @floatFromInt(chz);

    return math.Vec3.new(fchx*16+vecRel.x,vecRel.y,fchz*16+vecRel.z);
}

pub fn vecChunkFromKey(key:usize) math.Vec3 {
    var y:usize = key/256;
    var z:usize = ( key - y*256 ) / 16;
    var x:usize = key - y*256 - z*16;

    var nx:f32 = @floatFromInt(x);
    var ny:f32 = @floatFromInt(y);
    var nz:f32 = @floatFromInt(z);
    return math.Vec3.new(nx,ny,nz);
}

