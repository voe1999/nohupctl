# nohupctl

The helper that [Nohup](https://github.com/voe1999/Nohup) runs on your Mac or server: it lists the agents in herdr and tmux, decides what your phone hears about, and pairs the phone. This repository holds only the release builds; the source lives with the app.

## Install and pair

On the Mac (Remote Login on: System Settings → General → Sharing), paste in Terminal:

```sh
curl -fsSL https://nohup.carywang.workers.dev/install.sh | sh
```

It installs `nohupctl` to `~/.local/share/nohup/bin` (linked from `~/.local/bin`) and shows a pairing code. In Nohup: **Add a host → Scan a pairing code**, and point the camera at it. That's the whole setup.

- `nohupctl doctor` says what's missing.
- `nohupctl pair` shows a new code any time; `nohupctl devices` lists and revokes phones.
- `nohupctl reset` takes Nohup off the machine.

With herdr, `herdr plugin install voe1999/Nohup/plugin` adds the action "Nohup: Pair a phone", which runs the same code.

The Nohup app keeps the helper up to date once it has connected. Builds: macOS universal (arm64 and x86_64), Linux x86_64 and aarch64. Each release's `checksums.txt` is what `install.sh` checks downloads against.
