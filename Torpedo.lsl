/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 1.38
    @updated: "2023-02-11 15:12:27"
    @revision: 1183
    @localfile: ?defaultpath\Torpedo\?@name.lsl
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

//* settings
integer Torpedo=FALSE; //* or FALSE for rocket, it can go out of water
float WaterOffset = 0.1; //* if you want torpedo pull his face out of water a little
float Shock=15; //* power to push the target object on collide
float Interval = 1;
integer Life = 25; //* life in seconds
integer Targeting = 0; //* who we will targeting? select from bellow

integer TARGET_AGENT = 1;  //* agent on object, avatar should sitting on object
integer TARGET_PHYSIC = 1;  //* physic objects
integer TARGET_SCRIPTED = 2;  //* physic and scripted objects

//* for Torpedo
float InitVelocity = 1;

float LockVelocity = 4; //* run once the target detected
float Velocity = 3; //* normal speed

float LowVelocity = 0.1;
float LowDistance = 5;//* meters

float SensorRange = 100;

integer HorzVersion = FALSE; //* if you are using X direct mesh

//* Internal variables
//X Version
//vector ObjectFace = <1, 0, 0>;
//Z Version
vector ObjectFace = <0, 0, 1>;

//float current_velocity = 0;
float gravity = 0.0;
key target = NULL_KEY;
integer target_owner = FALSE; //* for testing
integer testing = FALSE;
integer launched = FALSE;

string CannonBall = "CannonBall";

vector rotate(vector v) //*rotate <1,0,0> to calc of normalized energy, see @references
{
    vector r;
    r.x =llCos(v.z)*llCos(v.y);
    r.y =llCos(v.x)*llSin(v.z)*llCos(v.y)+llSin(v.x)*llSin(v.y);
    r.z =llSin(v.x)*llSin(v.z)*llCos(v.y)-llCos(v.x)*llSin(v.z);
    return r;
}

playsoundExplode()
{
    llPlaySound("TorpedoExplode", 1.0);
}

playsoundLaunch()
{
    llPlaySound("TorpedoLaunch", 1.0);
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

        if (llGetInventoryKey(CannonBall) != NULL_KEY)
        {
            integer count = 2;
            while (count--)
                llRezObject("CannonBall", llGetPos() - ObjectFace, -ObjectFace * 25, ZERO_ROTATION, 1);
        }
    }
    llSleep(2);
}

stop(integer explode_it, integer hit_it)
{
    launched = FALSE;
    stateTorpedo = 0;
    llSetTimerEvent(0);

    integer number = (integer)llGetObjectDesc();
    llSetStatus(STATUS_PHYSICS, FALSE);

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
    if (HorzVersion)
    {
        rotation rot = llRotBetween(llRot2Fwd(ZERO_ROTATION), llVecNorm(target_pos - llGetPos()));
        llRotLookAt(rot, 0.5, 0.5);
    }
    else
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

lockAvatar(key k)
{
    if (k ==NULL_KEY)
        llOwnerSay("Nothing to lock");
    else
    {
        target = getRoot(k);
        llOwnerSay("Locked: " + llKey2Name(target));
        follow();
        llSleep(0.1);
        shoot();
    }
}

integer stateTorpedo = 0;
vector oldPos; //* for testing only to return back to original pos
rotation oldRot;
float ExtraVelocity = 0;
integer skip = 0;

push(float vel)
{
    vector v = ObjectFace;
    v =  v * vel * llGetMass();

    if (Torpedo) //* checking if it above water
    {
        vector pos = llGetPos();
        float water = llWater(ZERO_VECTOR) + WaterOffset;
        if (pos.z > water)
            v.z = -0.3;
    }

    //llSetForce(v, TRUE);
    llApplyImpulse(v, TRUE);
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

        PSYS_SRC_ANGLE_BEGIN,       PI+PI/20,
        PSYS_SRC_ANGLE_END,         PI-PI/20,

        PSYS_SRC_BURST_RADIUS,      1, //* todo to 1 and config

        PSYS_SRC_BURST_RATE,        0.1,
        PSYS_SRC_BURST_PART_COUNT,  25,

        PSYS_PART_START_COLOR,      <0.5,0.5,0.5>,
        PSYS_PART_END_COLOR,        <0.9,0.9,0.9>,

        PSYS_PART_START_SCALE,      <0.5, 0.5, 0>,
        PSYS_PART_END_SCALE,        <0.3, 0.3, 0>,

        PSYS_SRC_BURST_SPEED_MIN,     0.2,
        PSYS_SRC_BURST_SPEED_MAX,     0.5,

        PSYS_SRC_MAX_AGE,           0,

        PSYS_SRC_ACCEL,             <0.0, 0.0, 0.0>,
        PSYS_SRC_OMEGA,             <0.0, 0.0, 0.0>,

        PSYS_PART_MAX_AGE,          5,

        PSYS_PART_START_GLOW,       0.0,
        PSYS_PART_END_GLOW,         0.0,

        PSYS_PART_START_ALPHA,      0.1,
        PSYS_PART_END_ALPHA,        0.2

    ]);
}

shoot()
{
    burst();
    llSetStatus(STATUS_BLOCK_GRAB, TRUE);
    llSetVehicleType(VEHICLE_TYPE_AIRPLANE);
    //llSetVehicleType(VEHICLE_TYPE_NONE);

    //rotation refRot = llEuler2Rot(<0, 0, 0>);
    rotation refRot = llEuler2Rot(<0, PI/2, 0>);
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME, refRot);

    llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetBuoyancy(0);
    //llSetPhysicsMaterial(GRAVITY_MULTIPLIER| DENSITY, gravity ,0, 0, 1);
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, gravity ,0, 0, 0);

    //llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, <0, 0, 0>);
    //llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_OFFSET, -ObjectFace);

    //llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <50, 50, 50>);
    //llSetVehicleFloatParam(VEHICLE_ANGULAR_FRICTION_TIMESCALE, 0.1);

    llSetStatus(STATUS_PHYSICS, TRUE);

    launched = TRUE;
    stateTorpedo = Life;

    playsoundLaunch();
    push(InitVelocity);
    llSetTimerEvent(Interval);
}

respawn()
{
    llSetTimerEvent(0);
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME, ZERO_ROTATION);
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
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
    llStopLookAt();
    llStopMoveToTarget();
    llSensorRemove();
    llParticleSystem([]);
    llSetForce(ZERO_VECTOR, TRUE);
    testing = FALSE;
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
        if ((name == avi_name) && (!osIsNpc(id)))
            return id;
        ++index;
    }
    return NULL_KEY;
}

default
{
    state_entry()
    {
        //llOwnerSay("Physics engine name is " + osGetPhysicsEngineName());
        oldPos = llGetPos();
        oldRot = llGetRot();
        init();
        stateTorpedo = 0;
        integer number = (integer)llGetObjectDesc();
        if (number==0)
            llListen(0, "", llGetOwner(), "");
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
            if (launched)
                stop(FALSE, FALSE);
            else
            {
                testing = TRUE;
                //burst();
                //explode(FALSE);
                shoot();
                /*key avi_key = getAviKey("Zai");
                if (avi_key != NULL_KEY) {
                    lockAvatar(avi_key);
                }*/
            }
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
                if (testing || target_owner || (owner != llGetOwner()))
                {
                    if (Targeting == TARGET_AGENT)
                    {
                        integer info = llGetAgentInfo(k);
                        if (info & AGENT_ON_OBJECT)
                            target = getRoot(k);
                        else
                            target = NULL_KEY;
                    }
                    else
                        target = getRoot(k);

                    if (Torpedo && (target!=NULL_KEY))
                    {
                        vector target_pos = getPos(target);
                        float water = llWater(ZERO_VECTOR) + WaterOffset;
                        if (target_pos.z > water)
                            target = NULL_KEY; //* nop it is not under water
                    }

                    if (target!=NULL_KEY)
                    {
                        llOwnerSay("Locked: " + llKey2Name(target));
                        if (Torpedo)
                            llRegionSayTo(owner, 0, "A TORPEDO LOCKED ON TO YOU !");
                        else
                            llRegionSayTo(owner, 0, "A MISSILE LOCKED ON TO YOU !");
                        llSensorRemove(); //* only one target
                        ExtraVelocity = LockVelocity;
                        follow();
                        skip = 1;
                        llSetTimerEvent(Interval);//* make sure next push after 1 second
                        return;
                    }
                }
            }
        }
    }

    collision_start( integer num_detected )
    {
        if (launched)
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
         if (launched)
        {
            stop(TRUE, FALSE);
        }
    }

    timer()
    {
        //float speed = llVecMag(llGetVel()); //* meter per seconds
        //llSetText("Speed: " + (string)speed, <1,1,1>, 1);
        if (stateTorpedo == 0)
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
                if (stateTorpedo == Life) //* first pulse, we skipped first one to let torpedo get good position after launch
                {
                    llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE); //* now allow to turn left or right
                    if (target==NULL_KEY)
                        sence();
                }

                if (target!=NULL_KEY)
                    follow();

                float vel  =Velocity + ExtraVelocity;

                if (target!=NULL_KEY)
                {
                    vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
                    float dist = llFabs(llVecDist(target_pos, llGetPos()));

                    if (dist < LowDistance)
                        vel = LowVelocity;
                }
                push(vel);
                ExtraVelocity = 0;
                stateTorpedo--;
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (((channel == 0) || (channel == 1)) && (id == llGetOwner()))
        {
            string lockTo = "lock";

            if (llGetSubString(llToLower(message), 0, llStringLength(lockTo)-1) == lockTo)
            {
                string avi_name = llStringTrim(llGetSubString(message, llStringLength(lockTo), -1), STRING_TRIM);
                key avi_key = getAviKey(avi_name);
                if (avi_key != NULL_KEY) {
                    testing = TRUE;
                    lockAvatar(avi_key);
                }
                else
                    llOwnerSay("No avatar: " + avi_name);
            }
        }
    }
}