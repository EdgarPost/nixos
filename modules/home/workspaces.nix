# ============================================================================
# PROJECT WORKSPACES
# ============================================================================
#
# Per-project named workspaces via rofi picker + fast cycling.
#
# Commands:
#   project-cycle       Cycle/return to project workspaces
#   project-terminal    Open terminal in project dir (or plain ghostty)
#   project-picker      Select project from ghq repos (rofi menu)
#
# Keybindings:
#   Super+P             Cycle project workspaces (or return to last)
#   Super+Shift+P       Open project picker (rofi)
#   Super+Enter         Open terminal in project dir
#
# Behavior:
#   - Super+P on numeric workspace: jump to last focused project
#   - Super+P on project workspace: cycle to next (alphabetically)
#   - Workspaces sorted by name in waybar and cycle order
#   - Empty named workspaces auto-cleanup when last window closes
#
# ============================================================================

{ pkgs, ... }:

let
  # Cycle through project workspaces, or return to last project from numeric ws
  project-cycle = pkgs.writeShellScriptBin "project-cycle" ''
    current=$(hyprctl activeworkspace -j | jq -r '.name')

    # Named workspaces sorted alphabetically (matches waybar order)
    workspaces=$(hyprctl workspaces -j | jq -r '
      [.[] | select(.name | test("^[0-9]+$") | not)]
      | sort_by(.name)
      | .[].name
    ')

    count=$(echo "$workspaces" | grep -c . || true)
    [ "$count" -eq 0 ] && exit 0

    # On a numeric workspace: jump to most recently focused project
    if [[ "$current" =~ ^[0-9]+$ ]]; then
      target=$(hyprctl clients -j | jq -r '
        [.[] | select(.workspace.name | test("^[0-9]+$") | not)]
        | sort_by(.focusHistoryID)
        | .[0].workspace.name // empty
      ')
      [ -z "$target" ] && target=$(echo "$workspaces" | head -1)
      hyprctl dispatch workspace "name:$target"
      exit 0
    fi

    # On a named workspace: cycle to next alphabetically
    [ "$count" -le 1 ] && exit 0

    idx=0
    found=-1
    while IFS= read -r ws; do
      [ "$ws" = "$current" ] && found=$idx
      idx=$((idx + 1))
    done <<< "$workspaces"

    if [ "$found" -ge 0 ]; then
      next=$(( (found + 1) % count ))
    else
      next=0
    fi

    target=$(echo "$workspaces" | sed -n "$((next + 1))p")
    hyprctl dispatch workspace "name:$target"
  '';

  # Open terminal in project dir if on a named workspace, else plain ghostty
  project-terminal = pkgs.writeShellScriptBin "project-terminal" ''
    ws=$(hyprctl activeworkspace -j | jq -r '.name')

    # Numeric workspace = not a project, just open ghostty
    if [[ "$ws" =~ ^[0-9]+$ ]]; then
      exec ghostty
    fi

    # Find matching ghq repo by name
    root=$(ghq root)
    match=$(ghq list | grep "/$ws$" | head -1)

    if [ -n "$match" ]; then
      exec ghostty --gtk-single-instance=false --working-directory="$root/$match"
    else
      exec ghostty
    fi
  '';

  # Rofi picker: select from all ghq repos, active workspaces shown first
  project-picker = pkgs.writeShellScriptBin "project-picker" ''
    current=$(hyprctl activeworkspace -j | jq -r '.name')

    # All active workspace names (except current)
    all_ws=$(hyprctl workspaces -j | jq -r --arg cur "$current" '[.[] | select(.name != $cur) | .name] | .[]')

    # Focus ordering: workspace name -> lowest focusHistoryID (lower = more recent)
    ws_focus=$(hyprctl clients -j | jq -r --arg cur "$current" '
      [.[] | select(.workspace.name != $cur) | {ws: .workspace.name, fh: .focusHistoryID}]
      | group_by(.ws)
      | map({key: .[0].ws, value: ([.[].fh] | min)})
      | from_entries
    ')

    root=$(ghq root)

    active=()
    inactive=()

    while IFS= read -r repo; do
      [ -z "$repo" ] && continue
      name="''${repo##*/}"

      # Skip current workspace
      [ "$name" = "$current" ] && continue

      # Check if this repo has an active workspace
      if echo "$all_ws" | grep -qFx "$name"; then
        order=$(echo "$ws_focus" | jq -r --arg n "$name" '.[$n] // 9999')
        active+=("''${order}:''${repo}")
      else
        inactive+=("$repo")
      fi
    done < <(ghq list)

    # Sort active by focus recency (ascending = most recent first)
    sorted_active=$(printf '%s\n' "''${active[@]}" | sort -t: -k1 -n | cut -d: -f2-)

    # Combine: active workspaces first, then remaining repos
    selected=$(printf '%s\n%s\n' "$sorted_active" "$(printf '%s\n' "''${inactive[@]}")" | sed '/^$/d' | rofi -dmenu -p "Project" -i)
    [ -z "$selected" ] && exit 0

    name="''${selected##*/}"
    path="$root/$selected"

    # Switch to existing workspace, or create new one with Ghostty
    if hyprctl workspaces -j | jq -e --arg n "$name" '.[] | select(.name == $n)' > /dev/null 2>&1; then
      hyprctl dispatch workspace "name:$name"
    else
      hyprctl dispatch workspace "name:$name"
      hyprctl dispatch exec "ghostty --gtk-single-instance=false --working-directory='$path'"
    fi
  '';

  # Switch to the Nth project workspace (sorted alphabetically, excludes "main" and "chat")
  project-switch = pkgs.writeShellScriptBin "project-switch" ''
    n="$1"
    target=$(hyprctl workspaces -j | jq -r '
      [.[] | select(.name | test("^[0-9]+$") | not) | select(.name != "chat") | .name]
      | sort
      | .['$((n - 1))'] // empty
    ')
    [ -n "$target" ] && hyprctl dispatch workspace "name:$target"
  '';

  # Daemon: auto-remove named workspaces when last window closes
  workspace-cleanup = pkgs.writeShellScriptBin "workspace-cleanup" ''
    ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
      case "$line" in
        closewindow*)
          sleep 0.1
          windows=$(hyprctl activeworkspace -j | jq '.windows')
          if [ "$windows" = "0" ]; then
            name=$(hyprctl activeworkspace -j | jq -r '.name')
            # Only auto-remove named (non-numeric) workspaces
            if ! [[ "$name" =~ ^[0-9]+$ ]]; then
              hyprctl dispatch workspace previous
            fi
          fi
          ;;
      esac
    done
  '';

in
{
  home.packages = [ project-cycle project-terminal project-picker project-switch workspace-cleanup ];

  # Start cleanup daemon with Hyprland
  wayland.windowManager.hyprland.settings.exec-once = [
    "workspace-cleanup"
  ];
}
