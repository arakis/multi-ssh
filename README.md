## Usage

```bash
multi-ssh [OPTIONS] [COMMAND] [ARGS...]
```

**Basic Connection:**

```bash
# Connect to servers listed in ./servers.conf
./multi-ssh

# Use a different configuration file
./multi-ssh --config ~/my_servers.ini
```

**Options:**

*   `--help`: Display the help message.
*   `completion`: Output the path to the bash completion script.
*   `--syncronize-panes`: Use a single window with synchronized panes instead of multiple windows.
*   `--local-session <name>`: Set the local `tmux` session name (default: `multi-ssh`).
*   `--remote-session <name>`: Set the remote `tmux` session name (default: `remote-session`).
*   `--remote-user <username>`: Switch to `<username>` using `sudo su` after connecting remotely.
*   `--ssh-user <username>`: Use `<username>` for the SSH connection.
*   `--ssh-key <keyfile>`: Use the specified private key file for SSH authentication.
*   `--config <path>`: Path to the server configuration file (default: `./servers.conf`).

**Commands:**

*   `send-keys [command]`: Sends the specified `command` string to all remote sessions without pressing Enter. If `command` is omitted, sends the server-specific command from the `[servers]` section of the config file (if defined).
*   `exec [command]`: Executes the specified `command` on all remote sessions (sends the command followed by Enter). If `command` is omitted, executes the server-specific command from the `[servers]` section of the config file (if defined).
*   `kill`: Kills the remote `tmux` sessions and the local `multi-ssh` session.
*   `copy [remote:|]:src_path [remote:|]:dest_path`: Copies files using `rsync`. Use `remote:` prefix to indicate the path on the remote servers.
    *   Upload: `copy local/path remote:/remote/path`
    *   Download: `copy remote:/remote/path local/path`

**Examples:**

```bash
# Connect normally (using ./servers.conf)
./multi-ssh

# Connect with synchronized panes (overriding config if set differently)
./multi-ssh --syncronize-panes

# Connect using a specific SSH user and key (overriding config)
./multi-ssh --ssh-user admin --ssh-key ~/.ssh/id_admin

# Connect and switch to 'appuser' on remote servers (overriding config)
./multi-ssh --remote-user appuser

# Execute 'uptime' on all servers
./multi-ssh exec 'uptime'

# Send 'cd /var/www' to all servers (without executing)
./multi-ssh send-keys 'cd /var/www'

# Execute server-specific commands from servers.conf's [servers] section
./multi-ssh exec

# Upload a local file to the home directory on all servers
./multi-ssh copy ./myfile.txt remote:~/myfile.txt

# Download a log file from all servers into a local 'logs' directory
# (rsync will typically create subdirs named after servers if dest is a dir)
./multi-ssh copy remote:/var/log/app.log ./logs/

# Kill all associated remote and local tmux sessions
./multi-ssh kill
```

## Configuration File (`servers.conf`)

The script now uses an INI-style configuration file (default: `./servers.conf`).

**Format:**

```ini
# Server entries can appear first without the [servers] header
server1.example.com
server2.example.com tail -f /var/log/app.log
192.168.1.10 htop

[options]
# Set default options here. These correspond to the long command-line
# flags without the preceding '--'.
# Command-line flags will always override these settings.

# Example options:
# local-session = my-multi-ssh
# remote-session = remote-tmux
# remote-user = webadmin
# ssh-user = deployer
# ssh-key = /home/user/.ssh/deploy_key
# synchronize-panes = true # Use true/yes/1 or false/no/0

# Alternatively, you can explicitly use the [servers] header:
# [servers]
# server3.example.com
# server4.example.com
```

*   Lines starting with `#` or `;` are ignored as comments.
*   Empty lines are ignored.
*   The `[servers]` section lists target hosts, optionally followed by a default command for that host. **If server entries appear before any other section header (like `[options]`), the `[servers]` header itself can be omitted.**
*   The `[options]` section allows setting default values for most command-line options.

**Configuration Precedence:**

Settings are applied in the following order, with later settings overriding earlier ones:

1.  Script Defaults (hardcoded in `multi-ssh`).
2.  Configuration File (`servers.conf` or specified by `--config`).
3.  Command-Line Arguments (e.g., `--ssh-user`, `--syncronize-panes`).

## How it Works

Technically, the `multi-ssh` script performs the following steps when establishing connections (not using `kill`, `copy`, or `completion`):

1.  **Configuration Loading:** It first parses the configuration file (`servers.conf` by default, or specified via `--config`) to load the server list and default options.
2.  **Argument Parsing:** It then parses command-line arguments, which override any settings loaded from the configuration file.
3.  **Local Session Management:** It creates (or replaces if it exists) a local `tmux` session (name determined by CLI > config > default). This session acts as the control center on your local machine.
4.  **Server Processing:** It iterates through the list of servers obtained from the configuration file.
5.  **Local Window/Pane Setup:** For each server:
    *   **Default Mode:** It creates a new `tmux` *window* within the local session.
    *   **Sync Mode (`--syncronize-panes`):** It creates a new `tmux` *pane* within the first window of the local session. Pane synchronization is then enabled for this window.
6.  **SSH Connection:** It initiates an SSH connection to the server within the corresponding local window/pane. SSH options (user, key) are determined by CLI > config > defaults. The `-t` flag is used to allocate a pseudo-terminal.
7.  **Remote User Switching (Optional):** If a remote user is specified (CLI > config), the script sends `sudo su <username>` and `cd ~` after the SSH connection.
8.  **Remote Session Handling:** It sends a command to the remote server to create or attach to a remote `tmux` session (name determined by CLI > config > default).
9.  **Command Execution (Optional):** If `send-keys` or `exec` is used:
    *   If a command was provided on the command line (`exec 'uptime'`), that command is sent.
    *   If no command was provided (`exec`), the server-specific command from the `[servers]` section of the config file is sent (if one exists for that server).
    *   `exec` also sends an Enter keypress.
10. **Local Attachment:** Finally, the script attaches your terminal to the created local `tmux` session.

The `kill` command connects briefly to send a `tmux kill-session` command remotely before terminating the local session. The `copy` command uses `rsync` directly with appropriate SSH parameters for file transfers, using the server list from the config file.

## Bash Completion

The script supports bash completion to help with options and commands.

1.  Source the completion script in your shell environment. You can get the path to the completion script using:
    ```bash
    ./multi-ssh completion
    # Example output: /path/to/multi-ssh-completion.bash
    ```
2.  Add the following line to your `~/.bashrc` or `~/.bash_profile`, replacing the path with the actual output from the command above:
    ```bash
    source /path/to/multi-ssh-completion.bash
    ```
3.  Reload your shell configuration (`source ~/.bashrc`) or open a new terminal.

## Contributing

Contributions, issues, and feature requests are welcome.

## License

This project is open source. Please feel free to use, modify, and distribute it. (Consider adding a specific license like MIT if desired).