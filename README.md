# MARUS 2.0 - Docker Guide (ROS 2 Environment)

This repository provides a lightweight, containerized **ROS 2 Lyrical** environment for the **MARUS 2.0 Maritime Simulator**.

### 🏛️ Architecture Overview
- **Docker Container (ROS 2)**: Runs ROS 2 Lyrical, the `marus2_ros_adapter` gRPC communication bridge, and custom sensor messages (`uuv_sensor_msgs`).
- **Host Machine (Unity 6)**: Runs Unity 6 with the `marus2-example` simulation scene natively on your host OS.
- **Communication**: Because Docker runs in `network_mode: host`, Unity connects directly to the ROS 2 adapter over `localhost` (port 30052) with zero configuration or port forwarding needed.

---

## 📋 Prerequisites

1. **Docker & Docker Compose** installed on your host machine.
2. **Unity 6** (version `6000.x`) installed on your host machine via Unity Hub.
3. The **[marus2-example](https://github.com/MARUSimulator/marus2-example)** Unity project cloned on your host:
   ```bash
   git clone --recurse-submodules https://github.com/MARUSimulator/marus2-example.git
   ```

---

## 🚀 Quick Start

### 1. Build the Docker Image
Build the lightweight ROS 2 container (takes ~1-2 minutes):
```bash
docker compose build
```
*(or: `docker build -t marus2_docker:latest .`)*

### 2. Start the ROS 2 Container
Run the startup script:
```bash
chmod +x run_marus.sh
./run_marus.sh
```
*(or simply: `docker compose up -d`)*

---

## 🎮 Running the Simulation

### Step 1: Start the ROS 2 Environment
Execute the launch script:
```bash
./run_marus.sh
```
The ROS 2 adapter gRPC server starts **automatically** inside the container and immediately begins listening for Unity on `localhost:30052`.

### Step 2: Start the Simulation (On Host)
1. Open **Unity Hub** on your host machine.
2. Open the **`marus2-example`** project.
3. Open the example scene and press the **Play** button at the top of the Unity Editor.
4. Unity connects immediately to the ROS 2 adapter in real-time!

---

## 🛠️ Helpful Commands

- **Follow live ROS adapter logs**:
  ```bash
  docker compose logs -f
  ```
- **Open interactive terminal in container** (e.g. to inspect topics or run ROS nodes):
  ```bash
  docker compose exec marus2_simulator bash
  # e.g., ros2 topic list
  ```
- **Install dependencies for newly added ROS packages (`rosdep`)**:
  ```bash
  docker compose exec marus2_simulator bash
  cd ~/ros2_ws
  rosdep update
  rosdep install --from-paths src --ignore-src -y
  colcon build
  ```
- **Stop the environment**:
  ```bash
  docker compose down
  ```

---

## 📁 Shared Folder
A directory named `~/marus2_shared` is created on your host computer and mounted to `/home/marus2_user/shared` inside the container. Use this to exchange ROS bag files, launch files, and datasets between host and container.
