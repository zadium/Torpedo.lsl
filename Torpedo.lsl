/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-01-27 01:29:51"
    @revision: 543
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT

    @ref:

    @notice:
*/

float InitVelocity = 15;
float HighVelocity = 5;
float Velocity = 5;
float CurrentVelocity = 0;
float gravity = 0.0;
float sensor_range = 100;
integer steps =10;
key target = NULL_KEY;
integer target_owner = TRUE; //* for testing

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
}

init()
{
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
    llStopMoveToTarget();
    llSensorRemove();
    llParticleSystem([]);
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
            shoot();
        }
    }

    sensor( integer number_detected )
    {
        if (stateTorpedo>0)
        {
            while (number_detected>0)
            {
                llOwnerSay((string)(number_detected));
                number_detected--;
                key k = llDetectedKey(number_detected);
                key owner = llList2Key(llGetObjectDetails(k, [OBJECT_OWNER]), 0);
                if (target_owner || (owner != NULL_KEY && owner != llGetOwner()))
                {
                    target = k;
                    //llOwnerSay("lucked: " + llKey2Name(target));
                    llSensorRemove();
                    CurrentVelocity = HighVelocity;
                    follow();
                    return;
                }
            }
        }
    }

    timer()
    {
        if (stateTorpedo == 0)
        {
            llSetTimerEvent(0);
            stop();
        }
        else
        {
            if (stateTorpedo == steps)
            {
                llSensorRepeat("", NULL_KEY, PASSIVE | ACTIVE, sensor_range, 2 * PI, 1);
                llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
            }
            if (target!=NULL_KEY)
                follow();
            push(CurrentVelocity);
            stateTorpedo--;
        }
    }
}
