# Farming Simulator 25 Docker Server

Dedicated Farming Simulator 25 server running inside a docker image based on ArchLinux. 
This project is hosted at https://github.com/wine-gameservers/arch-fs25server/

## Table of contents
<!-- vim-markdown-toc GFM -->
* [Motivation](#motivation)
* [Getting Started](#getting-started)
	* [Hardware Requirements](#hardware-requirements)
	* [Software Requirements](#software-requirements)
		* [Linux Distribution](#linux-distribution)
		* [Server License](#server-license)
		* [VNC Client](#vnc-client)
* [Deployment](#deployment)
	* [Deploying with docker-compose](#docker-compose)
	* [Deploying with docker run](#docker-run)
* [Installation](#installation)
	* [Initial installation](#initial-installation)
		* [Downloading the dedicated server](#downloading-the-dedicated-server)
		* [Preparing the needed directories on the host machine](#preparing-the-needed-directories-on-the-host-machine)
		* [Unpack and move the installer](#unpack-and-move-the-installer)
		* [Starting the container](#starting-the-container)
		* [Connecting to the VNC Server](#connecting-to-the-vnc-Server)
	* [Server Installation](#server-installation)
		* [Running the installation](#running-the-installation)
		* [Starting the admin portal](#starting-the-admin-portal)
* [Environment variables](#environment-variables)
<!-- vim-markdown-toc -->

# Motivation

GIANTS Software encourages its customers to consider renting a server from one of their verified partners, as it helps protect their business and maintain close relationships with these partners. Unfortunately, they do not allow third parties to host servers in order to support their partner network effectively.

For customers who prefer running personal servers, there is a requirement to purchase all the game content (game, DLC, packs) twice. This means obtaining one license for the player and another license specifically for the server.

While renting a server remains a viable option for certain players, it has become increasingly common for game developers to provide free-to-use server tools. Regrettably, the server tools provided by GIANTS Software are considered outdated and inefficient. As a result, users are compelled to set up an entire Windows environment. However, with our project, we have overcome this limitation by enabling users to deploy servers within a lightweight Docker environment, eliminating the need for a Windows setup.

# Getting Started

Please note that this may not cover every possible scenario, particularly for NAS (synology) users. In such cases, you may need to utilize the provided admin console to configure the necessary directories and user permissions. If you encounter any issues while attempting to run the program, kindly refrain from sending me private messages. Instead, we recommend seeking assistance on our Discord server, where you can find additional support and guidance. [invite link to our Discord server](https://discord.gg/Ejz2MaXSNb). 

## Hardware Requirements

Intel: Haswell or newer (Intel Celeron specially from older generations are not recommended)
AMD: Zen1 or newer

- Server for 2-4 players (without DLCs) 2.4 GHz (min. 3 Cores), 4 GB RAM
- Server for 5-10 players (with DLCs) 2.8 GHz (min. 3 Cores), 8 GB RAM
- Server for up to 16 players (with all DLCs) 3.2 GHz (min. 4 Cores), 12 GB RAM

*** Storage depends on installed dlc + mods ***

## Software Requirements

### Linux Distribution

To install Docker and Docker Compose, please consult the documentation specific to your Linux distribution. It's important to note that the provided image is intended for operating systems that support Docker and utilize the x86_64 / amd64 architecture. Unfortunately, arm/apple architectures are not supported.

### Server License

GIANTS Software provides a dedicated server tool with the game, which means that in order to run a server, you will need to purchase an additional license from GIANTS. It is not possible to host and play on the same server using a single license. Therefore, you will need to buy everything twice in order to both run the server and play on it.

Please note that the Steam version of the game is not supported for running as a server inside a Docker environment. However, you can use the Steam version to play on the server.

To obtain the full game and all DLCs, we recommend purchasing the Farming Simulator 25 - Year 1 Bundle. This edition provides access to all the content, and it is the most cost-effective option to unlock all the game's features. Please be cautious about other versions available, as this edition ensures the inclusion of all the content you need.

- [Farming Simulator 25 - Year 1 Bundle](https://www.farming-simulator.com/buy-now.php?lang=en&country=us&platform=pcdigital)

## Deployment

The primary distinction between `docker run` and `docker-compose` is that `docker run` relies solely on command-line instructions, whereas `docker-compose` reads configuration data from a YAML file. If you are unsure about which option to choose, I recommend opting for `docker-compose`. It provides a more organized and manageable approach to container deployment by utilizing a YAML file to define and configure multiple containers and their dependencies.

### Docker compose
```
services:
  arch-fs25server:
    image: toetje585/arch-fs25server:latest
    container_name: arch-fs25server
    environment:
      - VNC_PASSWORD=<your vnc password>
      - WEB_USERNAME=<dedicated server portal username>
      - WEB_PASSWORD=<dedicated server portal password>
      - SERVER_NAME=<your server name>
      - SERVER_PASSWORD=<your game join password>
      - SERVER_ADMIN=<your server admin password>
      - SERVER_PLAYERS=16
      - SERVER_PORT=10823
      - SERVER_REGION=en
      - SERVER_MAP=MapUS
      - SERVER_DIFFICULTY=3
      - SERVER_PAUSE=2
      - SERVER_SAVE_INTERVAL=180.000000
      - SERVER_STATS_INTERVAL=31536000
      - SERVER_CROSSPLAY=true
      - AUTOSTART_SERVER=false
      - PUID=<UID from user>
      - PGID=<PGID from user>
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /opt/fs25/config:/opt/fs25/config
      - /opt/fs25/game:/opt/fs25/game
      - /opt/fs25/dlc:/opt/fs25/dlc
      - /opt/fs25/installer:/opt/fs25/installer
    ports:
      - 5900:5900/tcp
      - 6080:6080/tcp
      - 7999:7999/tcp
      - 10823:10823/tcp
      - 10823:10823/udp
    cap_add:
      - SYS_NICE
    restart: unless-stopped
```

### Docker run
```
$ docker run -d \
    --name arch-fs25server \
    -p 5900:5900/tcp \
    -p 6080:6080/tcp \
    -p 7999:7999/tcp \
    -p 10823:10823/tcp \
    -p 10823:10823/udp \
    -v /etc/localtime:/etc/localtime:ro \
    -v /opt/fs25/installer:/opt/fs25/installer \
    -v /opt/fs25/config:/opt/fs25/config \
    -v /opt/fs25/game:/opt/fs25/game \
    -v /opt/fs25/dlc:/opt/fs25/dlc \
    -e VNC_PASSWORD="<your vnc password>" \
    -e WEB_USERNAME="<dedicated server portal username>" \
    -e WEB_PASSWORD="<dedicated server portal password>" \
    -e SERVER_NAME="<your server name>" \
    -e SERVER_PASSWORD="your game join password" \
    -e SERVER_ADMIN="<your server admin password>" \
    -e SERVER_PLAYERS="16" \
    -e SERVER_PORT="10823" \
    -e SERVER_REGION="en" \
    -e SERVER_MAP="MapUS" \
    -e SERVER_DIFFICULTY="3" \
    -e SERVER_PAUSE="2" \
    -e SERVER_SAVE_INTERVAL="180.000000" \
    -e SERVER_STATS_INTERVAL="31536000" \
    -e SERVER_CROSSPLAY="true" \
    -e PUID=<UID from user> \
    -e PGID=<PGID from user> \
    toetje585/arch-fs25server
```
# Installation

## Initial installation

Before starting the Docker container, it is necessary to go through the initial configuration process. Unlike many other games that provide standalone server binaries, Farming Simulator does not offer this option. Instead, the required files are included in the digital download package. To obtain these files, you will need to download the full game (ZIP Version) and all DLC from the [Download Portal](https://eshop.giants-software.com/downloads.php).

We will provide more detailed instructions below, but rest assured that the installation process is a one-time requirement. If the compose file is correctly configured with the correct mount paths, you will not lose the installation or configuration files even if you remove or purge the Docker image/container.

## Downloading the dedicated server

If you purchased the game or already have a product key you can download the game/dlc on the host machine from the [Download Portal](https://eshop.giants-software.com/downloads.php)

- Farming Simulator 25 (ZIP Archive) 

The DLC files are often just an .exe executable you can download them, we move them into the right place later on.

## Preparing the needed directories on the host machine

To ensure that the installation remains intact even if you remove or update the Docker container, it is important to configure specific directories on the host side. A common practice is to place these directories in `/opt`, although you can choose any other preferred mount point according to your needs and preferences.

`$sudo mkdir -p /opt/fs25/{config,game,installer,dlc}`

To enable read and write access for the user account configured in the compose file (PUID/PGID), we need to ensure that the Docker container can interact with the designated directory. This can be achieved by executing the following command, which grants the necessary permissions:

```bash
sudo chown -R myuser:mygroup /opt/fs25
```

Replace `<myuser>` with the appropriate user and `<mygroup>` with the users primary group (often the same as `<myuser>` if unsure use the id command below).

To incorporate the necessary PUID (User ID) and PGID (Group ID) values into the docker-compose/run file, you can utilize the Linux `id` command to retrieve the appropriate values. Run the following command:

```bash
id username
```

Replace `username` with the desired username.

Once you have obtained the User ID (UID) and Group ID (PGID) from the output of the `id` command, add them to the docker-compose/run file using the following YAML syntax:

```yaml
- PUID=<UID from user>
- PGID=<PGID from user>
```

Make sure to append `<UID=>` with the actual User ID value and `<PGID=>` with the corresponding Group ID value.

Example:

```yaml
- PUID=1000
- PGID=1000
```

## Unpack and move the installer

You should now unpack the installer and place the unzipped files inside the */your/path/fs25/installer* directory, all dlc should be placed in the */your/path/fs25/dlc* directory. If we start the docker container those directories will be mapped inside the container hence making them available for installation.

*Note: left mounth paths are on the host machine, the right mount path is inside the docker image and should be left untouched*

```
- /your/path/fs25/installer:/opt/fs25/installer
- /your/path/fs25/config:/opt/fs25/config
- /your/path/fs25/game:/opt/fs25/game
- /your/path/fs25/dlc:/opt/fs25/dlc
```

## Starting the container

With the host directories configured and the compose file set up accordingly, you are now ready to start the container.
inside the same direcoty where the modified docker-compose.yml is located run the following command.

```bash
docker-compose up -d
```

*Tip: You can use `$docker ps` to see if the container started correctly.

## Connecting to the VNC Server

After starting the Docker container for the first time, you will need to go through the initial installation of the game and DLC using a VNC client. One example of a VNC client is VNC® Viewer. This will allow you to set up the game and install the necessary content within the Docker environment.

Access via web interface (noVNC)

http://<host ip>:<host port>/vnc.html?resize=remote&host=<host ip>&port=<host port>&&autoconnect=1

e.g.:-

http://192.168.1.10:6080/vnc.html?resize=remote&host=192.168.1.10&port=6080&&autoconnect=1

# Environment variables

Getting the PUID and GUID is explained [here](https://man7.org/linux/man-pages/man1/id.1.html).

| Name | Default | Purpose |
|----------|----------|-------|
| `VNC_PASSWORD` || Password for connecting using the vnc client |
| `WEB_USERNAME` | `admin` | Username for admin portal at :8080 |
| `SERVER_NAME` || Servername that will be shown in the server browser |
| `SERVER_PORT` | `10823` | Default: 10823, port that the server will listen on |
| `SERVER_PASSWORD` || The game join password |
| `SERVER_ADMIN` || The server ingame admin password |
| `SERVER_REGION` | `en` | en, de, jp, pl, cz, fr, es, ru, it, pt, hu, nl, cs, ct, br, tr, ro, kr, ea, da, fi, no, sv, fc |
| `SERVER_PLAYERS` | `16` | Default: 16, amount of players allowed on the server |
| `SERVER_MAP` | `MapUS` | Default: MapUS (Elmcreek), other official maps are: MapFR (Haut-Beyleron), MapAlpine (Erlengrat) |
| `SERVER_DIFFICULTY` | `3` | Default: 3, start from scratch |
| `SERVER_PAUSE` | `2` | Default: 2, pause the server if no players are connected 1, never pause the server |
| `SERVER_SAVE_INTERVAL` | `180.000000` | Default: 180.000000, in seconds.|
| `SERVER_STATS_INTERVAL` | `31536000` | Default: 120.000000|
| `SERVER_CROSSPLAY` | `true/false` | Default: true |
| `AUTOSTART_SERVER` | `true/false/web_only` | Default: false, if true the server will start automatically with the container, web_only will only start the web panel. Make sure to set this to false before installing or updating the game. |
| `PUID` || PUID of username used on the local machine |
| `GUID` || GUID of username used on the local machine |

# Discord

Need support or like to contribute towards our community you can try to join our Discord server.

https://discord.gg/Ejz2MaXSNb

# Legal disclaimer
This Docker container is not endorsed by, directly affiliated with, maintained, authorized, or sponsored by [Giants Software](https://giants-software.com) and [Farming Simulator 25](https://farming-simulator.com/). The logo [Farming Simulator 25](https://giants-software.com) are © 2024 Giants Software.
