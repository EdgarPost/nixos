# ============================================================================
# HYPRLAND HOME MODULE - Window Manager Configuration
# ============================================================================
#
# SYSTEM VS HOME MANAGER:
# System module (modules/nixos/hyprland.nix): Installs Hyprland, portals, fonts
# This module: User preferences - keybindings, appearance, startup apps
# ============================================================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hyprland;

  # Rofi project picker → tmux session per ghq project
  tmux-project = pkgs.writeShellScriptBin "tmux-project" ''
    root=$(${pkgs.ghq}/bin/ghq root)

    # Show rofi picker with ghq projects
    selected=$(${pkgs.ghq}/bin/ghq list | rofi -dmenu -p "Project" -i)
    [ -z "$selected" ] && exit 0

    name=$(echo "''${selected##*/}" | tr '.:' '--')
    path="$root/$selected"

    # Ensure tmux session exists for this project
    tmux has-session -t "=$name" 2>/dev/null || \
      tmux new-session -d -s "$name" -c "$path"

    # Focus existing ghostty or launch new one
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "com.mitchellh.ghostty")' > /dev/null 2>&1; then
      hyprctl dispatch focuswindow class:com.mitchellh.ghostty
      # Switch tmux client to the project session
      tmux switch-client -t "=$name"
    else
      # Launch ghostty with this project's tmux session
      ghostty -e tmux new-session -A -s "$name" -c "$path" &
    fi
  '';

  # Catppuccin wallpapers - fetched at build time
  catppuccin-wallpapers = pkgs.fetchFromGitHub {
    owner = "zhichaoh";
    repo = "catppuccin-wallpapers";
    rev = "1023077979591cdeca76aae94e0359da1707a60e";
    sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
  };
in
{
  options.hyprland.enableFancyEffects = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable expensive visual effects (blur, animations). Disable on iGPU/high-res setups.";
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      # Hyprland 0.55+ uses Lua config. This makes Home Manager generate
      # ~/.config/hypr/hyprland.lua instead of hyprland.conf.
      configType = "lua";
      # Use the Hyprland package from NixOS module (avoid duplicate installations)
      package = null;
      portalPackage = null;
      # Let systemd manage the session (creates hyprland-session.target)
      # Noctalia runs as a systemd user service wired to hyprland-session.target
      systemd.enable = true;

      settings = {
        # =====================================================================
        # LUA LOCALS
        # =====================================================================
        # These become local variables in the generated hyprland.lua and are used
        # by the raw keybinds in extraConfig.
        mod = {
          _var = "SUPER";
        };
        # Lua key parser splits modifiers by '+' rather than spaces, so join
        # the hyper combo with '+' (e.g. "SUPER+SHIFT+CTRL+ALT + M").
        hyper = {
          _var = "SUPER+SHIFT+CTRL+ALT";
        };
        terminal = {
          _var = "ghostty";
        };

        # =====================================================================
        # MONITOR CONFIGURATION
        # =====================================================================
        # Format: output, mode, position, scale
        # Use `hyprctl monitors` to see detected monitors
        monitor = [
          # Dell U4025QW: connected via both DisplayPort and Thunderbolt (TB is
          # for USB/KVM passthrough, no video). Both inputs would otherwise show
          # up as separate outputs and confuse screen-share pickers.
          {
            output = "DP-4";
            mode = "5120x2160@120";
            position = "0x0";
            scale = "1.25";
          }
          {
            output = "DP-5";
            disabled = true;
          }
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = "auto";
          }
        ];

        # =====================================================================
        # WINDOW RULES
        # =====================================================================
        window_rule = [
          {
            name = "picture-in-picture";
            match = {
              title = "^(Picture-in-Picture)$";
            };
            float = true;
            pin = true;
            size = "640 360";
            move = "3437 68";
            keep_aspect_ratio = true;
            no_initial_focus = true;
            no_follow_mouse = true;
            focus_on_activate = false;
          }

          # hyprland-share-picker (screen/window share selector) reports an
          # empty window class, so match by its title instead.
          {
            name = "share-picker";
            match = {
              title = "^(Select what to share)$";
            };
            float = true;
            center = true;
          }

          # Keep rendering when occluded so screen sharing can capture these
          # windows even when they're not currently visible. Costs CPU/GPU for
          # apps that animate in the background, so limited to a small allowlist.
          {
            name = "render-unfocused-ghostty";
            match = {
              class = "^(com.mitchellh.ghostty)$";
            };
            render_unfocused = true;
          }
          {
            name = "render-unfocused-zen";
            match = {
              class = "^(zen)$";
            };
            render_unfocused = true;
          }
        ];

        # =====================================================================
        # ENVIRONMENT VARIABLES
        # =====================================================================
        # Required for XDG portals and Wayland apps to work correctly
        env = [
          {
            _args = [
              "XDG_CURRENT_DESKTOP"
              "Hyprland"
            ];
          }
          {
            _args = [
              "XDG_SESSION_TYPE"
              "wayland"
            ];
          }
          {
            _args = [
              "XDG_SESSION_DESKTOP"
              "Hyprland"
            ];
          }
          {
            _args = [
              "TMUX_TMPDIR"
              "$XDG_RUNTIME_DIR"
            ];
          }
        ];

        # =====================================================================
        # STARTUP APPLICATIONS
        # =====================================================================
        # 1Password starts once when Hyprland starts. The dbus/systemd env
        # import and hyprland-session.target are handled by the module's
        # systemd.enable integration.
        on = {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("1password --silent")
              end
            '')
          ];
        };

        # =====================================================================
        # LOOK AND FEEL
        # =====================================================================
        # Grouped into hl.config() so the C++ config backend applies them.
        config = {
          general = {
            layout = "scrolling";
            gaps_in = 8;
            gaps_out = 16;
            border_size = 2;
            # Border colors set manually (catppuccin.hyprland disabled, incompatible with Hyprland 0.55.x)
            col = {
              active_border = "rgba(89b4faff)"; # Catppuccin Mocha blue
              inactive_border = "rgba(00000000)"; # Transparent - no border on inactive
            };
          };

          scrolling = {
            column_width = 0.5;
            focus_fit_method = 1; # Fit: minimal scroll to show focused column (two 0.5 columns sit side by side)
            explicit_column_widths = "0.333, 0.5, 0.75, 1.0";
          };

          decoration = {
            rounding = 8;
            shadow = {
              enabled = false;
            };
            blur = {
              enabled = cfg.enableFancyEffects;
              size = 8;
              passes = 3;
              new_optimizations = true;
              xray = false; # Blur desktop behind floating windows, not window below
              noise = 0.01;
              contrast = 1.0;
              brightness = 1.0;
              vibrancy = 0.2;
            };
          };

          animations = {
            enabled = true;
          };

          cursor = {
            no_hardware_cursors = true; # Use software cursors (avoids GPU cursor plane issues)
            use_cpu_buffer = true; # CPU-side cursor buffer (fixes cursor vanishing on Intel iGPU hotplug)
          };

          misc = {
            focus_on_activate = true; # Auto-focus windows when they request attention (e.g. browser from terminal)
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            mouse_move_enables_dpms = true; # Wake display on mouse move
            key_press_enables_dpms = true; # Wake display on key press
          };

          input = {
            kb_layout = "us";
            kb_options = "compose:ralt"; # Right Alt as Compose key for accented chars
            follow_mouse = 1; # Focus follows mouse
            sensitivity = -0.9; # 0 = no modification to input speed
            accel_profile = "adaptive"; # No acceleration (1:1 mouse movement)
            touchpad = {
              natural_scroll = true; # Two-finger scroll direction (like macOS)
            };
          };

          xwayland = {
            force_zero_scaling = true;
          };
        };

        # Animation curves (hl.curve)
        curve = [
          {
            _args = [
              "wind"
              {
                type = "bezier";
                points = [
                  [
                    0.05
                    0.85
                  ]
                  [
                    0.03
                    0.97
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "winIn"
              {
                type = "bezier";
                points = [
                  [
                    0.07
                    0.88
                  ]
                  [
                    0.04
                    0.99
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "winOut"
              {
                type = "bezier";
                points = [
                  [
                    0.20
                    (-0.15)
                  ]
                  [
                    0
                    1
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "liner"
              {
                type = "bezier";
                points = [
                  [
                    1
                    1
                  ]
                  [
                    1
                    1
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "md3_decel"
              {
                type = "bezier";
                points = [
                  [
                    0.05
                    0.80
                  ]
                  [
                    0.10
                    0.97
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "menu_decel"
              {
                type = "bezier";
                points = [
                  [
                    0.05
                    0.82
                  ]
                  [
                    0
                    1
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "menu_accel"
              {
                type = "bezier";
                points = [
                  [
                    0.20
                    0
                  ]
                  [
                    0.82
                    0.10
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "easeOutCirc"
              {
                type = "bezier";
                points = [
                  [
                    0
                    0.48
                  ]
                  [
                    0.38
                    1
                  ]
                ];
              }
            ];
          }
        ];

        # Animation definitions (hl.animation)
        animation = [
          {
            leaf = "border";
            enabled = true;
            speed = 1.6;
            bezier = "liner";
          }
          {
            leaf = "borderangle";
            enabled = true;
            speed = 82;
            bezier = "liner";
            style = "loop";
          }
          {
            leaf = "windowsIn";
            enabled = true;
            speed = 3.2;
            bezier = "winIn";
            style = "slide";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 2.8;
            bezier = "easeOutCirc";
          }
          {
            leaf = "windowsMove";
            enabled = true;
            speed = 3.0;
            bezier = "wind";
            style = "slide";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 1.8;
            bezier = "md3_decel";
          }
          {
            leaf = "layersIn";
            enabled = true;
            speed = 1.8;
            bezier = "menu_decel";
            style = "slide";
          }
          {
            leaf = "layersOut";
            enabled = true;
            speed = 1.5;
            bezier = "menu_accel";
          }
          {
            leaf = "fadeLayersIn";
            enabled = true;
            speed = 1.6;
            bezier = "menu_decel";
          }
          {
            leaf = "fadeLayersOut";
            enabled = true;
            speed = 1.8;
            bezier = "menu_accel";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 4.0;
            bezier = "menu_decel";
            style = "slide";
          }
          {
            leaf = "specialWorkspace";
            enabled = true;
            speed = 2.3;
            bezier = "md3_decel";
            style = "slidefadevert 15%";
          }
        ];

        # Touchpad gestures: 3-finger horizontal swipe switches workspace
        gesture = {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        };

      }; # End of settings

      # =====================================================================
      # KEYBINDINGS AND RAW LUA
      # =====================================================================
      # The binds are written as raw Lua because many of them are complex
      # shell pipelines that are easier to express directly than through the
      # Nix-to-Lua translation for every bind argument.
      extraConfig = ''
        -- =============================================================
        -- HYPER KEY BINDINGS (Caps Lock via keyd)
        -- High-level OS actions: app focus, launchers, session control
        -- =============================================================
        hl.bind(hyper .. " + M", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "thunderbird")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:thunderbird || thunderbird]]))
        hl.bind(hyper .. " + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))
        hl.bind(hyper .. " + A", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center audio"))
        hl.bind(hyper .. " + P", hl.dsp.exec_cmd("tmux-project"))
        hl.bind(hyper .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
        hl.bind(hyper .. " + B", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "zen")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:zen || zen]]))
        hl.bind(hyper .. " + S", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "Slack")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:Slack || slack]]))
        hl.bind(hyper .. " + T", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "com.mitchellh.ghostty")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:com.mitchellh.ghostty || ]] .. terminal))
        hl.bind(hyper .. " + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
        hl.bind(hyper .. " + Y", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "yazi")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:yazi || ghostty --class=yazi -e yazi]]))

        -- =============================================================
        -- MOD KEY BINDINGS (SUPER)
        -- Window management, navigation, workspaces
        -- =============================================================
        hl.bind(mod .. " + Q", hl.dsp.window.close())
        hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
        hl.bind(mod .. " + G", hl.dsp.window.float({ action = "toggle" }))

        hl.bind(mod .. " + CTRL + L", hl.dsp.layout("colresize +conf"))
        hl.bind(mod .. " + CTRL + H", hl.dsp.layout("colresize -conf"))

        hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
        hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
        hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
        hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

        hl.bind(mod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
        hl.bind(mod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))
        hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
        hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

        hl.bind(mod .. " + 1", hl.dsp.focus({ workspace = "1" }))
        hl.bind(mod .. " + 2", hl.dsp.focus({ workspace = "2" }))
        hl.bind(mod .. " + 3", hl.dsp.focus({ workspace = "3" }))
        hl.bind(mod .. " + 4", hl.dsp.focus({ workspace = "4" }))
        hl.bind(mod .. " + 5", hl.dsp.focus({ workspace = "5" }))
        hl.bind(mod .. " + 6", hl.dsp.focus({ workspace = "6" }))
        hl.bind(mod .. " + 7", hl.dsp.focus({ workspace = "7" }))
        hl.bind(mod .. " + 8", hl.dsp.focus({ workspace = "8" }))
        hl.bind(mod .. " + 9", hl.dsp.focus({ workspace = "9" }))

        hl.bind(mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
        hl.bind(mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
        hl.bind(mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
        hl.bind(mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
        hl.bind(mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
        hl.bind(mod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
        hl.bind(mod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
        hl.bind(mod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
        hl.bind(mod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))

        hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "e+1" }))
        hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

        hl.bind(mod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "e+1" }))
        hl.bind(mod .. " + SHIFT + M", hl.dsp.window.move({ monitor = "+1" }))

        -- =============================================================
        -- MEDIA / SESSION / SCREENSHOT BINDS
        -- =============================================================
        hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"))
        hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"))
        hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"))
        hl.bind("XF86AudioStop", hl.dsp.exec_cmd("noctalia msg media stop"))

        hl.bind(hyper .. " + Escape", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
        hl.bind("XF86PowerOff", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))

        hl.bind(mod .. " + CTRL + S", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
        hl.bind(mod .. " + CTRL + SHIFT + S", hl.dsp.exec_cmd("noctalia msg screenshot-region"))

        -- =============================================================
        -- REPEATING BINDS (volume, brightness, resize)
        -- =============================================================
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { repeating = true })
        hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { repeating = true })
        hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { repeating = true })

        hl.bind(mod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
        hl.bind(mod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

        -- =============================================================
        -- LOCKED BINDS (work on lockscreen)
        -- =============================================================
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
        hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })

        -- =============================================================
        -- MOUSE BINDS
        -- =============================================================
        hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
      '';
    };

    # ==========================================================================
    # ROFI - Used only by tmux-project picker (not as an app launcher anymore)
    # ==========================================================================
    # Noctalia handles app launching now ($hyper+D). Rofi is still invoked
    # directly by the tmux-project script as a generic dmenu picker.
    # programs.rofi is enabled so the catppuccin.rofi module can write the
    # themed config.rasi — the module is gated on programs.rofi.enable.
    programs.rofi.enable = true;
    catppuccin.rofi.enable = true;

    # ==========================================================================
    # WALLPAPERS
    # ==========================================================================
    # Symlink Catppuccin landscape wallpapers to ~/.wallpapers
    # These are fetched from GitHub at build time
    home.file.".wallpapers".source = "${catppuccin-wallpapers}/landscapes";

    # ==========================================================================
    # XDG-DESKTOP-PORTAL-HYPRLAND (screen sharing)
    # ==========================================================================
    # Auto-tick the "allow restore token" checkbox in hyprland-share-picker so
    # subsequent shares from the same app can skip the picker.
    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
        allow_token_by_default = true
      }
    '';

    # ==========================================================================
    # WAYLAND UTILITIES
    # ==========================================================================
    # Essential tools for a functional Wayland desktop
    home.packages = [
      tmux-project
      pkgs.rofi # Used by tmux-project picker (catppuccin.rofi themes it)
    ]
    ++ (with pkgs; [
      jq # JSON query tool
      wl-clipboard # Clipboard: wl-copy, wl-paste (like xclip for Wayland)
    ]);
  }; # End of config
}
