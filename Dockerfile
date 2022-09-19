FROM ros:melodic

RUN apt-get update -qq && apt-get install -y \
    ros-melodic-catkin \
    python-catkin-tools

RUN mkdir -p /home/catkin_ws/src
RUN catkin init --workspace /home/catkin_ws

WORKDIR /home/catkin_ws/src
RUN git clone -b melodic-devel https://github.com/ANYbotics/grid_map
RUN git clone https://github.com/ANYbotics/kindr
RUN git clone https://github.com/ANYbotics/kindr_ros
RUN git clone https://github.com/ANYbotics/message_logger
COPY ./elevation_mapping src/elevation_mapping

WORKDIR /home/catkin_ws
RUN rosdep install --from-paths src --ignore-src -r -y

# https://github.com/ANYbotics/grid_map/issues/292
RUN for f in $(find . -name '*.hpp'); do sed -in 's/<filters\/\(.*\)hpp.*/<filters\/\1h>/p' $f; done

# https://github.com/ANYbotics/elevation_mapping/issues/151
RUN sed -in \
    s/PCL_MAKE_ALIGNED_OPERATOR_NEW/EIGEN_MAKE_ALIGNED_OPERATOR_NEW/ \
    $(find . -name 'PointXYZRGBConfidenceRatio.hpp')

RUN . /opt/ros/melodic/setup.sh && catkin build
