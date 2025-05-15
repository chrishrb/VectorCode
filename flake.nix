{
  description = "Python template";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      self,
      ...
    }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        pkgVersion = "0.5.6";

        dependencies = with pkgs.python312Packages; [
          chromadb
          httpx
          numpy
          pathspec
          psutil
          pygments
          sentence-transformers
          shtab
          tabulate
          transformers
          tree-sitter
          tree-sitter-language-pack
          google-api-python-client
          colorlog
          json5
          lsprotocol
          pygls
        ];
        pythonEnv = pkgs.python312.withPackages (ps: dependencies);

        vectorcode = pkgs.python312Packages.buildPythonApplication rec {
          pname = "vectorcode";
          version = pkgVersion;
          format = "pyproject";

          src = self;

          nativeBuildInputs = with pkgs; [
            python312Packages.pdm-backend
            installShellFiles
          ];

          propagatedBuildInputs = dependencies;

          makeWrapperArgs = [
            "--set PYTHONPATH ${pythonEnv}/${pythonEnv.sitePackages}"
          ];

          optional-dependencies = with pkgs.python312Packages; {
            intel = [
              openvino
              optimum
            ];
            legacy = [
              numpy
              torch
              transformers
            ];
            lsp = [
              lsprotocol
              pygls
            ];
            mcp = [
              mcp
              pydantic
            ];
          };

          pythonImportsCheck = [ "vectorcode" ];

          nativeCheckInputs = with pkgs.python312Packages; [
            mcp
            pygls
            pytestCheckHook
            pytest-asyncio
          ];
          versionCheckProgramArg = "version";

          postInstall = ''
            mkdir -p $out/share/completions

            installShellCompletion --cmd vectorcode \
            --bash <(${pkgs.python312Packages.shtab}/bin/shtab --shell=bash -u vectorcode.cli_utils.get_cli_parser) \
            --zsh <(${pkgs.python312Packages.shtab}/bin/shtab --shell=zsh -u vectorcode.cli_utils.get_cli_parser)
          '';

          disabledTests = [
            # Require internet access
            "test_get_embedding_function"
            "test_get_embedding_function_fallback"
            "test_reranker"
            "test_common"
          ];

          meta = {
            description = "Code repository indexing tool to supercharge your LLM experience";
            homepage = "https://github.com/Davidyz/VectorCode";
            changelog = "https://github.com/Davidyz/VectorCode/releases/tag/${version}";
            license = pkgs.lib.licenses.mit;
            maintainers = with pkgs.lib.maintainers; [ GaetanLepage ];
            mainProgram = "vectorcode";
          };
        };
      in
      {
        packages = {
          default = vectorcode;
          vimPlugin = pkgs.vimUtils.buildVimPlugin {
            pname = "VectorCode";
            version = pkgVersion;
            src = self;
            dependencies = [
              pkgs.vimPlugins.plenary-nvim
            ];
            patches = pkgs.replaceVars ./nix/vim-plugin.patch {
              inherit vectorcode;
            };
          };
        };
      }
    );
}
