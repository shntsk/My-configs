# home-manager module: applies the suzuha niri keybinds automatically.
#
# What it does on every `home-manager switch`:
#   1. links niri-keybinds.kdl (from this repo) to ~/.config/niri/suzuha-keybinds.kdl
#   2. makes sure ~/.config/niri/config.kdl has `include "suzuha-keybinds.kdl"`
#   3. installs the tools the keybinds call (wpctl, playerctl, brightnessctl, cliphist, wl-clipboard)
#
# Requires niri 25.11+ (config `include` support) and home-manager.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.suzuha.niri;

  fileName = "suzuha-keybinds.kdl";
  includeLine = ''include "${fileName}"'';
  mainConfig = "${config.xdg.configHome}/niri/config.kdl";
in
{
  options.programs.suzuha.niri = {
    enable = lib.mkEnableOption "the suzuha keybinds for niri";

    installDependencies = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the programs the keybinds call: wpctl (wireplumber), playerctl,
        brightnessctl, cliphist and wl-clipboard.
      '';
    };

    patchMainConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Append `include "${fileName}"` to ~/.config/niri/config.kdl when it is
        missing, and create a minimal config.kdl if the file does not exist yet.
        Skipped when config.kdl is a symlink, because Nix manages it; add the
        include line there yourself in that case.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/${fileName}".source = ../niri-keybinds.kdl;

    home.packages = lib.mkIf cfg.installDependencies (with pkgs; [
      wireplumber # wpctl, for the volume keys
      playerctl
      brightnessctl
      cliphist
      wl-clipboard
    ]);

    home.activation.suzuhaNiriInclude = lib.mkIf cfg.patchMainConfig (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config=${lib.escapeShellArg mainConfig}
        include=${lib.escapeShellArg includeLine}

        if [ -L "$config" ]; then
          echo "suzuha: $config is a symlink managed by Nix, add this line to it yourself: $include" >&2
        elif [ ! -e "$config" ]; then
          $DRY_RUN_CMD mkdir -p "$(dirname "$config")"
          if [ -z "''${DRY_RUN:-}" ]; then
            printf '%s\n' "$include" > "$config"
          fi
        elif ! grep -qxF "$include" "$config"; then
          # added at the end, so these binds win over duplicates earlier in the file
          if [ -z "''${DRY_RUN:-}" ]; then
            printf '\n%s\n' "$include" >> "$config"
          fi
        fi
      ''
    );
  };
}
