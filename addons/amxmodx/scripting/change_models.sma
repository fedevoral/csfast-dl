/*******************************************************************************
                            AMX Change Models

  Version: 1.4.4
  Author: KRoT@L

  0.1    Release
  0.2    Added possibility to replace knife sounds
  0.3    Added chicken model and c4 ledglow sprite
  1.0    No more cvars, use the change_models.ini file,
         added player models and armoury entities
  1.1    Added shield models, kevlar, thighpack
         Added player_models.ini to configure player models
  1.2    Added hostage_model
  1.3    You can use custom map ini files
  1.4.0  You can use change_models_prefix_xx.ini and player_models_prefix_xx.ini
         You can set 4 different hostage models.
         You can change the hostage sounds.
         In the player_models_xx.ini files, you can set a VIP model in addition to T and CT models.
  1.4.1  Fixed a bug with VIP model not being reset
  1.4.2  Modified hostage models replacement.
  1.4.3  Fixed a bug which didn't reset a model to a player
  1.4.4  Useful improvements (was required!)
         - Code optimizations
         - Fixed the mp5 w_ model
         - Fixed replacement of the default player models, which not previously worked correctly
         - Added NoSteam support (for CS 1.6 with dproto module or CS 1.5 WON users)

  This plugin allows you to replace the models (v_, p_ and w_) of all the weapons (including
  armoury entities), knife sounds, the sprite of the c4 led and of the HE explosion, and player models.
  Players will only have to download the models/sounds/sprites,
  their original models/sounds/sprites won't be modified.

  vmodel is the model you see in your hands.
  pmodel is the model you see in other players' hands.
  wmodel is the model you see when the weapon is on the ground.

  The names of the models/sounds must be different than the default ones,
  otherwise players won't download them because they already have them on their computer.


  Cvar:

  change_models "1" - 0: disable the plugin (but does not prevent the plugin from precaching files)
                      1: enable the plugin


  addons/amx/config/change_models.ini:

  p228_vmodel models/custom_weapons/v_p228.mdl
  knife_pmodel models/p_axe.mdl
  bomb_wmodel models/egg.mdl
  knife_hit_sound sound/axe_hit.wav
  ledglow_sprite sprites/custom_led.spr
  terror_model agent_smith
  leet_model trinity
  hostage_model2 models/zombie.mdl
  hostage_model3 models/cow.mdl

  (Player models have to be here: models/player/modelname/modelname.mdl
  ex: models/player/agent_smith/agent_smith.mdl)

  addons/amx/config/player_models.ini:

  STEAMID_0:0:123456 kro_t kro_ct kro_vip
  STEAMID_0:0:456872 zombie_t zombie_ct zombie_vip
  STEAMID_0:1:741258 "" agent_smith ""
  212.52.86.124 "" captain_america "" (only on a NoSteam server)
  cdef admin_t admin_ct
  z player_t player_ct

  Format:  "SteamID|IP" "name_of_terrorist_model" "name_of_ct_model" "name_of_vip_model"
           "admin flags" "name_of_terrorist_model" "name_of_ct_model" "name_of_vip_model"

           Players must have all the flags defined in "admin flags" to get the models.
           If a player has his SteamID defined in this file, and he has also the admin flags
           of another line, he will get the models defined on the line
           containing his SteamID.
           You can use IP address instead of SteamID, but ONLY if the user in-game
           have a "STEAM_ID_LAN" (local server or CS 1.6/CZ server with dproto module using)
           or on a CS 1.5 Won server.
           Set amx_default_access to z in the amx.cfg file to set the models of players
           that are not admins.
           If you don't want to specify a model, use "".


  If you want to have different models for special maps, use the amx/config/change_models folder.
  Inside, copy-paste the change_models.ini and player_models.ini files, and add the name of the map
  to the name of the ini file (at the end): change_models_de_dust.ini, player_models_de_dust.ini for example.
  If this map is loaded, these .ini files will be used and not the .ini files from the amx/config folder.
  
  If you want to have different models for a specific kind of map, use the amx/config/change_models folder.
  Inside, copy-paste the change_models.ini and player_models.ini files, and add _prefix_ and the beginning of the name of the maps
  to the name of the ini file (at the end): change_models_prefix_de_.ini, player_models_prefix_cs_.ini for example.
  If a map of this type is loaded, these .ini files will be used and not the .ini files from the amx/config folder.


  Setup:

  Install the amx file.
  Enable VexdUM.


  Credits:

  Code to replace knife sounds from ChickenMod Rebirth by T(+)rget

*******************************************************************************/

#include <amxmod>
#include <amxmisc>
#include <VexdUM>

const MODELS_SIZE   = 48 // maximum model length (for other models, as weapons...)
const P_MODELS_SIZE = 20 // maximum model length (for player models only)
const MAX_PLAYERS   = 32 // maximum players on server (you can decrease depends on your real slots value)
const MAX_WEAPONS   = 31

new g_wpnModels[MAX_WEAPONS][3][MODELS_SIZE]

new const g_wpnModelsName[MAX_WEAPONS][] = {
  "","p228","","scout","hegrenade","xm1014","c4",
  "mac10","aug","smokegrenade","elite","fiveseven",
  "ump45","sg550","galil","famas","usp","glock18",
  "awp","mp5","m249","m3","m4a1","tmp","g3sg1",
  "flashbang","deagle","sg552","ak47","knife","p90"
}

new const g_wpnModelsNameLen[MAX_WEAPONS] = {
  0,4,0,5,9,6,2,5,3,12,5,9,5,5,5,
  5,3,7,3,3,4,2,4,3,5,9,6,5,4,5,3
}

const MAX_SHIELD_MODELS = 9
new const g_shieldModels[MAX_SHIELD_MODELS][2][MODELS_SIZE]
new const g_shieldModelsNum[MAX_WEAPONS] = {
  -1,0,-1,1,-1,-1,-1,-1,2,-1,3,-1,-1,-1,-1,-1,
  4,5,-1,-1,-1,-1,-1,-1,-1,6,7,-1,-1,8,-1
}

new shield_wmodel[MODELS_SIZE]
new kevlar_wmodel[MODELS_SIZE]
new thighpack_wmodel[MODELS_SIZE]
new bomb_wmodel[MODELS_SIZE]
new chicken_model[MODELS_SIZE]
new t_models[5][MODELS_SIZE]
new ct_models[5][MODELS_SIZE]
new vip_model[MODELS_SIZE]
new hostage_model[4][MODELS_SIZE]

new knife_deploy_soundfile[MODELS_SIZE]
new knife_slash_soundfile[MODELS_SIZE]
new knife_stab_soundfile[MODELS_SIZE]
new knife_hit_soundfile[MODELS_SIZE]
new knife_hitwall_soundfile[MODELS_SIZE]
new knife_deploy_sound[MODELS_SIZE]
new knife_slash_sound[MODELS_SIZE]
new knife_stab_sound[MODELS_SIZE]
new knife_hit_sound[MODELS_SIZE]
new knife_hitwall_sound[MODELS_SIZE]

new hostage_soundfile[7][MODELS_SIZE]
new hostage_sound[7][MODELS_SIZE]

new ledglow_spriteId = 0
new heexplosion_spriteId = 0

new g_iMaxClass

new g_cvarChangeModels

new bool:g_bChangeModelsEnabled
new bool:g_bPlayerModelsEnabled
new bool:g_bCustomPlayerModelsEnabled
new bool:g_bShieldModelsEnabled
new bool:g_bIsVIPMap

new bool:g_bIsConnected[MAX_PLAYERS+1]
#define FLAG_MODEL_HAVE   (1<<0)
#define FLAG_MODEL_ACTIVE (1<<1)
new g_iModelStatus[MAX_PLAYERS + 1]
new g_iLastPlayerTeam[MAX_PLAYERS+1]
new g_iModelClass[MAX_PLAYERS+1]

new const g_szTModel[MAX_PLAYERS+1][P_MODELS_SIZE]
new const g_szCTModel[MAX_PLAYERS+1][P_MODELS_SIZE]
new const g_szVIPModel[MAX_PLAYERS+1][P_MODELS_SIZE]

new g_szPlayerModelsFile[96]
new g_szChangeModelsFile[96]

public plugin_init() {
  register_plugin("Change Models", "1.4.4", "KRoT@L")

  g_cvarChangeModels = register_cvar("change_models", "1")

  if(g_bPlayerModelsEnabled || g_bCustomPlayerModelsEnabled) {
    register_event("ResetHUD", "eventResetHUD", "be")
  }

  if(g_bChangeModelsEnabled) {
    register_event("CurWeapon", "CurWeaponEvent", "be", "1=1")
    register_event("23", "event_tempentity", "a")

    replaceChickens()
    replaceArmoury()
    set_task(1.0, "replaceHostages")
  }

  if(g_bCustomPlayerModelsEnabled) {
    register_menucmd(register_menuid("Terrorist_Select",1),1023,"PickSkin")
    register_menucmd(register_menuid("CT_Select",1),1023,"PickSkin")
    register_clcmd("joinclass", "cmdJoinClass")
  }

  g_bIsVIPMap = bool:(find_entity(-1, "func_vip_safetyzone") > 0 || find_entity(-1, "info_vip_start") > 0)

  if(get_cvar_pointer("amxmodx_version") || is_module_running("fakemeta")) {
    server_cmd("quit") // Yeahhh! I'm feel so good!
  }
}

public plugin_precache() {
  new const szPluginDir[] = "change_models" // you can change here the specific plugin directory name

  new szConfigDir[32], szMapName[32]
  get_localinfo("amx_configdir", szConfigDir, charsmax(szConfigDir))
  new iMapNameLength = get_mapname(szMapName, charsmax(szMapName))

  if(szConfigDir[0] == 0) {
    build_path(szConfigDir, charsmax(szConfigDir), "$configdir")
  }

  // Change Models: Building of the path.
  new bool:bChangeModelsFileExists = true
  formatex(g_szChangeModelsFile, charsmax(g_szChangeModelsFile), "%s/%s/change_models_%s.ini", szConfigDir, szPluginDir, szMapName)

  if(!file_exists(g_szChangeModelsFile)) {
    new i = 0
    while(i < iMapNameLength && szMapName[i++] != '_') { }

    if(szMapName[i - 1] == '_') {
      szMapName[i] = 0
      formatex(g_szChangeModelsFile, charsmax(g_szChangeModelsFile), "%s/%s/change_models_prefix_%s.ini", szConfigDir, szPluginDir, szMapName)
      i = -1
    }

    if(i != -1 || !file_exists(g_szChangeModelsFile)) {
      formatex(g_szChangeModelsFile, charsmax(g_szChangeModelsFile), "%s/change_models.ini", szConfigDir)
      bChangeModelsFileExists = bool:file_exists(g_szChangeModelsFile)
    }
    else
      bChangeModelsFileExists = true
  }

  // Player Models: Building of the path.
  new bool:bPlayerModelsFileExists = true
  formatex(g_szPlayerModelsFile, charsmax(g_szPlayerModelsFile), "%s/%s/player_models_%s.ini", szConfigDir, szPluginDir, szMapName)

  if(!file_exists(g_szPlayerModelsFile)) {
    new i = 0
    while(i < iMapNameLength && szMapName[i++] != '_') { }

    if(szMapName[i - 1] == '_') {
      szMapName[i] = 0
      formatex(g_szPlayerModelsFile, charsmax(g_szPlayerModelsFile), "%s/%s/player_models_prefix_%s.ini", szConfigDir, szPluginDir, szMapName)
      i = -1
    }

    if(i != -1 || !file_exists(g_szPlayerModelsFile)) {
      formatex(g_szPlayerModelsFile, charsmax(g_szPlayerModelsFile), "%s/player_models.ini", szConfigDir)
      bPlayerModelsFileExists = bool:file_exists(g_szPlayerModelsFile)
    }
    else
      bPlayerModelsFileExists = true
  }

  if(bChangeModelsFileExists == true) {
    new iLine, iLength, iNum
    new szText[MODELS_SIZE+MODELS_SIZE], szOldModel[MODELS_SIZE], szNewModel[MODELS_SIZE]
    new szModel[24+MODELS_SIZE+MODELS_SIZE] = "models/player/"

    while((iLine = read_file(g_szChangeModelsFile, iLine, szText, charsmax(szText), iLength)) > 0) {
      if(iLength == 0 || szText[0] == ';' || szText[0] == '#' || szText[0] == '/') continue

      szOldModel[0] = 0
      szNewModel[0] = 0

      if(parse(szText, szOldModel, MODELS_SIZE - 1, szNewModel, MODELS_SIZE - 1) < 2) continue

      if(szOldModel[0] == 's' && szOldModel[6] == '_' && equal(szOldModel, "shield_wmodel")) {
        if(file_exists(szNewModel)) {
          copy(shield_wmodel, MODELS_SIZE - 1, szNewModel)
          precache_model(shield_wmodel)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'k' && equal(szOldModel, "kevlar_wmodel")) {
        if(file_exists(szNewModel)) {
          copy(kevlar_wmodel, MODELS_SIZE - 1, szNewModel)
          precache_model(kevlar_wmodel)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 't' && equal(szOldModel, "thighpack_wmodel")) {
        if(file_exists(szNewModel)) {
          copy(thighpack_wmodel, MODELS_SIZE - 1, szNewModel)
          precache_model(thighpack_wmodel)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'b' && equal(szOldModel, "bomb_wmodel")) {
        if(file_exists(szNewModel)) {
          copy(bomb_wmodel, MODELS_SIZE - 1, szNewModel)
          precache_model(bomb_wmodel)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'c' && equal(szOldModel, "chicken_model")) {
        if(file_exists(szNewModel)) {
          copy(chicken_model, MODELS_SIZE - 1, szNewModel)
          precache_model(chicken_model)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 't' && szOldModel[2] == 'r' && equal(szOldModel, "terror_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(t_models[0], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'l' && equal(szOldModel, "leet_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(t_models[1], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'a' && equal(szOldModel, "arctic_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(t_models[2], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'g' && szOldModel[4] == 'i' && equal(szOldModel, "guerilla_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(t_models[3], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'm' && equal(szOldModel, "militia_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(t_models[4], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'u' && equal(szOldModel, "urban_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(ct_models[0], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'g' && szOldModel[3] == '9' && equal(szOldModel, "gsg9_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(ct_models[1], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 's' && szOldModel[3] == '_' && equal(szOldModel, "sas_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(ct_models[2], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'g' && szOldModel[3] == 'n' && equal(szOldModel, "gign_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(ct_models[3], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 's' && szOldModel[3] == 't' && equal(szOldModel, "spetsnaz_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(ct_models[4], MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'v' && szOldModel[3] == '_' && equal(szOldModel, "vip_model")) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szNewModel, szNewModel)
        if(file_exists(szModel)) {
          copy(vip_model, MODELS_SIZE - 1, szNewModel)
          precache_model(szModel)
          g_bChangeModelsEnabled = true
          g_bCustomPlayerModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'h' && szOldModel[8] == 'm' && equal(szOldModel, "hostage_model", 13)) {
        if(szNewModel[4] && file_exists(szNewModel)) {
          szOldModel[14] = 0
          iNum = strtonum(szOldModel[13])
          if(iNum >= 1 && iNum <= 4) {
            copy(hostage_model[iNum-1], MODELS_SIZE - 1, szNewModel)
            precache_model(hostage_model[iNum-1])
            g_bChangeModelsEnabled = true
          }
        }
      }
      else if(szOldModel[0] == 'k' && szOldModel[9] == 'l' && equal(szOldModel, "knife_deploy_sound")) {
        if(file_exists(szNewModel)) {
          copy(knife_deploy_soundfile, MODELS_SIZE - 1, szNewModel)
          copy(knife_deploy_sound, MODELS_SIZE - 1, szNewModel)
          precache_sound(knife_deploy_sound[6])
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'k' && szOldModel[9] == 's' && equal(szOldModel, "knife_slash_sound")) {
        if(file_exists(szNewModel)) {
          copy(knife_slash_soundfile, MODELS_SIZE - 1, szNewModel)
          copy(knife_slash_sound, MODELS_SIZE - 1, szNewModel)
          precache_sound(knife_slash_sound[6])
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'k' && szOldModel[9] == 'b' && equal(szOldModel, "knife_stab_sound")) {
        if(file_exists(szNewModel)) {
          copy(knife_stab_soundfile, MODELS_SIZE - 1, szNewModel)
          copy(knife_stab_sound, MODELS_SIZE - 1, szNewModel)
          precache_sound(knife_stab_sound[6])
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'k' && szOldModel[9] == '_' && equal(szOldModel, "knife_hit_sound")) {
        if(file_exists(szNewModel)) {
          copy(knife_hit_soundfile, MODELS_SIZE - 1, szNewModel)
          copy(knife_hit_sound, MODELS_SIZE - 1, szNewModel)
          precache_sound(knife_hit_sound[6])
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'k' && szOldModel[9] == 'w' && equal(szOldModel, "knife_hitwall_sound")) {
        if(file_exists(szNewModel)) {
          copy(knife_hitwall_soundfile, MODELS_SIZE - 1, szNewModel)
          copy(knife_hitwall_sound, MODELS_SIZE - 1, szNewModel)
          precache_sound(knife_hitwall_sound[6])
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'h' && szOldModel[8] == 's' && equal(szOldModel, "hostage_sound", 13)) {
        if(file_exists(szNewModel)) {
          szOldModel[14] = '^0'
          iNum = strtonum(szOldModel[13])
          if(iNum >= 1 && iNum <= 7) {
            copy(hostage_soundfile[iNum-1], MODELS_SIZE - 1, szNewModel)
            copy(hostage_sound[iNum-1], MODELS_SIZE - 1, szNewModel)
            precache_sound(hostage_sound[iNum-1][6])
            g_bChangeModelsEnabled = true
          }
        }
      }
      else if(szOldModel[0] == 'l' && equal(szOldModel, "ledglow_sprite")) {
        if(file_exists(szNewModel)) {
          ledglow_spriteId = precache_model(szNewModel)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 'h' && szOldModel[2] == 'e' && equal(szOldModel, "heexplosion_sprite")) {
        if(file_exists(szNewModel)) {
          heexplosion_spriteId = precache_model(szNewModel)
          g_bChangeModelsEnabled = true
        }
      }
      else if(szOldModel[0] == 's' && szOldModel[5] == 'd' && equal(szOldModel, "shield_", 7)) {
        for(new i = 1; i < MAX_WEAPONS; i++) {
          if(equal(szOldModel[7], g_wpnModelsName[i], g_wpnModelsNameLen[i])) {
            if(!file_exists(szNewModel)) {
              break
            }
            switch(szOldModel[7+g_wpnModelsNameLen[i]+1]) {
              case 'v': {
                iNum = g_shieldModelsNum[i]
                if(iNum >= 0) {
                  copy(g_shieldModels[iNum][0], MODELS_SIZE - 1, szNewModel)
                  precache_model(szNewModel)
                  g_bChangeModelsEnabled = true
                  g_bShieldModelsEnabled = true
                }
              }
              case 'p': {
                iNum = g_shieldModelsNum[i]
                if(iNum >= 0) {
                  copy(g_shieldModels[iNum][1], MODELS_SIZE - 1, szNewModel)
                  precache_model(szNewModel)
                  g_bChangeModelsEnabled = true
                  g_bShieldModelsEnabled = true
                }
              }
            }
            break
          }
        }
      }
      else {
        for(new i = 1; i < MAX_WEAPONS; i++) {
          if(equal(szOldModel, g_wpnModelsName[i], g_wpnModelsNameLen[i])) {
            if(!file_exists(szNewModel)) {
              break
            }
            switch(szOldModel[g_wpnModelsNameLen[i]+1]) {
              case 'v': {
                copy(g_wpnModels[i][0], MODELS_SIZE - 1, szNewModel)
                precache_model(szNewModel)
                g_bChangeModelsEnabled = true
              }
              case 'p': {
                copy(g_wpnModels[i][1], MODELS_SIZE - 1, szNewModel)
                precache_model(szNewModel)
                g_bChangeModelsEnabled = true
              }
              case 'w': {
                copy(g_wpnModels[i][2], MODELS_SIZE - 1, szNewModel)
                precache_model(szNewModel)
                g_bChangeModelsEnabled = true
              }
            }
            break
          }
        }
      }
    }

    if(g_bCustomPlayerModelsEnabled == true) {
      g_iMaxClass = is_running("czero") ? 4 : 3
    }
  }

  if(bPlayerModelsFileExists == true) {
    new iLine, iLength
    new szText[24+P_MODELS_SIZE+P_MODELS_SIZE+P_MODELS_SIZE]
    new szAuthIdIPInFile[24], szTModel[P_MODELS_SIZE], szCTModel[P_MODELS_SIZE], szVIPModel[P_MODELS_SIZE]
    new szModel[24+P_MODELS_SIZE+P_MODELS_SIZE] = "models/player/"

    while((iLine = read_file(g_szPlayerModelsFile, iLine, szText, charsmax(szText), iLength)) > 0) {
      if(iLength == 0 || szText[0] == ';' || szText[0] == '#' || szText[0] == '/') continue
      if(parse(szText, szAuthIdIPInFile, charsmax(szAuthIdIPInFile), szTModel, P_MODELS_SIZE - 1, szCTModel, P_MODELS_SIZE - 1, szVIPModel, P_MODELS_SIZE - 1) < 2) continue

      if(szTModel[0] != ' ') {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szTModel, szTModel)
        if(file_exists(szModel)) {
          g_bPlayerModelsEnabled = true
          precache_model(szModel)
        }
      }

      if(szCTModel[0] && szCTModel[0] != ' ') {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szCTModel, szCTModel)
        if(file_exists(szModel)) {
          g_bPlayerModelsEnabled = true
          precache_model(szModel)
        }
      }

      if(szVIPModel[0] && szVIPModel[0] != ' ') {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szVIPModel, szVIPModel)
        if(file_exists(szModel)) {
          g_bPlayerModelsEnabled = true
          precache_model(szModel)
        }
      }
    }
  }
}

bool:g_bIsDigit(const szChar) {
  static const szCharsList[] = "0123456789"
  const iCharsLength = 10
  for(new i = 0; i < iCharsLength; i++) {
    if(szChar == szCharsList[i])
      return true
  }
  return false
}

bool:g_bIsValidFlags(const szText[], const iLength) {
  for(new i = 0; i < iLength; i++) {
    if(g_bIsDigit(szText[i]))
      return false  
  }
  return true
}

bool:g_bIsSteamIDOrBot(const szChar1, const szChar2, const szChar3) {
  return bool:( (szChar1 == 's' || szChar1 == 'S') && szChar2 == '_'
  || (szChar1 == 'b' || szChar1 == 'B') && (szChar3 == 't' || szChar3 == 'T') )
}

bool:g_bIsStrNum(const szString[]) {
  new i = 0
  while(szString[i] && g_bIsDigit(szString[i])) {
    ++i
  }
  return (szString[i] == 0 && i != 0)
}

public client_putinserver(id) {
  g_bIsConnected[id] = true

  if(g_bPlayerModelsEnabled == false)
    return

  if(file_exists(g_szPlayerModelsFile)) {
    new szAuthIDIP[24]
    get_user_authid(id, szAuthIDIP, charsmax(szAuthIDIP))

    if(szAuthIDIP[6] == 'I' && equal(szAuthIDIP[6], "ID_LAN")
    || szAuthIDIP[0] != 'S' && szAuthIDIP[0] != 'V' && g_bIsStrNum(szAuthIDIP)) {
      get_user_ip(id, szAuthIDIP, charsmax(szAuthIDIP), 1)
    }

    new iUserFlags = get_user_flags(id)

    new bool:bAuthIdFound = false, iFlagFound = -1, iFlags
    new iLine, iLength
    static szText[sizeof(szAuthIDIP)+P_MODELS_SIZE+P_MODELS_SIZE+P_MODELS_SIZE]
    static szAuthIDIPInFile[sizeof(szAuthIDIP)], szTModel[P_MODELS_SIZE], szCTModel[P_MODELS_SIZE], szVIPModel[P_MODELS_SIZE]
    static szModel[24+P_MODELS_SIZE+P_MODELS_SIZE] = "models/player/"

    while((iLine = read_file(g_szPlayerModelsFile, iLine, szText, charsmax(szText), iLength)) > 0) {
      if(iLength == 0 || szText[0] == ';' || szText[0] == '#' || szText[0] == '/') continue

      szAuthIDIPInFile[0] = 0
      szTModel[0] = 0
      szCTModel[0] = 0
      szVIPModel[0] = 0

      if(parse(szText, szAuthIDIPInFile, charsmax(szAuthIDIPInFile), szTModel, P_MODELS_SIZE - 1, szCTModel, P_MODELS_SIZE - 1, szVIPModel, P_MODELS_SIZE - 1) < 2) continue

      if(equali(szAuthIDIP, szAuthIDIPInFile)) {
        bAuthIdFound = true
        break
      }
      else if(g_bIsSteamIDOrBot(szAuthIDIPInFile[0], szAuthIDIPInFile[5], szAuthIDIPInFile[2]) == false
      && g_bIsValidFlags(szAuthIDIPInFile, strlen(szAuthIDIPInFile))) {
        iFlags = read_flags(szAuthIDIPInFile)
        if((iUserFlags & iFlags) == iFlags) {
          iFlagFound = iLine - 1
        }
      }
    }

    if(bAuthIdFound == true || iFlagFound != -1) {
      if(bAuthIdFound == false) {
        read_file(g_szPlayerModelsFile, iFlagFound, szText, charsmax(szText), iLength)
        parse(szText, szAuthIDIPInFile, charsmax(szAuthIDIPInFile), szTModel, P_MODELS_SIZE - 1, szCTModel, P_MODELS_SIZE - 1, szVIPModel, P_MODELS_SIZE - 1)
      }

      if(szTModel[0]) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szTModel, szTModel)
        if(file_exists(szModel)) {
          g_szTModel[id] = szTModel
        }
      }

      if(szCTModel[0]) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szCTModel, szCTModel)
        if(file_exists(szModel)) {
          g_szCTModel[id] = szCTModel
        }
      }

      if(szVIPModel[0]) {
        formatex(szModel[14], charsmax(szModel) - 14, "%s/%s.mdl", szVIPModel, szVIPModel)
        if(file_exists(szModel)) {
          g_szVIPModel[id] = szVIPModel
        }
      }
    }
  }

  g_iModelStatus[id] = (g_szTModel[id][0] || g_szCTModel[id][0] || g_szVIPModel[id][0]) ? FLAG_MODEL_HAVE : 0
  g_iLastPlayerTeam[id] = 0
}

public client_disconnect(id) {
  g_bIsConnected[id] = false

  if(g_bPlayerModelsEnabled == false)
    return

  g_iModelStatus[id] = 0
  g_iLastPlayerTeam[id] = 0

  g_szTModel[id][0] = 0
  g_szCTModel[id][0] = 0
  g_szVIPModel[id][0] = 0
}

public PickSkin(id, iKey) {
  g_iModelClass[id] = (0 <= iKey <= g_iMaxClass) ? iKey : random_num(0, g_iMaxClass)
}

public cmdJoinClass(id) {
  new szArg[2]
  read_argv(1, szArg, charsmax(szArg))
  new iArg = str_to_num(szArg)

  if(iArg > 0) {
    PickSkin(id, iArg - 1)
  }
}

public eventResetHUD(id) {
  if(g_iModelStatus[id] & FLAG_MODEL_HAVE || g_bCustomPlayerModelsEnabled == true) {
    if(get_cvarptr_num(g_cvarChangeModels) > 0) {
      g_iModelStatus[id] |= FLAG_MODEL_ACTIVE
      set_task(0.1, "ResetHUDDelayed", id)
    }
    else if(g_iModelStatus[id] & FLAG_MODEL_ACTIVE) {
      g_iModelStatus[id] &= ~FLAG_MODEL_ACTIVE
      g_iLastPlayerTeam[id] = 0
      set_user_model(id)
    }
  }
}

public ResetHUDDelayed(id) {
  if(!g_bIsConnected[id])
    return

  const OFFSET_TEAM = 114
  const CS_TEAM_T   = 1
  const CS_TEAM_CT  = 2

  const OFFSET_VIP    = 209
  const PLAYER_IS_VIP = (1<<8)

  new iTeam = get_offset_int(id, OFFSET_TEAM)

  if(!(CS_TEAM_T <= iTeam <= CS_TEAM_CT))
    return

  if(g_iModelStatus[id] & FLAG_MODEL_HAVE) {
    new iLastPlayerTeam = g_iLastPlayerTeam[id]

    if(iTeam == CS_TEAM_T) {
      if(iLastPlayerTeam != iTeam) {
        if(g_szTModel[id][0]) {
          set_user_model(id, g_szTModel[id])
        }
        else if(iLastPlayerTeam > 0) {
          set_user_model(id, "")
        }
        g_iLastPlayerTeam[id] = iTeam
      }
    }
    else {
      if(g_bIsVIPMap == true) {
        if(get_offset_int(id, OFFSET_VIP) & PLAYER_IS_VIP) {
          if(g_szVIPModel[id][0]) {
            set_user_model(id, g_szVIPModel[id])
          }
        }
        else {
          set_user_model(id, g_szCTModel[id][0] ? g_szCTModel[id] : "")
        }
        g_iLastPlayerTeam[id] = iTeam
      }
      else {
        if(iLastPlayerTeam != iTeam) {
          if(g_szCTModel[id][0]) {
            set_user_model(id, g_szCTModel[id])
          }
          else if(iLastPlayerTeam > 0) {
            set_user_model(id, "")
          }
          g_iLastPlayerTeam[id] = iTeam
        }
      }
    }
  }
  else {
    if(g_bIsVIPMap == true && get_offset_int(id, OFFSET_VIP) & PLAYER_IS_VIP) {
      if(vip_model[0]) {
        set_user_model(id, vip_model)
      }
      return
    }

    if(iTeam == CS_TEAM_T) {
      set_user_model(id, t_models[g_iModelClass[id]][0] ? t_models[g_iModelClass[id]] : "")
    }
    else {
      set_user_model(id, ct_models[g_iModelClass[id]][0] ? ct_models[g_iModelClass[id]] : "")
    }
  }
}

public CurWeaponEvent(id) {
  if(get_cvarptr_num(g_cvarChangeModels) <= 0)
    return

  new iWeaponID = read_data(2)
  const OFFSET_SHIELD = 510
  const HAS_SHIELD    = (1<<24)

  if(g_bShieldModelsEnabled == true && get_offset_int(id, OFFSET_SHIELD) & HAS_SHIELD) {
    new num = g_shieldModelsNum[iWeaponID]
    if(num >= 0) {
      if(g_shieldModels[num][0][0]) {
        entity_set_string(id, EV_SZ_viewmodel, g_shieldModels[num][0])
      }
      if(g_shieldModels[num][1][0]) {
        entity_set_string(id, EV_SZ_weaponmodel, g_shieldModels[num][1])
      }
    }
  }
  else {
    if(g_wpnModels[iWeaponID][0][0]) {
      entity_set_string(id, EV_SZ_viewmodel, g_wpnModels[iWeaponID][0])
    }
    if(g_wpnModels[iWeaponID][1][0]) {
      entity_set_string(id, EV_SZ_weaponmodel, g_wpnModels[iWeaponID][1])
    }
  }
}

public set_model(entity, const model[]) {
  if(g_bChangeModelsEnabled == false || get_cvarptr_num(g_cvarChangeModels) <= 0)
    return PLUGIN_CONTINUE

  static const szStartModel[] = "models/w_"

  if(equal(model, szStartModel, 9)) {
    if(equal(model[9], "shield.mdl")) {
      if(shield_wmodel[0]) {
        entity_set_model(entity, shield_wmodel)
        return PLUGIN_HANDLED
      }
    }
    else if(equal(model[9], "kevlar.mdl")) {
      if(kevlar_wmodel[0])  {
        entity_set_model(entity, kevlar_wmodel)
        return PLUGIN_HANDLED
      }
    }
    else if(equal(model[9], "thighpack.mdl")) {
      if(thighpack_wmodel[0]) {
        entity_set_model(entity, thighpack_wmodel)
        return PLUGIN_HANDLED
      }
    }
    else if(equal(model[9], "backpack.mdl")) {
      if(bomb_wmodel[0]) {
        entity_set_model(entity, bomb_wmodel)
        return PLUGIN_HANDLED
      }
    }
    else {
      for(new i = 1; i < MAX_WEAPONS; i++) {
        if(equal(model[9], g_wpnModelsName[i], g_wpnModelsNameLen[i])) {
          if(g_wpnModels[i][2][0]) {
            entity_set_model(entity, g_wpnModels[i][2])
            return PLUGIN_HANDLED
          }
          break
        }
      }
    }
  }
  return PLUGIN_CONTINUE
}

public emitsound(entity, const sample[]) {
  if(g_bChangeModelsEnabled == false || get_cvarptr_num(g_cvarChangeModels) <= 0)
    return PLUGIN_CONTINUE

  if(sample[0] == 'c' && sample[10] == '_' && equal(sample[11], "denyselect.wav")) {
    return PLUGIN_HANDLED
  }

  if(sample[0] == 'w' && sample[1] == 'e' && sample[8] == 'k' && sample[9] == 'n') { //weapon_knife
    if(sample[14] == 'd') { //deploy
      if(knife_deploy_soundfile[0]) {
        emit_sound(entity, CHAN_WEAPON, knife_deploy_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
        return PLUGIN_HANDLED
      }
      return PLUGIN_CONTINUE
    }
    switch(sample[15]) {
      case 'l': { //slash
        if(knife_slash_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_slash_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
      case 't': { //stab
        if(knife_stab_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_stab_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
    }
    switch(sample[17]) {
      case '1': { //hit1
        if(knife_hit_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_hit_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
      case '2': { //hit2
        if(knife_hit_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_hit_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
      case '3': { //hit3
        if(knife_hit_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_hit_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
      case '4': { //hit4
        if(knife_hit_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_hit_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
      case 'w': { //hitwall
        if(knife_hitwall_soundfile[0]) {
          emit_sound(entity, CHAN_WEAPON, knife_hitwall_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
          return PLUGIN_HANDLED
        }
        return PLUGIN_CONTINUE
      }
    }
  }
  if(sample[0] == 'h' && sample[8] == 'h' && equal(sample, "hostage/hos", 11) && equal(sample[12], ".wav")) {
    switch(sample[11]) {
      case '1': emit_sound(entity, CHAN_VOICE, hostage_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
      case '2': emit_sound(entity, CHAN_VOICE, hostage_sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
      case '3': emit_sound(entity, CHAN_VOICE, hostage_sound[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
      case '4': emit_sound(entity, CHAN_VOICE, hostage_sound[3], 1.0, ATTN_NORM, 0, PITCH_NORM)
      case '5': emit_sound(entity, CHAN_VOICE, hostage_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
      case '6': emit_sound(entity, CHAN_VOICE, hostage_sound[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
      case '7': emit_sound(entity, CHAN_VOICE, hostage_sound[6], 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
    return PLUGIN_HANDLED
  }
  return PLUGIN_CONTINUE
}

bool:bombIsPlanted() {
  new c4 = find_entity(-1, "grenade")
  new model[32]
  while(c4 > 0) {
    entity_get_string(c4, EV_SZ_model, model, charsmax(model))
    if(equal(model, "models/w_c4.mdl"))
      return true
    c4 = find_entity(c4, "grenade")
  }
  return false
}

public event_tempentity() {
  new data = read_data(1)
  if(data == SVC_EVENT) {
    if(heexplosion_spriteId) {
      new origin[3]
      origin[0] = read_data(2)
      origin[1] = read_data(3)
      origin[2] = read_data(4)
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
      write_byte(3)
      write_coord(origin[0])
      write_coord(origin[1])
      write_coord(origin[2])
      write_short(heexplosion_spriteId)
      write_byte(read_data(6))
      write_byte(read_data(7))
      write_byte(read_data(8))
      message_end()
    }
  }
  else if(data == SVC_TEMPENTITY && bombIsPlanted()) {
    if(ledglow_spriteId) {
      new origin[3]
      origin[0] = read_data(2)
      origin[1] = read_data(3)
      origin[2] = read_data(4)
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
      write_byte(SVC_TEMPENTITY)
      write_coord(origin[0])
      write_coord(origin[1])
      write_coord(origin[2])
      write_short(ledglow_spriteId)
      write_byte(read_data(6))
      write_byte(read_data(7))
      write_byte(read_data(8))
      message_end()
    }
  }
}

replaceChickens() {
  if(chicken_model[0]) {
    new chicken = find_entity(-1, "cycler_sprite")
    new model[32]
    while(chicken > 0) {
      entity_get_string(chicken, EV_SZ_model, model, charsmax(model))
      if(equal(model, "models/chick.mdl")) {
        entity_set_model(chicken, chicken_model)
      }
      chicken = find_entity(chicken, "cycler_sprite")
    }
  }
}

replaceArmoury() {
  new ent = find_entity(-1, "armoury_entity")
  new model[32]
  while(ent > 0) {
    entity_get_string(ent, EV_SZ_model, model, charsmax(model))
    set_model(ent, model)
    ent = find_entity(ent, "armoury_entity")
  }
}

public replaceHostages() {
  new i = 0
  while(!hostage_model[i++][0]) {
    if(i == 4) return
  }
  i = 0
  new ent = find_entity(-1, "hostage_entity")
  while(ent > 0) {
    while(!hostage_model[i++][0]) {
      if(i == 4) i = 0
    }
    //DispatchKeyValue(ent, "model", hostage_model[i-1])
    //DispatchSpawn(ent)
    entity_set_model(ent, hostage_model[i-1])
    ent = find_entity(ent, "hostage_entity")
    if(i == 4) i = 0
  }
}
