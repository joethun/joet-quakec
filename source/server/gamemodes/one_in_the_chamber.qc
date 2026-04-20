/*
	server/gamemodes/one_in_the_chamber.qc

	Core Logic for One in the Chamber.

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

// Each kill grants this many bullets
#define OITC_BULLETS_PER_KILL   1
// Melee kills grant the same as gun kills
#define OITC_BULLETS_PER_MELEE  1

float oitc_ran_post_init_logic;

void() Gamemode_OITC_Init =
{
    game_modifier_can_use_equipment = false;
    game_modifier_powerup_max_ammo = false;
    game_modifier_powerup_weapon_upgrade = false;
    game_modifier_can_packapunch = false;
    game_modifier_powerup_free_perk = false;
};

void() Gamemode_OITC_Frame =
{
    if (oitc_ran_post_init_logic == false) {
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

        oitc_ran_post_init_logic = true;
    }
};

void() Gamemode_OITC_PlayerSpawn =
{
    // Give the 357 with exactly 1 bullet in the mag, no reserve.
    // Weapon_AssignWeapon auto-fills reserve when passed 0, so we
    // assign first then zero it out manually.
    Weapon_RemoveWeapon(0);
    Weapon_AssignWeapon(0, W_357, 1, 0, 0);
    self.weapons[0].weapon_reserve = 0;

    // Always start with the Bowie Knife
    self.has_bowie_knife = true;
};

//
// Gamemode_OITC_GetWeaponDamage(damage, weapon_id, weapon_tier)
// The 357 deals a flat 500 damage per shot.
//
float(float damage, float weapon_id, float weapon_tier) Gamemode_OITC_GetWeaponDamage =
{
    if (EqualNonPapWeapon(weapon_id) == W_357)
        return 500;

    return damage;
};

//
// Gamemode_OITC_DieHandler(attacker, death_style)
// Grants bullets to the attacker on a kill.
//
void(entity attacker, float death_style) Gamemode_OITC_DieHandler =
{
    if (attacker.classname != "player")
        return;

    float bullets_to_add;

    // Melee kills reward more bullets
    if (death_style == DMG_TYPE_MELEE)
        bullets_to_add = OITC_BULLETS_PER_MELEE;
    else
        bullets_to_add = OITC_BULLETS_PER_KILL;

    // Add bullets directly to the 357's magazine, capped at 1
    entity old_self = self;
    self = attacker;

    float slot = Weapon_PlayerHasWeapon(self, W_357, false);
    if (slot > 0) {
        self.weapons[slot - 1].weapon_magazine += bullets_to_add;
        if (self.weapons[slot - 1].weapon_magazine > 1)
            self.weapons[slot - 1].weapon_magazine = 1;
    }

    self = old_self;
};
