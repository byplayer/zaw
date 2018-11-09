# zaw source for todoist
# https://github.com/sachaos/todoist.git

function zaw-src-todoist() {
  local item_list="$(todoist --header --namespace list)"
  title="${${(f)item_list}[1]}"
  items="$(echo $item_list|sed '1d')"
  id_list="$(echo $items| awk '{print $1}')"
  : ${(A)candidates::=${(f)id_list}}
  : ${(A)cand_descriptions::=${(f)items}}
  actions=(zaw-src-todoist-show zaw-src-todoist-close zaw-src-todoist-delete)
  act_descriptions=("show" "close" "delete")
  src_opts=(-t "$title")
}

function zaw-src-todoist-show () {
  BUFFER="todoist show $1"
  zle accept-line
}

function zaw-src-todoist-close () {
  BUFFER="todoist close $1"
  zle accept-line
}

function zaw-src-todoist-delete () {
  BUFFER="todoist delete $1"
  zle accept-line
}

zaw-register-src -n todoist zaw-src-todoist
