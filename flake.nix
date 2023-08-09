{
  description = "flake for ptags.nvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix";

    ptags = {
      url = "git+https://github.com/dkuettel/ptags.nvim?submodules=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ptags, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        machNix = import mach-nix {
          inherit pkgs;
          python = "python310";
        };

        ptagsPythonDependencies = machNix.mkPython {
          # TODO: requirements = builtins.readFile ./python/requirements.txt;

          requirements = ''
            setuptools
            typer==0.7.0
            tabulate==0.9.0
            tree_sitter==0.20.1
          '';

          providers = {
            _default = "wheel";
            tree-sitter = "nixpkgs,sdist";
          };
        };

        ptagsNeovimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "ptags_nvim";
          version = "latest";
          src = ptags;

          buildInputs = [ ptagsPythonDependencies pkgs.makeWrapper ];
          buildPhase = ''
            python3.10 python/ptags.py python/ptags.py
          '';

          # patch bin/ptags to use our Python
          postInstall = ''
            echo "python3.10 $out/python/ptags.py \$@" > $out/bin/ptags
            wrapProgram $out/bin/ptags --prefix PATH : ${ptagsPythonDependencies}/bin \
          '';
        };

      in
      {
        packages = {
          default = ptagsNeovimPlugin;
          ptags_nvim = ptagsNeovimPlugin;
        };
      }
    );
}
