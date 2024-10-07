#!/usr/bin/sh

this_script=${0##*/}

this=$(realpath $0)
this_dir=${this%/*}

tmp=true
random=false
choose=false
dry=false
write=false
raw=false
theme=''

if [[ -z $TMUX ]]; then
  in_tmux=false
else
  in_tmux=true
fi

case $1 in
  '--help'|'-h')
    echo "Usage: ${this_script} [OPTIONS...] [THEME]"
    echo "Description: Applies or tests a base16 theme from base16-shell"
    echo "Options:
  -t: don't set TMP
  -w: write source file
  -k: dry: don't apply
  -r: restore from TMP (from -t absent)
  -R: restore from TMP raw (from -w present)
  -f: choose from fzf
  -c: choose random"
    exit 0 ;;
esac

for arg in $@; do
  case $arg in
    '-t') tmp=false ;;
    '-k') dry=true ;;
    '-r') theme="$(cat /tmp/.tt 2>/dev/null)" ;;
    '-R') raw=true; dry=true; tmp=false ;;
    '-f') choose=true ;;
    '-w') write=true ;;
    '-c') random=true ;;
    *) theme="$arg" ;;
  esac
done

if $random; then
  theme=$(cd "${this_dir}/scripts"
          find . -maxdepth 1 -type f | shuf -n1 | sed 's!./base16-!!;s!\.sh$!!')
elif $choose; then
  $in_tmux && fzfc_opts='--tmux' || fzfc_opts=''

  theme=$(cd "${this_dir}/scripts"
          find . -maxdepth 1 -type f |  sed 's!./base16-!!;s!\.sh$!!'|\
          fzfc --prompt "Choose theme: " --height=-100% $fzfc_opts)

  [[ -z $theme ]] && exit 0
fi

if $raw; then
  if [[ ! -r /tmp/.tt.txt ]]; then
    echo "[ !! ] Raw theme doesn't exist or is unreadable"
    exit 1
  fi

  cat /tmp/.tt.txt

  exit 0
elif [[ -z $theme ]]; then
  echo "[ !! ] Missing theme. See \`--help'"
  exit 1
elif [[ ! -f "${this_dir}/scripts/base16-${theme}.sh" ]]; then
  echo "[ !! ] Theme doesn't exist"
  exit 1
fi

if $tmp; then
  echo "$theme" > /tmp/.tt
fi

# TODO: handle some other terminals (fbterm, ...)

# NOTE: each `.sh' file had its output based on `TERM', so we have to set it
# as an envvar (maybe we could add cmdline option for that instead?)
unset ITERM_SESSION_ID
unset TMUX

if $write; then
  source "${this_dir}/scripts/base16-${theme}.sh" > /tmp/.tt.txt

  if ! $dry; then
    cat /tmp/.tt.txt
  fi
elif ! $dry; then
  source "${this_dir}/scripts/base16-${theme}.sh"
fi
