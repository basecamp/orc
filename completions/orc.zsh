if [[ ! -o interactive ]]; then
    return
fi

compctl -K _orc orc

_orc() {
  local word words completions
  read -cA words
  word="${words[2]}"

  if [ "${#words}" -eq 2 ]; then
    completions="$(orc commands)"
  else
    completions="$(orc completions "${word}")"
  fi

  reply=("${(ps:\n:)completions}")
}
