#!/bin/bash
echo Downloading tmate...
wget https://github.com/tmate-io/tmate/releases/download/2.2.1/tmate-2.2.1-static-linux-amd64.tar.gz
echo Extracting
tar xf tmate-2.2.1-static-linux-amd64.tar.gz --strip 1
echo Launching tmate session with tmate.sock $(which tmux)
export TERM=xterm 
strace -f ./tmate -S tmate.sock new-session -d 
#./tmate -S tmate.sock new-session -d 
echo Waiting for tmate to establish back-channel
./tmate -S tmate.sock wait tmate-ready
./tmate -S tmate.sock display -p '#{tmate_ssh}'
