FROM osrf/ros:noetic-desktop
# The OSRF ROS Noetic containers use the root user.
# Therefore, the following commands are executed as root up until the
# USER user statement.

# Arguments
ARG user
ARG uid
ARG home
ARG workspace
ARG shell

# We love UTF!
ENV LANG C.UTF-8

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN apt-get update
RUN apt-get install -y ros-noetic-image-transport-plugins ros-noetic-vision-msgs ros-noetic-camera-calibration ros-noetic-camera-calibration-parsers ros-noetic-camera-info-manager ros-noetic-video-stream-opencv ros-noetic-plotjuggler

RUN set -x \
	    && useradd -ms /bin/bash ${user} \
        && echo "${user}:${user}" | chpasswd && adduser ${user} sudo \
        && echo "${user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        
# Install some handy tools.
RUN set -x \
        && apt-get update \
#        && apt-get upgrade -y \
        && apt-get install -y mesa-utils \ 
        && apt-get install -y iputils-ping \ 
        && apt-get install -y apt-transport-https ca-certificates \
        && apt-get install -y openssh-server python3-pip exuberant-ctags \
        && apt-get install -y git vim tmux nano htop sudo curl wget gnupg2 tree gdb less ssh zsh \
        && apt-get install -y  bash-completion \
        && pip3 install powerline-shell  \
        && rm -rf /var/lib/apt/lists/* 
#        && useradd -ms /bin/bash user \
#        && echo "user:user" | chpasswd && adduser user sudo \
#        && echo "user ALL=(ALL) NOPASSWD: ALL " >> /etc/sudoers

RUN apt-get install -y python3-yaml python3-opencv python3-numpy 
RUN pip3 install scipy numpy imutils pyyaml pymavlink # pycairo pygobject

# The OSRF contianer didn't link python3 to python, causing ROS scripts to fail.
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install VSCode
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft-archive-keyring.gpg
RUN sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
RUN apt-get install -y apt-transport-https
RUN apt-get update
RUN apt-get install -y code 

RUN git clone https://github.com/catkin/catkin_tools.git &&  cd catkin_tools && pip3 install -r requirements.txt --upgrade && python setup.py install --record install_manifest.txt

# Switch to user
USER "${user}"
# This is required for sharing Xauthority
ENV QT_X11_NO_MITSHM=1
ENV CATKIN_TOPLEVEL_WS="${workspace}/devel"
# Switch to the workspace
WORKDIR ${workspace}
