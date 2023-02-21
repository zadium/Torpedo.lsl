/**
    @name: MissileLauncher
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-02-21 23:44:16"
    @revision: 103
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT
*/
//* settings
integer channel_private_number = 5746;

//*------------------

integer channel_number = 0;
string target_name = "";

sendCommand(string cmd, string params) {
    if (params != "")
        cmd = cmd + " " + params;
    llRegionSay(channel_number, cmd);
}

sendCommandTo(key id, string cmd, string params) {
    if (params != "")
        cmd = cmd + " " + params;
    llRegionSayTo(id, channel_number, cmd);
}

integer getChannel()
{
    key owner = llGetOwner();
    return (((integer)("0x"+llGetSubString((string)owner,-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF ) + channel_private_number;
}

launch(string target, float power)
{
    vector pos;
    vector power = <0,0,0>;
    rotation rot;

    target_name = target;

    string name = llGetInventoryName(INVENTORY_OBJECT, 0);

    if (llGetAttached())
    {
        rot = llGetLocalRot() * llGetRot();
        //vector vec = llVecNorm(llRot2Euler(rot));
        pos = llGetRootPosition() + llGetLocalPos() + <0,0,1>;;
    }
    else
    {
        rot = llGetRot();
        pos = llGetPos() + <0,0,1>;
    }

    power = llVecNorm(llRot2Euler(rot));
    llRezObject(name, pos, power, rot, 1); //* do not pass 0
}

default
{
    state_entry()
    {
        channel_number = getChannel();
        llListen(0, "", llGetOwner(), "");
    }

    on_rez(integer number)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        if (target_name != "")
        {
            llSleep(2); //* wait to make missile listen
               sendCommandTo(id, "target", target_name);
            target_name = "";
        }
    }

    touch_start(integer num_detected)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            if (target_name == "")
            {
                launch("", 0);
            }
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (((channel == 0) || (channel == 1)) && (id == llGetOwner()))
        {
            if (target_name == "")
            {
                string targetTo = "target ";

                if (llGetSubString(llToLower(message), 0, llStringLength(targetTo)-1) == targetTo)
                {
                    message = llGetSubString(llToLower(message), llStringLength(targetTo), -1);
                    list params = llParseStringKeepNulls(message,[";"],[""]);
                    string target = llList2String(params, 0);
                    float power = llList2Float(params, 1);
                    if (target != "")
                    {
                        launch(target, power);
                    }
                }
            }
        }
    }
}