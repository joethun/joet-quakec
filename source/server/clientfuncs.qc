/*
	server/clientfuncs.qc

	Used to communicate between server and client

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

// ============================================================
// Engine Packet Helpers
// ============================================================

#ifdef FTE

//
// FTE_RunParticleEffect(target, particle_type, position, optional_field, optional_entity)
// Fires a CSQC_EVENT_PARTICLE to the target client, or all clients if target == world.
//
void(entity target, float particle_type, vector position, float optional_field, entity optional_entity) FTE_RunParticleEffect =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_PARTICLE);
	WriteByte(MSG_MULTICAST, particle_type);
	WriteCoord(MSG_MULTICAST, position_x);
	WriteCoord(MSG_MULTICAST, position_y);
	WriteCoord(MSG_MULTICAST, position_z);
	WriteByte(MSG_MULTICAST, optional_field);
	WriteEntity(MSG_MULTICAST, optional_entity);

	if (target != world) {
		msg_entity = target;
		multicast(position, MULTICAST_ONE);
	} else {
		multicast(position, MULTICAST_ALL);
	}
};

#endif // FTE

// ============================================================
// Game State / Round Events
// ============================================================

void() NotifyGameEnd =
{
#ifdef FTE
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_ENDGAME);
	multicast('0 0 0', MULTICAST_ALL);
#endif // FTE
}

void SetUpdate(entity client, float type, float val1, float val2, float val3)
{
#ifdef FTE
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATE);
	WriteByte(MSG_MULTICAST, type);
	WriteByte(MSG_MULTICAST, val1);
	WriteByte(MSG_MULTICAST, val2);
	WriteByte(MSG_MULTICAST, val3);

	// UT_ROUNDS_CHANGE (type 2) broadcasts to all clients; everything else is per-client.
	if (type == 2) {
		multicast('0 0 0', MULTICAST_ALL);
	} else {
		msg_entity = client;
		multicast('0 0 0', MULTICAST_ONE);
	}
#endif // FTE
}

#ifdef FTE

void(float mode, entity to) ReportMapMode =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_MAPTYPE);
	WriteByte(MSG_MULTICAST, mode);
	msg_entity = to;
	multicast('0 0 0', MULTICAST_ONE);
}

//
// FTE_IncrementRound(round)
// Alerts all clients of new round value.
// -- RELIABLE --
//
void(float round) FTE_IncrementRound =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_ROUNDCHANGE);
	WriteByte(MSG_MULTICAST, round);
	multicast('0 0 0', MULTICAST_ALL_R);
};

void(string track_name) songegg =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_MUSICSTREAM);
	WriteString(MSG_MULTICAST, track_name);
	multicast('0 0 0', MULTICAST_ALL);
};

#endif // FTE

// ============================================================
// Revive Icon State
// ============================================================

void(float player_index, float state) ChangeReviveIconState =
{
#ifdef FTE
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_REVIVECHANGE);
	WriteByte(MSG_MULTICAST, player_index);
	WriteByte(MSG_MULTICAST, state);
	multicast('0 0 0', MULTICAST_ALL);
#endif // FTE
}

void(float player_index) EnableReviveIcon =
{
#ifdef FTE
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_REVIVEON);
	WriteByte(MSG_MULTICAST, player_index);
	multicast('0 0 0', MULTICAST_ALL);
#endif // FTE
}

void(float index) DisableReviveIcon =
{
#ifdef FTE
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_REVIVEOFF);
	WriteByte(MSG_MULTICAST, index);
	multicast('0 0 0', MULTICAST_ALL);
#endif // FTE
}

// ============================================================
// Weapon Effects
// ============================================================

void(entity who, float weapon) CL_SendWeaponFire =
{
	float recoil_return_time = getWeaponRecoilReturn(weapon);
	vector weapon_recoil = GetWeaponRecoil(weapon);

	msg_entity = who;

#ifdef FTE
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONRECOIL);
	WriteCoord(MSG_MULTICAST, weapon_recoil_x);
	WriteCoord(MSG_MULTICAST, weapon_recoil_y);
	WriteCoord(MSG_MULTICAST, weapon_recoil_z);
	multicast('0 0 0', MULTICAST_ONE);
#else
	WriteByte(MSG_ONE, SVC_WEAPONFIRE);
	WriteLong(MSG_ONE, recoil_return_time);
	WriteCoord(MSG_ONE, weapon_recoil_x);
	WriteCoord(MSG_ONE, weapon_recoil_y);
	WriteCoord(MSG_ONE, weapon_recoil_z);
#endif // FTE

	self.recoil_delay = 60 / recoil_return_time + time;
}

//
// nzp_hitmarker(who, death_marker)
// Tells the client to draw a hitmarker; death_marker flags a red hitmarker.
//
void(entity who, float death_marker) nzp_hitmarker =
{
#ifdef FTE
	SetUpdate(who, UT_HM, death_marker, 0, 0);
#else
	msg_entity = who;
	WriteByte(MSG_ONE, SVC_HITMARK);
#endif // FTE
};

#ifdef FTE

void(entity who) grenade_pulse =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_GRENADEPULSE);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);
}

void(entity who) nzp_bettyprompt =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BETTYPROMPT);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);
}

void(entity to, float type, float cost, float weapon) useprint =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_USEPRINT);
	WriteByte(MSG_MULTICAST, type);
	WriteLong(MSG_MULTICAST, cost);
	WriteByte(MSG_MULTICAST, weapon);
	msg_entity = to;
	multicast('0 0 0', MULTICAST_ONE);
}

#endif // FTE

// ============================================================
// HUD / UI Packets
// ============================================================

void(vector org) CallExplosion =
{
#ifndef FTE
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord(MSG_BROADCAST, org_x);
	WriteCoord(MSG_BROADCAST, org_y);
	WriteCoord(MSG_BROADCAST, org_z);
#else
	FTE_RunParticleEffect(world, CSQC_PART_EXPLOSION, org, 0, world);
#endif // FTE
}

void(vector org) Effect_Fire =
{
#ifndef FTE
	particle(self.origin, v_up * 8, 111, 0);
#else
	FTE_RunParticleEffect(world, CSQC_PART_FIRE, org, 0, world);
#endif // FTE
};

#ifdef FTE

//
// FTE_BroadcastMessage(target, broadcast_type, broadcast_time, player_id)
// Sends a CSQC event to display on-screen text.
// Use world to send to all clients.
// -- RELIABLE --
//
void(entity target, float broadcast_type, float broadcast_time, float player_id) FTE_BroadcastMessage =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_BROADCASTMESSAGE);
	WriteByte(MSG_MULTICAST, broadcast_type);
	WriteByte(MSG_MULTICAST, broadcast_time);
	WriteByte(MSG_MULTICAST, player_id);

	if (target != world) {
		msg_entity = target;
		multicast('0 0 0', MULTICAST_ONE_R);
	} else {
		multicast('0 0 0', MULTICAST_ALL_R);
	}
};

//
// nzp_screenflash(target, color, duration, type)
// FTE equivalent of the nzp_screenflash builtin.
//
void(entity target, float color, float duration, float type) nzp_screenflash =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_SCREENFLASH);
	WriteByte(MSG_MULTICAST, color);
	WriteByte(MSG_MULTICAST, duration);
	WriteByte(MSG_MULTICAST, type);

	if (target != world) {
		msg_entity = target;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		multicast('0 0 0', MULTICAST_ALL);
	}
};

//
// nzp_rumble(target, low_frequency, high_frequency, duration)
// FTE equivalent of the nzp_rumble builtin.
//
void(entity target, float low_frequency, float high_frequency, float duration) nzp_rumble =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_RUMBLE);
	WriteShort(MSG_MULTICAST, low_frequency);
	WriteShort(MSG_MULTICAST, high_frequency);
	WriteShort(MSG_MULTICAST, duration);
	msg_entity = target;
	multicast('0 0 0', MULTICAST_ONE);
};

//
// nzp_poweruptoast(powerup_id)
// FTE equivalent of the nzp_poweruptoast builtin.
//
void(float powerup_id) nzp_poweruptoast =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_POWERUPTOAST);
	WriteByte(MSG_MULTICAST, powerup_id);
	multicast('0 0 0', MULTICAST_ALL);
};

//
// nzp_setplayername(target, player_name)
// FTE equivalent of the nzp_setplayername builtin.
//
void(entity target, string player_name) nzp_setplayername =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_PLAYERNAME);
	WriteString(MSG_MULTICAST, player_name);
	msg_entity = target;
	multicast('0 0 0', MULTICAST_ONE);
};

#endif // FTE

void(float count) UpdatePlayerCount =
{
#ifdef FTE
	if (count == 0)
		return;

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_PLAYERUPDATE);
	WriteByte(MSG_MULTICAST, count);
	multicast('0 0 0', MULTICAST_ALL);
#endif // FTE
}

// ============================================================
// Chat
// ============================================================

#ifdef FTE

void CSQC_SendChatMessage(float player_id, string message) =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_CHATMESSAGE);
	WriteByte(MSG_MULTICAST, num_for_edict(self) - 1);
	WriteByte(MSG_MULTICAST, player_id);
	WriteString(MSG_MULTICAST, message);
	multicast('0 0 0', MULTICAST_ALL);
};

void CSQC_SendChatMessageToPlayer(float player_id, string message, entity who) =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_CHATMESSAGE);
	WriteByte(MSG_MULTICAST, num_for_edict(self) - 1);
	WriteByte(MSG_MULTICAST, player_id);
	WriteString(MSG_MULTICAST, message);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);
};

#endif // FTE

// ============================================================
// World Text
// ============================================================

#ifdef FTE

void(string chaptertitle, string location, string date, string person, entity who) WorldText =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WORLDDATA);
	WriteString(MSG_MULTICAST, chaptertitle);
	WriteString(MSG_MULTICAST, location);
	WriteString(MSG_MULTICAST, date);
	WriteString(MSG_MULTICAST, person);

	if (player_count == 1) {
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		multicast('0 0 0', MULTICAST_ALL);
	}
}

#endif // FTE

// ============================================================
// Player Networking
// ============================================================

#ifdef FTE

/*
=================
Player_SendEntity
    Networks the player info.
=================
*/
float Player_SendEntity(entity ePVEnt, float flChanged)
{
	self.ping = infokeyf(self, "ping");

	WriteByte(MSG_ENTITY, 1);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	WriteAngle(MSG_ENTITY, self.angles_x);
	WriteAngle(MSG_ENTITY, self.angles_y);
	WriteAngle(MSG_ENTITY, self.angles_z);
	WriteShort(MSG_ENTITY, self.velocity_x);
	WriteShort(MSG_ENTITY, self.velocity_y);
	WriteShort(MSG_ENTITY, self.velocity_z);
	WriteByte(MSG_ENTITY, self.playernum);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteByte(MSG_ENTITY, self.frame);
	WriteShort(MSG_ENTITY, self.movetype);
	WriteShort(MSG_ENTITY, self.flags);
	WriteByte(MSG_ENTITY, self.stance);
	WriteFloat(MSG_ENTITY, self.points);
	WriteShort(MSG_ENTITY, self.kills);
	WriteShort(MSG_ENTITY, self.headshots);
	WriteShort(MSG_ENTITY, self.downs);
	WriteShort(MSG_ENTITY, self.revives);
	WriteByte(MSG_ENTITY, self.is_in_menu);
	WriteByte(MSG_ENTITY, self.is_spectator);
	WriteShort(MSG_ENTITY, self.ping);
	return TRUE;
}

#endif // FTE

// ============================================================
// Per-Frame Client Updates (FTE only)
// ============================================================

#ifdef FTE

//
// FTE_InterpolatePunchAngle(person)
// Punchangle interpolation handled in SSQC for FTE.
//
void(entity person) FTE_InterpolatePunchAngle =
{
	// Early-out: skip fabs calls when punchangle is already zero.
	if (person.punchangle_x == 0 && person.punchangle_y == 0)
		return;

	// It's fine that lerp_factor is server-framerate-dependent since this runs server-side.
	float lerp_factor = 0.9 * frametime;

	for (int i = 0; i < 2; i++) {
		float difference = person.punchangle[i] * lerp_factor;

		if (fabs(person.punchangle[i]) > 0.01) {
			if (person.punchangle[i] >= difference)
				person.punchangle[i] -= difference;
			else if (person.punchangle[i] <= -difference)
				person.punchangle[i] -= difference;
			else
				person.punchangle[i] = 0;
		} else {
			person.punchangle[i] = 0;
		}
	}
};

//
// FTE_UpdateDynamicFOV(person)
// Context-sensitive adjustment of the client's viewzoom factor.
//
void(entity person) FTE_UpdateDynamicFOV =
{
	// Early-out: nothing to do if not zoomed and viewzoom is already correct.
	if (!person.zoom && person.viewzoom == 1)
		return;

	float viewzoom_differential = 1 - (0.018 * GetWeaponZoomAmount(person.weapon));
	float has_scoped_weapon = WepDef_HasSniperScore(person.weapon);

	// Sniper scope-in: force-set viewzoom as soon as the scope draws.
	if (person.zoom == 2) {
		person.viewzoom = viewzoom_differential;
		return;
	}

	// Scoped weapon but not zoomed in: reset viewzoom to 1.
	if (has_scoped_weapon) {
		if (person.viewzoom != 1)
			person.viewzoom = 1;
		return;
	}

	// Utilize a sigmoid curve to minimize motion sickness during ADS.
	if (person.zoom == 1 && person.viewzoom != viewzoom_differential) {
		float sigmoid_input = (person.viewzoom - viewzoom_differential) * 10;
		float sigmoid_output = 1 / (1 + exp(-sigmoid_input));
		float viewzoom_adjustment_rate = 0.06 * (sigmoid_output + 0.5) * (frametime * 20);

		if (person.viewzoom > viewzoom_differential) {
			person.viewzoom -= viewzoom_adjustment_rate;
			if (person.viewzoom < viewzoom_differential)
				person.viewzoom = viewzoom_differential;
		} else {
			person.viewzoom = viewzoom_differential;
		}
	} else if (person.zoom != 1 && person.viewzoom != 1) {
		// Zoom out at a constant rate.
		person.viewzoom += 0.85 * frametime;
		if (person.viewzoom > 1)
			person.viewzoom = 1;
	}
};

#endif // FTE

// ============================================================
// Utility Functions
// ============================================================

// "Removes" an entity in a way that can be restored on restart.
void(entity ent) Ent_FakeRemove =
{
	ent.entity_removed = true;
	ent.oldmodel  = ent.model;
	ent.oldorigin = ent.origin;
	ent.bbmins    = ent.mins;
	ent.bbmaxs    = ent.maxs;
	ent.sprintflag = ent.solid;
	ent.use       = SUB_Null;
	ent.think     = SUB_Null;
	ent.nextthink = 0;

	ent.solid = SOLID_NOT;
	setsize(ent, '0 0 0', '0 0 0');
	setmodel(ent, "");
}

// Precaches a model and sets self to use it.
void(string modelname) Precache_Set =
{
	modelname = Compat_ConvertOldAssetPath(modelname);
	precache_model(modelname);
	setmodel(self, modelname);
};

// Returns a random float in [-1, 1].
float() crandom =
{
	return 2 * (random() - 0.5);
}

// Returns true if 'them' is looking at 'me'.
float(entity them, entity me) PlayerIsLooking =
{
#ifdef QUAKEC_TEST
	return true;
#else
	float ret = false;
	float old_solid = me.solid;
	me.solid = SOLID_BBOX;

#ifdef FTE
	// Temporarily expose the target to the tracer's dimension_hit
	// so the traceline can collide with it.
	float old_dimension_solid = me.dimension_solid;
	me.dimension_solid = HITBOX_DIM_LIMBS | HITBOX_DIM_ZOMBIES | HITBOX_DIM_PLAYERS;
#endif // FTE

	setorigin(me, me.origin);

	makevectors(them.v_angle);
	vector source = them.origin + them.view_ofs;

	traceline(source, source + v_forward * 50, 0, them);

	if (trace_startsolid) {
		if (v_forward * normalize(me.origin - them.origin) > 0.7)
			ret = true;
	} else if (trace_ent == me) {
		ret = true;
	}

	me.solid = old_solid;

#ifdef FTE
	me.dimension_solid = old_dimension_solid;
#endif // FTE

	setorigin(me, me.origin);
	return ret;
#endif // QUAKEC_TEST
};
