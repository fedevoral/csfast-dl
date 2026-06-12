#include <amxmodx>
#include <reapi>

#define PLUGIN_VERSION "1.0.0"

enum PluginCvars
{
    MENU_AFTER_ROUND,
    Float:AUTO_CLOSE_MENU,
    FLAG_ACCESS[2]
}

new g_eCvars[PluginCvars], g_iFlag, glb_iMenu

public plugin_init()
{
    register_plugin("Spawn Weapons Menu", PLUGIN_VERSION, "Huehue")
    
    RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", 1)

    bind_pcvar_num(create_cvar("swm_after_round", "2", FCVAR_NONE, "After X round to show weapons menu"), g_eCvars[MENU_AFTER_ROUND])
    bind_pcvar_float(create_cvar("swm_auto_close_menu_after", "5.0", FCVAR_NONE, "After X seconds to close the menu"), g_eCvars[AUTO_CLOSE_MENU])
    bind_pcvar_string(create_cvar("swm_vip_flag_access", "b", FCVAR_NONE, "Access to the menu If you set flag for VIP users^nFor everyone to use it leave it blank, don't set flag"), g_eCvars[FLAG_ACCESS], charsmax(g_eCvars[FLAG_ACCESS]))

    AutoExecConfig(true, "SpawnWeaponsMenu", "HuehuePlugins_Config")


    glb_iMenu = menu_create("\rWeapons Menu", "WeaponsMenu_Handler")

    menu_additem(glb_iMenu, "\d>>\yAK47 & Deagle\d<<")
    menu_additem(glb_iMenu, "\d>>\yM4A1 & Deagle\d<<")
}

public OnConfigsExecuted()
{
    g_iFlag = g_eCvars[FLAG_ACCESS] == EOS ? ADMIN_ALL : read_flags(g_eCvars[FLAG_ACCESS])
}

public CBasePlayer_Spawn(id)
{
    if (!is_user_alive(id) || !Check_Access(id, g_iFlag))
        return HC_CONTINUE

    if (get_member_game(m_iTotalRoundsPlayed) >= g_eCvars[MENU_AFTER_ROUND])
    {
        menu_display(id, glb_iMenu, .time = floatround(g_eCvars[AUTO_CLOSE_MENU]))
        set_task(g_eCvars[AUTO_CLOSE_MENU], "CloseMenu", id)
    }

    return HC_CONTINUE
}

public CloseMenu(id)
{
    show_menu(id, 0, "^n", 1)
}

public WeaponsMenu_Handler(id, iMenu, iItem)
{
    switch (iItem)
    {
        case MENU_EXIT, MENU_TIMEOUT: return;
        case 0: rg_give_item_ex(id, "weapon_ak47", GT_REPLACE, 30, 90);
        case 1: rg_give_item_ex(id, "weapon_m4a1", GT_REPLACE, 30, 90);
    }
    rg_give_item_ex(id, "weapon_deagle", GT_REPLACE, 7, 35)
    rg_give_item_ex(id, "weapon_hegrenade", .bpammo = 1)
    rg_give_item_ex(id, "weapon_flashbang", .bpammo = 1)

    if (get_member(id, m_iTeam) == TEAM_CT)
        rg_give_defusekit(id, true)
}

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, ammo = 0, bpammo = 0)
{
    rg_give_item(id, weapon, type)

    if (ammo)
        rg_set_user_ammo(id, rg_get_weapon_info(weapon, WI_ID), ammo)

    if (bpammo)
        rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), bpammo)
}

bool:Check_Access(id, iUserFlag)
{
    if (iUserFlag == ADMIN_ALL || get_user_flags(id) & iUserFlag)
        return true
    else
        return false
}