#!/bin/bash
firefox "http://"$CONTAINER_IP":7999/index.html?lang=en&username="$WEB_USERNAME"&password="$WEB_PASSWORD"&login=Login"