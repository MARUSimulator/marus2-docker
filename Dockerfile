# syntax=docker/dockerfile:1
FROM ros:lyrical-ros-base

ARG USERNAME=marus2_user
ARG UNITY_VERSION=6000.3.23f1
ARG ROS_DISTRO=lyrical
ENV HOME /home/$USERNAME
SHELL ["/bin/bash", "-c"]

# Nvidia GPU and graphics configuration (enables GPU and Vulkan passthrough)
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute

# Update system and install basic dependencies (including libraries required by Unity 6 and Vulkan)
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git git-lfs wget curl pip xz-utils locales \
    libvulkan1 libvulkan-dev vulkan-tools \
    libglvnd0 libglx0 libegl1 libgles2 mesa-utils \
    libasound2t64 libnss3 libnspr4 libsecret-1-0 libarchive13 libcap2

# Set up user and grant passwordless sudo privileges
RUN useradd -ms /bin/bash ${USERNAME} && adduser ${USERNAME} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -a -G sudo,dialout ${USERNAME}

# Install Unity Hub for Linux
RUN sh -c 'echo "deb https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list' \
 && wget -qO - https://hub.unity3d.com/linux/keys/public | apt-key add \
 && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y unityhub

USER ${USERNAME}

# Configure Git to automatically rewrite git@ SSH URLs to HTTPS.
# This prevents submodule updates from failing if they are configured as SSH in the upstream repository.
RUN git config --global url."https://github.com/".insteadOf "git@github.com:"

# Download and install Unity Editor (unattended installation using tarball)
WORKDIR ${HOME}
RUN mkdir -p ${HOME}/Unity/Hub/Editor/${UNITY_VERSION} \
 && wget -q https://download.unity3d.com/download_unity/09d2ecc7fb28/LinuxEditorInstaller/Unity-${UNITY_VERSION}.tar.xz \
 && tar -xf Unity-${UNITY_VERSION}.tar.xz -C ${HOME}/Unity/Hub/Editor/${UNITY_VERSION} \
 && rm Unity-${UNITY_VERSION}.tar.xz

# Register the installed Unity Editor within Unity Hub
RUN unityhub -- --headless editors --add --path ${HOME}/Unity/Hub/Editor/${UNITY_VERSION}/Editor/Unity

# Clone MARUS 2.0 example project and update its submodules
RUN git clone https://github.com/MARUSimulator/marus2-example.git \
 && cd marus2-example \
 && git submodule update --init --recursive

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
 && (git checkout lyrical || git checkout master || git checkout main)

# Build the ROS 2 workspace using colcon
WORKDIR ${HOME}/ros2_ws
RUN source /opt/ros/lyrical/setup.bash && colcon build

# Source ROS 2 environments automatically on shell startup
RUN echo -e "source /opt/ros/lyrical/setup.bash\nsource ${HOME}/ros2_ws/install/setup.bash" >> ${HOME}/.bashrc

USER root
