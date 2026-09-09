# syntax=docker/dockerfile:1
FROM ros:lyrical-ros-base

ARG USERNAME=marus2_user
ARG ROS_DISTRO=lyrical
ENV HOME=/home/$USERNAME
SHELL ["/bin/bash", "-c"]

# Update system and install essential tools & ROS 2 dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git git-lfs wget curl python3-pip python3-colcon-common-extensions \
    python3-rosdep locales gnupg \
    ros-${ROS_DISTRO}-cv-bridge python3-opencv \
 && rm -rf /var/lib/apt/lists/*

# Set up user and grant passwordless sudo privileges
RUN useradd -ms /bin/bash ${USERNAME} && adduser ${USERNAME} sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
 && usermod -a -G sudo,dialout ${USERNAME}

# Initialize rosdep (if not already initialized by base image)
RUN [ -f /etc/ros/rosdep/sources.list.d/20-default.list ] || rosdep init

USER ${USERNAME}

# Configure Git to automatically rewrite git@ SSH URLs to HTTPS.
# This prevents submodule updates from failing if they are configured as SSH in upstream repositories.
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# Set up ROS 2 workspace
RUN mkdir -p ${HOME}/ros2_ws/src

# Clone and configure marus2_ros_adapter for Unity-ROS communication
WORKDIR ${HOME}/ros2_ws/src
RUN git clone https://github.com/MARUSimulator/marus2_ros_adapter.git \
 && cd marus2_ros_adapter \
 && (git checkout lyrical || git checkout master || git checkout main) \
 && pip install -r requirements.txt --break-system-packages \
 && git submodule update --init --recursive

# Clone sensor messages repository (uuv_sensor_msgs)
RUN git clone https://github.com/labust/uuv_sensor_msgs.git \
 && cd uuv_sensor_msgs \
 && (git checkout lyrical || git checkout humble || git checkout main)

# Update rosdep and install all workspace package dependencies
WORKDIR ${HOME}/ros2_ws
RUN rosdep update \
 && sudo apt-get update \
 && (rosdep install --from-paths src --ignore-src -y -r --rosdistro ${ROS_DISTRO} || rosdep install --from-paths src --ignore-src -y -r) \
 && sudo rm -rf /var/lib/apt/lists/*

# Build the ROS 2 workspace using colcon
RUN source /opt/ros/lyrical/setup.bash && colcon build

# Source ROS 2 environments automatically on shell startup
RUN echo -e "source /opt/ros/lyrical/setup.bash\nsource ${HOME}/ros2_ws/install/setup.bash" >> ${HOME}/.bashrc

# Create convenience launcher shortcut for ROS adapter
USER root
RUN printf '#!/bin/bash\nsource /opt/ros/lyrical/setup.bash\nsource /home/%s/ros2_ws/install/setup.bash\nexec ros2 launch marus2_ros_adapter ros2_server_launch.py "$@"\n' "${USERNAME}" > /usr/local/bin/launch_adapter \
 && chmod +x /usr/local/bin/launch_adapter

USER ${USERNAME}
WORKDIR ${HOME}

CMD ["launch_adapter"]
