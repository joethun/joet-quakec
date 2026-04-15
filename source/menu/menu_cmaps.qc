// Since these are built on-the-fly, do not populate here
string menu_cmaps_buttons[13];

float menu_cmaps_init;

//
// Menu_CustomMaps_Init()
// Resets pagination for the custom maps browser.
//
void() Menu_CustomMaps_Init =
{
    menu_cmaps_init = true;
    custom_maps_page = 0;
};

void() Menu_CustomMaps_NextPage =
{
    Menu_PlaySound(MENU_SND_ENTER);
    custom_maps_page++;
}

void() Menu_CustomMaps_PrevPage =
{
    Menu_PlaySound(MENU_SND_ENTER);
    custom_maps_page--;
}

void(string bsp_name, string bsp_folder) Menu_CustomMaps_LoadMap =
{
    // Pass the full path so the engine can locate the BSP
    current_selected_bsp = strcat("custom/", bsp_folder, "/maps/", bsp_name);
    last_map_menu = current_menu;
    cvar_set("sv_gamemode", "0");
    cvar_set("sv_difficulty", "0");
    cvar_set("sv_startround", "0");
    cvar_set("sv_magic", "1");
    cvar_set("sv_headshotonly", "0");
    cvar_set("sv_maxai", "24");
    cvar_set("sv_fastrounds", "0");
    current_menu = MENU_LOBBY;
};
string(string prev_id) Menu_CustomMaps_GetNextButton =
{
    if (prev_id == "")
        return menu_cmaps_buttons[0];

    string ret = menu_cmaps_buttons[0];

    for(float i = 0; i < menu_cmaps_buttons.length; i++) {
        if (menu_cmaps_buttons[i] == prev_id) {
            if (i + 1 >= menu_cmaps_buttons.length)
                break;

            ret = menu_cmaps_buttons[i + 1];
            break;
        }
    }

    if (ret == "")
        return menu_cmaps_buttons[0];

    return ret;
};

string(string next_id) Menu_CustomMaps_GetPreviousButton =
{
    string last_populated_entry = "";
    for(float j = menu_cmaps_buttons.length - 1; j > 0; j--) {
        if (menu_cmaps_buttons[j] != "") {
            last_populated_entry = menu_cmaps_buttons[j];
            break;
        }
    }

    if (next_id == "")
        return last_populated_entry;

    string ret = last_populated_entry;

    for(float i = menu_cmaps_buttons.length - 1; i > 0; i--) {
        if (menu_cmaps_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_cmaps_buttons[i - 1];
            break;
        }
    }

    return ret;
};

//
// Menu_CustomMapButton(order, id, bsp_name, index)
// Like Menu_MapButton but reads from custom_maps[].
//
float(float order, string id, string bsp_name, float index) Menu_CustomMapButton =
{
    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

    float is_hovered = sui_is_hovered(id);
    vector text_color = is_hovered ? [0.9, 0.15, 0.15] : [0.95, 0.93, 0.85];
    vector position = [6, 50 + (order * 25)];
    vector bbox_pos = position - [6, 5, 0];
    vector bbox_size = [290, 22];

    if (is_hovered) {
        sui_fill(bbox_pos, bbox_size, [0, 0, 0], 0.9, 0);
        sui_fill(bbox_pos, [bbox_size_x, 2], [0.6, 0.1, 0.1], 1, 0);
        sui_fill(bbox_pos + [0, bbox_size_y - 2], [bbox_size_x, 2], [0.6, 0.1, 0.1], 1, 0);
        sui_fill(bbox_pos + [bbox_size_x - 2, 0], [2, bbox_size_y], [0.6, 0.1, 0.1], 1, 0);
    }

    string title = custom_maps[index].map_name_pretty;
    if (!title)
        title = custom_maps[index].map_name;
    sui_text(position - [getTextWidth(strtoupper(title), MENU_TEXT_MEDIUM_x), 0, 0] + [275, 0, 0], MENU_TEXT_MEDIUM, strtoupper(title), text_color, 1, 0);

    if (is_hovered) {
        sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);

        if (custom_maps[index].map_use_thumbnail) {
            sui_fill([150, -70], [302, 174], [0.4, 0.4, 0.4], 1, 0);
            sui_pic([150, -70], [300, 170], strcat("maps/custom/", custom_maps[index].map_folder, "/gfx/menu/custom/", custom_maps[index].map_name, ".png"), [1, 1, 1], 1, 0);
        }

        for(int i = 0; i < 8; i++) {
            sui_text([150, 30 + (i * 14)], MENU_TEXT_SMALL, custom_maps[index].map_desc[i], [1, 1, 1], 1, 0);
        }

        // Badge: always USERMAP for custom maps
        string badge_name = "USERMAP";
        sui_text([30 + (getTextWidth(badge_name, MENU_TEXT_SUPERSMALL_x)/2), 5], MENU_TEXT_SUPERSMALL, badge_name, [0.7, 0.15, 0.15], 1, 0);
        sui_subpic([12, 4], [20, 20], "gfx/menu/map_badges", [1, 1, 1], [0.5, 0], [0.25, 0.5], 1, 0);

        if (custom_maps[index].map_author != "") {
            sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
            string author = custom_maps[index].map_author;
            sui_text([0, -30], MENU_TEXT_MEDIUM, title, [1, 1, 1], 1, 0);
            sui_text([0, -15], MENU_TEXT_MEDIUM, author, [0.7, 0.15, 0.15], 1, 0);
        }

        sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
    }

    sui_action_element(bbox_pos, bbox_size, id, sui_noop);

    return sui_is_clicked(id);
}

void() Menu_CustomMaps =
{
    if (!menu_cmaps_init)
        Menu_CustomMaps_Init();

    Menu_DrawBackground();
    Menu_DrawTitle("CUSTOM MAPS");
    Menu_DrawMapPanel();

    int i;

    for(int h = 0; h < 13; h++) {
        menu_cmaps_buttons[h] = "";
    }

    int maps_on_page = 10;
    int maps_start_position = (custom_maps_page * 10);

    if (maps_on_page > custom_maps_count - maps_start_position)
        maps_on_page = custom_maps_count - maps_start_position;

    if (custom_maps_count == 0) {
        sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
        sui_text([6, 75], MENU_TEXT_MEDIUM, "NO CUSTOM MAPS FOUND", [0.5, 0.3, 0.3], 1, 0);
        sui_text([6, 95], MENU_TEXT_SMALL, "Place .bsp files in maps/custom/", [0.5, 0.3, 0.3], 1, 0);
    }

    for (i = maps_start_position; i < maps_on_page + maps_start_position; i++) {
        int menu_position = (i + 1) - (custom_maps_page * 10);
        string bsp_name = custom_maps[i].map_name;

        menu_cmaps_buttons[menu_position - 1] = sprintf("cmap_%s", bsp_name);

        Menu_CustomMapButton(menu_position, sprintf("cmap_%s", bsp_name), bsp_name, i) ? Menu_CustomMaps_LoadMap(bsp_name, custom_maps[i].map_folder) : 0;
    }

    int current_registry_position = ((i + 1) - (custom_maps_page * 10)) - 1;

    Menu_DrawDivider(11.25);

    if (maps_on_page + maps_start_position < custom_maps_count) {
        menu_cmaps_buttons[current_registry_position] = "cmap_next";
        current_registry_position++;
        Menu_Button(-3, "cmap_next", "NEXT PAGE", "Advance to next page") ? Menu_CustomMaps_NextPage() : 0;
    } else {
        Menu_GreyButton(-3, "NEXT PAGE");
    }

    if (custom_maps_page != 0) {
        menu_cmaps_buttons[current_registry_position] = "cmap_prev";
        current_registry_position++;
        Menu_Button(-2, "cmap_prev", "PREVIOUS PAGE", "Return to last page") ? Menu_CustomMaps_PrevPage() : 0;
    } else {
        Menu_GreyButton(-2, "PREVIOUS PAGE");
    }

    menu_cmaps_buttons[current_registry_position] = "cmap_back";

    Menu_Button(-1, "cmap_back", "BACK", "Return to map browser") ? current_menu = last_map_menu : 0;

    sui_pop_frame();
};
