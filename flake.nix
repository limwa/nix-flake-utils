{
  description = "A set of utilities to aid in the development of high-quality Nix flakes.";

  inputs = {
    systems.url = "github:nix-systems/default";
  };

  outputs = { systems, ...}: {
    lib = import ./lib {
      defaultSystems = import systems;
    };
  };
}
