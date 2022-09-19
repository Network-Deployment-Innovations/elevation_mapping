#!/bin/bash
set -e

export LANG=C.UTF8
export LC_ALL=C.UTF-8
export ROS_DISTRO=melodic

echo "$(tput setaf 2)Starting install...$(tput sgr0)"

# make sure some simple stuff is present for the next step
apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    sudo lsb-release gnupg2

# add ROS debian repos
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
sudo echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros1-latest.list
sudo apt-get update -qq 

# https://github.com/osrf/docker_images/blob/master/ros/melodic/ubuntu/bionic/ros-core/Dockerfile
sudo echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    sudo apt-get -qq -y --no-install-recommends install tzdata

# sudo apt-get install -y --no-install-recommends -q \
#     dirmngr

sudo apt-get install -y --no-install-recommends \
    ros-$ROS_DISTRO-ros-core

# https://github.com/osrf/docker_images/blob/master/ros/melodic/ubuntu/bionic/ros-base/Dockerfile
sudo apt-get -qq -y --no-install-recommends install \
    build-essential \
    python-rosdep \
    python-rosinstall \
    python-vcstools \

rosdep init && rosdep update --rosdistro $ROS_DISTRO

sudo apt-get install -y --no-install-recommends \
    ros-$ROS_DISTRO-ros-base

sudo apt-get install -y --no-install-recommends \
    ros-$ROS_DISTRO-catkin \
    python-catkin-tools \
    git

rm -rf /var/lib/apt/lists/*

source /opt/ros/$ROS_DISTRO/setup.bash

cd ..
# should be in catkin_ws/src/

git clone -b $ROS_DISTRO-devel https://github.com/ANYbotics/grid_map
git clone https://github.com/ANYbotics/kindr
git clone https://github.com/ANYbotics/kindr_ros
git clone https://github.com/ANYbotics/message_logger

cd ..
# should be in catkin_ws/

catkin init --workspace .

rosdep install --from-paths src --ignore-src -r -y

# https://github.com/ANYbotics/grid_map/issues/292
for f in $(find . -name '*.hpp'); do sed -in 's/<filters\/\(.*\)hpp.*/<filters\/\1h>/p' $f; done

# https://github.com/ANYbotics/elevation_mapping/issues/151
sed -in \
    s/PCL_MAKE_ALIGNED_OPERATOR_NEW/EIGEN_MAKE_ALIGNED_OPERATOR_NEW/ \
    $(find . -name 'PointXYZRGBConfidenceRatio.hpp')

catkin build
