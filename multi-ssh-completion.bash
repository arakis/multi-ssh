#!/bin/bash

_multi_ssh_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--syncronize-panes --send-keys --exec --local-session --remote-session --remote-user --ssh-user --ssh-key --completion"

    # Handle all cases
    case "$prev" in
        --local-session|--remote-session|--remote-user|--ssh-user|--ssh-key)
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