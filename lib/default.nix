{defaultSystems}: let
  stdlib = import ./stdlib.nix;
in rec {
  # Removes all attributes with a value of `null` from the given attribute set.
  # Utilities like `nix flake show` will often error if an attribute is `null`, so this function is useful for cleaning up attribute sets.
  mkOptionalAttrs = attrs:
    builtins.listToAttrs (
      builtins.filter ({value, ...}: value != null) (
        stdlib.attrEntries attrs
      )
    );

  # Creates a template for a Nix flake.
  # If `description` is not provided, it is read from the flake at the root of the template, if it exists.
  # If `welcomeText` is not provided, it is read from the contents of the `README.md` file at the root of the template, if it exists.
  mkTemplate = {
    path,
    description ? null,
    welcomeText ? null,
  }:
    mkOptionalAttrs {
      inherit path;

      description = let
        flake = stdlib.fallback (stdlib.tryImport "${path}/flake.nix") {description = null;};
      in
        stdlib.fallthrough [
          description
          flake.description
        ] (throw "No description provided and no flake.nix found at ${path}");

      welcomeText = stdlib.fallback welcomeText (stdlib.tryReadFile "${path}/README.md");
    };

  mkFlake = mkFlakeWith {};

  mkFlakeWith = {
    systems ? defaultSystems,
    forEachSystem ? system: {inherit system;},
  }: let
    mkSystemAttrs = fn:
      builtins.listToAttrs (
        builtins.map (
          system:
            stdlib.nameValuePair system (
              fn (forEachSystem system)
            )
        )
        systems
      );

    mkFlakeTopLevel = prototype: let
      systemTopLevelAttrs = [
        "apps"
        "bundlers"
        "checks"
        "defaultApp"
        "defaultBundler"
        "defaultPackage"
        "devShell"
        "devShells"
        "formatter"
        "hydraJobs"
        "legacyPackages"
        "packages"
      ];
    in
      builtins.listToAttrs (
        builtins.map (
          attr: let
            fn = prototype.${attr} or null;
          in
            stdlib.nameValuePair attr (stdlib.try mkSystemAttrs fn)
        )
        systemTopLevelAttrs
      );
  in
    prototype:
      mkOptionalAttrs (
        prototype
        // mkFlakeTopLevel prototype
      );
}
