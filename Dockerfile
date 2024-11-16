FROM binhex/arch-int-gui:latest
LABEL org.opencontainers.image.authors="Toetje585"
LABEL org.opencontainers.image.source="https://github.com/winegameservers/arch-fs25server"

# release tag name from buildx arg
ARG RELEASETAG

# arch from buildx --platform, e.g. amd64
ARG TARGETARCH

ADD build/*.conf /etc/supervisor/conf.d/

# add install bash script
ADD build/root/*.sh /root/

# add bash script to run app
ADD run/nobody/*.sh /usr/local/bin/

# add js script to run app
ADD run/nobody/*.mjs /usr/local/bin/

# add pre-configured config files for nobody
ADD config/nobody/ /home/nobody/.build/

# add rootfs files

COPY build/rootfs /

# install app
#############

# make executable and run bash scripts to install app
RUN chmod +x /root/*.sh && \
	/bin/bash /root/install.sh "${RELEASETAG}" "${TARGETARCH}"

# docker settings
#################

# env
#####

# set environment variables for user nobody
ENV HOME=/home/nobody

# set environment variable for terminal
ENV TERM=xterm

# set environment variables for language
ENV LANG=en_GB.UTF-8

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/bash", "/usr/local/bin/init.sh"]
