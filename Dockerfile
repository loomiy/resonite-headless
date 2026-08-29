# rusty-reso-ws-tty build
FROM rust:latest AS rust-builder

RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev git && \
    rm -rf /var/lib/apt/lists/*

RUN cargo install --git https://gitlab.peacefulbeast.eu/TomTam/rusty-reso-ws-tty --root /build

FROM mcr.microsoft.com/dotnet/runtime:10.0

LABEL	name=resonite-headless org.opencontainers.image.authors="panther.ru@gmail.com"

ENV	STEAMAPPID=2519830 \
	STEAMAPP=resonite \
	STEAMCMDURL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
	STEAMCMDDIR=/opt/steamcmd \
	STEAMBETA=__CHANGEME__ \
	STEAMBETAPASSWORD=__CHANGEME__ \
	STEAMLOGIN=__CHANGEME__ \
	DOTNETVERSION="10.0" \
	USER=2000 \
	HOMEDIR=/home/steam \
	RML_VERSION=latest \
	RML=true
ENV	STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-headless"

# Prepare the basic environment
RUN	set -x && \
	apt -y update && \
	apt -y upgrade && \
	apt -y install btop curl libfreetype6 libfreetype6 lib32gcc-s1 libopus-dev libopus0 opus-tools && \
	rm -rf /var/lib/{apt,dpkg,cache}

# Copy rusty-reso-ws-tty 
COPY --from=rust-builder /build/bin/rusty-websocket-tty /usr/local/bin/rusty-websocket-tty
RUN chmod 755 /usr/local/bin/rusty-websocket-tty

# Add locales
RUN	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
	sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
	sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=en_US.UTF-8 && \
	update-locale LANG=en_GB.UTF-8 && \
	rm -rf /var/lib/{apt,dpkg,cache}
ENV	LANG=en_GB.UTF-8

# Fix the LetsEncrypt CA cert (is this still needed?)
#RUN	sed -i 's#mozilla/DST_Root_CA_X3.crt#!mozilla/DST_Root_CA_X3.crt#' /etc/ca-certificates.conf && update-ca-certificates

# Create user, install SteamCMD
RUN	groupadd --gid ${USER} steam && \
	useradd --home-dir ${HOMEDIR} \
		--create-home \
		--shell /bin/bash \
		--comment "" \
		--gid ${USER} \
		--uid ${USER} \
		steam && \
	mkdir -p ${STEAMCMDDIR} ${STEAMAPPDIR} /Config /Logs /Scripts && \
	cd ${STEAMCMDDIR} && \
	curl -sqL ${STEAMCMDURL} | tar zxfv - && \
	chown -R ${USER}:${USER} ${STEAMCMDDIR} ${STEAMAPPDIR} /Config /Logs

COPY	--chown=${USER}:${USER} --chmod=755 ./src/setup_resonite.sh ./src/start_resonite.sh /Scripts/

# Switch to user
USER	${USER}

WORKDIR	${STEAMAPPDIR}

VOLUME ["${STEAMAPPDIR}", "/Config", "/Logs"]

STOPSIGNAL SIGINT

ENTRYPOINT ["/Scripts/setup_resonite.sh"]
CMD ["/Scripts/start_resonite.sh"]
