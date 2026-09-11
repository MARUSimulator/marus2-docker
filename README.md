# MARUS 2.0 - Docker Environment

A plug-and-play **ROS 2 Lyrical** container for the **MARUS 2.0 Simulator**.

This environment comes pre-configured with ROS 2, the `marus2_ros_adapter` gRPC bridge. It allows you to run simulations seamlessly with Unity 6 without needing to install ROS 2 or Linux on your host machine.

---

## 📋 Prerequisites

1. **Docker & Docker Compose** installed and running on your host machine
2. **Unity 6** (version `6000.5`) installed via Unity Hub.
3. The **[marus2-example](https://github.com/MARUSimulator/marus2-example)** Unity project cloned on your host:
   ```bash
   git clone --recurse-submodules https://github.com/MARUSimulator/marus2-example.git
   ```

---

## 🚀 Quick Start (Running the Simulation)

### Step 1: Start the ROS 2 Environment
From the `marus2-docker` directory, run the launch script:

```bash
chmod +x run_marus.sh
./run_marus.sh
```

*(On the first run, Docker automatically downloads the pre-built image from GitHub Container Registry. No manual build required!)*

The ROS adapter starts automatically inside the container and begins listening on `localhost:30052`.

> 💡 **Tip**: To run in the background (detached mode), use `./run_marus.sh -d`.

### Step 2: Start the Simulation in Unity
1. Open **Unity Hub** on your host computer.
2. Open the **`marus2-example`** project.
3. Open the example scene and press the **Play** button at the top of the Unity Editor.
4. Unity will automatically connect to the ROS 2 adapter!

---

## 🛠️ Interacting with ROS 2

While the container is running, you can inspect topics, run nodes, or launch graphical tools:

- **Open an interactive shell in the container**:
  ```bash
  docker compose exec marus2_simulator bash
  ```
  *(ROS 2 environments and workspace setups are sourced automatically)*

- **List active ROS 2 topics**:
  ```bash
  docker compose exec marus2_simulator ros2 topic list
  ```

- **Echo a topic**:
  ```bash
  docker compose exec marus2_simulator ros2 topic echo /marus/pose
  ```

- **View live adapter logs**:
  ```bash
  docker compose logs -f
  ```

- **Stop the simulation container**:
  ```bash
  docker compose down
  ```

---

## 📁 Shared Folder (`~/marus2_shared`)

A shared directory is automatically prepared on your host machine:
```text
~/marus2_shared
```
This folder is mapped to `/home/marus2_user/shared` inside the container. Use it to easily exchange ROS bag recordings, custom launch files, scripts, and logs between your host and the container.

---

## 🔧 Building from Source (For Developers)

If you want to modify the ROS adapter or sensor packages locally instead of using the pre-built image:

1. **Clone the repository with submodules**:
   ```bash
   git clone --recurse-submodules https://github.com/MARUSimulator/marus2-docker.git
   ```
   *(If already cloned without submodules, run: `git submodule update --init --recursive`)*

2. **Build the image locally**:
   ```bash
   docker compose build
   ```

3. **Launch your local build**:
   ```bash
   ./run_marus.sh
   ```

### Developer Details
- **`src/marus2_ros_adapter`**: ROS 2 to Unity gRPC communication bridge.
- **`src/uuv_sensor_msgs`**: Custom underwater vehicle sensor message definitions.
- **Automated Updates**: [Dependabot](.github/dependabot.yml) checks daily for upstream updates to submodules and opens pull requests.
- **CI/CD**: Merging or tagging triggers the [GitHub Actions workflow](.github/workflows/docker-publish.yml) to publish a new image to `ghcr.io/marusimulator/marus2-docker`.
