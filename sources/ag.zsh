#
# zaw-src-ag
#
# search using ag and open file
#

zmodload zsh/parameter

if (( $+commands[ag] )); then
    AG_COMMAND="ag"
else
    # ag not found
    return
fi

autoload -U read-from-minibuffer

function zaw-src-ag() {
    local buf
    read-from-minibuffer "${AG_COMMAND} "
    buf=$(${AG_COMMAND} ${(Q@)${(z)REPLY}})
    if [[ $? != 0 ]]; then
        return 1
    fi
    : ${(A)candidates::=${(f)buf}}
    : ${(A)cand_descriptions::=${(f)buf}}
    actions=(\
        zaw-src-ag-open-file \
    )
    act_descriptions=(\
        "Open" \
    )
}

function zaw-src-ag-open-file() {
    local filename=${1%%:*}
    local line=${${1#*:}%%:*}
    if [[ -z $ZAW_EDITOR_JUMP_PARAM ]]; then
        ZAW_EDITOR_JUMP_PARAM="+%LINE% %FILE%"
    fi
    BUFFER="${ZAW_EDITOR} ${${ZAW_EDITOR_JUMP_PARAM/\%LINE\%/$line}/\%FILE\%/$filename}"
    zle accept-line
}

zaw-register-src -n ag zaw-src-ag
