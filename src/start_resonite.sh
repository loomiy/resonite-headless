#!/bin/sh

if [ -f ${STEAMAPPDIR}/Headless/Resonite.dll ]; then
    echo 'Resonite.dll is in the new (permanent) location, running...'

    RML_ARGS=""
    if [ "$RML" = "true" ]; then
        RML_ARGS="-LoadAssembly Libraries/ResoniteModLoader.dll"
    fi

    exec ${STEAMAPPDIR}/dotnet-runtime/dotnet ${STEAMAPPDIR}/Headless/Resonite.dll -HeadlessConfig /Config/Config.json -Logs /Logs ${RML_ARGS}
else
    echo 'Resonite.dll not found, weird!'
    sleep 10
fi

