#!/bin/bash

# Run this as root, from the directory containing it!
#
# USAGE: sudo ./install.bash
#

stackPath=./

robot=kingfisher
user=administrator
release=$(ls /opt/ros/ | tail -n1)

ln -s /home/${user}/ros/setup.bash /etc/ros/setup.bash
source /etc/ros/setup.bash
pushd `rospack find ${robot}_bringup`/upstart > /dev/null

# Copy udev rules and udev helper to the usual spots
cp `rospack find ${robot}_bringup`/udev/* /etc/udev/rules.d/
cp `rospack find ${robot}_bringup`/bin/clearpath-name /usr/sbin/

function do_subs {
  # source file, dest file, interface, robot, job, release
  cp $1 $2
  sed -i "s/interface0/$3/g" $2
  sed -i "s/portnum/$4/g" $2
  sed -i "s/robot/$5/g" $2
  sed -i "s/job/$6/g" $2
  sed -i "s/release/$7/g" $2 
  sed -i "s/user/$8/g" $2 
}

function install_job {
  job=$1
  interface=$2
  portnum=$3

  echo "Installing $robot-$job using network interface $interface, port $portnum."
  
  cp $stackPath/mklaunch /usr/sbin/mklaunch
  do_subs $stackPath/start /usr/sbin/$robot-$job-start $interface $portnum $robot $job $release $user
  chmod +x /usr/sbin/$robot-$job-start

  do_subs $stackPath/stop /usr/sbin/$robot-$job-stop $interface $portnum $robot $job $release $user
  chmod +x /usr/sbin/$robot-$job-stop

  do_subs $stackPath/job.conf /etc/init/$robot-$job.conf $interface $portnum $robot $job $release $user

  # Copy launch files into /etc/ros/
  launch_path=/etc/ros/$release/$robot/$job.d
  mkdir -p $launch_path 
  cp `rospack find ${robot}_bringup`/launch/$job/* $launch_path
}

# substitutions: interface0, robot, job, release
install_job core eth0 11310
install_job interface wlan0 11311

popd > /dev/null
