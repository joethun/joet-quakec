/*
	server/gamemodes/minimalist.qc

	Core Logic for Minimalist Mode.

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

float minimalist_ran_post_init_logic;

.float minimalist_has_chosen_weapon;
.float minimalist_chosen_weapon_id;

void() Gamemode_Minimalist_Init =
{
    // Only allow 1 perk at a time (can replace it)
    game_modifier_perk_purchase_limit = 1;
};

void() Gamemode_Minimalist_Frame =
{
    if (minimalist_ran_post_init_logic == false) {
        minimalist_ran_post_init_logic = true;
    }
};

void() Gamemode_Minimalist_PlayerSpawn =
{
    // Reset weapon choice on first spawn only
    if (self.minimalist_has_chosen_weapon == 0) {
        self.minimalist_chosen_weapon_id = 0;
    }
};

//
// Gamemode_Minimalist_DrinkPerk(client)
// Called when a player drinks a perk. Strips any existing
// perk first so the player can swap their one allowed perk.
//
void(entity client) Gamemode_Minimalist_DrinkPerk =
{
    // Remove all current perks so the new one replaces them.
    // GivePerk() will OR in the new perk after this returns.
    client.perks = 0;

    // Reset Juggernog health if they had it
    client.max_health = 100;
    if (client.health > 100)
        client.health = 100;
};

//
// Gamemode_Minimalist_CanBuyWeapon(client, weapon)
// Returns true if the player is allowed to buy this weapon.
// First purchase locks in their choice; subsequent purchases
// are only allowed for the same weapon (for ammo refills).
//
float(entity client, float weapon) Gamemode_Minimalist_CanBuyWeapon =
{
    // Grenades and bowie are always allowed
    if (weapon == W_GRENADE || weapon == W_BETTY || weapon == W_BOWIE)
        return true;

    // If they haven't chosen a weapon yet, lock in this choice
    if (client.minimalist_has_chosen_weapon == 0) {
        client.minimalist_has_chosen_weapon = 1;
        client.minimalist_chosen_weapon_id = EqualNonPapWeapon(weapon);
        return true;
    }

    // Allow buying the same weapon (or its PAP'd variant) for ammo
    if (EqualNonPapWeapon(weapon) == client.minimalist_chosen_weapon_id)
        return true;

    // Different weapon — strip the old one and lock in the new choice
    entity old_self = self;
    self = client;
    Weapon_RemoveWeapon(0);
    self = old_self;

    client.minimalist_chosen_weapon_id = EqualNonPapWeapon(weapon);
    return true;
};

//
// Gamemode_Minimalist_BuyWeapon(client, weapon)
// Post-purchase callback.
//
void(entity client, float weapon) Gamemode_Minimalist_BuyWeapon =
{
    return;
};
