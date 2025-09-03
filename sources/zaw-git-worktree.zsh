# zaw source for git worktree

function zaw-src-git-worktree() {
    git rev-parse --git-dir >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        local worktree_list="$(git worktree list --porcelain)"
        if [[ -n "$worktree_list" ]]; then
            # Parse git worktree list --porcelain output
            # Format: worktree <path>\nHEAD <commit>\nbranch <branch>\n\n
            local -a worktrees paths branches commits descriptions
            local current_path current_commit current_branch

            while IFS= read -r line; do
                case "$line" in
                    worktree\ *)
                        current_path="${line#worktree }"
                        ;;
                    HEAD\ *)
                        current_commit="${line#HEAD }"
                        ;;
                    branch\ *)
                        current_branch="${line#branch refs/heads/}"
                        ;;
                    "")
                        if [[ -n "$current_path" ]]; then
                            local dir_name="${current_path:t}"  # Get last directory name
                            worktrees+=("$current_path")
                            paths+=("$current_path")
                            commits+=("$current_commit")
                            if [[ -n "$current_branch" ]]; then
                                branches+=("$current_branch")
                                descriptions+=("$dir_name [$current_branch] ${current_commit:0:8}")
                            else
                                branches+=("(detached)")
                                descriptions+=("$dir_name [(detached)] ${current_commit:0:8}")
                            fi
                        fi
                        current_path=""
                        current_commit=""
                        current_branch=""
                        ;;
                esac
            done <<< "$worktree_list"

            # Add the last worktree if the output doesn't end with empty line
            if [[ -n "$current_path" ]]; then
                local dir_name="${current_path:t}"  # Get last directory name
                worktrees+=("$current_path")
                paths+=("$current_path")
                commits+=("$current_commit")
                if [[ -n "$current_branch" ]]; then
                    branches+=("$current_branch")
                    descriptions+=("$dir_name [$current_branch] ${current_commit:0:8}")
                else
                    branches+=("(detached)")
                    descriptions+=("$dir_name [(detached)] ${current_commit:0:8}")
                fi
            fi

            : ${(A)candidates::=$worktrees}
            : ${(A)cand_descriptions::=$descriptions}
        fi
    fi

    actions=( \
        zaw-src-git-worktree-select \
        zaw-src-git-worktree-delete-branch \
        zaw-src-git-worktree-delete \
        zaw-callback-append-to-buffer)
    act_descriptions=( \
        "select worktree" \
        "delete branch and worktree" \
        "delete worktree" \
        "append to edit buffer")
    src_opts=()
}

function zaw-src-git-worktree-select() {
    local worktree_path="$1"
    if [[ -d "$worktree_path" ]]; then
        BUFFER="cd '$worktree_path'"
        zle accept-line
    else
        echo "Worktree path not found: $worktree_path"
    fi
}

function _zaw-validate-worktree() {
    local worktree_path="$1"

    local current_worktree="$(git rev-parse --show-toplevel 2>/dev/null)"

    if [[ "$worktree_path" == "$current_worktree" ]]; then
        echo "Cannot delete current worktree: $worktree_path"
        return 1
    fi

    if [[ ! -d "$worktree_path" ]]; then
        echo "Worktree path not found: $worktree_path"
        return 1
    fi

    if ! git -C "$worktree_path" diff --quiet HEAD 2>/dev/null || ! git -C "$worktree_path" diff --quiet --cached 2>/dev/null; then
        echo "Error: Uncommitted changes found in worktree: $worktree_path"
        return 1
    fi

    if [[ -n "$(git -C "$worktree_path" ls-files --others --exclude-standard 2>/dev/null)" ]]; then
        echo "Error: Untracked files found in worktree: $worktree_path"
        return 1
    fi

    return 0
}

function zaw-src-git-worktree-delete() {
    local worktree_path="$1"

    if _zaw-validate-worktree "$worktree_path"; then
        BUFFER="git worktree remove -f '$worktree_path'"
        zle accept-line
    fi
}

function zaw-src-git-worktree-delete-branch() {
    local worktree_path="$1"

    if _zaw-validate-worktree "$worktree_path"; then
        local branch_name="$(git -C "$worktree_path" branch --show-current 2>/dev/null)"

        if [[ -n "$branch_name" ]]; then
            BUFFER="git worktree remove -f '$worktree_path' && git branch -d '$branch_name'"
        else
            BUFFER="git worktree remove -f '$worktree_path'"
        fi
        zle accept-line
    fi
}

zaw-register-src -n git-worktree zaw-src-git-worktree
