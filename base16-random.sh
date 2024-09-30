#!/usr/bin/sh

this=$0
this_dir=${this%/*}

cd "${this_dir}/scripts"

find . -maxdepth 1 -type f | shuf -n1 | xargs -r ../base16-apply.sh
