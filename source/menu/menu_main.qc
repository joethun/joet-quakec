string menu_main_buttons[4] = {"mm_start", "mm_coop", "mm_options", "mm_credits"};

string(string prev_id) Menu_Main_GetNextButton =
{
    if (prev_id == "")
        return menu_main_buttons[0];

    string ret = menu_main_buttons[0];

    for(float i = 0; i < menu_main_buttons.length; i++) {
        if (menu_main_buttons[i] == prev_id) {
            if (i + 1 >= menu_main_buttons.length)
                break;

            ret = menu_main_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Main_GetPreviousButton =
{
    if (next_id == "")
        return menu_main_buttons[menu_main_buttons.length - 1];

    string ret = menu_main_buttons[menu_main_buttons.length - 1];

    for(float i = menu_main_buttons.length - 1; i > 0; i--) {
        if (menu_main_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_main_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Main =
{
    Menu_DrawBackground();
    Menu_DrawTitle("MAIN MENU");
    Menu_DrawBuildDate();

    Menu_Button(1, "mm_start", "SOLO", "Play solo") ? Menu_StartSolo() : 0;
    Menu_Button(2, "mm_coop", "COOPERATIVE", "Play with up to eight players") ? current_menu = MENU_COOP : 0;
    Menu_DrawDivider(3);
    Menu_Button(3.25, "mm_options", "CONFIGURATION", "Tweak game-related options") ? current_menu = MENU_OPTIONS : 0;
    Menu_DrawDivider(4.25);
    Menu_Button(4.50, "mm_credits", "CREDITS", "NZ:P Team + Special Thanks") ? current_menu = MENU_CREDITS : 0;

    Menu_SocialBadge(1, "soc_youtube", "youtube.com/@nzpteam", 2);
    Menu_SocialBadge(2, "soc_bluesky", "@nzportable.bsky.social", 3);
    Menu_SocialBadge(3, "soc_patreon", "patreon.com/cypressimplex", 4);
    Menu_SocialBadge(4, "soc_docs", "docs.nzp.gay", 1);

	sui_pop_frame();	
};
