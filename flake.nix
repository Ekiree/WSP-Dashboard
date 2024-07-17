{
    description = "Dashboard Nix Package";

    inputs = {
        # Nix Packages
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
        flake-utils.url = "github:numtide/flake-utils";

        #poetry2nix
        poetry2nix = {
            url = "github:nix-community/poetry2nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, flake-utils, poetry2nix, ... }: 
        flake-utils.lib.eachDefaultSystem (system: 
            let
                inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs; }) mkPoetryApplication mkPoetryEnv defaultPoetryOverrides;
                pkgs = nixpkgs.legacyPackages.${system};
                system = "x86_64-linux";
            in
            {
                # Production Packages
                packages = {
                    dashboard = mkPoetryApplication { projectDir = self; };
                    default = self.packages.${system}.dashboard;


                };

                # Shell for app dependencies.
                #
                #     nix develop
                #
                # Use this shell for developing your app.
                devShells.${system}.default = mkPoetryEnv { 
                    projectDir = self;

                    # Overide packates to uset setuptools
                    overrides = defaultPoetryOverrides.extend (self: super: {
                        django-localflavor = super.django-localflavor.overridePythonAttrs
                        (
                            old: {
                                buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                            }
                        );
                    });

                    # Packages
                    buildInputs = [
                        pkgs.sops
                        pkgs.jq
                        pkgs.libmysqlclient
                    ];

                    inputsFrom = [ 
                        self.packages.${system}.dashboard 
                    ];

                    # Command run upon shell start
                    shellHook = ''
                        export POETFOLIO_SECRET_KEY=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_secret_key)
                        export POETFOLIO_PRODUCTION=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_production)
                        export POETFOLIO_DB_NAME=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_db_name)
                        export POETFOLIO_DB_USER=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_db_user)
                        export POETFOLIO_DB_PASSWORD=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_db_password)
                        export POETFOLIO_STATIC=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_static)
                        export POETFOLIO_MEDIA=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_media)
                        export POETFOLIO_EMAIL_HOST=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_email_host)
                        export POETFOLIO_EMAIL_USER=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_email_user)
                        export POETFOLIO_EMAIL_PASSWORD=$(sops  --decrypt secrets/secrets.json | jq -r .poetfolio_email_password)

                        export PS1="\n(develop)\[\033[1;32m\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\$\[\033[0m\] "
                        echo "Development Shell Initialized"
                    '';
                }; 

                # Shell for poetry.
                #
                #     nix develop .#poetry
                #
                # Use this shell for changes to pyproject.toml and poetry.lock.
                devShells.poetry = pkgs.mkShell {
                    packages = [ 
                        pkgs.poetry 
                    ];
                };
            });
}
