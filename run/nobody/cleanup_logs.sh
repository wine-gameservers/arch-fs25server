#!/bin/bash

# Lets purge the logs so we won't have errors/warnings at server start...

if [ -f ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/server.log ]
then
  rm ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/server.log && touch ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/server.log
else
  touch ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/server.log
fi

if [ -f ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/webserver.log ]
then
  rm ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/webserver.log && touch ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/webserver.log
else
  touch ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs/webserver.log
fi

if [ -f ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/log.txt ]
then
  rm ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/log.txt && touch ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/log.txt
else
  touch ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/log.txt
fi
