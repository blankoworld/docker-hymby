# This is a Dockerfile to create a Hymby development environment on Debian Wheezy (version 7)
#
# VERSION 0.0

# use Debian wheezy (version 7) image provided by docker.io
FROM debian:wheezy

MAINTAINER Olivier Dossmann, olivier+dockerfile@dossmann.net

# Get noninteractive frontend for Debian to avoid some problems:
#    debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

# Update package list before installing ones
RUN apt-get update

# Install program to configure locales
RUN apt-get install -y locales
RUN dpkg-reconfigure locales && \
  locale-gen C.UTF-8 && \
  /usr/sbin/update-locale LANG=C.UTF-8
# Install needed default locale for Makefly
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
  locale-gen
# Set default locale for the environment
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# PROGRAMS
# first hymby needed programs
RUN apt-get install -y python-markdown
# then development tools
RUN apt-get install -y git-core vim zsh tmux

# DEFAULT root user
RUN echo 'root:hymby' |chpasswd # change default root password
# DEFAULT docker user
# Add special user docker
RUN useradd -m docker # create the home directory (-m option)
RUN echo "docker:docker" | chpasswd # change default docker password
# Permit docker user to user tmux
RUN gpasswd -a docker utmp
# Change docker user default shell
RUN chsh -s /usr/bin/zsh docker

# INSTALL hymby repository
RUN cd /opt && \
  git clone --depth 1 http://github.com/blankoworld/hymby.git && \
  chown docker hymby/ -R

# Install Makefly as default static weblog engine
RUN apt-get install -y lua5.1 liblua5.1-filesystem0 liblua5.1-markdown0
RUN cd /opt/hymby && \
  git clone --depth 1 http://github.com/blankoworld/makefly.git hosted_engine
ADD makefly.rc /opt/hymby/hosted_engine/makefly.rc

# Create Hymby's configuration file
RUN cp /opt/hymby/hymbyrc.example /opt/hymby/hymbyrc

# Change owner of /opt/hymby
RUN chown docker /opt/hymby -R

# Add tmux configuration for docker user
ADD tmux.conf /home/docker/.tmux.conf
# Add vim configuration
ADD vimrc /home/docker/.vimrc
# Add zsh configuration
ADD zshrc /home/docker/.zshrc

# Open some ports: 8080(Hymby's default port)
EXPOSE 8080

# Gain docker permission 
USER docker
