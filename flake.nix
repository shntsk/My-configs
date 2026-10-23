{
  description = "suzuha niri keybinds as a home-manager module";

  outputs = { self, ... }: {
    homeManagerModules.default = import ./nix/niri-keybinds.nix;
    homeManagerModules.niri-keybinds = self.homeManagerModules.default;
  };
}
