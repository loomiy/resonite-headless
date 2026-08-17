#!/bin/sh

BETAPASSWORDPARAM=""
if [ -n "${STEAMBETAPASSWORD}" ]; then
	BETAPASSWORDPARAM="-betapassword ${STEAMBETAPASSWORD}"
fi

# RML Setup
mkdir -p ${STEAMAPPDIR}/Libraries ${STEAMAPPDIR}/rml_config ${STEAMAPPDIR}/rml_libs ${STEAMAPPDIR}/rml_mods

if [ "$RML_VERSION" = "latest" ]; then
    RML_URL="https://github.com/resonite-modding-group/ResoniteModLoader/releases/latest/download"
else
    RML_URL="https://github.com/resonite-modding-group/ResoniteModLoader/releases/download/${RML_VERSION}"
fi

curl -L -o "${STEAMAPPDIR}/Libraries/ResoniteModLoader.dll" "${RML_URL}/ResoniteModLoader.dll"
curl -L -o "${STEAMAPPDIR}/rml_libs/0Harmony.dll" "${RML_URL}/0Harmony.dll"

bash "${STEAMCMDDIR}/steamcmd.sh" \
	+@sSteamCmdForcePlatformType windows \
	+force_install_dir ${STEAMAPPDIR} \
	+login ${STEAMLOGIN} \
	+app_license_request ${STEAMAPPID} \
	+app_update ${STEAMAPPID} -beta ${STEAMBETA} ${BETAPASSWORDPARAM} validate \
	+quit

chmod +x ${STEAMAPPDIR}/dotnet-install.sh
${STEAMAPPDIR}/dotnet-install.sh --channel ${DOTNETVERSION} --runtime dotnet --install-dir ${STEAMAPPDIR}/dotnet-runtime

find ${STEAMAPPDIR}/Data/Assets -type f -atime +7 -delete
find ${STEAMAPPDIR}/Data/Cache -type f -atime +7 -delete
find /Logs -type f -name *.log -atime +30 -delete
mkdir -p Headless/Migrations
exec $*
