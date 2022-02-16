#!/bin/sh
PWD=`pwd`
echo $PWD
if [ ! -d atomic-red-team ]; then
  git clone https://github.com/redcanaryco/atomic-red-team.git atomic-red-team
fi
