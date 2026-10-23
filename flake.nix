{
  description = "suzuha niri keybinds: one command to install them";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      # nix run github:YOUR_USER/suzuha
      packages = forAll (_system: pkgs: {
        default = pkgs.writeShellApplication {
          name = "suzuha-niri-keybinds";
          runtimeInputs = [ pkgs.coreutils pkgs.gnugrep ];
          text = ''
            dir="''${XDG_CONFIG_HOME:-$HOME/.config}/niri"
            config="$dir/config.kdl"
            include='include "suzuha-keybinds.kdl"'

            mkdir -p "$dir"

            # always refreshed, so running this again after a git push updates the keybinds
            install -m 644 ${./niri-keybinds.kdl} "$dir/suzuha-keybinds.kdl"
            echo "installed $dir/suzuha-keybinds.kdl"

            if [ -L "$config" ]; then
              echo "warning: $config is a symlink managed by Nix, add this line to it yourself:" >&2
              echo "  $include" >&2
            elif [ ! -e "$config" ]; then
              printf '%s\n' "$include" > "$config"
              echo "created $config"
            elif ! grep -qxF "$include" "$config"; then
              # added at the end, so these binds win over duplicates earlier in the file
              printf '\n%s\n' "$include" >> "$config"
              echo "added the include line to $config"
            else
              echo "$config already has the include line"
            fi

            missing=""
            for tool in wpctl playerctl brightnessctl cliphist wl-copy wl-paste; do
              command -v "$tool" > /dev/null 2>&1 || missing="$missing $tool"
            done

            if [ -n "$missing" ]; then
              echo
              echo "missing programs the keybinds call:$missing"
              echo "add to your NixOS config: wireplumber playerctl brightnessctl cliphist wl-clipboard"
            fi

            echo "niri reloads its config on save, nothing else to do."
          '';
        };
      });

      apps = forAll (system: _pkgs: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${system}.default;
        };
      });

      # optional, only if you use home-manager
      homeManagerModules.default = import ./nix/niri-keybinds.nix;
    };
}
