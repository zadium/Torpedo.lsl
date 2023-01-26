/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-01-27 00:34:45"
    @revision: 469
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT

    @ref:

    @notice:
*/

float InitVelocity = 15; //meters / second.
float Velocity = 10; //meters / second.
float CurrentVelocity = 0; //meters / second.
float gravity = 0.0;
float sensor_range = 100;
integer steps =10;

follow(key target){
    vector target_pos = llList2Vector(llGetObjectDetails(target, [OBJECT_POS]), 0);
    llRotLookAt(llRotBetween(llRot2Fwd(ZERO_ROTATION), llVecNorm(target_pos - llGetPos())), 1.0, 0.4);
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
    //llSetStatus(STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
    //llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, FALSE);
    //llSetBuoyancy(0);
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, gravity,0,0,0);

    //llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, <0, 0, 0>);
    //llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_OFFSET, <1, 0, 0>);

    llSetStatus(STATUS_PHYSICS, TRUE);

    stateTorpedo = steps;

    playsoundLaunch();
    llSetTimerEvent(1);
    CurrentVelocity = Velocity;
    push(InitVelocity);
    //llSensor("", NULL_KEY, AGENT, sensor_range, PI);
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
        llSensorRepeat("", NULL_KEY, PASSIVE | ACTIVE, sensor_range, 2 * PI, 1);
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
        llSensorRepeat("", NULL_KEY, PASSIVE | ACTIVE, sensor_range, 2 * PI, 1);
        if (llDetectedKey(0) == llGetOwner())
        {
          //  shoot();
        }
    }

    sensor( integer number_detected )
    {
        if (number_detected > 0)
        {
            follow(llDetectedKey(0));
            if (stateTorpedo>0)
            {
                //llOwnerSay(llDetectedName(0));
                CurrentVelocity = InitVelocity;
                follow(llDetectedKey(0));
            }
        }
    }

    timer()
    {
        stateTorpedo--;
        if (stateTorpedo == 0)
        {
            llSetTimerEvent(0);
            stop();
        }
        if (stateTorpedo < 1) //* stop engine
        {
            //llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
            //llSetVehicleType(VEHICLE_TYPE_SLED);
            //llSetForce(<-0.1, 0, 0.0>, TRUE);
            //llSetBuoyancy(0);
        }
        else if (stateTorpedo == steps - 1)
        {
            llSensorRepeat("", NULL_KEY, PASSIVE | ACTIVE, sensor_range, 2 * PI, 1);
        }
        else
        {
            push(CurrentVelocity);
        }
    }
}
