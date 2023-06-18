/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 2.10
    @updated: "2023-06-18 22:55:44"
    @revision: 1637
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @source: https://github.com/zadium/Torpedo.lsl
    @license: MIT

    @ref:
           https://wiki.secondlife.com/wiki/LlRotBetween

    @resources
        https://soundbible.com/1793-Flashbang.html

    @references
        https://www.youtube.com/watch?v=mZiR9Bd6bS8
        My Daughter

    @notice:
*/

//* User Settings
integer Torpedo=FALSE; //* or FALSE for rocket, it can go out of water, Terpodo dose not targets any object over water
string Grenade = "CannonBall"; //* special object to shoot aginst target on explode
integer GrenadeCount = 2; //* How many?

float WaterOffset = 0.1; //* if you want torpedo pull his face out of water a little
float Shock=15; //* power to push the target object on collide
float Interval = 0.1;
integer Life = 10; //* life in seconds, seconds = life*interval
integer Targeting = 0; //* who we will targeting? select from bellow

integer TARGET_SIT_AGENT = 0;  //* agent on object, avatar should sitting on object
integer TARGET_PHYSIC = 1;  //* physic objects
integer TARGET_SCRIPTED = 2;  //* physic and scripted objects


//*------------------------------------------
float SpeedFactor = 1; //* multiply with Velocity
float InitVelocity = 2; //* low to make it stable first

float LockVelocity = 5; //* run once when the target detected
float Velocity = 3; //* normal speed

float LowDistance = 10;//* meters, to start push directly to the target
float SideVelocity = 3;
//float LowVelocity = 1; //* when target position it last than LowDistance

float ProximityHit = 5; //* Hit the target if reached this distance, disabled if 0

float SensorRange = 100;

//*-------------------------------------------
float gravity = 0.0;
key target = NULL_KEY;
integer target_owner = TRUE; //* for testing
integer testing = FALSE;
integer launched = FALSE;

integer channel_private_number = 5746;

//*------------------

integer channel_number = 0;
integer listen_handle = 0;

integer getChannel()
{
    key owner = llGetOwner();
    return (((integer)("0x"+llGetSubString((string)owner,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF ) + channel_private_number;
}

playsoundExplode()
{
    if (llGetInventoryKey("TorpedoExplode"))
        llPlaySound("TorpedoExplode", 1.0);
}

playsoundLaunch()
{
    llSetSoundQueueing(TRUE);
    if (llGetInventoryKey("TorpedoLaunch"))
        llPlaySound("TorpedoLaunch", 1.0);
    if (llGetInventoryKey("TorpedoSound"))
         llLoopSoundMaster("TorpedoSound", 1.0);
}

rez()
{
    if (llGetInventoryKey(Grenade) != NULL_KEY)
    {
        vector object_face;
        object_face = <0, 0, 1> * llGetRot();

        vector e = object_face * 10;
        integer count = GrenadeCount;
        while (count--)
            llRezObject(Grenade, llGetPos() + object_face, e, ZERO_ROTATION, 1);
    }
}

explode(integer hit_it)
{
    playsoundExplode();

    //PSYS_SRC_TEXTURE, "Fire",

    llParticleSystem([
       PSYS_PART_FLAGS,
            PSYS_PART_INTERP_SCALE_MASK
            //| PSYS_PART_FOLLOW_VELOCITY_MASK
            //| PSYS_PART_INTERP_COLOR_MASK
            | PSYS_PART_EMISSIVE_MASK
            //| PSYS_PART_RIBBON_MASK
            //| PSYS_PART_WIND_MASK
            ,
        PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE,

        //PSYS_PART_BLEND_FUNC_SOURCE, PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_SRC_BURST_RATE,        0.1,
        PSYS_SRC_BURST_PART_COUNT,  25,

        PSYS_SRC_ANGLE_BEGIN,       -PI,
        PSYS_SRC_ANGLE_END,         PI,

        PSYS_PART_START_COLOR,      <0.5,0.3,0.1>,
        PSYS_PART_END_COLOR,        <1,0.5,0.1>,

        PSYS_PART_START_SCALE,      <3, 3, 0>,
        PSYS_PART_END_SCALE,        <5, 5, 0>,

        PSYS_SRC_BURST_SPEED_MIN,   0.1,
        PSYS_SRC_BURST_SPEED_MAX,   0.2,

        PSYS_SRC_BURST_RADIUS,      5,
        PSYS_SRC_MAX_AGE,           3,
        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.5>,

        PSYS_SRC_OMEGA,             <0.2, 0.2, 0.2>,

        PSYS_PART_MAX_AGE,          4,

        PSYS_PART_START_GLOW,       0.1,
        PSYS_PART_END_GLOW,         0.0,

        PSYS_PART_START_ALPHA,      0.5,
        PSYS_PART_END_ALPHA,        1

    ]);

    if (hit_it)
    {
        if (Shock>0)
        {
            vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
            vector vec = llVecNorm(target_pos - llGetPos());
            vec = vec * llGetObjectMass(target) * Shock;
            llPushObject(target, vec, ZERO_VECTOR, FALSE);
        }

        llMessageLinked(LINK_SET, 0, "shoot", target);
        rez();
    }
    llSleep(2);
}

stop(integer explode_it, integer hit_it)
{
    launched = FALSE;
    stateTorpedo = FALSE;
    launchedTime = 0;
    llSetTimerEvent(0);

    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetSoundQueueing(FALSE);
    llStopSound();

    if (explode_it)
    {
        explode(hit_it);
    }

    target = NULL_KEY;
    llSleep(0.5);
    if (testing)
        respawn();
    else
        llDie();
}

vector getPos(key k)
{
    vector target_pos = llList2Vector(llGetObjectDetails(k, [OBJECT_POS]), 0);
    if (Torpedo)
    {
        //* get the bottom of object, not center of object
        list box = llGetBoundingBox(k); //* not really the bounding box :(  it wrong of object rotating, and /llGetRot() not help
        vector min = llList2Vector(box, 0);
        vector max=llList2Vector(box, 1);
        if (min.z<max.z)
            target_pos.z += min.z;
        else
            target_pos.z += max.z;
    }
    return target_pos;
}

follow()
{
    vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);

    if (Torpedo)
    {
        float water = llWater(ZERO_VECTOR) + WaterOffset;
        if (target_pos.z > water)
        {
            target_pos.z = water; //* shifting it above, good to have it over water a little
        }
    }
    llLookAt(target_pos, 0.5, 0.5);
}

key getRoot(key k)
{
    if (k==NULL_KEY)
        return k;
    else
    {
        key root = llList2Key(llGetObjectDetails(k, [OBJECT_ROOT]), 0);
        if (root != NULL_KEY)
            return root;
        else
            return k;
    }
}

lock(key k)
{
    llSensorRemove(); //* only one target
    target = getRoot(k);
    key owner = llList2Key(llGetObjectDetails(k, [OBJECT_OWNER]), 0);
    llOwnerSay("Locked: " + llKey2Name(target));
    if (Torpedo)
        llRegionSayTo(owner, 0, "A TORPEDO LOCKED ON TO YOU !");
    else
        llRegionSayTo(owner, 0, "A MISSILE LOCKED ON TO YOU !");
}

lockObject(key k)
{
    if (k ==NULL_KEY)
        llOwnerSay("Nothing to lock");
    else
    {
        lock(k);
        launch();
        follow();
    }
}

targetObject(key k)
{
    if (k ==NULL_KEY)
        llOwnerSay("Nothing to lock");
    else
    {
        lock(k);
        ExtraVelocity = LockVelocity;
        follow();
        skip = 1;
        llSetTimerEvent(Interval);//* make sure next push after 1 second
    }
}

integer stateTorpedo = FALSE;
float launchedTime = 0;
vector oldPos; //* for testing only to return back to original pos
rotation oldRot;
float ExtraVelocity = 0;
integer skip = 0;
float factor;

push(float vel)
{
    vel = vel * factor;
    vector v;
    vector pos = llGetPos();
    float mass =llGetMass();

    if (Torpedo) //* checking if it above water
    {
        float water = llWater(ZERO_VECTOR) + WaterOffset;
        if (pos.z > water)
        {
            llApplyImpulse(<0,0,-0.5> * mass, FALSE);
        }
    }

    v = <0, 0, 1>;

    integer push_it = TRUE;

    if (target != NULL_KEY)
    {
        vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
        float dist = llFabs(llVecDist(target_pos, pos));
        if ((ProximityHit>0) && (dist < ProximityHit))
        {
            stop(TRUE, TRUE);
        }
        else if (dist < LowDistance)
        {
            vector vec = llVecNorm(target_pos - pos) * mass * SideVelocity * factor;
            llApplyImpulse(vec, TRUE);
            push_it = FALSE;
        }
    }

    if (push_it)
    {
        v =  v * vel * mass;
        //llSetForce(v, TRUE);
        llApplyImpulse(v, TRUE);
    }
}

sence()
{
    integer flags = AGENT;
    if (Targeting==TARGET_PHYSIC)
        flags = ACTIVE | PASSIVE;
    else if (Targeting==TARGET_SCRIPTED)
        flags = ACTIVE | SCRIPTED;

    llSensorRepeat("", NULL_KEY, flags, SensorRange, 2 * PI, 1);
}

burst()
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
        //-PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE,
        PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE,
        //PSYS_SRC_TEXTURE, "bubbles",

        //-PSYS_SRC_ANGLE_BEGIN,       PI,
        //-PSYS_SRC_ANGLE_END,         -PI,

        PSYS_SRC_ANGLE_BEGIN,       PI+PI/24,
        PSYS_SRC_ANGLE_END,         PI-PI/24,

        PSYS_SRC_BURST_RADIUS,      1, //* todo to 1 and config

        PSYS_SRC_BURST_RATE,        0.1,
        PSYS_SRC_BURST_PART_COUNT,  15,

        PSYS_PART_START_COLOR,      <0.6,0.6,0.6>,
        PSYS_PART_END_COLOR,        <0.9,0.9,0.9>,

        PSYS_PART_START_SCALE,      <0.5, 0.5, 0>,
        PSYS_PART_END_SCALE,        <0.8, 0.8, 0>,

        PSYS_SRC_BURST_SPEED_MIN,     0.2,
        PSYS_SRC_BURST_SPEED_MAX,     0.5,

        PSYS_SRC_MAX_AGE,           0,

        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.0>,
        PSYS_SRC_OMEGA,             <0.0, 0.0, 0.0>,

        PSYS_PART_MAX_AGE,          5,

        PSYS_PART_START_GLOW,       0.01,
        PSYS_PART_END_GLOW,         0.0,

        PSYS_PART_START_ALPHA,      0.1,
        PSYS_PART_END_ALPHA,        0.2

    ]);
}

launch()
{
    vector object_face;
    object_face = <0, 0, 1>;

    burst();
    llMessageLinked(LINK_SET, 0, "start", NULL_KEY);

    llSetStatus(STATUS_BLOCK_GRAB, TRUE);
    llSetVehicleType(VEHICLE_TYPE_AIRPLANE);
    //llSetVehicleType(VEHICLE_TYPE_SLED);
    //llSetVehicleType(VEHICLE_TYPE_NONE);//* no collide work

    //rotation refRot = llEuler2Rot(<0, 0, 0>);
    rotation refRot = llEuler2Rot(<0, PI/2, 0>);
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME, refRot);
    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_OFFSET, -object_face);
    llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <1000, 1000, 20000>);

    llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetBuoyancy(0);
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, gravity ,0, 0, 0);

    //llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, <PI, PI, PI>);
    //llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 1>);

    //llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <50, 50, 50>);
    //llSetVehicleFloatParam(VEHICLE_ANGULAR_FRICTION_TIMESCALE, 0.1);

    llSetStatus(STATUS_PHYSICS, TRUE);

    launched = TRUE;
    stateTorpedo = FALSE;
    launchedTime = llGetTime();

    playsoundLaunch();

    push(InitVelocity);
    llSetTimerEvent(Interval);
}

respawn()
{
    factor = SpeedFactor * Interval;
    llOwnerSay((string)factor);
    llSetSoundQueueing(FALSE);
    llStopSound();
    llMessageLinked(LINK_SET, 0, "stop", NULL_KEY);
    llSetTimerEvent(0);
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME, llGetRot());
    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, 1,0,0,0);
    llSetForce(ZERO_VECTOR, TRUE);
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
    llSetText("", <1,1,1>, 1);
    llSetVehicleRotationParam( VEHICLE_REFERENCE_FRAME, ZERO_ROTATION / llGetRootRotation());
    llStopLookAt();
    llStopMoveToTarget();
    llSensorRemove();
    llParticleSystem([]);
    llSetForce(ZERO_VECTOR, TRUE);
    llMessageLinked(LINK_SET, 0, "stop", NULL_KEY);
    testing = FALSE;
    factor = SpeedFactor * Interval;
    llOwnerSay((string)factor);
}

key getAviKey(string avi_name)
{
    avi_name = llToLower(avi_name);
    integer len = llStringLength(avi_name);
    list avatars = llGetAgentList(AGENT_LIST_PARCEL, []);
    integer count = llGetListLength(avatars);

    integer index;
    string name;
    key id;
    while (index < count)
    {
        id = llList2Key(avatars, index);
        name = llGetSubString(llToLower(llKey2Name(id)), 0, len - 1);
        if ((name == avi_name))// && (!osIsNpc(id)))
            return id;
        ++index;
    }
    return NULL_KEY;
}

getMessage(string message)
{
    string targetTo = "target ";

    if (llGetSubString(llToLower(message), 0, llStringLength(targetTo)-1) == targetTo)
    {
        message = llGetSubString(llToLower(message), llStringLength(targetTo), -1);
        list params = llParseStringKeepNulls(message,[","],[]);
        string targetName = llList2String(params, 0);
        float power;
        string s;
        s = llStringTrim(llList2String(params, 1), STRING_TRIM);
        if (s != "")
            factor = (float)s * Interval;
        s = llStringTrim(llList2String(params, 2), STRING_TRIM);
        if (s != "")
            power = (float)s;

        key target_key = getAviKey(targetName);
        if (target_key != NULL_KEY)
        {
            if (launched)
            {
                targetObject(target_key);
            }
            else
            {
                testing = TRUE;
                lockObject(target_key);
            }
        }
        else
            llOwnerSay("No object: " + targetName);
    }
}

default
{
    state_entry()
    {
        //llOwnerSay("Physics engine name is " + osGetPhysicsEngineName());
        oldPos = llGetPos();
        oldRot = llGetRot();
        init();
        stateTorpedo = FALSE;
        launchedTime = 0;
        llStopSound();
        llListen(0, "", llGetOwner(), "");
    }

    on_rez(integer number)
    {
        llSetStatus(STATUS_PHYSICS, FALSE);
        init();
        if (number > 0)
        {
            llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
            //* llListen dose not work when rezzed from another object, so we will listen in first timer event
            //channel_number = getChannel();
            //listen_handle = llListen(channel_number, "", llGetOwner(), "");
            launch();
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
            if (launched)
                stop(FALSE, FALSE);
            else
            {
                testing = TRUE;
                launch();
                //rez();
                //burst();
                //explode(FALSE);
                /*key avi_key = getAviKey("Zai");
                if (avi_key != NULL_KEY) {
                    lockObject(avi_key);
                }*/
            }
        }
    }

    sensor( integer number_detected )
    {
        if (launchedTime>0)
        {
            while (number_detected>0)
            {
                number_detected--;
                key k = llDetectedKey(number_detected);
                key owner = llList2Key(llGetObjectDetails(k, [OBJECT_OWNER]), 0);
                if (testing || target_owner || (owner != llGetOwner()))
                {
                    if (Targeting == TARGET_SIT_AGENT)
                    {
                        integer info = llGetAgentInfo(k);
                        if (info & AGENT_ON_OBJECT)
                        {
                            target = getRoot(k);
                        }
                        else
                            target = NULL_KEY;
                    }
                    else
                        target = getRoot(k);


                    if (Torpedo && (target!=NULL_KEY)) //* prevent see over water
                    {
                        vector target_pos = getPos(target);
                        float water = llWater(ZERO_VECTOR) + WaterOffset;
                        if (target_pos.z > water)
                            target = NULL_KEY; //* nop it is not under water
                    }

                    if (target!=NULL_KEY)
                    {
                        targetObject(target);
                        return;
                    }
                }
            }
        }
    }

    collision_start( integer num_detected )
    {
        if (launched && ((llGetTime() - launchedTime)>2)) //* do not collide before 2 seconds
        {
            if (target != NULL_KEY)
                if (llDetectedKey(0)==target)
                {
                    stop(TRUE, TRUE);
                }
        }
    }

    land_collision_start(vector pos)
    {
        if (launched && ((llGetTime() - launchedTime)>2)) //* do not collide before 2 seconds
        {
            stop(TRUE, FALSE);
        }
    }

    timer()
    {
        //float speed = llVecMag(llGetVel()); //* meter per seconds
        //llSetText("Speed: " + (string)speed, <1,1,1>, 1);
        if ((llGetTime()-launchedTime) > Life)
        {
            llSetTimerEvent(0);
            stop(FALSE, FALSE);
        }
        else
        {
            if (skip > 0)
            {
                skip--;
                if (target!=NULL_KEY)
                    follow();
            }
            else
            {
                if (!stateTorpedo) //* first pulse, we skipped first one to let torpedo get good position after launch
                {
                    llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE); //* now allow to turn left or right
                    if (target==NULL_KEY)
                    {
                        sence();
                        //* not working in on_rez :(
                        channel_number = getChannel();
                        if (listen_handle == 0)
                        {
                            listen_handle = llListen(channel_number, "", NULL_KEY, "");
                        }
                    }
                }

                if (target!=NULL_KEY)
                    follow();

                float vel  =Velocity + ExtraVelocity;
/*
                if (target!=NULL_KEY)
                {
                    vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
                    float dist = llFabs(llVecDist(target_pos, llGetPos()));

                    if (dist < LowDistance)
                        vel = LowVelocity;
                }
*/
                push(vel);
                ExtraVelocity = 0;
                stateTorpedo = TRUE;
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
       if (((channel == 0) && (id == llGetOwner())) || ((channel == channel_number) && (llGetOwnerKey(id) == llGetOwner())))
        {
            getMessage(llStringTrim(message, STRING_TRIM));
        }
    }
}