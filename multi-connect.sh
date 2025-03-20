#!/bin/bash

# This script creates a local tmux session and connects to remote servers from servers.txt.
# For each server, it establishes an SSH connection and creates or attaches to a remote tmux session.
# If the script is run multiple times, it destroys any existing local session and creates a new one.

# Session names
LOCAL_SESSION_NAME="multi-connect"
REMOTE_SESSION_NAME="remote-session"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install tmux and try again."
    exit 1
fi

# Check if the local tmux session already exists
if tmux has-session -t $LOCAL_SESSION_NAME 2>/dev/null; then
    # Kill existing session
    tmux kill-session -t $LOCAL_SESSION_NAME
fi

# Check if servers.txt exists
if [ ! -f servers.txt ]; then
    echo "Error: servers.txt not found."
    exit 1
fi

# Load servers from servers.txt
servers=()
while IFS= read -r line; do
    # Skip empty lines
    if [ -n "$line" ]; then
        servers+=("$line")
    fi
done < servers.txt

# Ensure servers.txt has at least one server
if [ ${#servers[@]} -eq 0 ]; then
    echo "No servers found in servers.txt"
    exit 1
fi

# Create a new local tmux session
tmux new-session -d -s $LOCAL_SESSION_NAME

# Define the remote command to check for existing session and create or attach
remote_cmd="if tmux has-session -t $REMOTE_SESSION_NAME 2>/dev/null; then tmux attach-session -t $REMOTE_SESSION_NAME; else tmux new-session -s $REMOTE_SESSION_NAME; fi"

# Process the first server
first_server=${servers[0]}
tmux rename-window -t $LOCAL_SESSION_NAME:0 "$first_server"
tmux send-keys -t $LOCAL_SESSION_NAME:0 "ssh -t $first_server '$remote_cmd'" C-m

# Process each additional server
for i in $(seq 1 $((${#servers[@]}-1))); do
    server=${servers[$i]}
    # Create a new window instead of splitting the existing one
    tmux new-window -t $LOCAL_SESSION_NAME: -n "$server"
    tmux send-keys -t $LOCAL_SESSION_NAME:$i "ssh -t $server '$remote_cmd'" C-m
done

# Attach to the local tmux session
tmux attach-session -t $LOCAL_SESSION_NAME