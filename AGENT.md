# AGENT.md — Guidance for AI Coding Agents

Operating instructions for AI coding agents working in this repository.

## Source of Truth

The `.nix` files **are** the documentation. If there's ever a conflict between
this file (or README) and the Nix config, the Nix config wins. Read the actual
config before proposing changes — don't rely on memory of what's configured.

## Quick Layout

```text
flake.nix                # Entry point: inputs, user, mkSystem, host definitions
hosts/<name>/            # System config per machine (imports common + modules)
home/{default,server}.nix  # Home Manager entry points (desktop / headless)
profiles/{base,desktop,dev}.nix  # Composable home-manager profiles
modules/nixos/           # System-level modules, one file per feature
modules/home/            # User-level modules, one file per program
```

## Core Workflows

### Rebuilding

Use the `nrs` fish function (defined in `modules/home/aliases.nix`) instead of
bare `sudo nixos-rebuild switch` when possible — it builds, shows a package
diff (`nvd diff /run/current-system result`), and asks before switching:

```fish
nrs .#framework-desktop      # build + diff, then confirm switch
nrs .#framework-laptop
```

Raw equivalents when you need them (e.g. no confirmation):

```bash
sudo nixos-rebuild switch --flake .#framework-desktop
sudo nixos-rebuild test --flake .#framework-desktop  # boot once, don't make default
```

Home Manager only (non-NixOS servers):

```bash
home-manager switch --flake .#edgar@server
```

### Verifying Your Changes Before Commit

1. **Evaluate all configurations** — catches attrset/import errors:

   ```bash
   nix eval --raw .#nixosConfigurations.framework-desktop.config.system.build.toplevel.drvPath
   nix eval --raw .#nixosConfigurations.framework-laptop.config.system.build.toplevel.drvPath
   nix eval --raw .#homeConfigurations."edgar@server".activationPackage.drvPath
   ```

   The eval should succeed (a store path is printed). Warnings are OK.

2. **Update the lock after changing inputs** (`flake.nix`):

   ```bash
   nix flake lock
   ```

   Removed inputs get pruned automatically.

3. **Markdown files**: run the linter after editing docs:

   ```bash
   nix run nixpkgs#markdownlint-cli2 -- README.md AGENT.md
   ```

   Important: tables must be fully compact (no spaces around pipes), e.g.
   `|NixOS|Home Manager|` — otherwise MD060 fails.

## Conventions

- **One module per feature/program**, imported where it's used
  (`modules/nixos/<feature>.nix`, `modules/home/<program>.nix`).
- **Architecture-gated packages** use `lib.optionals` inside lists, never
  `lib.mkIf` in `home.packages`:

  ```nix
  home.packages =
    with pkgs;
    [ universal ]
    ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [ x86-only ];
  ```

- **`hardware-configuration.nix` is machine-generated** — never hand-edit; copy
  from `/etc/nixos/` when adding a host.
- **`system.stateVersion` is set once at host creation and never bumped.**
- **No secrets in the repo.** Secrets flow through 1Password (SSH agent at
  `~/.1password/agent.sock`, CLI injection). Never suggest committing keys or
  tokens; reference them via `op://` items in per-user config instead.
- **Prefer nixpkgs over flake inputs.** Before adding a new `inputs.<name>`,
  check whether the package/module already exists in nixpkgs (`nix search nixpkgs
  <name>`, and check the resolved home-manager/nixpkgs revisions in
  `flake.lock`). Pin a flake only when nixpkgs genuinely lags or lacks it.

## Git Etiquette

- **One atomic commit per logical change** — avoid unrelated edits in the same
  commit. Stage exactly the files for that change (`git add -A` only when all
  uncommitted work belongs together).
- Commit message: conventional-style one-liner summarizing the change.
- When removing files, use `git rm` so the deletion is recorded together with
  the rest of the change.
- After a substance change, confirm the user has rebuilt/verified before
  committing unless they asked you to commit directly.

## Working Style

This is a personal config the user actively tinkers with:

- Explain significant decisions briefly; don't over-explain routine changes.
- Challenge decisions when you see a simpler or more standard way — but respect
  the user's choice once they make it.
- Prefer the established patterns in this repo over introducing new ones
  (KISS). If you introduce something new, make it look like the existing code.
