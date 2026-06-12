#include <amxmod>
#include <VexdUM>

#define FALL_VELOCITY 350.0

new g_bAlive, g_bFalling
#define SetIdBits(%1,%2)    %1 |= (1<<(%2-1))
#define RemoveIdBits(%1,%2) %1 &= ~(1<<(%2-1))
#define GetIdBits(%1,%2)    %1 & (1<<(%2-1))

new bool:g_bEnabled
new g_cvar_mp_falldamage

public plugin_init() {
  register_plugin("No Fall Damage", "0.3", "v3x");
  register_logevent("eRoundStart", 2, "1=Round_Start");
  register_event("ResetHUD", "eResetHUD", "be");
  register_event("DeathMsg", "eDeathMsg", "a");
  if(get_cvar_pointer("mp_falldamage") == 0) {
    g_cvar_mp_falldamage = register_cvar("mp_falldamage", "0");
  }
}

public eRoundStart() {
  g_bEnabled = (get_cvarptr_num(g_cvar_mp_falldamage) > 0) ? false : true;
}

public eResetHUD(id) {
  SetIdBits(g_bAlive, id);
  //g_bEnabled = (get_cvarptr_num(g_cvar_mp_falldamage) > 0) ? false : true;
}

public eDeathMsg() {
  RemoveIdBits(g_bAlive, read_data(2));
}

public client_prethink(id) {
  if(g_bEnabled && GetIdBits(g_bAlive, id)) {
    const m_flFallVelocity = 251;
    if(get_offset_float(id, m_flFallVelocity) >= FALL_VELOCITY) {
      SetIdBits(g_bFalling, id);
    }
    else {
      RemoveIdBits(g_bFalling, id);
    }
  }
}

public client_postthink(id) {
  if(g_bEnabled && GetIdBits(g_bAlive, id) && GetIdBits(g_bFalling, id)) {
    entity_set_int(id, EV_INT_watertype, CONTENTS_WATER);
  }
}
