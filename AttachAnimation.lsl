/**
    @name: AttachAnimation
    @description:

    @author: Zai Dium
    @version: 1.10
    @updated: "2023-06-18 19:38:24"
    @revision: 6
    @localfile: ?defaultpath\Torpedo\?@name.lsl
    @source: https://github.com/zadium/AttachAnimation.lsl
    @license: MIT

    @ref
        https://community.secondlife.com/forums/topic/477699-laser-that-rezzes-in-front-of-you-on-command-how-to/
        llRezAtRoot( "MySuperLaserGun", llGetPos() + <2.0,0.0,1.5>*llGetRot(), ZERO_VECTOR, llGetRot(), 0);
*/

//* settings
string animation = "Launcher";

default
{
    state_entry()
    {
        if (llGetAttached())
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
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
}
