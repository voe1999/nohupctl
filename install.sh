#!/bin/sh
# Installs nohupctl on this machine and shows a pairing
# code for the Nohup app:
#
#   curl -fsSL https://nohup.carywang.workers.dev/install.sh | sh
#
# The release build for this machine comes from github.com/voe1999/nohupctl
# (releases only), checked against the release's checksums.txt, and lands
# in ~/.local/share/nohup/bin with a link in ~/.local/bin. The Nohup app
# keeps it up to date once it has connected. Set NOHUP_NO_PAIR=1 to install
# without showing the code; NOHUP_RELEASE_URL overrides where the files
# come from (tests point it at a local directory).
set -eu

release="${NOHUP_RELEASE_URL:-https://github.com/voe1999/nohupctl/releases/latest/download}"
home="${HOME:?}"
dir="$home/.local/share/nohup/bin"
bin="$dir/nohupctl"
link="$home/.local/bin/nohupctl"

case "$(uname -s) $(uname -m)" in
    Darwin*) asset=nohupctl-darwin-universal.gz ;;
    "Linux x86_64"|"Linux amd64") asset=nohupctl-linux-x86_64.gz ;;
    "Linux aarch64"|"Linux arm64") asset=nohupctl-linux-aarch64.gz ;;
    *) echo "nohup: there is no build of nohupctl for $(uname -sm) yet." >&2; exit 1 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/checksums.txt" "$release/checksums.txt" || { echo "nohup: couldn't reach $release." >&2; exit 1; }
expected=$(grep " $asset\$" "$tmp/checksums.txt" | cut -d' ' -f1)
[ -n "$expected" ] || { echo "nohup: the latest release has no $asset yet." >&2; exit 1; }

# Already this build (the app installs the same one): nothing to download.
# Releases are tagged v<version>.<build>, "v1.0.58" for nohupctl 1.0 (58).
latest=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$release/checksums.txt" 2>/dev/null | sed -n 's|.*/v\([0-9.]*\)/.*|\1|p')
# `version` prints {"build":58,…,"version":"1.0"}: "1.0.58" for the tag, "1.0 (58)" to say.
said() { "$bin" version 2>/dev/null; }
build_of() { sed -n 's/.*"build":\([0-9]*\).*/\1/p'; }
version_of() { sed -n 's/.*"version":"\([^"]*\)".*/\1/p'; }
current=""
if [ -x "$bin" ]; then
    current="$(said | version_of)"
    b="$(said | build_of)"; [ -n "$b" ] && current="$current.$b"
fi
if [ -z "$latest" ] || [ "$current" != "$latest" ]; then
    echo "nohup: downloading nohupctl ($asset)…"
    curl -fsSL -o "$tmp/$asset" "$release/$asset"
    actual=$( { if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$tmp/$asset"; else sha256sum "$tmp/$asset"; fi; } | cut -d' ' -f1)
    [ "$actual" = "$expected" ] || { echo "nohup: $asset doesn't match checksums.txt." >&2; exit 1; }
    umask 077
    mkdir -p "$dir"
    gunzip -c "$tmp/$asset" > "$bin.new"
    chmod 755 "$bin.new"
    mv -f "$bin.new" "$bin"
fi
mkdir -p "$home/.local/bin"
ln -sfn "$bin" "$link"
"$bin" postinstall >/dev/null 2>&1 || true
"$bin" setup >/dev/null 2>&1 || true
b="$(said | build_of)"
echo "nohup: installed nohupctl $(said | version_of)${b:+ ($b)} at $bin"
case ":${PATH:-}:" in
    *":$home/.local/bin:"*) ;;
    *) echo "nohup: add ~/.local/bin to your PATH to run nohupctl by name." ;;
esac

[ "${NOHUP_NO_PAIR:-}" = "" ] || exit 0
if [ "$(uname -s)" = Darwin ] && ! "$bin" doctor --json 2>/dev/null | grep -q '"remoteLogin":true'; then
    echo "nohup: Remote Login is off. Turn it on in System Settings → General → Sharing → Remote Login, then run: nohupctl pair"
    exit 0
fi
# stdin is the pipe this script came through; the pane takes its keys from the terminal.
[ -t 1 ] || { echo "nohup: no terminal here; run nohupctl pair from one."; exit 0; }
exec "$bin" pair </dev/tty
