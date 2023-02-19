/**
    @name: MissileBurst
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-02-13 20:05:22"
    @revision: 21
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT
*/
//* settings

CyberEngineFire()
{
    llParticleSystem([
       PSYS_PART_FLAGS,
            PSYS_PART_INTERP_COLOR_MASK
            | PSYS_PART_RIBBON_MASK
            | PSYS_PART_FOLLOW_VELOCITY_MASK
            | PSYS_PART_INTERP_SCALE_MASK
            | PSYS_PART_EMISSIVE_MASK
            //| PSYS_PART_WIND_MASK
            ,
        PSYS_SRC_PATTERN,              PSYS_SRC_PATTERN_ANGLE_CONE,

        PSYS_SRC_BURST_RADIUS,      0.0,
        PSYS_SRC_MAX_AGE,           0,
        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.0>,
        PSYS_SRC_BURST_RATE,        0.01,
        PSYS_SRC_BURST_PART_COUNT,  5,

        PSYS_SRC_BURST_SPEED_MIN,   2,
        PSYS_SRC_BURST_SPEED_MAX,   1,

        PSYS_SRC_OMEGA,             <0.0, 0.0, 0.0>,

        PSYS_PART_MAX_AGE,          0.5,

        PSYS_SRC_ANGLE_BEGIN,       -PI/10,
        PSYS_SRC_ANGLE_END,         PI/10,

        PSYS_PART_START_COLOR,      < 0.9, 0.8, 0.4 >,
        PSYS_PART_END_COLOR,        < 0.9, 0.4, 0.2 >,

        PSYS_PART_START_GLOW,       0.05,
        PSYS_PART_END_GLOW,         0.01,

        PSYS_PART_START_ALPHA,      0.5,
        PSYS_PART_END_ALPHA,        0.01,

        PSYS_PART_START_SCALE,      <0.9, 0.9, 0.0>,
        PSYS_PART_END_SCALE,        <0.9, 0.9, 0.0>

        ]);
}

integer active = FALSE;

default
{
    state_entry()
    {
        llParticleSystem([]);
    }

    touch(integer num_detected)
    {
           if (active)
           {
            llParticleSystem([]);
            active = FALSE;
        }
           else
           {
               CyberEngineFire();
            active = TRUE;
        }
    }

    link_message( integer sender_num, integer num, string message, key id )
    {
        if (message == "start")
            CyberEngineFire();
        else if (message == "stop")
            llParticleSystem([]);

    }

}
