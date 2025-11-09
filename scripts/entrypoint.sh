#!/usr/bin/env bash
set -e
# source ROS
source "/opt/ros/${ROS_DISTRO}/setup.bash" || true
# source workspace overlay if present
if [ -f "/workspaces/install/setup.bash" ]; then
  source "/workspaces/install/setup.bash"
fi
exec "$@"
