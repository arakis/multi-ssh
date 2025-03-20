#!/bin/bash

_multi_ssh_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--syncronize-panes --send-keys --exec --local-session --remote-session --remote-user --ssh-user --ssh-key --completion --help"

    # Handle all cases
    case "$prev" in
        --ssh-key)
            # Provide file completion for SSH key files
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        --local-session|--remote-session|--remote-user|--ssh-user)
            # These options expect an argument, don't complete anything
            return 0
            ;;
        *)
            # Complete with available options
            if [[ ${cur} == -* ]]; then
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                return 0
            fi
            ;;
    esac
}

complete -F _multi_ssh_completion multi-ssh 