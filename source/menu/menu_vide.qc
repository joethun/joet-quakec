string menu_video_buttons[9] = {"vm_shfps", "vm_maxps", "vm_vsync", "vm_fov", "vm_gamma", "vm_uwide", "vm_parts", "vm_filtr", "vm_back"};

float menu_video_init;

float current_showfps;
float current_vsync;
float current_ultrawide;
float current_particles;
float current_filter;

void() Menu_Video_StoreCurrentSettings =
{
    current_showfps = cvar("show_fps");
    current_vsync = cvar("vid_vsync");
    current_ultrawide = cvar("vid_ultrawide_limiter");
    current_particles = cvar("nzp_particles");
    current_filter = (substring(strtoupper(cvar_string("gl_texturemode")), 0, 10) == "GL_NEAREST");
}

void() Menu_Video_Init =
{
    Menu_Video_StoreCurrentSettings();
    menu_video_init = true;
};

void() Menu_Video_UpdateParticles =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_particles = !current_particles;
    cvar_set("nzp_particles", ftos(current_particles));
};

void() Menu_Video_UpdateUltrawide =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_ultrawide = !current_ultrawide;
    cvar_set("vid_ultrawide_limiter", ftos(current_ultrawide));
};

void() Menu_Video_UpdateShowFPS =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_showfps++;
    if (current_showfps > 2) current_showfps = 0;
    localcmd(sprintf("show_fps %d\n", current_showfps));
};

void() Menu_Video_UpdateVsync =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_vsync = !current_vsync;
    cvar_set("vid_vsync", ftos(current_vsync));
};

void() Menu_Video_UpdateFiltering =
{
    Menu_PlaySound(MENU_SND_ENTER);
    float is_filter = (substring(strtoupper(cvar_string("gl_texturemode")), 0, 10) == "GL_NEAREST");
    if (is_filter) {
        cvar_set("gl_texturemode", "GL_LINEAR_MIPMAP_LINEAR");
        current_filter = 0;
    } else {
        cvar_set("gl_texturemode", "GL_NEAREST_MIPMAP_LINEAR");
        current_filter = 1;
    }
};

void() Menu_Video_ApplySettings =
{
    Menu_PlaySound(MENU_SND_ENTER);
    localcmd("saveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

string(string prev_id) Menu_Video_GetNextButton =
{
    if (prev_id == "")
        return menu_video_buttons[0];

    string ret = menu_video_buttons[0];

    for(float i = 0; i < menu_video_buttons.length; i++) {
        if (menu_video_buttons[i] == prev_id) {
            if (i + 1 >= menu_video_buttons.length)
                break;

            ret = menu_video_buttons[i + 1];
            break;
        }
    }

    if (cvar("vid_vsync") && ret == "vm_maxps")
        ret = "vm_vsync";

    return ret;
};

string(string next_id) Menu_Video_GetPreviousButton =
{
    if (next_id == "")
        return menu_video_buttons[menu_video_buttons.length - 1];

    string ret = menu_video_buttons[menu_video_buttons.length - 1];

    for(float i = menu_video_buttons.length - 1; i > 0; i--) {
        if (menu_video_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_video_buttons[i - 1];
            break;
        }
    }

    if (cvar("vid_vsync") && ret == "vm_maxps")
        ret = "vm_shfps";

    return ret;
};

void() Menu_Video =
{
    if (!menu_video_init)
        Menu_Video_Init();
    
    Menu_DrawBackground();
    Menu_DrawTitle("VIDEO OPTIONS");

    Menu_DrawMapPanel();

    // Show FPS
    Menu_Button(1, "vm_shfps", "SHOW FPS", "Toggles display of the game's current FPS value") ? Menu_Video_UpdateShowFPS() : 0;
    string showfps_string = "";
    switch(current_showfps) {
        case 0: showfps_string = "DISABLED"; break;
        case 1: showfps_string = "ENABLED"; break;
        case 2: showfps_string = "VERBOSE"; break;
        default: break;
    }
    Menu_DrawOptionValue(1, showfps_string);

    // Max FPS
    if (cvar("vid_vsync") == 0) {
        Menu_Button(2, "vm_maxps", "MAX FPS", "Configure maximum FPS value") ? 0 : 0;
        Menu_CvarSlider(2, "vm_maxps", [10, 500, 490], "cl_maxfps", true, false, false);
    } else {
        Menu_GreyButton(2, "[VSYNC ON] MAX FPS");
    }

    // VSync
    Menu_Button(3, "vm_vsync", "VSYNC", "Sync framerate with display") ? Menu_Video_UpdateVsync() : 0;
    string vsync_string = "";
    if (current_vsync) vsync_string = "ENABLED";
    else vsync_string = "DISABLED";
    Menu_DrawOptionValue(3, vsync_string);

    // Field of View
    Menu_Button(4, "vm_fov", "FIELD OF VIEW", "Change camera field of view") ? 0 : 0;
    Menu_CvarSlider(4, "vm_fov", [10, 150, 140], "fov", true, false, false);

    // Gamma
    Menu_Button(5, "vm_gamma", "GAMMA", "Adjust game black level") ? 0 : 0;
    Menu_CvarSlider(5, "vm_gamma", [0.3, 2, 17], "gamma", false, true, false);

    // Ultrawide Mode
    Menu_Button(6, "vm_uwide", "ULTRAWIDE MODE", "Condenses HUD closer to center of display") ? Menu_Video_UpdateUltrawide() : 0;
    string wide_string = "";
    if (current_ultrawide) wide_string = "ENABLED";
    else wide_string = "DISABLED";
    Menu_DrawOptionValue(6, wide_string);

    // Particles
    Menu_Button(7, "vm_parts", "PARTICLES", "Toggle particle effects for performance") ? Menu_Video_UpdateParticles() : 0;
    string part_string = "";
    if (current_particles) part_string = "ENABLED";
    else part_string = "DISABLED";
    Menu_DrawOptionValue(7, part_string);

    // Texture Filtering
    Menu_Button(8, "vm_filtr", "TEXTURE FILTERING", "Choose 3D environment filtering mode") ? Menu_Video_UpdateFiltering() : 0;
    string filt_string = "";
    if (current_filter) filt_string = "NEAREST";
    else filt_string = "LINEAR";
    Menu_DrawOptionValue(8, filt_string);

    Menu_DrawDivider(12.25);
    Menu_Button(-1, "vm_back", "BACK", "Return to configuration menu") ? current_menu = MENU_OPTIONS : 0;

	sui_pop_frame();	
};
