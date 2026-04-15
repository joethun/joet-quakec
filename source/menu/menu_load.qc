string UserMapNameLookup(string bsp_name);
string(string s) strip_custommapinfo;
string(string s) get_custommapfolder;

string loading_tips[] =
{
    "NZ:P boner!!!",
    "Quick Revive will resurrect you in solo.",
    "Use Quick Revive to revive faster in co-op!",
    "Jugger-Nog increases your health.",
    "Speed Cola increases Reload speed.",
    "Speed Cola allows faster barricade building",
    "Double Tap will improve rate of fire.",
    "Stamin-Up increases your movement speed.",
    "PhD Flopper grants explosive immunity.",
    "Dolphin dive with PhD to cause PAIN!",
    "Deadshot Daiquiri removes sniper scope sway.",
    "Deadshot Daiquiri increases weapon accuracy.",
    "Carry three weapons with Mule Kick!",
    "Pack-A-Punch the Kar 98k to get to round 500!",
    "NZ:P is on too many platforms to keep count of.",
    "Max Ammo doesn't refill your mag, so RELOAD!",
    "KA-BOOM!",
    "NZ:P has been in development since 2009.",
    "Hold a crawler and hunt for secrets.",
    "'Where's the armor station?'",
    "https://docs.nzp.gay/",
    "FTE is a pretty awesome Quake sourceport",
    "Support the Internet Archive!",
    "Down with all that's good and clean...",
    "As seen on YouTube!",
    "Pack-A-Punch the Springfield twice to get a cool prize!",
    "Autodesk Inventor",
    "Joe T Edition made by Joe Thundercheeks.",
    "Now with less bugs!",
    "Free software!"
};

float loading_tip_endtime;
string current_tip;
string latched_map_loading;

string GetLoadingTip() =
{
    if (time > loading_tip_endtime) {
        current_tip = loading_tips[random() * loading_tips.length];
        loading_tip_endtime = time + 5;
    }

    return current_tip;
};

void(vector screensize, float opaque) m_drawloading =
{
    // Black Background
    drawfill([0, 0], screensize, [0, 0, 0], 1);

    string current_map_loading = (map_name_override != "") ? map_name_override : cvar_string("mapname");

    // If blank, clear the latch and keep the screen black until FTE sends it to us.
    if (current_map_loading == "") {
        latched_map_loading = "";
        return;
    }

    // Latch the map name on first sight so we keep the full "custom/..." path
    // even if the engine drops the prefix just before finishing the load.
    // Also reset the latch if the engine reports a map that doesn't match what
    // we latched — this handles the case where mapname jumps directly from one
    // map to another without ever being empty (e.g. rejoining a different custom
    // map round), which would otherwise leave the old loading screen in place.
    if (latched_map_loading == "") {
        latched_map_loading = current_map_loading;
    } else {
        // Strip the custom/ prefix from the latch for comparison, since the
        // engine may report just the bare BSP name while we stored the full path.
        string latch_bare = latched_map_loading;
        if (substring(latch_bare, 0, 7) == "custom/")
            latch_bare = strip_custommapinfo(strcat("maps/", latch_bare, ".bsp"));

        string current_bare = current_map_loading;
        if (substring(current_bare, 0, 7) == "custom/")
            current_bare = strip_custommapinfo(strcat("maps/", current_bare, ".bsp"));

        if (current_bare != latch_bare)
            latched_map_loading = current_map_loading;
    }

    string loading_tip = GetLoadingTip();
    string map_name_pretty = "";
    string map_loadscreen_path;

    if (substring(latched_map_loading, 0, 7) == "custom/") {
        string full = strcat("maps/", latched_map_loading, ".bsp");
        map_loadscreen_path = sprintf("maps/custom/%s/gfx/lscreen/%s",
            get_custommapfolder(full), strip_custommapinfo(full));
    } else {
        map_loadscreen_path = sprintf("gfx/lscreen/%s", latched_map_loading);
    }

    if (map_name_override != "OVERRIDE") {
        float file_handle = fopen(sprintf("%s.png", map_loadscreen_path), FILE_READ);
        if (file_handle == -1)
            map_loadscreen_path = "gfx/lscreen/lscreen";
        else
            fclose(file_handle);

        map_name_pretty = UserMapNameLookup(latched_map_loading);
    } else {
        map_name_pretty = "Direct Connect";
        map_loadscreen_path = "gfx/lscreen/lscreen";
    }

    // Loading screen
    drawpic([0, 0], map_loadscreen_path, screensize, [1, 1, 1], 1);

    // Cinematic Lines
    drawfill([0, 0], [screensize_x, 36], [0, 0, 0], 175/255);
    drawfill([0, screensize_y - 36], [screensize_x, 36], [0, 0, 0], 175/255);

    // Map Title
    Draw_String([10, 5], map_name_pretty, MENU_TEXT_LARGE, [0.9, 0.15, 0.15], 1, 0);

    // Notice for how to end server connecting
    if (loading_into_server == true) {
        string abort_message = "Press ESC to abort connection and return to menu";
        drawfill([0, 111], [screensize_x, 36], [0, 0, 0], 175/255);
        Draw_String([screensize_x/2 - getTextWidth(abort_message, MENU_TEXT_MEDIUM_x)/2, 120], abort_message, MENU_TEXT_MEDIUM, [1, 1, 1], 1, 0);
    }

    // Loading Tip
    Draw_String([screensize_x/2 - getTextWidth(loading_tip, MENU_TEXT_SMALL_x)/2, screensize_y - 25], loading_tip, MENU_TEXT_SMALL, [1, 1, 1], 1, 0);
};
