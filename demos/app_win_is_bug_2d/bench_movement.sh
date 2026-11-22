#!/bin/sh
# Time the no-win movement proof on a 120 x 80 board.
set -eu
demo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
trap 'exit 1' HUP INT TERM

# Preserve the starting position and enlarge only the map dimensions.
sed -e '/^def map_w()/{n;s/12n/120n/;}' -e '/^def map_h()/{n;s/8n/80n/;}' "$demo/main.bend" > "$scratch/main.bend"
cp "$demo/BOARD.bend" "$scratch/"
sed '/^law never_on_flag:/,$d' "$demo/LAWS.bend" > "$scratch/LAWS.bend"

# Keep the move invariant and its proof. The rendered-board law and its
# helpers are a separate workload. The proof uses inclusive board bounds.
sed -e '/^def fchk(/,/^def off_flag(/{ /^def off_flag(/!d; }' \
    -e '/^def Laws.never_on_flag(/,$d' \
    -e 's/11n/119n/g; s/7n/79n/g' \
    "$demo/PROOF.bend" > "$scratch/PROOF.bend"

if [ "$#" -eq 0 ]; then set -- bend; fi
time "$@" "$scratch/PROOF.bend"
