{
  description = "VectorCode";
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

        vectorcode = pkgs.python312Packages.buildPythonApplication rec {
          pname = "vectorcode";
          version = pkgVersion;
          format = "pyproject";

          src = self;

          nativeBuildInputs = with pkgs; [
            python312Packages.pdm-backend
            makeWrapper
            installShellFiles
          ];

          propagatedBuildInputs = with pkgs.python312Packages; [
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

          postFixup = ''
            wrapProgram $out/bin/vectorcode \
              --prefix PYTHONPATH : "$out/${pkgs.python312.sitePackages}"
            wrapProgram $out/bin/vectorcode-server \
              --prefix PYTHONPATH : "$out/${pkgs.python312.sitePackages}"
            wrapProgram $out/bin/vectorcode-mcp-server \
              --prefix PYTHONPATH : "$out/${pkgs.python312.sitePackages}"
          '';

          postInstall = ''
            installShellCompletion --cmd vectorcode \
              --bash <($out/bin/vectorcode --print-completion bash) \
              --zsh <($out/bin/vectorcode --print-completion zsh)
            installShellCompletion --cmd vectorcode-server \
              --bash <($out/bin/vectorcode --print-completion bash) \
              --zsh <($out/bin/vectorcode --print-completion zsh)
            installShellCompletion --cmd vectorcode-mcp-server \
              --bash <($out/bin/vectorcode --print-completion bash) \
              --zsh <($out/bin/vectorcode --print-completion zsh)
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
