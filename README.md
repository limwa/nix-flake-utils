# nix-flake-utils

This flake provides a set of utilities I find useful for writing flakes.
For instance, this flake is used across all of the templates available at [limwa/nix-registry](https://github.com/limwa/nix-registry).

## Instalation

To install this flake, add the following statements to the input section of your flake.

```nix
inputs = {
    utils.url = "github:limwa/nix-flake-utils";
};
```

If you want to use a different set of default systems, you can override the `systems` input.

```nix
inputs = {
    systems.url = "github:nix-systems/default";

    utils.url = "github:limwa/nix-flake-utils";
    utils.inputs.systems.follows = "systems";
};
```

## Usage

### `lib.mkOptionalAttrs :: attrs -> attrs`

This function accepts a attrset and returns the same attrset, but removes all attributes that have a `null` value.

This is mostly used in declaring high-level flake outputs, because flake outputs, in general, cannot have `null` values.
As such, if you want to declare a package that only exists in a given system (`x86_64-linux`, for instance), you can use this function and return `null` on the other architectures.

### `lib.mkTemplate :: { path, description ? null, welcomeText ? null } -> template`

This function accepts a `path` attribute, as well as a `description` and `welcomeText`. If `description` is `null`, then the description of the flake at `path` will be used. Likewise, if `welcomeText` is `null`, the contents of the `README.md` file at `path` will be used.

This is useful for declaring templates, avoiding repetition and making it easier to update flake templates.

### `lib.mkFlakeWith :: { systems ? null, forEachSystem :: string -> attrs } -> attrs -> attrs`

This function for the first argument takes in an attrset with two attributes:

- `systems`, an array of systems to generate attributes for. If this is not provided, the default list of systems is used.
- `forEachSystem`, a function that accepts a system specifier and returns an attrset. If this is not provided, the function `system: { inherit system; };` is used.

The second argument for this function is an attrset with a structure similar to a flake. However, all of the arguments that are system-dependent (like `devShells`, `packages`, among others) need to be a function with the signature `attrset -> attrset`, where the input is the attrset returned by `forEachSystem`.

As such, this function is very useful for declaring flakes with multi-architecture support, in a consistent and easy manner.

#### Example

```nix
{
    description = "Example usage of the mkFlakeWith function";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        utils.url = "github:limwa/nix-flake-utils";
    };

    outputs = {nixpkgs, utils, ...}:
        utils.lib.mkFlakeWith {
            forEachSystem = system: {
                pkgs = import nixpkgs {
                    inherit system;
                };
            };
        } {
            # `packages` is a system-dependent attribute.
            # As such, `mkFlakeWith` will automatically
            # declare the `hello` package for all of the default systems.
            packages = {pkgs}: {
                hello = pkgs.hello;
            };

            # `overlays` is not a system-dependent attribute.
            # As such, `mkFlakeWith` will leave it as is.
            # Note that here you do not have access to the `pkgs` attribute.
            overlays = {
                add-custom-package = final: prev: {
                    custom = final.callPackage ./packages/custom.nix {};
                };
            };
        };
}
```

Running `nix flake show --all-systems` with this flake yields the following result:

```
├───overlays
│   └───add-custom-package: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   └───hello: package 'hello-2.12.2' - 'Program that produces a familiar, friendly greeting'
    ├───aarch64-linux
    │   └───hello: package 'hello-2.12.2' - 'Program that produces a familiar, friendly greeting'
    ├───x86_64-darwin
    │   └───hello: package 'hello-2.12.2' - 'Program that produces a familiar, friendly greeting'
    └───x86_64-linux
        └───hello: package 'hello-2.12.2' - 'Program that produces a familiar, friendly greeting'
```

### `lib.mkFlake :: attrset -> attrset`

Same as `lib.mkFlakeWith {}` - that is, using the default `systems` and `forEachSystem` attributes.
