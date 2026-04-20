/*
	server/gamemodes/randomizer.qc

	Core Logic for Randomizer Mode.

	Copyright (C) 2021-2025 NZ:P Team

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

#define RANDOMIZER_WEAPON_SWAP_TIME     30

float randomizer_ran_post_init_logic;

.float randomizer_next_swap_time;

float(float weapon_id) Gamemode_Randomizer_WeaponIDIsValid =
{
    // Non-weapons should be excluded.
    if (weapon_id == W_NOWEP || weapon_id == W_GRENADE ||
        weapon_id == W_BETTY || weapon_id == W_BOWIE ||
        weapon_id == W_RESERVED || weapon_id == W_RESERVED2)
        return false;
    
    // Also NO FLAMETHROWER
    if (weapon_id == W_M2)
        return false;

    return true;
};

float() Gamemode_Randomizer_GetRandomWeapon =
{
    float found_eligible_weapon = false;
    float weapon_id = 0;

    while (!found_eligible_weapon) {
        weapon_id = rint(random() * 59);
        float final_id = EqualNonPapWeapon(weapon_id);

        if (Gamemode_Randomizer_WeaponIDIsValid(final_id)) {
            found_eligible_weapon = true;
            return final_id;
        }
    }

    return W_COLT;
};

void() Gamemode_Randomizer_Init =
{
    // Precache all valid weapons upfront so mid-game swaps
    // don't trigger client downloads in coop.
    for (float i = 0; i < 60; i++) {
        float wep = EqualNonPapWeapon(i);
        if (Gamemode_Randomizer_WeaponIDIsValid(wep)) {
            precache_model(GetWeaponModel(wep, 0));
            precache_model(GetWeaponModel(wep, 1));
            precache_extra(wep);
        }
    }

    // Precache sounds
    precache_sound("sounds/misc/ching.wav");

    game_modifier_can_melee = true;
    game_modifier_can_use_equipment = true;
    game_modifier_can_earn_misc_score = true;
    game_modifier_powerup_free_perk = true;
    game_modifier_powerup_max_ammo = true;
    game_modifier_powerup_weapon_upgrade = true;
    game_modifier_can_packapunch = false;
};

void() Gamemode_Randomizer_Frame =
{
    if (randomizer_ran_post_init_logic == false) {
        // Disable weapon buy triggers
        entity buy_weapon = find(world, classname, "buy_weapon");
        while(buy_weapon != world) {
            buy_weapon.solid = SOLID_NOT;
            buy_weapon = find(buy_weapon, classname, "buy_weapon");
        }

        // Disable Mystery Box
        entity mystery_box = find(world, classname, "mystery");
        while(mystery_box != world) {
            mystery_box.solid = SOLID_NOT;
            mystery_box = find(mystery_box, classname, "mystery");
        }

        randomizer_ran_post_init_logic = true;
    }

    // Check each player for weapon swap
    entity players = find(world, classname, "player");
    while(players != world) {
        // Make sure the Player never runs out of ammo.
        players.weapons[0].weapon_reserve = getWeaponAmmo(players.weapons[0].weapon_id);

        // Initialize swap time on first frame
        if (players.randomizer_next_swap_time == 0) {
            players.randomizer_next_swap_time = time + RANDOMIZER_WEAPON_SWAP_TIME;
        }

        // Time to swap weapons!
        if (time >= players.randomizer_next_swap_time && !players.downed) {
            entity old_self = self;
            self = players;
            
            // Get a random weapon
            float new_weapon = Gamemode_Randomizer_GetRandomWeapon();
            
            // Remove current weapon and give new one
            Weapon_RemoveWeapon(0);
            Weapon_GiveWeapon(new_weapon, 0, 0, 0);
            
            // Play sound
            Sound_PlaySound(self, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
            
            // Set next swap time
            self.randomizer_next_swap_time = time + RANDOMIZER_WEAPON_SWAP_TIME;
            
            self = old_self;
        }

        players = find(players, classname, "player");
    }
};

void() Gamemode_Randomizer_PlayerSpawn =
{
    // Give a random starting weapon
    Weapon_RemoveWeapon(0);
    float starting_weapon = Gamemode_Randomizer_GetRandomWeapon();
    Weapon_GiveWeapon(starting_weapon, 0, 0, 0);
    
    // Initialize the swap timer
    self.randomizer_next_swap_time = time + RANDOMIZER_WEAPON_SWAP_TIME;
};
