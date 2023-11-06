# Ros image
FROM osrf/ros:humble-desktop

### SOME SETUP
# Install packages without prompting the user to answer any questions
ENV DEBIAN_FRONTEND noninteractive

# Make apt to always ignore recommended and suggested packages
# This is particularly important with rosdep which invoked apt without `--no-install-recommends`
RUN echo \
  'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend

# Update system
RUN apt update && apt upgrade -y

# Install sudo
RUN apt-get update && apt-get install -q -y --no-install-recommends sudo && \
  rm -rf /var/lib/apt/lists/*

### CREATE NEW USER
# Build-time arguments
ARG USERNAME=docker-dev
ARG GROUPNAME=$USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set username and home environment variables
ENV USERNAME $USERNAME
ENV HOME /home/$USERNAME

# Create a new user with the provided details
RUN groupadd --gid $USER_GID $GROUPNAME && \
  useradd --create-home --home-dir /home/$USERNAME --shell /bin/bash --uid $USER_UID --gid $USER_GID $USERNAME

# Add the new user to the sudoers group with no password
RUN echo "$USERNAME:x:$USER_UID:$USER_GID:Developer,,,:$HOME:/bin/bash" >> /etc/passwd && \
  echo "$USERNAME:x:$USER_GID:" >> /etc/group && \
  echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME && \
  chmod 0440 /etc/sudoers.d/$USERNAME && \
  chown $USER_UID:$USER_GID -R $HOME

### Install the necessary stuff
# Change user
USER $USERNAME:$GROUPNAME

# Install text editors
RUN sudo apt update && sudo apt upgrade -y
RUN sudo apt install nano -y
RUN sudo apt install vim -y

# Other useful stuff
RUN sudo apt install curl -y
RUN sudo apt install wget -y

# Install python depencies
RUN sudo apt install python3-pip -y
RUN pip3 install rosbags

# Download UXRCE Agent
WORKDIR /home/$USERNAME
RUN git clone https://github.com/eProsima/Micro-XRCE-DDS-Agent.git
WORKDIR Micro-XRCE-DDS-Agent
RUN mkdir build
WORKDIR build
RUN cmake ..
RUN make
RUN sudo make install
RUN sudo ldconfig /usr/local/lib/

# Install some ROS2 dependencies
RUN rosdep update
RUN sudo apt install ros-humble-navigation2 -y
RUN sudo apt install ros-humble-nav2-bringup -y
RUN pip install numpy 
RUN sudo apt install ros-humble-rmw-cyclonedds-cpp -y

### Final setup
WORKDIR /home/$USERNAME
RUN echo "\n#Source ROS \nsource /opt/ros/foxy/setup.bash" >> .bashrc
RUN echo "\n\n#Fix display\nexport DISPLAY=:0" >> .bashrc

## Clone explorer demo
RUN mkdir -p ~/explorer_ws/src
WORKDIR /home/$USERNAME/explorer_ws/src
RUN git clone https://github.com/dantepiotto/random_explorer.git
WORKDIR /home/$USERNAME/explorer_ws
RUN colcon build --symlink-install
RUN echo "source install/setup.bash" >> .bashrc
