#!/bin/bash

_multi_ssh_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Group options in a more meaningful order
    # Help and info options, main commands, session options, connection options
    opts="--help completion send-keys exec kill copy --syncronize-panes --local-session --remote-session --remote-user --ssh-user --ssh-key --config --servers"

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

    case "$prev" in
        --ssh-key|--config)
            # Provide file completion for files
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        copy)
            # Check if we're dealing with a remote:local format
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
            ;;
        --local-session|--remote-session|--remote-user|--ssh-user)
            # These options expect an argument, don't complete anything
            return 0
            ;;
        --servers)
            return 0
            ;;
        send-keys|exec)
            # No specific completion for the command string itself
            return 0
            ;;
        *)
            # Complete with available options
            if [[ ${cur} == -* ]]; then
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                return 0
            fi
            
            # If we just completed a remote:path and are at a new argument position
            if [[ $copy_mode -eq 1 && $COMP_CWORD -eq $((i+2)) ]]; then
                # Provide file completion and remote: for the destination
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
            
            # If we reach here, suggest all available options that don't start with --
            # This ensures we suggest the verb commands like 'copy', 'kill', etc.
            local verb_opts=$(echo "${opts}" | tr ' ' '\n' | grep -v '^--' | tr '\n' ' ')
            COMPREPLY=( $(compgen -W "${verb_opts}" -- ${cur}) )
            return 0
            ;;
    esac
}

complete -F _multi_ssh_completion multi-ssh 