#!/usr/bin/env bash
# macOS-configuration installer
#
#   curl -fsSL https://raw.githubusercontent.com/vks-g/macOS-configuration/main/install.sh | bash
#
# Options (after `| bash -s --` when piping, or directly when run from a clone):
#   --yes          accept every default without asking (defaults never use sudo)
#   --links-only   only link the configs (+ zsh snippet, scroll helper); no brew,
#                  no system settings, no services
#   --dry-run      print what would happen, change nothing
#
# What it touches — and nothing else:
#   ~/.config/{aerospace,sketchybar,ghostty,btop,fastfetch,neofetch}, ~/.config/starship.toml,
#   ~/.tmux.conf     → replaced by symlinks into this repo (old ones are MOVED to a
#                      timestamped backup folder, never deleted)
#   ~/.zshrc         → one `source` line appended (a copy is backed up first)
# Only if you say yes: Homebrew packages, the keep-awake sudo rule, Dock settings.
# Never touched: ~/.claude, ~/.ssh, git config, or any other file.

main() {
  set -euo pipefail

  REPO_URL="https://github.com/vks-g/macOS-configuration.git"
  DEFAULT_DIR="$HOME/.local/share/macOS-configuration"
  BACKUP_ROOT="$HOME/.config-backups/macOS-configuration"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  BACKUP_DIR="$BACKUP_ROOT/$STAMP"
  ZSH_MARKER="# macOS-configuration"

  ASSUME_YES=0 LINKS_ONLY=0 DRY_RUN=0
  for arg in "$@"; do
    case "$arg" in
      -y|--yes)     ASSUME_YES=1 ;;
      --links-only) LINKS_ONLY=1 ;;
      --dry-run)    DRY_RUN=1 ;;
      -h|--help)    sed -n '2,20p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null || true; return 0 ;;
      *) err "Unknown option: $arg"; return 1 ;;
    esac
  done

  [ "$(uname -s)" = "Darwin" ] || { err "This installer is for macOS only."; return 1; }

  # source (in repo) : destination (relative to $HOME)
  LINKS=(
    "config/aerospace:.config/aerospace"
    "config/sketchybar:.config/sketchybar"
    "config/ghostty:.config/ghostty"
    "config/btop:.config/btop"
    "config/fastfetch:.config/fastfetch"
    "config/neofetch:.config/neofetch"
    "config/starship.toml:.config/starship.toml"
    "home/.tmux.conf:.tmux.conf"
  )

  [ "$DRY_RUN" = 1 ] && warn "Dry run: nothing will be changed."

  get_repo
  [ "$LINKS_ONLY" = 1 ] || install_packages
  link_configs
  add_zsh_snippet
  build_scroll_helper
  if [ "$LINKS_ONLY" = 0 ]; then
    setup_tmux_plugins
    setup_keep_awake_rule
    setup_dock
    start_services
  fi
  summary
}

# ───────────────────────── helpers ─────────────────────────
info() { printf '\033[34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m  %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m  %s\n' "$*"; }
err()  { printf '\033[31m✗\033[0m  %s\n' "$*" >&2; }

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi
}

# ask "Question?" y|n  → returns 0 for yes. Reads from the terminal even when the
# script itself is piped in; without a terminal (or with --yes) the default is used.
ask() {
  local question="$1" default="$2" reply hint
  [ "$default" = y ] && hint="[Y/n]" || hint="[y/N]"
  if [ "$ASSUME_YES" = 1 ] || ! { : </dev/tty; } 2>/dev/null; then
    reply="$default"
  else
    printf '\033[35m?\033[0m  %s %s ' "$question" "$hint" >/dev/tty
    read -r reply </dev/tty || reply=""
    reply="${reply:-$default}"
  fi
  case "$reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# ───────────────────────── steps ─────────────────────────
get_repo() {
  # Running from a clone? Use it. Otherwise clone (or update) the default copy.
  local self_dir=""
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  if [ -n "$self_dir" ] && [ -d "$self_dir/config/aerospace" ]; then
    REPO="$self_dir"
    ok "Using this copy of the repo: $REPO"
    return
  fi

  REPO="${MACOS_CONFIG_DIR:-$DEFAULT_DIR}"
  if ! xcode-select -p >/dev/null 2>&1; then
    warn "git needs Apple's Command Line Tools. Starting their installer…"
    run xcode-select --install || true
    err "Re-run this command once the Command Line Tools have finished installing."
    exit 1
  fi
  if [ -d "$REPO/.git" ]; then
    info "Updating $REPO"
    run git -C "$REPO" pull --ff-only
  elif [ -e "$REPO" ]; then
    err "$REPO exists but isn't a git clone. Move it away or set MACOS_CONFIG_DIR."
    exit 1
  else
    info "Cloning into $REPO"
    run mkdir -p "$(dirname "$REPO")"
    run git clone --depth 1 "$REPO_URL" "$REPO"
  fi
}

install_packages() {
  if ! command -v brew >/dev/null 2>&1; then
    if ask "Homebrew isn't installed. Install it (official script from brew.sh)?" n; then
      run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  if ! command -v brew >/dev/null 2>&1; then
    warn "Skipping packages (no Homebrew). The configs will still be linked."
    return
  fi
  ask "Install the apps and tools these configs use (only the missing ones)?" y || return 0

  local casks=(nikitabobko/tap/aerospace ghostty font-jetbrains-mono-nerd-font)
  local formulae=(felixkratz/formulae/sketchybar jq macmon blueutil starship tmux btop fastfetch neofetch tty-clock gping)

  run brew tap nikitabobko/tap >/dev/null 2>&1 || true
  run brew tap FelixKratz/formulae >/dev/null 2>&1 || true
  # Newer Homebrew only loads third-party formulae you've trusted; trust just this one
  if brew commands 2>/dev/null | grep -qx trust; then
    run brew trust --formula felixkratz/formulae/sketchybar >/dev/null 2>&1 || true
  fi

  local pkg name
  for pkg in "${casks[@]}"; do
    name="${pkg##*/}"
    if brew list --cask "$name" >/dev/null 2>&1; then ok "$name (already installed)"
    else info "Installing $name"; run brew install --cask "$pkg" || warn "Couldn't install $name — continuing"; fi
  done
  for pkg in "${formulae[@]}"; do
    name="${pkg##*/}"
    if brew list --formula "$name" >/dev/null 2>&1; then ok "$name (already installed)"
    else info "Installing $name"; run brew install "$pkg" || warn "Couldn't install $name — continuing"; fi
  done
}

link_configs() {
  info "Linking configs (existing ones go to $BACKUP_DIR)"
  local entry src dest rel
  for entry in "${LINKS[@]}"; do
    src="$REPO/${entry%%:*}"
    rel="${entry#*:}"
    dest="$HOME/$rel"

    if [ ! -e "$src" ]; then warn "Missing in repo, skipped: ${entry%%:*}"; continue; fi
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      ok "~/$rel (already linked)"; continue
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      run mv "$dest" "$BACKUP_DIR/$rel"
      [ "$DRY_RUN" = 1 ] || printf '%s\t%s\n' "$rel" "$BACKUP_DIR/$rel" >> "$BACKUP_DIR/manifest.tsv"
      warn "Backed up ~/$rel"
    fi
    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
    ok "~/$rel → repo"
  done
}

add_zsh_snippet() {
  local rc="$HOME/.zshrc" line
  line="[ -f \"$REPO/zsh/mac-rice.zsh\" ] && source \"$REPO/zsh/mac-rice.zsh\"  $ZSH_MARKER"
  if [ -f "$rc" ] && grep -qF "$ZSH_MARKER" "$rc"; then ok "~/.zshrc already sources the snippet"; return; fi
  ask "Add the aero-on / aero-off aliases to ~/.zshrc (one line; a copy is backed up)?" y || return 0
  if [ -f "$rc" ]; then
    run mkdir -p "$BACKUP_DIR"
    run cp -p "$rc" "$BACKUP_DIR/.zshrc.copy"
  fi
  if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] append to ~/.zshrc: %s\n' "$line"
  else printf '\n%s\n' "$line" >> "$rc"; fi
  ok "~/.zshrc sources zsh/mac-rice.zsh"
}

build_scroll_helper() {
  local dir="$REPO/config/sketchybar/helpers"
  if ! command -v clang >/dev/null 2>&1; then
    warn "clang not found: skipping the scroll helper (names will pause ~1 s between scrolls)"
    return
  fi
  run clang -O2 -o "$dir/scroll_driver" "$dir/scroll_driver.c" && ok "Built the SketchyBar scroll helper"
}

setup_tmux_plugins() {
  command -v tmux >/dev/null 2>&1 || return 0
  [ -d "$HOME/.tmux/plugins/tpm" ] && { ok "tmux plugin manager already installed"; return; }
  ask "Install the tmux plugin manager (TPM) into ~/.tmux/plugins/tpm?" y || return 0
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "TPM installed — inside tmux, press prefix + I to fetch the plugins"
}

setup_keep_awake_rule() {
  local target=/etc/sudoers.d/sketchybar-pmset tmp
  [ -f "$target" ] && { ok "Keep-awake sudo rule already installed"; return; }
  echo
  info "The bar's keep-awake button runs 'sudo pmset -a disablesleep 0/1'."
  info "Clicking it can work without a password via a sudo rule that allows ONLY those two commands."
  ask "Install that rule now (asks for your password)?" n || { warn "Skipped: the button will show SUDO when clicked"; return 0; }
  tmp="$(mktemp)"
  sed "s/__USER__/$(id -un)/g" "$REPO/config/sketchybar/helpers/sudoers-pmset.template" > "$tmp"
  if ! /usr/sbin/visudo -cf "$tmp" >/dev/null; then
    err "The sudo rule failed validation — not installed."; rm -f "$tmp"; return 0
  fi
  run sudo install -m 0440 -o root -g wheel "$tmp" "$target"
  run sudo /usr/sbin/visudo -c >/dev/null && ok "Keep-awake sudo rule installed ($target)"
  rm -f "$tmp"
}

setup_dock() {
  ask "Auto-hide the Dock and group windows by app in Mission Control (AeroSpace's recommendation)?" n || return 0
  run mkdir -p "$BACKUP_DIR"
  if [ "$DRY_RUN" = 0 ]; then
    { echo "com.apple.dock autohide = $(defaults read com.apple.dock autohide 2>/dev/null || echo unset)"
      echo "com.apple.dock expose-group-apps = $(defaults read com.apple.dock expose-group-apps 2>/dev/null || echo unset)"
    } > "$BACKUP_DIR/dock-defaults.txt"
  fi
  run defaults write com.apple.dock autohide -bool true
  run defaults write com.apple.dock expose-group-apps -bool true
  run killall Dock
  ok "Dock updated (previous values saved in $BACKUP_DIR/dock-defaults.txt)"
}

start_services() {
  if command -v sketchybar >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    if ask "Start SketchyBar now and at login?" y; then
      run brew services restart felixkratz/formulae/sketchybar >/dev/null && ok "SketchyBar running"
    fi
  fi
  if [ -d /Applications/AeroSpace.app ]; then
    if pgrep -x AeroSpace >/dev/null 2>&1; then
      run aerospace reload-config && ok "AeroSpace config reloaded"
    elif ask "Start AeroSpace now?" y; then
      run open -a AeroSpace && ok "AeroSpace started"
    fi
  fi
}

summary() {
  echo
  ok "Done."
  if [ -f "$BACKUP_DIR/manifest.tsv" ] || [ -f "$BACKUP_DIR/.zshrc.copy" ]; then
    info "Your previous files are in: $BACKUP_DIR"
  fi
  cat <<EOF

Next steps
  • System Settings → Privacy & Security → Accessibility: allow AeroSpace
    (and sketchybar, for the Control Center button).
  • System Settings → Control Center → "Automatically hide and show the menu bar" → Always
    so SketchyBar replaces the macOS menu bar.
  • Quit Ghostty fully (⌘Q) and reopen it to load the new look.

Undo everything:  $REPO/uninstall.sh
EOF
}

main "$@"
