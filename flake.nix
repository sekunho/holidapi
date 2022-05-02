{
  description = "Holidefs API: A JSON API interface for the `holidefs` library.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
    in {

      devShells."${system}".default = pkgs.mkShell {
        buildInputs = with pkgs; [
          elixir
          erlang
          elixir_ls
        ];

        LANG="en_US.UTF-8";
        LC_TYPE="en_US.UTF-8";
      };

    };
}
