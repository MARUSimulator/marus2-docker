# MARUS2 - Docker Guide

## 📋 Prerequisites & Host Setup

Before proceeding, ensure your host machine has an **Nvidia GPU** with the latest drivers installed.

### 1. Install Nvidia Container Toolkit
To allow your Docker container to access the physical GPU on your host machine for rendering Unity 6 and RViz 2, install the **Nvidia Container Toolkit** on your host:


[https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)


---

## 🚀 Quick Start Steps

### 1. Clone the Repository
Clone this configuration repository and navigate to its root folder:
```bash
git clone https://github.com/MARUSimulator/marus2-docker.git
cd marus2-docker
```

### 2. Build the Docker Image
Since all packages are cloned via HTTPS, the build command is incredibly simple and **no longer requires passing your private SSH keys**:
```bash
docker build -t marus2_docker:latest .
```

### 3. Start the Environment
Choose one of the following options to launch the container:

#### Option A: Using the Automated Script (Recommended)
The helper script sets display permissions, verifies Nvidia drivers, prepares a shared directory (`~/marus2_shared`), and brings up the container:
```bash
chmod +x run_simulator.sh
./run_simulator.sh
```

#### Option B: Running Manually
```bash
# Allow local container connections to your display server (for GUI support)
xhost +local:docker

# Launch the container in the background
docker compose up -d
```

---

## 🎮 Launching the Simulation

### 1. Access the Container
Connect to the interactive terminal of your running container:
```bash
docker compose exec marus2_simulator bash
```

### 2. Run the ROS 2 Lyrical Adapter
Inside the container terminal, launch the adapter server:
```bash
ros2 launch marus2_ros_adapter ros2_server_launch.py
```

### 3. Start Unity 6 and Load the Simulator
Open a new terminal window on your host computer, connect to the container again, and launch Unity Hub:
```bash
docker compose exec marus2_simulator bash
unityhub
```
Inside the Unity Hub graphical interface:
1. Click **Add** (or **Add project from disk**).
2. Browse and select the pre-configured project located at: `/home/marus2_user/marus2-example`.
3. Open the project with **Unity 6 (6000.3.23f1)** and press **Play** to start the simulation
