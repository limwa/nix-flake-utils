# This file contains a collection of utility functions that provide more complex functionality than Nix's built-in functions.
rec {
  # Lists
  zip2 = zip2' (x: y: [x y]);
  zip2' = fn: xs: ys:
    if xs == [] || ys == []
    then []
    else [(fn (builtins.head xs) (builtins.head ys))] ++ zip2' fn (builtins.tail xs) (builtins.tail ys);

  # Attrsets
  nameValuePair = name: value: {inherit name value;};
  attrEntries = attrs: zip2' nameValuePair (builtins.attrNames attrs) (builtins.attrValues attrs);

  # Paths
  tryReadFile = try' builtins.pathExists builtins.readFile;
  tryImport = try' builtins.pathExists import;

  # Null values
  fallback = x: y:
    if x != null
    then x
    else y;

  fallthrough = values: default: let
    first = builtins.head values;
    rest = builtins.tail values;
  in
    fallback first (
      if rest == []
      then default
      else fallthrough rest default
    );

  try = try' (x: x != null);
  try' = cond: fn: arg:
    if cond arg
    then fn arg
    else null;
}
