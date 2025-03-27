#!/bin/bash

_multi_ssh_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Group options in a more meaningful order
    # Help and info options, main commands, session options, connection options
    opts="--help --syncronize-panes kill copy send-keys exec --session --local-session --remote-session --remote-user --ssh-user --ssh-key --config --servers --layout --initial-workdir completion"

    # Check if we're completing a copy operation anywhere in the command
    local i
    local copy_mode=0
    for ((i=1; i<COMP_CWORD; i++)); do
        if [[ "${COMP_WORDS[i]}" == "copy" ]]; then
            copy_mode=1
            break
        fi
    done

    # Handle all cases
    if [[ $copy_mode -eq 1 && $COMP_CWORD -gt $((i+1)) ]]; then
        # We're completing the second part (destination) of a copy operation
        if [[ ${cur} == *:* ]]; then
            # Split at the colon
            local remote_part="${cur%%:*}"
            local local_part="${cur#*:}"
            
            # Complete the local part but preserve the remote part
            local completions=($(compgen -f -- "${local_part}"))
            COMPREPLY=()
            for comp in "${completions[@]}"; do
                COMPREPLY+=("${remote_part}:${comp}")
            done
        else
            # Add "remote:" as a completion option along with standard file completion
            local completions=($(compgen -f -- "${cur}"))
            
            # Only add remote: as an option if it matches the current prefix
            if [[ "remote:" =~ ^"${cur}" ]]; then
                completions+=("remote:")
            fi
            
            COMPREPLY=("${completions[@]}")
        fi
        return 0
    fi

    # First check if we're at the start of the command (first argument after multi-ssh)
    if [[ $COMP_CWORD -eq 1 ]]; then
        # We're at the first argument, suggest all available options
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    # Handle completion for options that take arguments
    case "$prev" in
        --local-session|--remote-session|--remote-user|--ssh-user)
            # No specific suggestions, default completion (e.g., usernames) might apply
            return 0
            ;;
        --ssh-key|--config|--initial-workdir)
            # Suggest files/directories
            _filedir # Use bash-completion's file/dir helper
            return 0
            ;;
        --servers)
            # No specific suggestions for server list
            return 0
            ;;
        --layout)
            # Suggest layout modes
            COMPREPLY=($(compgen -W "pane window" -- ${cur}))
            return 0
            ;;
        send-keys|exec)
            # No specific suggestions for commands
            return 0
            ;;
        copy)
             # Suggest files/directories or "remote:" for the first copy argument
            if [[ "remote:" == "${cur}"* ]]; then
                 COMPREPLY=($(compgen -f -P "remote:" -- ${cur#remote:}) $(compgen -f -- ${cur}) "remote:")
            else
                 COMPREPLY=($(compgen -f -- ${cur}) "remote:")
            fi
            _filedir # Use bash-completion's file/dir helper
            # Add remote: back if it was filtered out by _filedir
            if [[ "remote:" == "${cur}"* ]] && ! [[ " ${COMPREPLY[@]} " =~ " remote: " ]]; then
                 COMPREPLY+=("remote:")
            fi
            return 0
            ;;
    esac

    # If the previous word was not an option that takes an argument,
    # suggest options or main commands.
    if [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    else
        # Suggest main commands if not starting with '-' (completion is usually first)
        local commands="send-keys exec kill copy"
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
    fi

    return 0
}

complete -F _multi_ssh_completion multi-ssh 