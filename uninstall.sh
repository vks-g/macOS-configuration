#!/usr/bin/env bash
# macOS-configuration uninstaller
#
#   ~/.local/share/macOS-configuration/uninstall.sh [--dry-run]
#
# Removes ONLY the symlinks install.sh created (links that point into this repo),
# puts your backed-up files back, and removes the one line install.sh added to
# ~/.zshrc. Homebrew packages, the keep-awake sudo rule and Dock settings are
# left alone; the commands to remove those are printed at the end.

main() {
  set -euo pipefail
  DRY_RUN=0
  [ "${1:-}" = "--dry-run" ] && DRY_RUN=1

  REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BACKUP_ROOT="$HOME/.config-backups/macOS-configuration"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  ZSH_MARKER="# macOS-configuration"
  DESTS=(.config/aerospace .config/sketchybar .config/ghostty .config/btop .config/fastfetch .config/neofetch .config/nvim
         .config/starship.toml .tmux.conf)

  [ "$DRY_RUN" = 1 ] && warn "Dry run: nothing will be changed."

  local rel dest target backup
  for rel in "${DESTS[@]}"; do
    dest="$HOME/$rel"
    if [ -L "$dest" ]; then
      target="$(readlink "$dest")"
      case "$target" in
        "$REPO"/*) run rm "$dest"; ok "Removed link ~/$rel" ;;
        *) warn "~/$rel links somewhere else ($target) — left alone"; continue ;;
      esac
    elif [ -e "$dest" ]; then
      warn "~/$rel is a real file/folder (not ours) — left alone"; continue
    fi
    backup="$(latest_backup "$rel")"
    if [ -n "$backup" ]; then
      run mv "$backup" "$dest"
      ok "Restored ~/$rel from $(dirname "$backup")"
    fi
  done

  local rc="$HOME/.zshrc"
  if [ -f "$rc" ] && grep -qF "$ZSH_MARKER" "$rc"; then
    run mkdir -p "$BACKUP_ROOT/uninstall-$STAMP"
    run cp -p "$rc" "$BACKUP_ROOT/uninstall-$STAMP/.zshrc.copy"
    if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] remove the "%s" line from ~/.zshrc\n' "$ZSH_MARKER"
    else
      # Drop the snippet line, plus the blank line install.sh put before it
      awk -v m="$ZSH_MARKER" '
        index($0, m) { if (hold && prev != "") print prev; hold = 0; next }
        { if (hold) print prev; prev = $0; hold = 1 }
        END { if (hold) print prev }' "$BACKUP_ROOT/uninstall-$STAMP/.zshrc.copy" > "$rc"
    fi
    ok "Removed the snippet line from ~/.zshrc"
  fi

  cat <<EOF

Left in place (remove yourself if you want):
  • Homebrew packages:   brew uninstall --cask aerospace ghostty · brew uninstall sketchybar macmon blueutil …
  • SketchyBar service:  brew services stop sketchybar
  • Keep-awake rule:     sudo rm /etc/sudoers.d/sketchybar-pmset
  • Dock settings:       see dock-defaults.txt in $BACKUP_ROOT/<date>/ for the old values
  • This repo:           $REPO
EOF
}

info() { printf '\033[34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m  %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m  %s\n' "$*"; }

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi
}

# Newest backup of a given path that's still on disk (from any install run)
latest_backup() {
  local rel="$1" manifest line path
  [ -d "$BACKUP_ROOT" ] || return 0
  for manifest in $(ls -1r "$BACKUP_ROOT"/*/manifest.tsv 2>/dev/null); do
    while IFS=$'\t' read -r line path; do
      if [ "$line" = "$rel" ] && { [ -e "$path" ] || [ -L "$path" ]; }; then
        printf '%s\n' "$path"; return 0
      fi
    done < "$manifest"
  done
}

main "$@"
