## multi-ssh

`multi-ssh` is a command-line utility designed to simplify the management of simultaneous SSH connections to multiple remote servers. It leverages `tmux` to create organized sessions, allowing you to interact with servers in separate panes within a single window or in individual windows per server. Features include synchronized input across panes, executing commands on all servers, copying files using `rsync`, and customizable configurations via a config file.

[![Click here for a demo](https://asciinema.org/a/grO4CnvXiJPOWDfXJAbQ8TRts.svg)](https://asciinema.org/a/grO4CnvXiJPOWDfXJAbQ8TRts)

## Usage

```bash
multi-ssh [OPTIONS] [COMMAND] [ARGS...]
```

**Basic Connection:**

```bash
# Connect to servers listed in ./servers.conf
./multi-ssh

# Use a different configuration file
./multi-ssh --config ~/my_servers.conf
```

**Options:**

*   `--help`: Display the help message.
*   `completion`: Output the completion function

**Layout & Session Options:**

*   `--layout <pane|window>`: Specify layout: `pane` (default, one window, multiple panes) or `window` (one window per server).
*   `--syncronize-panes`: Enable synchronized input across panes (only valid with `--layout pane`, which is the default layout).
*   `--session <name>`: Set both the local and remote `tmux` session names simultaneously. Overridden by `--local-session` and `--remote-session` if they are also provided.
*   `--local-session <name>`: Set the local `tmux` session name (default: `multi-ssh`).
*   `--remote-session <name>`: Set the remote `tmux` session name (default: `remote-session`).

**Connection Options:**

*   `--remote-user <username>`: Switch to `<username>` using `sudo su` after connecting remotely.
*   `--ssh-user <username>`: Use `<username>` for the SSH connection.
*   `--ssh-key <keyfile>`: Use the specified private key file for SSH authentication.
*   `--config <path>`: Path to the server configuration file (default: `./servers.conf`).
*   `--servers <host1,...>`: Comma-separated list of specific servers to connect to. If provided, only these servers will be used, overriding/filtering the list in `servers.conf`. Servers not found in the config file will be included without a default command.
*   `--initial-workdir <path>`: Change to this directory on remote hosts *after* connecting (and potentially switching user with `sudo su`) but *before* starting/attaching the remote `tmux` session. If not provided, the default behavior is maintained (no `cd` unless `--remote-user` is used, in which case it defaults to the remote user's home `~`).

**In-Session Commands:**

*   **Toggle Pane Synchronization:** While in a `pane` layout session, press `Prefix + S` (e.g., `Ctrl+B` then `Shift+S`) to toggle the `synchronize-panes` option on or off for the current window.
*   **Toggle Layout:** Press `Prefix + L` (e.g., `Ctrl+B` then `L`) to attempt switching between the 'pane' layout (one window, multiple panes) and the 'window' layout (one window per server). This feature is experimental.

**Commands:**

*   `send-keys [command]`: Sends the specified `command` string to all remote sessions without pressing Enter. If `command` is omitted, sends the server-specific command from the `[servers]` section of the config file (if defined).
*   `exec [command]`: Executes the specified `command` on all remote sessions (sends the command followed by Enter). If `command` is omitted, executes the server-specific command from the `[servers]` section of the config file (if defined).
*   `kill`: Kills the remote `tmux` sessions and the local `multi-ssh` session.
*   `copy [remote:|]:path [remote:|]:path`: Copy files between local and remote using rsync.
*   `toggle-layout`: (Internal command used by keybinding) Toggles between pane and window layouts in an active session.

**Examples:**

```bash
# Connect normally (using ./servers.conf, default pane layout)
./multi-ssh

# Connect with synchronized panes (pane layout is default)
./multi-ssh --syncronize-panes

# Connect using the window layout (one window per server)
./multi-ssh --layout window

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

# Connect only to specific servers, overriding the config list
./multi-ssh --servers server1.example.com,192.168.1.10
```

## Configuration File (`servers.conf`)

A configuration file can be used (default: `./servers.conf`).

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
# layout = window          # Use 'pane' or 'window'
# initial-workdir = /srv/app # Change to this dir on remote hosts

[include]
# Include other configuration files recursively.
# Paths can be absolute or relative to the *current* file's directory.
# Useful for sharing common settings or server lists.
# Example:
# /etc/multi-ssh/global_options.conf
# ../shared/common_servers.conf
# project_specific_dev.conf

# Alternatively, you can explicitly use the [servers] header:
# [servers]
# server3.example.com
# server4.example.com
```

*   Lines starting with `#` or `;` are ignored as comments.
*   Empty lines are ignored.
*   The `[servers]` section lists target hosts, optionally followed by a default command for that host. **If server entries appear before any other section header (like `[options]` or `[include]`), the `[servers]` header itself can be omitted.**
*   The `[options]` section allows setting default values for most command-line options. Options are applied in the order they are encountered, potentially being overridden by later options in the same file or an including file, and finally by command-line arguments.
*   The `[include]` section allows specifying other configuration files to load. Paths are interpreted relative to the file containing the `[include]` directive, unless they are absolute paths. Files are parsed recursively, and a mechanism prevents infinite loops caused by circular includes. Settings from included files are loaded as if they were pasted into the including file at the location of the include directive.

**Configuration Precedence:**

Settings are applied in the following order, with later settings overriding earlier ones:

1.  Script Defaults (hardcoded in `multi-ssh`).
2.  Configuration Files: Settings are loaded sequentially. When a file is included, its contents are processed immediately before continuing with the rest of the including file. Therefore, settings within an included file are applied, then settings *after* the include directive in the parent file are applied (potentially overriding the included settings).
3.  Command-Line Arguments (e.g., `--ssh-user`, `--syncronize-panes`).

## How it Works

Technically, the `multi-ssh` script performs the following steps when establishing connections (not using `kill`, `copy`, or `completion`):

1.  **Configuration Loading:** It first parses the configuration file (`servers.conf` by default, or specified via `--config`) to load the server list and default options. If `--servers` is provided, the server list from the config file is filtered based on this argument.
2.  **Argument Parsing:** It then parses command-line arguments, which override any settings loaded from the configuration file.
3.  **Local Session Management:** It creates (or replaces if it exists) a local `tmux` session (name determined by CLI > config > default). This session acts as the control center on your local machine.
4.  **Server Processing:** It iterates through the final list of servers (either all from config or filtered by `--servers`).
5.  **Local Window/Pane Setup:** For each server:
    *   **Default Mode (`--layout pane`):** It creates a new `tmux` *pane* within the first window (`window 0`) of the local session. If `--syncronize-panes` is also specified, pane synchronization is enabled for this window.
    *   **Window Mode (`--layout window`):** It creates a new `tmux` *window* within the local session. `--syncronize-panes` is not compatible with this mode.
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

1.  Add the following line to your `~/.bashrc` or `~/.bash_profile` (make sure to replace `/path/to/multi-ssh` with the actual path to your script):
    ```bash
    source <(/path/to/multi-ssh completion)
    ```
    This command executes `multi-ssh completion`, which now outputs the completion script directly, and sources its output.
2.  Reload your shell configuration (`source ~/.bashrc`) or open a new terminal.

## A Powerful Alternative to pssh and clusterssh

While tools like `pssh` excel at parallel non-interactive command execution and `clusterssh` provides synchronized input across multiple graphical terminal windows, `multi-ssh` offers a compelling alternative by deeply integrating with `tmux`.

This approach provides several advantages:

*   **Unified Terminal Interface:** Manages all connections within a single, familiar `tmux` session, avoiding window clutter.
*   **Flexible Layouts:** Easily switch between viewing servers in panes (for side-by-side comparison or synchronized input) or dedicated windows within the same `tmux` session.
*   **Remote Session Persistence:** Actively manages `tmux` sessions on the remote servers, allowing you to detach and re-attach without losing your work state.
*   **Integrated Workflow:** Combines interactive sessions with powerful command-line execution (`exec`, `send-keys`), file transfer (`copy`), and session management (`kill`) capabilities.
*   **Rich Configuration:** Define server groups, default commands per server, and connection parameters easily.
*   **Terminal-Native:** Operates entirely within the terminal, requiring no graphical environment.

If you are comfortable with `tmux` and seek a powerful, flexible, and session-oriented way to manage multiple servers interactively and programmatically, `multi-ssh` provides a robust solution.

## Comparison with Similar Tools

| Feature             | multi-ssh                      | pssh (parallel-ssh)           | clusterssh (cssh)                |
| :------------------ | :----------------------------- | :---------------------------- | :------------------------------- |
| **Paradigm**        | `tmux`-based session manager   | Parallel command executor     | Multi-window manager             |
| **Interface**       | Single `tmux` session          | Command-line (non-interactive)| Multiple `xterm` windows + Console |
| **Interaction**     | Interactive (within `tmux`)    | Non-interactive               | Interactive (console sync)       |
| **Synchronization** | `tmux synchronize-panes`       | N/A (Parallel execution)      | Master console input broadcast   |
| **Layout**          | Panes or Windows (toggleable)  | N/A                           | Separate graphical windows       |
| **Remote Session**  | Manages remote `tmux` sessions | No                            | No                               |
| **Built-in Copy**   | Yes (`rsync`)                  | Yes (`pscp`/`prsync`)         | No (Manual `scp`/`rsync`)        |
| **Built-in Kill**   | Yes (Remote `tmux kill`)       | Yes (`pnuke`)                 | No (Manual `kill`)               |
| **Configuration**   | Config file + CLI                 | Host file + CLI               | Config file + CLI                |
| **Dependencies**    | `bash`, `tmux`, `ssh`, `rsync` | `python`, `ssh`               | `perl`, `ssh`, X11, `xterm`      |
| **Primary Use Case**| Interactive `tmux` multi-admin | Batch command execution       | Graphical interactive multi-admin|

## Contributing

Contributions, issues, and feature requests are welcome.

## License

This project is open source under the MIT license. Please feel free to use, modify, and distribute it.
