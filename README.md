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
```yaml
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
```yaml
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

## Install Docker and Docker Compose
You will need to have docker and docker compose on your host. You can find detailled instructions for various OS's [at Docker](https://docs.docker.com/engine/install/). If you did everything correctly, `docker -v` and `docker compose version` should output some kind of version number.

## Choosing a non-root user

It is recommended to not run your LS server as a root user and instead either create a seperate user for that or re-use a non-privileged user. You technically can use the root user, but that raises major security concerns.

Choose a name for your user. This README uses `myuser` as example. We recommend to download this Readme File, open it in some kind of text editor and replace all ocurrances of `myuser` with your chosen username. To create a new user, run

```sh
sudo adduser myuser
sudo adduser myuser docker
```
The first command creates your new user. You will be asked for a password for this user, followed by some general information you can leave blank. You might also disable password login and add ssh-keys instead, but that is out of scope for this instructions.
The second command adds your newly created user to the docker group, so it can start docker containers later on.

If you just created this user, log out and re-login using your newly created user. The remainder of this README assumes that you are logged in as `myuser`.

## Downloading the dedicated server

If you purchased the game or already have a product key you can download the game and DLCs on the host machine from GIANTS [download portal](https://eshop.giants-software.com/downloads.php). You now should have a ZIP Archive containing Farming Simulator 25.
The DLC files are often just an .exe executable. You can just download them using `curl` or `wget`, we move them into the right place later on.

## Preparing the needed directories on the host machine

To ensure that the installation remains intact even if you remove or update the Docker container, it is important to configure specific directories on the host. A common practice is to place these directories in `/opt`, although you can choose any other preferred mount point according to your needs and preferences.

The remainder of this instructions assumes, that the game is inside of the directory `/mydir`, which should not be called this way. Instead, replace all occurences of `/mydir` with the directory you chose, e.G. `/opt`.

```sh
sudo mkdir -p /mydir/fs25/{config,game,installer,dlc}
```

To enable read and write access for the user account configured in the compose file (PUID/PGID), we need to ensure that the Docker container can interact with the designated directory. This can be achieved by executing the following command, which grants the necessary permissions:

```sh
sudo chown -R myuser:myuser /mydir/fs25
```

Note, that the first `myuser` in `myuser:myuser` relates to the user's name, the second `myuser` does relate to the users primary group. If you created that user as mentioned above, the users primary group will be called like the user itself, though it might not always be this way. If your user's primary group is called different, replace the second `myuser` with that group's name.

You can see your user's id (PUID), it's primary group name and the primary group ID (PGID) using the command
```sh
id myuser
```
which will output something like
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),0(root),27(sudo),100(users),998(docker)
```

You will need those values for the docker compose configuration, so make a note of them.

## Unpack and move the installer

You should now unpack the installer and place the unzipped files inside the directory `/mydir/fs25/installer/`, all dlc should be placed in the directory `/mydir/fs25/dlc/` directory. If we start the docker container those directories will be accessed by the container, hence making them available for installation.

## Downloading and updating the compose file / run command.
The reccomended way to start the docker containers is using the tool docker compose. You will need to download the `docker-compose.yml` from this repository and store it on your host. You can just leave it in your users home directory or place it somewhere else, as long as you remember where you left it.

Open it in some text editor of your choice.

You'll find a tree structure. Under `services > arch-fs25server > mounts` you should find a list of directories. If you downloaded the file from here and put your game files into `/opt/fs25`, you're good to go.
If you chose another directory, make shure you change the paths accordingly. If you downloaded the Instructions File and replaced the dir name, these entries should be fine:
```yaml
- /mydir/fs25/installer:/opt/fs25/installer
- /mydir/fs25/config:/opt/fs25/config
- /mydir/fs25/game:/opt/fs25/game
- /mydir/fs25/dlc:/opt/fs25/dlc
```

You'll need to set a few values under `services > arch-fs25server > as well`. The downloaded file should contain defaults. Change them according to your wishes. You'll find explanations in the Table [Environment variables](#environment-variables).

## Starting the container

With the host directories configured and the compose file set up accordingly, you are now ready to start the container.
inside the same direcoty where the modified docker-compose.yml is located run the following command.

```bash
docker compose up -d
```
The `-d` makes your containers run in the background, so they keep running if you disconnect from your shell session. To see what's happening, you can access the container's logs with `docker compose -f`


*Tip: You can use `$docker ps` to see if the container started correctly.

## Connecting to the VNC Server

After starting the Docker container for the first time, you will need to go through the initial installation of the game and DLC using a VNC client. This will allow you to set up the game and install the necessary content within the Docker environment.

This project includes a ready-to-go VNC Client, so you won't need to download anything. You need to know the port under which you'll be able to access VNC. If you didn't change it, it should be `6080`. If you are connected to your host via ssh, get your host's IP so you can access it. Otherwise, you can use `127.0.0.1` as your IP.

Open `http://<ip>:<port>/vnc.html?resize=remote&host=<ip>&port=<port>&&autoconnect=1` in a browser of your choice, while replacing IP and Port with your values. Please nothe, that both of them occur twice! You'll be prompted for a password, which you set as environment variable `VNC_PASSWORD`.

It might happen, that the connection fails on first attempt. Go get a coffee and wait a few minutes, before making another attempt.

You should now see a desktop environment. Double Click 'Setup' to install FS25. You'll need your FS25 Serial Number now. Wait for the installation process to complete.
After that, click 'Start Server'. This should spawn your game server and also open the web admin portal. You don't need to access it from your host, you can also navigate to `http://<ip>:7999` from another machine. The credentials are those you chose as `WEB_USERNAME` and `WEB_PASSWORD` in the `docker-compose.yml`.

# Environment variables

Getting the PUID and GUID is explained [here](https://man7.org/linux/man-pages/man1/id.1.html).

| Name | Default | Purpose |
|----------|----------|-------|
| `VNC_PASSWORD` || Password for connecting using the vnc client |
| `WEB_USERNAME` | `admin` | Username for admin portal at :7999 |
| `WEB_PASSWORD' | `webpassword` | Password for the admin portal |
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
