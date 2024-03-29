/**
    @name: MissileLauncher
    @description:

    @author: Zai Dium
    @version: 1.10
    @updated: "2023-06-23 20:24:25"
    @revision: 281
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @source: https://github.com/zadium/Torpedo.lsl
    @license: MIT

    @ref
        https://community.secondlife.com/forums/topic/477699-laser-that-rezzes-in-front-of-you-on-command-how-to/
        llRezAtRoot( "MySuperLaserGun", llGetPos() + <2.0,0.0,1.5>*llGetRot(), ZERO_VECTOR, llGetRot(), 0);
*/
//* settings
integer channel_private_number = 5746;

//*------------------

integer channel_number = 0;
string target_message = "";

float SensorRange = 100;
integer target_owner = TRUE;
float LaunchLife = 50;

integer getChannel()
{
    key owner = llGetOwner();
    return (((integer)("0x"+llGetSubString((string)owner,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF ) + channel_private_number;
}

playsoundLaunch()
{
    if (llGetInventoryKey("TorpedoLaunch"))
        llPlaySound("TorpedoLaunch", 1.0);
}

launch(string message)
{
    llSensorRemove();
    playsoundLaunch();

    vector pos;
    vector power = <0,0,0>;
    rotation rot;

    target_message = message;

    string name = llGetInventoryName(INVENTORY_OBJECT, 0);

    if (llGetAttached())
    {
        //rot = llGetLocalRot() * llGetRootRotation(); //* not work fine

        list box = llGetBoundingBox(llGetKey());
        vector size = llList2Vector(box, 1) - llList2Vector(box, 0);

        rot = llGetRootRotation();
        pos = (llGetRootPosition() + llGetLocalPos()) + (<size.z, 0, 0> * rot) ; //* in front of launcher

        vector v1 = llRot2Euler(llGetRootRotation());
        //* we will use avatar facing
        rot = llEuler2Rot(<0, PI/2, 0>) * llEuler2Rot(<0, 0, v1.z>); //* because missile is to up we rotated it to forward

        /*
        llOwnerSay("---");
        llOwnerSay((string)(llRot2Euler(llList2Rot(llGetLinkPrimitiveParams( LINK_ROOT, [PRIM_ROTATION] ), 0)) * RAD_TO_DEG));

        llOwnerSay((string)(llRot2Euler(llGetRootRotation()) * RAD_TO_DEG));
        llOwnerSay((string)(llRot2Euler(llGetRot()) * RAD_TO_DEG));
        llOwnerSay((string)(llRot2Euler(llGetLocalRot()) * RAD_TO_DEG));
        llOwnerSay((string)(llRot2Euler(rot) * RAD_TO_DEG));
        */
    }
    else
    {
        rot = llGetRot();
        pos = llGetPos() + (llRot2Up(rot) * 2) ; //* in front of launcher
    }

    power = llVecNorm(llRot2Euler(rot));
    integer number = 1; //* auto target
    if (target_message !="")
        number = 2; //* wait for message
    llRezObject(name, pos, power, rot, number); //* do not pass 0
    llSetTimerEvent(LaunchLife); //* to reenable sensor again
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

default
{
    state_entry()
    {
        channel_number = getChannel();
        llListen(0, "", llGetOwner(), "");
        if (!llGetAttached())
        {
            llSensorRepeat("", NULL_KEY, AGENT, SensorRange, PI, 1);
        }
    }

    on_rez(integer number)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        if (target_message != "")
        {
            llSleep(2); //* wait to make missile listen
            llRegionSayTo(id, channel_number, target_message);
            target_message = "";
        }
    }

    touch_start(integer num_detected)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            if (target_message == "")
            {
                launch("");
            }
        }
    }

    sensor( integer number_detected )
    {
        while (number_detected>0)
        {
            number_detected--;
            key k = llDetectedKey(number_detected);
            key owner = llList2Key(llGetObjectDetails(k, [OBJECT_OWNER]), 0);
            key target = NULL_KEY;
            if (target_owner || (owner != llGetOwner()))
            {
                integer info = llGetAgentInfo(k);
                if (info & AGENT_ON_OBJECT)
                    target = getRoot(k);

                if (target!=NULL_KEY)
                {
                    launch("/target " + llKey2Name(k)+",3,"+(string)LaunchLife);
                    return;
                }
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0);
        llSensorRepeat("", NULL_KEY, AGENT, SensorRange, PI, 1);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (((channel == 0) || (channel == 1)) && (id == llGetOwner()))
        {
            if (target_message == "")
            {
                string targetTo = "/target ";

                if (llGetSubString(llToLower(message), 0, llStringLength(targetTo)-1) == targetTo)
                {
                    launch(message);
                }
            }
        }
    }
}