/**
    @name: Torpedo
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-01-26 17:30:52"
    @revision: 216
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: ?

    @ref:

    @notice:
*/

float Velocity = 15.0; //meters / second.
integer steps =10;

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

push()
{
    vector v = <1, 0, 0>;
    v =  v * Velocity * llGetMass();
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
    llSetPhysicsMaterial(GRAVITY_MULTIPLIER, 0.5,0,0,0);

    //llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, <0, 0, 0>);
    //llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_OFFSET, <1, 0, 0>);

    llSetStatus(STATUS_PHYSICS, TRUE);

    stateTorpedo = steps;

    playsoundLaunch();
    llSetTimerEvent(1);
    push();
}

stop()
{
    llSetTimerEvent(0);
    llSetStatus(STATUS_PHYSICS, FALSE);
    llSetRegionPos(oldPos);
    llSetRot(oldRot);
}

init()
{
    llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
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
    }

    touch_start(integer num_detected)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            shoot();
        }
    }

    timer()
    {
        stateTorpedo--;
        if (stateTorpedo == steps - 1)
        {
            //llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Z | STATUS_ROTATE_Y, TRUE);
            //llSetVehicleType(VEHICLE_TYPE_SLED);
            //llSetForce(<-0.1, 0, 0.0>, TRUE);
            //llSetBuoyancy(0);
        }
        if (stateTorpedo == 0)
        {
            llSetTimerEvent(0);
            stop();
        }
        else
        {
            push();
        }
    }
}
