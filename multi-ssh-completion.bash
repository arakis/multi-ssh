#!/bin/bash

_multi_ssh_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--syncronize-panes --send-keys --exec"

    # Handle all cases
    case "$prev" in
        --send-keys|--exec)
            # No specific completion for command arguments
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