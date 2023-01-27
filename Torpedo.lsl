/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-01-27 14:41:29"
    @revision: 627
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT

    @ref:
       https://wiki.secondlife.com/wiki/LlRotBetween

    @notice:
*/

//* settings
integer Torpedo=TRUE; //* or FALSE for rocket, it can go out of water

float InitVelocity = 15;
float HighVelocity = 5;
float Velocity = 4;
float SensorRange = 100;
integer Life = 10; //* life in seconds
integer Targeting = 1;

integer TARGET_AGENT = 0;  //* agent on object, avatar should sitting on object
integer TARGET_PHYSIC = 1;  //* physic objects
integer TARGET_SCRIPTED = 2;  //* physic and scripted objects

//* Internal variables
float current_velocity = 0;
float gravity = 0.0;
key target = NULL_KEY;
integer target_owner = TRUE; //* for testing
integer testing = FALSE;

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
    target = NULL_KEY;
    integer number = (integer)llGetObjectDesc();
    llSetStatus(STATUS_PHYSICS, FALSE);
    playsoundExplode();
    llSleep(0.5);
    if (testing)
        spawn();
    else
        llDie();
}

follow()
{
    vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);

    if (Torpedo)
    {
        float water = llWater(ZERO_VECTOR);
        if (target_pos.z > water)
        {
            target_pos.z = water + 0.1; //* shifting it above, good to have it over water a little
        }
    }

    llRotLookAt(llRotBetween(llRot2Fwd(ZERO_ROTATION), llVecNorm(target_pos - llGetPos())), 1, 0.4);
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

    stateTorpedo = Life;

    playsoundLaunch();
    current_velocity = Velocity;
    push(InitVelocity);
    llSetTimerEvent(1);
}

spawn()
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
                    if (Targeting==TARGET_PHYSIC)
                    {
                        target = k;
                    }
                    else if (Targeting==TARGET_SCRIPTED)
                    {
                        target = k;
                    }
                    else
                    {
                        integer info = llGetAgentInfo(k);
                        if (info & AGENT_ON_OBJECT)
                        {
                            //* TODO: can we get the root of agent, mean the object sitting on it
                            key root = llList2Key(llGetObjectDetails(k, [LINK_ROOT]), 0);
                            if (root != NULL_KEY)
                                target = root;
                            else
                                target = k;
                        }
                    }

                    if (target!=NULL_KEY)
                    {
                        llOwnerSay("locked: " + llKey2Name(target));
                        llSensorRemove();
                        current_velocity = HighVelocity;
                        follow();
                        return;
                    }
                }
            }
        }
    }

    collision_start( integer num_detected )
    {
        if (target != NULL_KEY)
            if (llDetectedKey(0)==target)
            {
                stateTorpedo = 0;
                llSetTimerEvent(0);
                explode();
            }
    }


    timer()
    {
        if (stateTorpedo == 0)
        {
            llSetTimerEvent(0);
            explode();
        }
        else
        {
            if (stateTorpedo == Life) //* first pulse, we skipped first one to let torpedo get good position after launch
            {

                integer flags = AGENT;
                if (Targeting==TARGET_PHYSIC)
                    flags = ACTIVE;
                else if (Targeting==TARGET_SCRIPTED)
                    flags = ACTIVE | SCRIPTED;

                llSensorRepeat("", NULL_KEY, flags, SensorRange, 2 * PI, 1);
                llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE); //* now allow to turn left or right
            }

            if (target!=NULL_KEY)
                follow();
            push(current_velocity);
            stateTorpedo--;
        }
    }
}
