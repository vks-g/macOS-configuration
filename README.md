# macOS-configuration

A Catppuccin Mocha setup for macOS: tiling windows with **AeroSpace**, a floating-pill **SketchyBar**, and a translucent **Ghostty**. It's a port of my Arch Linux / Hyprland rice ([ArchLinux-configuration](https://github.com/vks-g/ArchLinux-configuration)) to the Mac, and it keeps System Integrity Protection **on**.

<!-- screenshots -->

## What's inside

| Config | What it does |
| --- | --- |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) · `config/aerospace` | i3-style tiling with 8pt gaps. New windows auto-split like Hyprland's dwindle layout. Apps are pinned to workspaces, and ⌥ is the modifier. |
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) · `config/sketchybar` | Menu-bar replacement laid out around the notch. Details below. |
| [Ghostty](https://ghostty.org) · `config/ghostty` | Catppuccin Mocha, 85% opacity with blur, hidden title bar, JetBrainsMono Nerd Font. |
| [Starship](https://starship.rs) · `config/starship.toml` | Shell prompt. |
| tmux · `home/.tmux.conf` | Catppuccin tmux with TPM, vi keys and mouse support. |
| btop · `config/btop` | btop settings. |
| neofetch · `config/neofetch` | neofetch settings. |
| `zsh/mac-rice.zsh` | Two aliases, `aero-off` and `aero-on`, to quit and restart AeroSpace. Handy before exam or proctoring apps that don't get along with it. |

The bar, from left to right:

1. Workspace pills.
2. A keep-awake toggle.
3. CPU, RAM (used/total) and CPU temperature.
4. The clock, beside the notch.
5. Spotify now-playing, with previous/play/next controls.
6. Wi-Fi and Bluetooth names, volume, battery and a Control Center button.

Long names scroll continuously at the same speed. Every gap between pills is exactly 8pt.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/vks-g/macOS-configuration/main/install.sh | bash
```

The installer clones this repo to `~/.local/share/macOS-configuration`. It asks before each optional step, and when there's no terminal to ask in, it uses the safe default.

| Step | Default |
| --- | --- |
| Install the missing apps and tools with Homebrew (AeroSpace, SketchyBar, Ghostty, JetBrainsMono Nerd Font, jq, macmon, blueutil, starship, tmux, btop, neofetch) | yes |
| Link the configs (see below) | always |
| Add one `source` line to `~/.zshrc` for the aliases | yes |
| Build the small scroll helper for SketchyBar (needs `clang`) | always, if clang exists |
| Install the tmux plugin manager | yes |
| Install the sudo rule for the keep-awake button (asks for your password) | **no** |
| Auto-hide the Dock and group windows by app | **no** |
| Start SketchyBar and AeroSpace | yes |

Options: add them after `| bash -s --`, or pass them to `./install.sh` in a clone.

- `--dry-run` shows every action and changes nothing. Worth running first.
- `--links-only` only links the configs: no Homebrew, no sudo, no system settings.
- `--yes` accepts all the defaults without asking.

### What it touches, and what it doesn't

- **Replaced with symlinks into the repo:** `~/.config/{aerospace,sketchybar,ghostty,btop,neofetch}`, `~/.config/starship.toml` and `~/.tmux.conf`.
- **Your existing versions are moved, never deleted,** to `~/.config-backups/macOS-configuration/<date-time>/`. A `manifest.tsv` in that folder records what came from where.
- **`~/.zshrc`** gets one line, marked `# macOS-configuration`. A copy of the old file is saved first.
- **Never touched:** `~/.claude`, `~/.ssh`, your git config, and everything else. Running the installer again is safe: links that already exist are left alone.

### After installing

- **Accessibility:** System Settings → Privacy & Security → Accessibility. Allow **AeroSpace**, and **sketchybar** if you want the Control Center button to work.
- **Hide the macOS menu bar:** System Settings → Control Center → "Automatically hide and show the menu bar" → **Always**, so SketchyBar takes its place.
- **Ghostty:** quit it completely (⌘Q) and reopen it. Its opacity and blur only load on a full restart.

## Keybindings (AeroSpace, ⌥ = Option)

| Keys | Action |
| --- | --- |
| ⌥ I / Q / W / E / R / T / Y · ⌥ 8 / 9 / 0 | Go to workspace 1–7 · 8–10 |
| ⌥ ⇧ + the same key | Move the window there and follow it |
| ⌥ H / J / K / L | Focus left / down / up / right |
| ⌥ ⌃ ← ↓ ↑ → | Move the window |
| ⌥ ⇧ ← ↓ ↑ → | Resize |
| ⌥ ↩ | New Ghostty window |
| ⌥ F / S / D / O | Arc / Spotify / Discord / Obsidian |
| ⌥ B | Close the window |
| ⌥ ⇧ F | Toggle floating |
| ⌥ / · ⌥ , | Tiles (flip direction) · Accordion |
| ⌥ ⇧ ; | Service mode: Esc reloads the config, R resets the layout, ⌥⇧ H/J/K/L joins windows |

Arc, Spotify, Discord and Obsidian open on workspaces 3, 4, 5 and 6. System Settings and Shottr always float.

## Privacy

Nothing in this setup sends data anywhere.

- **Stats:** CPU, RAM and temperature come from `macmon`, which reads the chip's sensors locally without sudo.
- **Wi-Fi name:** read with `ipconfig`, so no Location Services permission is needed.
- **Spotify:** the pill uses Spotify's own local notifications. Its buttons ask macOS once for permission to control Spotify.
- **Keep-awake:** the optional sudo rule allows exactly two commands, `pmset -a disablesleep 0` and `pmset -a disablesleep 1`, and nothing else.

## Uninstall

```sh
~/.local/share/macOS-configuration/uninstall.sh            # add --dry-run to preview
```

The uninstaller:
- removes only the symlinks that point into this repo,
- restores your newest backups, and
- removes the `~/.zshrc` line.

Homebrew packages, the sudo rule and the Dock settings stay as they are. The uninstaller prints the commands to remove those yourself.

## Notes

- **Requirements:** AeroSpace needs macOS 13 or later. `macmon`, used for the stats, is Apple Silicon only.
- **Notch:** the layout assumes a notched MacBook, with the clock left of the notch and Spotify right of it. On other displays those two pills simply sit around the centre.
- **Ghostty's second config file:** Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config`, and anything set there still applies on top of this config.

## Credits

[Catppuccin](https://catppuccin.com) · [AeroSpace](https://github.com/nikitabobko/AeroSpace) · [SketchyBar](https://github.com/FelixKratz/SketchyBar) · [Ghostty](https://ghostty.org) · [macmon](https://github.com/vladkens/macmon) · [Nerd Fonts](https://www.nerdfonts.com)
