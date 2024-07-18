{
    description = "Dashboard Nix Package";

    inputs = {
        # Nix Packages
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
        flake-utils = {
            url = "github:numtide/flake-utils";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        #poetry2nix
        poetry2nix = {
            url = "github:nix-community/poetry2nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, flake-utils, poetry2nix, ... }: 
        flake-utils.lib.eachDefaultSystem (system: 
            let
                pkgs = nixpkgs.legacyPackages.${system};
                
                # Setting up nix2poetry
                inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
                    mkPoetryApplication
                    mkPoetryEnv
                    defaultPoetryOverrides
                ;
                
                # Configure production python application with poetry2nix
                poetryProd = mkPoetryApplication {
                    projectDir = self;
                    overrides = p2n-overrides;
                };
               
                # Configure development python environment with poetry2nix
                poetryDev = mkPoetryEnv {
                  projectDir = self;
                  overrides = p2n-overrides;
                };
                
                # Configure build dependencies for individual python packages
                pypkgs-build-requirements = {
                    django-localflavor = [ "setuptools" ];
                };
                p2n-overrides = defaultPoetryOverrides.extend (self: super:
                  builtins.mapAttrs (package: build-requirements:
                    (builtins.getAttr package super).overridePythonAttrs (old: {
                      buildInputs = (old.buildInputs or [ ]) ++ (builtins.map (pkg: if builtins.isString pkg then builtins.getAttr pkg super else pkg) build-requirements);
                    })
                  ) pypkgs-build-requirements
                );
            in
            {
                # Production Application Package
                packages.default = poetryProd.dependencyEnv;

                # Development shell 
                devShells.default = pkgs.mkShell { 
                    packages = [
                        pkgs.poetry
                        pkgs.jq
                        pkgs.sops
                        poetryDev
                    ];

                    # Command run upon shell start
                    shellHook = ''
                        export POETFOLIO_SECRET_KEY=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_secret_key)
                        export POETFOLIO_PRODUCTION=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_production)
                        export POETFOLIO_DB_NAME=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_db_name)
                        export POETFOLIO_DB_USER=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_db_user)
                        export POETFOLIO_DB_PASSWORD=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_db_password)

                        export POETFOLIO_DB_HOST=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_db_host)
                        export POETFOLIO_STATIC=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_static)
                        export POETFOLIO_MEDIA=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_media)
                        export POETFOLIO_EMAIL_HOST=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_email_host)
                        export POETFOLIO_EMAIL_USER=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_email_user)
                        export POETFOLIO_EMAIL_PASSWORD=$(sops  --decrypt ./secrets/secrets.json | jq -r .poetfolio_email_password)

                        export PS1="\n(develop)\[\033[1;32m\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\$\[\033[0m\] "
                    '';
                }; 
            });
}
