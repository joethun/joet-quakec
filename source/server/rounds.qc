/*
	server/rounds.qc

	wave logic

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
float(float current_count, float current_round, float round_type, float current_player_count) Gamemode_GetZombieTotalForRound;
string(string current_tune) Gamemode_GetEndRoundTune;
string(string current_tune) Gamemode_GetStartRoundTune;
string(string current_tune) Gamemode_GetEndSpecialRoundTune;
string(string current_tune) Gamemode_GetStartSpecialRoundTune;
string(string current_taunt) Gamemode_GetHellhoundTaunt;
float(float current_delay) Gamemode_GetRoundDelay;

void() SUB_UseTargets;
float() spawn_a_dogA;
void() zapper_cooldown;

void() Spawn_Enemy =
{
	// temporarily prevent spawning
	if (nuke_powerup_spawndelay > time)
		return;

	if (roundtype == 1)
	{
		if (spawn_a_zombieA())
		{
			Current_Zombies = Current_Zombies + 1;
		}
	}
	else if (roundtype == 2)
	{
		if (spawn_a_dogA())
		{
			Current_Zombies = Current_Zombies + 1;
		}
	}
}

// Early-round scale factors indexed by round (rounds 1-5 get scaled down, 6+ = full)
float round_scale_factors[] = { 0.25, 0.30, 0.50, 0.70, 0.90 };

float() getZombieTotal = {
	float count;

	if (roundtype == 1) {
		float multiplier = (rounds / 5 > 1) ? rounds / 5 : 1;

		if (rounds >= 10)
			multiplier *= rounds * 0.15;

		// Solo uses 0.5 player-equivalent, coop scales with extra players
		float effective_players = (player_count == 1) ? 0.5 : (player_count - 1);
		count = 24 + rint(effective_players * 6 * multiplier);

		// Scale down for early rounds (rounds 1-5)
		if (rounds < 6)
			count = floor(count * round_scale_factors[rounds - 1]);
	} else {
		// Dog rounds: 2 waves, more dogs after round 14
		count = ((rounds <= 14) ? 6 : 8) * player_count;
	}

	count = Gamemode_GetZombieTotalForRound(count, rounds, roundtype, player_count);

	switch (cvar("sv_difficulty")) {
		case 1:  count = floor(count * 0.90); break;
		case 2:
		case 3:  count = floor(count * 1.25); break;
		default: break;
	}

	return count;
}

//
// Rounds_PlayTransition(sound_path)
// A nice wrapper for sound() that checks if
// music is playing and proceeds if not.
//
void(string sound_path) Rounds_PlayTransition =
{
	// Don't play any round stuff while there's a song egg happening.
	if (music_override > time)
		return;

	Sound_PlaySound(world, sound_path, SOUND_TYPE_MUSIC_ROUND, SOUND_PRIORITY_PLAYALWAYS);
}

void() updateDogRound =
{
	// Pick a gap of 5, 6, or 7 rounds until the next dog round
	dogRound = rounds + 5 + floor(random() * 3);
}

void() PlayerSpawn;

void() EndRound =
{
	string end_round_tune = "";

	entity who = find(world,classname,"spectator");
	while(who != world)
	{
		if(who.is_spectator)
		{
			self = who;
			PlayerSpawn();
		}
		who = find(who, classname, "spectator");
	}

	rounds_change = 4;
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);

	if (map_has_hellhounds && rounds == dogRound) {
		end_round_tune = "sounds/rounds/droundend.wav";
		end_round_tune = Gamemode_GetEndSpecialRoundTune(end_round_tune);
		dogWave = false;
	} else {
		end_round_tune = "sounds/rounds/eround.wav";
		end_round_tune = Gamemode_GetEndRoundTune(end_round_tune);
	}

	if (cvar("sv_fastrounds") == 0)
		Rounds_PlayTransition(end_round_tune);

	if (cvar("sv_fastrounds") == 0)
		round_changetime = time + 10;
	else
		round_changetime = time + 0.2;

	round_changetime = Gamemode_GetRoundDelay(round_changetime);

	// No Perks? No Problem & Abstinence Program
	if (rounds >= 10) {
		entity players = find(world, classname, "player");
		while (players != world) {
			if (players.ach_tracker_abst == 0)
				GiveAchievement(8, players);
			if (rounds >= 16 && players.ach_tracker_npnp == 0)
				GiveAchievement(5, players);
			players = find(players, classname, "player");
		}
	}

	// Fire off all trigger_atroundent ents
	entity triggers = find(world, classname, "trigger_atroundend");
	while(triggers != world) {
		if (triggers.health == rounds) {
			entity oldself = self;
			self = triggers;
			SUB_UseTargets();
			self = oldself;
		}
		triggers = find(triggers, classname, "trigger_atroundend");
	}
}
void(entity players) Zoning_SetFog;
void() NewRound =
{
	string new_round_tune = "";

	entity tempe;
	round_changetime = 0;
	spawn_time = time + 5;
	if (delay_at_round > 0.08) {
		delay_at_round *= 0.95;
		if (delay_at_round < 0.08)
			delay_at_round = 0.08;
	}
	if (rounds != 0)
	{
		if (map_has_hellhounds && rounds == (dogRound - 1)) {
			new_round_tune = "sounds/rounds/droundstart.wav";
			new_round_tune = Gamemode_GetStartSpecialRoundTune(new_round_tune);
			dogWave = true;
			dog_round_count++;

			string hellhound_taunt = "";
			hellhound_taunt = Gamemode_GetHellhoundTaunt(hellhound_taunt);
			if (hellhound_taunt != "") {
				Sound_PlaySound(world, hellhound_taunt, SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
			}
		} else {
			new_round_tune = "sounds/rounds/nround.wav";
			new_round_tune = Gamemode_GetStartRoundTune(new_round_tune);
		}

		Rounds_PlayTransition(new_round_tune);

		rounds_change = 6;
		SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
		blink_return = time + 2;
	}

	// if we just had a dog round, set the next
	if (map_has_hellhounds && rounds == dogRound) {
		updateDogRound();
	}

	rounds = rounds + 1;

#ifdef FTE

	// FTE-Specific - alert CSQC of the round increment for HUD display
	FTE_IncrementRound(rounds);

#endif // FTE

	tempe = find(world, classname, "player");
	while (tempe)
	{
		if(tempe.grenades & 1)
		{
			tempe.primary_grenades = tempe.primary_grenades + 2;
			if (tempe.primary_grenades > 4)
				tempe.primary_grenades = 4;
		}

		if(tempe.grenades & 2)
		{
			tempe.secondary_grenades = tempe.secondary_grenades + 2;
			if (tempe.secondary_grenades > 2)
				tempe.secondary_grenades = 2;
		}

		// Set everyone to full health.
		tempe.health = tempe.max_health;

		// Reset total repaired barricades for this round
		tempe.barricade_reward = 0;

		Zoning_SetFog(tempe);	

		tempe = find(tempe, classname, "player");
	}

	set_z_health();

	barricade_reward_maximum = (50 * rounds > 500) ? 500 : 50 * rounds;

	Current_Zombies = 0;
	spawn_delay = 0;
	totalpowerups = 0;

	Remaining_Zombies = Total_Zombies = getZombieTotal();

	switch(rounds) {
		case 5: 	GiveAchievement(0); break;
		case 10: 	GiveAchievement(1); break;
		case 15: 	GiveAchievement(2); break;
		default: 	break;
	}

	// Set up delay for zombie spawning, decaying toward 0.08s minimum
	if (zombie_spawn_delay > 0.08)
		zombie_spawn_delay *= 0.95;
	else
		zombie_spawn_delay = 0.08;

	// Reset to 2 seconds on round 1
	if (rounds == 1)
		zombie_spawn_delay = 2;

	// Actually start the timer
	zombie_spawn_timer = 2 + time;

	if (rounds >= 10 && ach_tracker_spin == 0) {
		GiveAchievement(10);
	}

	// Refresh Electric Traps
	entity zaps = find(world, classname, "zapper_switch");
	while(zaps != world) {
		if (zaps.mode == 1) {
			zaps.think = zapper_cooldown;
            zaps.nextthink = time + 0.1;
		}
		zaps = find(zaps, classname, "zapper_switch");
	}
}

void() Round_Core =
{
	if (in_endgame_sequence)
		return;

	if (round_changetime) {
		if (round_changetime <= (time + 2)) {
			if (!rounds)
				rounds_change = 2;
			else
				rounds_change = 5;
		}
	}
	if (blink_return && blink_return < time) {
		if (rounds_change == 6) {
			blink_return = time + 3;
			rounds_change = 7;
		} else {
			blink_return = 0;
			rounds_change = 0;
		}
	}

	if (round_changetime < time && round_changetime != 0) {
		roundtype = 1;
		NewRound();
		return;
	} else if (round_changetime != 0) return;

	if (Total_Zombies > Current_Zombies && spawn_time < time) {
		Spawn_Enemy();
	}

	if (Remaining_Zombies < 1 && !Delay_Time) {
		Delay_Time = time + 1;
		rounds_change = 3;
	} else if (Delay_Time && Delay_Time < time) {
		Delay_Time = 0;
		EndRound();
	}

	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
}

void() InitRounds =
{
	roundtype = 1;
	delay_at_round = 2/0.95;
	totalpowerups = 0;
	powerup_activate = 2000;

	switch(cvar("sv_difficulty")) {
		case 0: powerup_score_threshold = ((player_count + 1) * 500) + powerup_activate; break;
		case 1: powerup_score_threshold = ((player_count) * 500) + powerup_activate; break;
		case 2: powerup_score_threshold = ((player_count + 1) * 750) + powerup_activate; break;
		case 3: powerup_score_threshold = ((player_count + 1) * 1250) + powerup_activate; break;
		default: powerup_score_threshold = ((player_count + 1) * 500) + powerup_activate; break;
	}

	// cypress -- fix Soft_Restart spawning multiple 
	// pairs of zombie spawn points.
	if (!roundinit)
		spawnAllZombEnts();
	
	if (cvar("sv_startround") == 0) {
		round_changetime = time + 3.5;
		rounds_change = 1;
	} else {
		NewRound();
	}

	roundinit = 1;
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
}
