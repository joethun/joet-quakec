/*
	server/main.qc

	mostly functions that will be called from the engine and are
	expected to exist

	Copyright (C) 2021-2024 NZ:P Team

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

*/

void() LS_Setup;
void() PU_Init;
void() Compat_Init;
void() Gamemode_Init;
void() Gamemode_Frame;
void() SUB_Remove = {remove(self);}
string(string current_tune) Gamemode_GetSplashTune;

.float gungame_weapon_idx;
.float gungame_score_threshold;

//called when starting server/loading the map
void() main =
{
	cheats_have_been_activated = false;
	global_trace_damage_multiplier = 1;
}

float ai_delay_time;
float time_before_gamestart;

//
// Way_SetBrushEntNonSolid(ent_name)
// FIXME: Move this elsewhere..
// Wrapper for finding brush ents of classname
// and making them non-solid. For use only
// with Waypoint Mode.
//
void(string ent_name) Way_SetBrushEntNonSolid =
{
	entity ent = find(world, classname, ent_name);
	while(ent != world) {
		ent.solid = SOLID_NOT;
		ent.touch = SUB_Null;
		ent = find(ent, classname, ent_name);
	}
}

//called for each frame that QC runs
float zombie_cleaned_w;
void() StartFrame =
{
	framecount = framecount + 1;

	if (waypoint_mode) {
		if (!zombie_cleaned_w) {
			entity zent;
			zent = find (world, classname, "ai_zombie");
			while (zent)
			{
				remove (zent);
				zent = find (zent, classname, "ai_zombie");
			}
			zombie_cleaned_w = true;

			zent = find (world, classname, "waypoint");
			while (zent)
			{
				if (zent.targetname != "")
					setmodel(zent, "models/way/normal_way_door.spr");
				else
					setmodel(zent, "models/way/normal_way.spr");
				zent = find (zent, classname, "waypoint");
			}
			Way_SetBrushEntNonSolid("door_nzp_cost");
			Way_SetBrushEntNonSolid("door_nzp");
			Way_SetBrushEntNonSolid("door");
		}
		return;
	}

	if (roundinit) {
		Round_Core();

		if (ai_delay_time < time) {
			Do_Zombie_AI ();

			// This determines the delay between each AI's update sequence.
			// It needs to be variable -- the more AI, the smaller this number
			// should end up being, or else you'll have AI completely stall
			// waiting for it's chance in the spotlight.
			// -----

#ifdef FTE

			// On FTE, Do_Zombie_AI processes up to 8 zombies per call,
			// cycling through the list. At 0.01s intervals, each zombie
			// updates roughly every 0.03-0.08s depending on total count.
			ai_delay_time = time + 0.01;

#else

			// On other platforms, have this be 0.03 / ai factor / 12.
			// This means that:
			// AI Updates at ~30Hz with 12 Zombies
			// AI Updates at ~45Hz with 18 Zombies
			// AI Updates at ~60Hz with 24 Zombies
			ai_delay_time = time + (0.03 / (nzp_maxai()/12));

#endif // FTE

		}
	} else {
		if (!time_before_gamestart) {
			entity SpawnedIn;
			SpawnedIn = find(world, classname, "player");

			if (SpawnedIn) {
				entity hellhound = find(world, classname, "spawn_dog");

				if (hellhound != world)
					map_has_hellhounds = true;

				Compat_Init();
				updateDogRound();
				time_before_gamestart = time + 3;
			}
			return;
		} else if (time_before_gamestart < time) {
			InitRounds();
			nzp_screenflash(world, SCREENFLASH_COLOR_BLACK, 1, SCREENFLASH_FADE_OUT);

			if (cvar("sv_startround") == 0) {
				string splash_tune = "sounds/rounds/splash.wav";
				splash_tune = Gamemode_GetSplashTune(splash_tune);
				Rounds_PlayTransition(splash_tune);
			}

			entity players = find(world, classname, "player");
			
			while(players != world) {
				if (players.name != "")
					nzp_setplayername(players, players.name);
				nzp_setclientmode(cvar("sv_gamemode"));

				players = find(players, classname, "player");
			}

		} else {
			nzp_screenflash(world, SCREENFLASH_COLOR_BLACK, 90, SCREENFLASH_FADE_OUT);
		}
	}

	Gamemode_Frame();
}
string(string s) precache_model         = #20;

void() precaches =
{
	precache_model ("models/player.mdl");

	//
	// Models
	//

	// sprites
	precache_model ("models/sprites/sprkle.spr");
	precache_model ("models/sprites/explosion.spr");
	precache_model ("models/sprites/null.spr");
	precache_model ("models/sprites/lightning.spr");

	if (cvar("waypoint_mode")) {
		precache_model ("models/way/current_way.spr");
		precache_model ("models/way/current_way_door.spr");
		precache_model ("models/way/last_way.spr");
		precache_model ("models/way/last_way_door.spr");
		precache_model ("models/way/normal_way.spr");
		precache_model ("models/way/normal_way_door.spr");
		precache_model ("models/way/way_jump.spr");
		precache_model ("models/way/way_land.spr");
	}

	// zombie
	precache_model ("models/ai/zfull.mdl");
	precache_model ("models/ai/zal(.mdl");
	precache_model ("models/ai/zar(.mdl");
	precache_model ("models/ai/zb%.mdl");
	precache_model ("models/ai/zh^.mdl");

	// For debugging zombie AI
	if (cvar("developer")) {
		precache_model ("models/way/normal_way.spr");
	}

	// zombie crawler
	precache_model ("models/ai/zcfull.mdl");
	precache_model ("models/ai/zbc%.mdl");
	precache_model ("models/ai/zalc(.mdl");
	precache_model ("models/ai/zarc(.mdl");
	precache_model ("models/ai/zhc^.mdl");

	// start weapons
	precache_model ("models/weapons/m1911/v_colt.mdl");
	precache_model ("models/weapons/m1911/g_colt.mdl");
	precache_model ("models/weapons/knife/v_knife.mdl");
	precache_model ("models/weapons/grenade/v_grenade.mdl");
	precache_model ("models/weapons/grenade/g_grenade.mdl");
	precache_extra (W_BIATCH);

#ifdef FTE

	// FTE only has co-op, so don't precache morphine elsewhere.
	precache_model ("models/weapons/morphine/v_morphine.mdl");

#endif // FTE

	//
	// Sounds
	//

	// player-made

#ifdef FTE

	precache_sound("sounds/player/footstep1.wav");
	precache_sound("sounds/player/footstep2.wav");
	precache_sound("sounds/player/footstep3.wav");
	precache_sound("sounds/player/footstep4.wav");
	precache_sound("sounds/player/footstep5.wav");

#endif // FTE

	precache_sound("sounds/player/jump.wav");
	precache_sound("sounds/player/land.wav");
	precache_sound("sounds/player/pain4.wav");

	// weapons
	precache_sound("sounds/weapons/colt/magin.wav");
	precache_sound("sounds/weapons/colt/magout.wav");
	precache_sound("sounds/weapons/colt/shoot.wav");
	precache_sound("sounds/weapons/colt/slide.wav");
	precache_sound("sounds/weapons/papfire.wav");

	// grenade
	precache_sound("sounds/weapons/grenade/prime.wav");
	precache_sound("sounds/weapons/grenade/throw.wav");
	precache_sound("sounds/weapons/grenade/explode.wav");

	// melee
	precache_sound("sounds/weapons/knife/knife_hitbod.wav");
	precache_sound("sounds/weapons/knife/knife.wav");
	precache_sound("sounds/weapons/knife/knife_hit.wav");

	// tunes
	precache_sound("sounds/rounds/eround.wav");
	precache_sound("sounds/rounds/nround.wav");
	precache_sound("sounds/rounds/splash.wav");
	precache_sound("sounds/music/end.wav");

	// purchasing
	precache_sound("sounds/misc/ching.wav");
	precache_sound("sounds/misc/buy.wav");
	precache_sound("sounds/misc/denybuy.wav");

	// power-ups
	precache_sound("sounds/pu/pickup.wav");
	precache_sound("sounds/pu/powerup.wav");
	precache_sound("sounds/pu/drop.wav");
	precache_sound("sounds/pu/byebye.wav");

	// zombie walk
	precache_sound("sounds/zombie/w0.wav");
	precache_sound("sounds/zombie/w1.wav");
	precache_sound("sounds/zombie/w2.wav");
	precache_sound("sounds/zombie/w3.wav");
	precache_sound("sounds/zombie/w4.wav");
	precache_sound("sounds/zombie/w5.wav");
	precache_sound("sounds/zombie/w6.wav");
	precache_sound("sounds/zombie/w7.wav");
	precache_sound("sounds/zombie/w8.wav");
	precache_sound("sounds/zombie/w9.wav");

	// zombie run
	precache_sound("sounds/zombie/r0.wav");
	precache_sound("sounds/zombie/r1.wav");
	precache_sound("sounds/zombie/r2.wav");
	precache_sound("sounds/zombie/r3.wav");
	precache_sound("sounds/zombie/r4.wav");
	precache_sound("sounds/zombie/r5.wav");
	precache_sound("sounds/zombie/r6.wav");
	precache_sound("sounds/zombie/r7.wav");
	precache_sound("sounds/zombie/r8.wav");
	precache_sound("sounds/zombie/r9.wav");

	// zombie swipe
	precache_sound("sounds/zombie/a0.wav");
	precache_sound("sounds/zombie/a1.wav");
	precache_sound("sounds/zombie/a2.wav");
	precache_sound("sounds/zombie/a3.wav");
	precache_sound("sounds/zombie/a4.wav");
	precache_sound("sounds/zombie/a5.wav");
	precache_sound("sounds/zombie/a6.wav");
	precache_sound("sounds/zombie/a7.wav");

	// zombie death
	precache_sound("sounds/zombie/d0.wav");
	precache_sound("sounds/zombie/d1.wav");
	precache_sound("sounds/zombie/d2.wav");
	precache_sound("sounds/zombie/d3.wav");
	precache_sound("sounds/zombie/d4.wav");
	precache_sound("sounds/zombie/d5.wav");
	precache_sound("sounds/zombie/d6.wav");
	precache_sound("sounds/zombie/d7.wav");

	// zombie taunt
	precache_sound("sounds/zombie/t0.wav");
	precache_sound("sounds/zombie/t1.wav");
	precache_sound("sounds/zombie/t2.wav");
	precache_sound("sounds/zombie/t3.wav");
	precache_sound("sounds/zombie/t4.wav");

	// zombie footsteps
	precache_sound("sounds/zombie/s0.wav");
	precache_sound("sounds/zombie/s1.wav");
	precache_sound("sounds/zombie/sc0.wav");
	precache_sound("sounds/zombie/sc1.wav");

	// null
	precache_sound("sounds/null.wav");
}

//called when map loaded
void() worldspawn =
{
	precaches();

	// Define all of our Light Styles
	LS_Setup();

	// Init Power-Ups
	PU_Init();

#ifdef FTE

	clientstat(STAT_CURRENTMAG, EV_FLOAT, weapons[0].weapon_magazine);
	clientstat(STAT_CURRENTMAG2, EV_FLOAT, weapons[0].weapon_magazine_left);
	clientstat(STAT_POINTS, EV_FLOAT, points);
	clientstat(STAT_WEAPON2FRAME, EV_FLOAT, weapon2frame);
	clientstat(STAT_WEAPON2MODELI, EV_FLOAT, weapon2modelindex);
	clientstat(STAT_WEAPONSKIN, EV_FLOAT, weaponskin);
	clientstat(STAT_GRENADES, EV_FLOAT, primary_grenades);
	clientstat(STAT_SECGRENADES, EV_FLOAT, secondary_grenades);
	clientstat(STAT_PROGRESSBAR, EV_FLOAT, progress_bar_percent);
	clientstat(STAT_WEAPONDURATION, EV_FLOAT, weapon_animduration);
	clientstat(STAT_WEAPON2DURATION, EV_FLOAT, weapon2_animduration);
	clientstat(STAT_WEAPONZOOM, EV_FLOAT, zoom);
	clientstat(STAT_INSTA, EV_FLOAT, insta_icon);
	clientstat(STAT_X2, EV_FLOAT, x2_icon);
	clientstat(STAT_SPECTATING, EV_FLOAT, is_spectator);
	clientstat(STAT_PLAYERNUM, EV_FLOAT, playernum);
	clientstat(STAT_PLAYERSTANCE, EV_FLOAT, stance);
	clientstat(STAT_FACINGENEMY, EV_FLOAT, facingenemy);
	clientstat(STAT_VIEWZOOM, EV_FLOAT, viewzoom);
	clientstat(STAT_MAXHEALTH, EV_FLOAT, max_health);
	clientstat(STAT_PERKS, EV_FLOAT, perks);
	clientstat(STAT_TOTALSCORE, EV_FLOAT, score);
	clientstat(STAT_WEAPONNAME, EV_STRING, Weapon_Name);
	clientstat(STAT_WEAPONNAMETOUCH, EV_STRING, Weapon_Name_Touch);
	clientstat(STAT_WEAPONTIER, EV_FLOAT, weapon_tier);
	clientstat(STAT_VIEWMODEL_EFFECTS, EV_FLOAT, viewmodel_effects);
	clientstat(STAT_VIEWMODEL2_EFFECTS, EV_FLOAT, viewmodel2_effects);

	// Gun Game
	clientstat(STAT_GUNGAME_IDX, EV_FLOAT, gungame_weapon_idx);
	clientstat(STAT_GUNGAME_SCOREGOAL, EV_FLOAT, gungame_score_threshold);

	autocvar(sv_enablechatplugins, 0);
	autocvar(sv_maprotationbasename, "map_rotation");
	autocvar(sv_maprotationmode, 0);
	autocvar(sv_gamemode, 0);
	autocvar(sv_difficulty, 0);
	autocvar(sv_startround, 0);
	autocvar(sv_magic, 1);
	autocvar(sv_headshotonly, 0);
	autocvar(sv_maxai, 24);
	autocvar(sv_fastrounds, 0);

	autocvar(sv_spoofmonth, 0);

	current_month_of_year = nzp_getmonthofyear();

#endif // FTE

	mappath = strcat("maps/", mapname);
	mappath = strzone(mappath);

	LoadWaypointData();
	Zoning_LoadData();
	Zoning_SpawnEnts();

	//set game elements
	G_PRONEPOINTS = 0;
	G_STARTWEAPON[0] = W_COLT;
	G_STARTWEAPON[1] = 8;
	G_STARTWEAPON[2] = 32;
	G_WORLDTEXT = 1;
	G_PERKS = 0;
	G_PERKPOWER = 0;

	game_modifier_can_melee = true;
    game_modifier_can_use_equipment = true;
    game_modifier_can_earn_misc_score = true;
	game_modifier_powerup_free_perk = false;
	game_modifier_powerup_max_ammo = true;
	game_modifier_powerup_weapon_upgrade = false;
	game_modifier_powerup_bonus_points = false;
	game_modifier_powerup_toast_for_all = false;
	game_modifier_can_packapunch = true;
	game_modifier_grenades_explode_on_contact = false;
	game_modifier_packapunch_uses_tiers = false;
	game_modifier_packapunch_is_instant = false;
	game_modifier_maxammo_fills_magazine = false;
	game_modifier_hellhound_fog_color = "200 525 54 55 60";
	game_modifier_default_fog_color = world.fog;
	game_modifier_perk_purchase_limit = 8;
	game_modifier_cost_multiplier = 1;

	sprint_max_time = 4.0;

	//
	// World Gravity Multiplier
	//

	// FIXME: This should technically poll sv_gravity but
	// we do not currently enforce a default that resets
	// on a new server.
	float sv_gravity = 800;

	// worldspawn "gravity" field is a multiplier to be applied
	// to sv_gravity.
	if (!world.gravity) world.gravity = 1;
	world.gravity = clamp(world.gravity, 0.1, 2);

	// Update the cvar for the server.
	cvar_set("sv_gravity", ftos(sv_gravity * world.gravity));

#ifdef FTE

	// We need to get the currently loaded map's pretty name
	// (if it exists) so we can send it to clients or broadcast
	// it.
	string mapname_pretty;
	float map_txt_file = fopen(sprintf("maps/%s.txt", mapname), FILE_READ);

	if (map_txt_file == -1) {
		mapname_pretty = mapname;
	} else {
		mapname_pretty = strtrim((fgets(map_txt_file)));
		fclose(map_txt_file);
	}

	cvar_set("mapname_pretty", mapname_pretty);
	localcmd(sprintf("serverinfo mapname_pretty %s\n", mapname_pretty));

#endif // FTE

	Gamemode_Init();
}

void() SpectatorConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the spectators.\n");
}

//
// UpdateLimbBounds(zombie, limb, do_relink)
// Shared helper for updating a single zombie limb's bounding box.
// When do_relink is true, also sets the limb's origin (full relink).
//
void(entity zombie, entity limb, float do_relink) UpdateLimbBounds =
{
	if (!limb)
		return;

	if (do_relink)
		setorigin(limb, zombie.origin);

	limb.angles = zombie.angles;

	if (limb.deadflag)
		limb.frame = zombie.frame;

	vector ofs = (v_right * limb.view_ofs_x) + (v_forward * limb.view_ofs_y) + (v_up * limb.view_ofs_z);
	vector mn = limb.bbmins + ofs;
	vector mx = limb.bbmaxs + ofs;

	// Ensure min < max on each axis
	float tmpval;
	if(mn_x > mx_x) { tmpval = mn_x; mn_x = mx_x; mx_x = tmpval; }
	if(mn_y > mx_y) { tmpval = mn_y; mn_y = mx_y; mx_y = tmpval; }
	if(mn_z > mx_z) { tmpval = mn_z; mn_z = mx_z; mx_z = tmpval; }

	setsize(limb, mn, mx);
};

void() RelinkZombies =
{
	entity ent = world;

	while ((ent = find(ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)
			continue;

#ifdef FTE
		// Optimized model switching - cache crawling state
		float is_crawler = (ent.crawling == 1);
		float all_limbs_dead = (ent.larm.deadflag && ent.rarm.deadflag && ent.head.deadflag);

		if (all_limbs_dead) {
			setmodel(ent.larm, "");
			setmodel(ent.rarm, "");
			setmodel(ent.head, "");

			string full_model = is_crawler ? "models/ai/zcfull.mdl" : "models/ai/zfull.mdl";
			if (ent.model != full_model)
				setmodel(ent, full_model);
		} else {
			string body_model = is_crawler ? "models/ai/zbc%.mdl" : "models/ai/zb%.mdl";
			if (ent.model != body_model)
				setmodel(ent, body_model);

			if (ent.larm.deadflag && ent.larm.model == "")
				setmodel(ent.larm, is_crawler ? "models/ai/zalc(.mdl" : "models/ai/zal(.mdl");

			if (ent.rarm.deadflag && ent.rarm.model == "")
				setmodel(ent.rarm, is_crawler ? "models/ai/zarc(.mdl" : "models/ai/zar(.mdl");

			if (ent.head.deadflag && ent.head.model == "")
				setmodel(ent.head, is_crawler ? "models/ai/zhc^.mdl" : "models/ai/zh^.mdl");
		}
#endif // FTE

		makevectors(ent.angles);
		UpdateLimbBounds(ent, ent.head, true);
		UpdateLimbBounds(ent, ent.larm, true);
		UpdateLimbBounds(ent, ent.rarm, true);
	}
}

void() LinkZombiesHitbox =
{
	entity ent = world;

	while ((ent = find(ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)
			continue;

		makevectors(ent.angles);
		UpdateLimbBounds(ent, ent.head, false);
		UpdateLimbBounds(ent, ent.larm, false);
		UpdateLimbBounds(ent, ent.rarm, false);
	}
}

void() EndFrame =
{
	// Only relink zombies if there are any alive
	if (Current_Zombies > 0)
		RelinkZombies();

	if (cheats_have_been_activated == false && cvar("sv_cheats") == 1) {
		cheats_have_been_activated = true;
	}
};