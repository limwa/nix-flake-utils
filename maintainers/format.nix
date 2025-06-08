{pkgs ? import <nixpkgs> {}}:
pkgs.mkShellNoCC {
  packages = [pkgs.alejandra];

  shellHook = ''
    alejandra .
    exit $?
  '';
}
