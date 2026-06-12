#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new const szUpperTag[]  = "\rTAG\d -";
new const szChatTag[] = "^4TAG:";

#define iMaxSkin  30   // Kac adet skin varsa "+1" fazlası. !! Aksi takdirde hata çıkarabilir.

new const g_szSkinsFile[] = "addons/amxmodx/configs/Skins.ini";   // Skin verilerinin kayıt yolu. * The storage location of the skin data.

enum _:SkinData
{
	szSkinName[32],
	szSkinFile[64],
	szSkinWeaponCode[32]
};
new Array:g_aSkin;
	
new	bool:g_blActiveSkin[MAX_PLAYERS+1][iMaxSkin];

public plugin_init()
{
	register_plugin("Weapon Skin Menu", "0.1", "` BesTCore;");

	register_clcmd("say /skin", "clcmd_skins", ADMIN_KICK);
	register_clcmd("nightvision", "clcmd_skins", ADMIN_KICK);

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "RG_CBasePlayerWeapon_DefaultDeploy_Pre", .post = false);
}
public clcmd_skins(const id)
{
	new bestm = menu_create(fmt("%s Skin Menu", szUpperTag), "clcmd_skins_handler"), iSize = ArraySize(g_aSkin), aData[SkinData];

	for(new i = 0; i < iSize; i++)
	{
		ArrayGetArray(g_aSkin, i, aData);
		menu_additem(bestm, fmt("%s%s", aData[szSkinName], g_blActiveSkin[id][i] ? " \d[\yAKTIF\d]":""), fmt("%d", i));
	}
	menu_setprop(bestm, MPROP_EXITNAME, "\rCikis");
	menu_display(id, bestm);
}
public clcmd_skins_handler(const id, const iMenu, const iItem)
{
	if(iItem != MENU_EXIT)
	{
		SkinActivated(id, iItem);
	}

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}
// Skin activation function.
SkinActivated(const id, const iValue)
{
	g_blActiveSkin[id][iValue] = true;

	new aDataPlayer[SkinData];

	ArrayGetArray(g_aSkin, iValue, aDataPlayer);

	replace_string(aDataPlayer[szSkinName], charsmax(aDataPlayer), "\r", "");   // Remove spaces.
	replace_string(aDataPlayer[szSkinName], charsmax(aDataPlayer), "\w", "");
	replace_string(aDataPlayer[szSkinName], charsmax(aDataPlayer), "\d", "");
	replace_string(aDataPlayer[szSkinName], charsmax(aDataPlayer), "\y", "");

	client_print_color(id, id, "%s ^3Basarili bir sekilde^4 %s ^3adli skini kullanmaya basladiniz.", szChatTag, aDataPlayer[szSkinName]);

	new aData[SkinData], iSize = ArraySize(g_aSkin);

	for(new i = 0; i < iSize; i++)
	{
		ArrayGetArray(g_aSkin, i, aData);

		if(equal(aData[szSkinWeaponCode], aDataPlayer[szSkinWeaponCode]) && i != iValue)   // Remove other skins from the weapon.
		{
			g_blActiveSkin[id][i] = false;
		}
	}
}
public RG_CBasePlayerWeapon_DefaultDeploy_Pre(const iWeapon, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
	new id = get_member(iWeapon, m_pPlayer);

	new iSize = ArraySize(g_aSkin), aData[SkinData], iWeaponIdType = get_member(iWeapon, m_iId);

	for(new i = 0; i < iSize; i++)
	{
		ArrayGetArray(g_aSkin, i, aData);

		if(iWeaponIdType != get_weaponid(aData[szSkinWeaponCode]))   // If the weapon does not match the code, skip it.
		{
			continue;
		}
		if(g_blActiveSkin[id][i] == false)   // If the player doesn't have the skin, skip it.
		{
			continue;
		}

		SetHookChainArg(2, ATYPE_STRING, aData[szSkinFile]);   // Add your skin.
	}
}
public plugin_precache()
{
	g_aSkin = ArrayCreate(SkinData);

	new iFile = fopen(g_szSkinsFile, "rt");

	if(iFile)
	{
		new szBuffer[MAX_FMT_LENGTH],
			pSkinName[32], pSkinFile[64], pSkinWeaponCode[32], aData[SkinData];

		while(fgets(iFile, szBuffer, charsmax(szBuffer)))
		{
			trim(szBuffer);

			if(szBuffer[0] == EOS || szBuffer[0] == ';')
			{
				continue;
			}

			parse(szBuffer, pSkinName, charsmax(pSkinName), pSkinFile, charsmax(pSkinFile), pSkinWeaponCode, charsmax(pSkinWeaponCode));

			copy(aData[szSkinName], charsmax(aData), pSkinName);
			copy(aData[szSkinFile], charsmax(aData), pSkinFile);
			copy(aData[szSkinWeaponCode], charsmax(aData), pSkinWeaponCode);

			ArrayPushArray(g_aSkin, aData);

			precache_model(fmt("%s", pSkinFile));
		}
		fclose(iFile);
	}
}
public plugin_end()
{
	ArrayDestroy(g_aSkin);
}