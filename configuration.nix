{ pkgs, inputs, config, modulesPath, ... }: {
    imports = [ 
        "${modulesPath}/virtualisation/amazon-image.nix"
    ];
    
    # turn this to false when dashboard is put into a derivation
    nix.enable = true;

    users.users.poetfolio = {
        isNormalUser = true;
        home = "/home/poetfolio";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHi147srccRTMnUiFn9kZYaoS6z29UUkCHpNBqPZFII/ ekiree" ];
    };

    # Install packages
    environment.systemPackages = with pkgs; [
        git
        jq
        sops
        python311Packages.gunicorn
    ];

    # Enable ssh
    services.openssh.enable = true;

    #Activate firewall
    # networking = {
    #     enable = true;
    #     firewall.allowedTCPPorts = [80 443 22 ];
    # };

    #Systemd Socket and Service for gunicorn
    environment.etc = { 
        # gunicorn.socket
        # "systemd/system/gunicorn.socket" = { 
        #     text = ''
        #         [Unit]
        #         Description=gunicorn socket

        #         [Socket]
        #         ListenStream=/run/gunicorn.sock

        #         [Install]
        #         WantedBy=sockets.target
        #     '';
        # };

        # gunicorn.service
        # "systemd/system/gunicorn.service" = { 
        #     text = ''
        #         [Unit]
        #         Description=gunicorn daemon
        #         Requires=gunicorn.socket
        #         After=network.target

        #         [Service]
        #         User=poetfolio
        #         Group=www-data
        #         WorkingDirectory=/home/poetfolio/WSP-Dashboard/dashboard_project
        #         ExecStart=${pkgs.python311Packages.gunicorn}bin/gunicorn \
        #                   --access-logfile - \
        #                   --workers 3 \
        #                   --bind unix:/run/gunicorn.sock \
        #                   poetfolio.wsgi:application

        #         [Install]
        #         WantedBy=multi-user.target
        #     '';
        # };
    };

    #Set environmental variables
    system.activationScripts = {
        prod.text = ''
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

        '';
    };

    system.stateVersion = "24.05";
}
