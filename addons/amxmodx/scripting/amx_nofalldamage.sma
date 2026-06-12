#include <amxmodx>
#include <hamsandwich>

#define PLUGIN "No Fall Damage"
#define VERSION "1.0"
#define AUTHOR "devoceko"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
    if (damage_type & (1<<5)) { // DMG_FALL is (1<<5)
        return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}
