# syntax=docker/dockerfile:1.7
FROM osrf/ros:jazzy-desktop-full-noble

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000
ENV DEBIAN_FRONTEND=noninteractive
# define workspace dir BEFORE we use it
ENV WS=/workspaces

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-dev-tools python3-pip python3-colcon-common-extensions \
    python3-vcstool python3-rosdep build-essential cmake git curl \
    vim nano libudev-dev udev usbutils mesa-utils libgl1-mesa-dri libglu1-mesa \
    x11-apps dbus-x11 iputils-ping net-tools less ripgrep sudo \
 && rm -rf /var/lib/apt/lists/*

# create or reuse group/user
RUN set -eux; \
    # 1) group: reuse GID if it exists
    if getent group "${USER_GID}" >/dev/null 2>&1; then \
        EXISTING_GROUP="$(getent group "${USER_GID}" | cut -d: -f1)"; \
        groupname="${EXISTING_GROUP}"; \
    else \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
        groupname="${USERNAME}"; \
    fi; \
    # 2) user: reuse UID if it exists
    if id -u "${USER_UID}" >/dev/null 2>&1; then \
        EXISTING_USER="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
        usermod -l "${USERNAME}" "${EXISTING_USER}" || true; \
        usermod -g "${USER_GID}" "${USERNAME}" || true; \
    else \
        useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USERNAME}"; \
    fi; \
    # 3) add groups, sudo
    usermod -aG dialout,video,plugdev "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
    chmod 0440 /etc/sudoers.d/${USERNAME}; \
    # 4) make workspace and chown using ACTUAL group name
    mkdir -p "${WS}"; \
    chown -R "${USERNAME}:${groupname}" "${WS}"

# rosdep in image
RUN rosdep init || true && rosdep update

# entrypoint
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# source ROS in shells
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/skel/.bashrc

USER ${USERNAME}
WORKDIR ${WS}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
