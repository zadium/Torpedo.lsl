/**
    @name: MissileLauncher
    @description:

    @author: Zai Dium
    @version: 1.4
    @updated: "2023-06-15 16:09:55"
    @revision: 196
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @source: https://github.com/zadium/Torpedo.lsl
    @license: MIT

    @ref
        https://community.secondlife.com/forums/topic/477699-laser-that-rezzes-in-front-of-you-on-command-how-to/
        llRezAtRoot( "MySuperLaserGun", llGetPos() + <2.0,0.0,1.5>*llGetRot(), ZERO_VECTOR, llGetRot(), 0);
*/
//* settings
integer channel_private_number = 5746;
string animation = "HandOnLauncher";

//*------------------

integer channel_number = 0;
string target_message = "";

sendCommand(string cmd, string params) {
    if (params != "")
        cmd = cmd + " " + params;
    llRegionSay(channel_number, cmd);
}

integer getChannel()
{
    key owner = llGetOwner();
    return (((integer)("0x"+llGetSubString((string)owner,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF ) + channel_private_number;
}

launch(string message)
{
    vector pos;
    vector power = <0,0,0>;
    rotation rot;

    target_message = message;

    string name = llGetInventoryName(INVENTORY_OBJECT, 0);

    if (llGetAttached())
    {
        rot = llGetLocalRot() * llGetRootRotation();
        //vector vec = llVecNorm(llRot2Euler(rot));
        //pos = llGetRootPosition() + llGetLocalPos() + <0,0,1>;
        pos = (llGetRootPosition() + llGetLocalPos()) + (llRot2Up(rot) * 2) ; //* in front of launcher
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
    llRezObject(name, pos, power, rot, 1); //* do not pass 0
}

default
{
    state_entry()
    {
        channel_number = getChannel();
        if (llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        llListen(0, "", llGetOwner(), "");
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

    attach(key id)
    {
        if (id != NULL_KEY)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        }
        else
        {
            if (animation != "")
            {
                llStopAnimation(animation);
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (llGetAttached())
            {
                llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
            }

        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStartAnimation(animation);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (((channel == 0) || (channel == 1)) && (id == llGetOwner()))
        {
            if (target_message == "")
            {
                string targetTo = "target ";

                if (llGetSubString(llToLower(message), 0, llStringLength(targetTo)-1) == targetTo)
                {
                    launch(message);
                }
            }
        }
    }
}