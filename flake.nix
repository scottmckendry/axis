{
  description = "AXIS - Automated eXperimental Infrastructure System dev shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
              curl
              fluxcd
              fzf
              git
              jq
              just
              kubectl
              kubectl-cnpg
              libsecret
              restic
              sops
              talosctl
              yq-go
            ];
          };
        }
      );
    };
}
