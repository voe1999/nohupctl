#!/bin/sh
# Installs nohup-web, Nohup's page for a browser that can't run the app
# (Safari on an old iPad), on the computer whose agents it shows:
#
#   curl -fsSL https://nohup.carywang.workers.dev/web.sh | sh
#
# It needs nohupctl there already (its gateway is what the page reads).
# The build for this machine comes from the release NOHUP_WEB_RELEASE_URL
# names (tests point it at a local directory), checked against its checksums, and lands in
# ~/.local/share/nohup-web with a link in ~/.local/bin. Then it runs at
# login and prints the link that pairs a browser. `nohup-web uninstall`
# stops it; deleting the folder removes it.
set -eu

release="${NOHUP_WEB_RELEASE_URL:-https://github.com/voe1999/nohupctl/releases/download/nohup-web}"
home="${HOME:?}"
dir="$home/.local/share/nohup-web"
link="$home/.local/bin/nohup-web"

case "$(uname -s) $(uname -m)" in
    Darwin*) asset=nohup-web-darwin-universal.tar.gz ;;
    "Linux x86_64"|"Linux amd64") asset=nohup-web-linux-x86_64.tar.gz ;;
    "Linux aarch64"|"Linux arm64") asset=nohup-web-linux-aarch64.tar.gz ;;
    *) echo "nohup-web: there is no build for $(uname -sm) yet." >&2; exit 1 ;;
esac

[ -x "$home/.local/share/nohup/bin/nohupctl" ] || command -v nohupctl >/dev/null 2>&1 || {
    echo "nohup-web: install nohupctl first: curl -fsSL https://nohup.carywang.workers.dev/install.sh | sh" >&2
    exit 1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/checksums.txt" "$release/nohup-web-checksums.txt" || { echo "nohup-web: couldn't reach $release." >&2; exit 1; }
expected=$(grep " $asset\$" "$tmp/checksums.txt" | cut -d' ' -f1)
[ -n "$expected" ] || { echo "nohup-web: the release has no $asset." >&2; exit 1; }
echo "nohup-web: downloading ${asset}…"
curl -fsSL -o "$tmp/$asset" "$release/$asset"
actual=$( { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$tmp/$asset"; else sha256sum "$tmp/$asset"; fi; } | cut -d' ' -f1)
[ "$actual" = "$expected" ] || { echo "nohup-web: $asset doesn't match the checksums." >&2; exit 1; }

umask 077
tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$(dirname "$dir")"
rm -rf "$dir.old"
[ -d "$dir" ] && mv "$dir" "$dir.old"
mv "$tmp/nohup-web" "$dir"
rm -rf "$dir.old"
chmod 755 "$dir" "$dir/nohup-web"
mkdir -p "$home/.local/bin"
ln -sfn "$dir/nohup-web" "$link"

# NOHUP_WEB_NO_SERVICE=1 installs without running it at login (tests).
if [ "${NOHUP_WEB_NO_SERVICE:-}" = "" ]; then "$dir/nohup-web" install; fi
echo
"$dir/nohup-web" pair
