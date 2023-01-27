/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-01-27 03:23:41"
    @revision: 592
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT

    @ref:
       https://wiki.secondlife.com/wiki/LlRotBetween

    @notice:
*/

float InitVelocity = 15;
float HighVelocity = 5;
float Velocity = 5;
float CurrentVelocity = 0;
float gravity = 0.0;
float sensor_range = 100;
integer steps =30; //* life in seconds
key target = NULL_KEY;
integer target_owner = TRUE; //* for testing
integer testing = FALSE;

follow()
{
    vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
    llRotLookAt(llRotBetween(llRot2Fwd(ZERO_ROTATION), llVecNorm(target_pos - llGetPos())), 1, 0.4);
}

playsoundExplode()
{
    llPlaySound("TorpedoExplode", 1.0);
}

playsoundLaunch()
{
    llPlaySound("TorpedoLaunch", 1.0);
}

explode()
{
    integer number = (integer)llGetObjectDesc();
    llSetStatus(STATUS_PHYSICS, FALSE);
    playsoundExplode();
}

integer stateTorpedo = 0;
vector oldPos; //* for testing only to return back to original pos
rotation oldRot;

push(float vel)
{
    vector v = <1, 0, 0>;
    v =  v * vel * llGetMass();
    //llSetForce(v, TRUE);
    llApplyImpulse(v, TRUE);
}

shoot()
{
    llParticleSystem([
       PSYS_PART_FLAGS,
            PSYS_PART_INTERP_COLOR_MASK
            //| PSYS_PART_FOLLOW_VELOCITY_MASK
            | PSYS_PART_INTERP_SCALE_MASK
            | PSYS_PART_EMISSIVE_MASK
            //| PSYS_PART_RIBBON_MASK
            //| PSYS_PART_WIND_MASK
            ,
        PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE,
        //PSYS_SRC_TEXTURE, "bubbles",

        //PSYS_PART_BLEND_FUNC_SOURCE, PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_SRC_BURST_RATE,        0.05,
        PSYS_SRC_BURST_PART_COUNT,  25,

        PSYS_SRC_ANGLE_BEGIN,       -PI/8,
        PSYS_SRC_ANGLE_END,         PI/8,

        PSYS_PART_START_COLOR,      <1,1,1>,
        PSYS_PART_END_COLOR,        <1,1,1>,

        PSYS_PART_START_SCALE,      <0.2, 0.2, 0>,
        PSYS_PART_END_SCALE,        <0.9, 0.9, 0>,

        PSYS_SRC_BURST_SPEED_MIN,     0.1,
        PSYS_SRC_BURST_SPEED_MAX,     0.2,

        PSYS_SRC_BURST_RADIUS,      0.0,
        PSYS_SRC_MAX_AGE,           0,
        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.0>,

        PSYS_SRC_OMEGA,             <0.0, 0.0, 0.0>,

        PSYS_PART_MAX_AGE,          1,

        PSYS_PART_START_GLOW,       0.0,
        PSYS_PART_END_GLOW,         0.0,

        PSYS_PART_START_ALPHA,      0.1,
        PSYS_PART_END_ALPHA,        0.2

    ]);

    llSetStatus(STATUS_BLOCK_GRAB, TRUE);
    llSetVehicleType(VEHICLE_TYPE_AIRPLANE);
    //llSetVehicleType(VEHICLE_TYPE_SLED);
    llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetBuoyancy(0);
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, gravity ,0,0,0);

    //llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, <0, 0, 0>);
    //llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_OFFSET, <1, 0, 0>);

    llSetStatus(STATUS_PHYSICS, TRUE);

    stateTorpedo = steps;

    playsoundLaunch();
    CurrentVelocity = Velocity;
    push(InitVelocity);
    llSetTimerEvent(1);
}

stop()
{
    llSetTimerEvent(0);
    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, 1,0,0,0);
    llSensorRemove();
    llStopMoveToTarget();
    llStopLookAt();
    llParticleSystem([]);
    llSleep(1);
    llSetRegionPos(oldPos);
    llSetRot(oldRot);
    testing = FALSE;
}

init()
{
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
    llStopLookAt();
    llStopMoveToTarget();
    llSensorRemove();
    llParticleSystem([]);
    testing = FALSE;
}

default
{
    state_entry()
    {
        oldPos = llGetPos();
        oldRot = llGetRot();
        init();
        stateTorpedo = 0;
    }

    on_rez(integer number)
    {
        llSetStatus(STATUS_PHYSICS, FALSE);
        init();
        if (number > 0) {
            llSetObjectDesc((string)number);
            llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
            shoot();
        }
        else
        {
            oldPos = llGetPos();
            oldRot = llGetRot();
        }
    }

    touch_start(integer num_detected)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            testing = TRUE;
            shoot();
        }
    }

    sensor( integer number_detected )
    {
        if (stateTorpedo>0)
        {
            while (number_detected>0)
            {
                number_detected--;
                key k = llDetectedKey(number_detected);
                key owner = llList2Key(llGetObjectDetails(k, [OBJECT_OWNER]), 0);
                if (target_owner || (owner != NULL_KEY && owner != llGetOwner()))
                {
                    integer info = llGetAgentInfo(k);
                    if (info & AGENT_ON_OBJECT)
                    {
                        target = k;
                        llOwnerSay("lucked: " + llKey2Name(target));
                        llSensorRemove();
                        CurrentVelocity = HighVelocity;
                        follow();
                        return;
                    }
                }
            }
        }
    }

    collision( integer num_detected )
    {
        if (target != NULL_KEY)
            if (llDetectedKey(0)==target)
            {
                stateTorpedo = 0;
            }
    }


    timer()
    {
        if (stateTorpedo == 0)
        {
            llSetTimerEvent(0);
            if (testing)
                stop();
        }
        else
        {
            if (stateTorpedo == steps)
            {
                llSensorRepeat("", NULL_KEY, AGENT, sensor_range, 2 * PI, 1);
                llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
            }
            if (target!=NULL_KEY)
                follow();
            push(CurrentVelocity);
            stateTorpedo--;
        }
    }
}
