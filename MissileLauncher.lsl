/**
    @name: MissileLauncher
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2023-02-20 20:54:48"
    @revision: 26
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @license: MIT
*/
//* settings

default
{
    state_entry()
    {

    }

    on_rez(integer number)
    {
        llResetScript();
    }

    touch_start(integer num_detected)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            string Name = llGetInventoryName(INVENTORY_OBJECT, 0);
            rotation rot = llGetLocalRot() * llGetRot();
            //vector vec = llVecNorm(llRot2Euler(rot));
            vector vec = <0,0,1>;
            llRezObject(Name, llGetRootPosition()+llGetLocalPos()+vec, <0,0,0>, rot, 1); //* do not pass 0
        }
    }

}