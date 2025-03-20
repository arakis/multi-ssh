#!/bin/bash

# This script creates a local tmux session and connects to remote servers from servers.txt.
# For each server, it establishes an SSH connection and creates or attaches to a remote tmux session.
# If the script is run multiple times, it destroys any existing local session and creates a new one.

# Session names
LOCAL_SESSION_NAME="multi-connect"
REMOTE_SESSION_NAME="remote-session"

# Remote user to switch to after connecting
REMOTE_USER="creatica"

# Default options
SYNCHRONIZE_PANES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --syncronize-panes)
            SYNCHRONIZE_PANES=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Available options: --syncronize-panes"
            exit 1
            ;;
    esac
done

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

# Process all servers
for i in $(seq 0 $((${#servers[@]}-1))); do
    server=${servers[$i]}
    
    if [ $i -eq 0 ]; then
        # For the first server, rename the initial window
        tmux rename-window -t $LOCAL_SESSION_NAME:0 "$server"
    else
        if [ "$SYNCHRONIZE_PANES" = true ]; then
            # Create a new pane for each additional server when sync is enabled
            tmux split-window -t $LOCAL_SESSION_NAME:0 -v
            # Ensure even layout for all panes
            tmux select-layout -t $LOCAL_SESSION_NAME:0 tiled
        else
            # Create a new window for each additional server (original behavior)
            tmux new-window -t $LOCAL_SESSION_NAME: -n "$server"
        fi
    fi
    
    # Determine target for send-keys
    if [ "$SYNCHRONIZE_PANES" = true ]; then
        # When using panes, we need to target the specific pane
        target="$LOCAL_SESSION_NAME:0.$i"
    else
        # When using windows, we target the window
        target="$LOCAL_SESSION_NAME:$i"
    fi
    
    # Send SSH command to the target
    tmux send-keys -t "$target" "ssh -t $server" C-m

    # if remote user is set, send sudo su $REMOTE_USER before running tmux
    if [ -n "$REMOTE_USER" ]; then
        tmux send-keys -t "$target" "sudo su $REMOTE_USER" C-m
        tmux send-keys -t "$target" "cd ~" C-m
    fi
    
    # Now run the tmux command after potential user switch
    tmux send-keys -t "$target" "$remote_cmd" C-m
done

# Enable synchronize-panes if the flag was set
if [ "$SYNCHRONIZE_PANES" = true ]; then
    tmux set-window-option -t $LOCAL_SESSION_NAME:0 synchronize-panes on
fi

# Attach to the local tmux session
tmux attach-session -t $LOCAL_SESSION_NAME