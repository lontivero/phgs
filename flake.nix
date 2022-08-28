{
  description = "My personal server setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      squash-compression = "xz -Xdict-size 100%";
      version = builtins.substring 0 8 self.lastModifiedDate;
    in {

        rootfs = pkgs.stdenv.mkDerivation {
          name = "rootfs";
          tor = pkgs.tor;
          git = pkgs.git;
          nginx = pkgs.nginx;
          certbot = pkgs.certbot;
          coreutils = pkgs.coreutils;
          buildCommand = ''
              # Prepare the portable service file-system layout
              mkdir -p $out/etc/systemd/system $out/proc $out/sys $out/dev $out/run $out/tmp $out/var/tmp $out/var/lib
              touch $out/etc/resolv.conf $out/etc/machine-id
              cp ${./files/os-release} $out/etc/os-release

              # Create the mount-point for the cert store
              mkdir -p $out/var/{lib,log,cache}/{nginx,git,tor/onion_service}
              ln -sf /var/lib/private/tor $out/var/lib/tor
              ln -sf /var/lib/private/git $out/var/lib/git 
              ln -sf /var/lib/private/nginx $out/var/lib/nginx 
              ln -sf /var/log/private/nginx $out/var/log/nginx 

              mkdir -p $out/run/nginx

              # setup systemd units
              substituteAll ${./files/git-server.service.in} $out/etc/systemd/system/personal.git-server.service
              substituteAll ${./files/tor-server.service.in} $out/etc/systemd/system/personal.tor-server.service
              substituteAll ${./files/nginx.service.in} $out/etc/systemd/system/personal.nginx.service
              cp ${./files/torrc.in} $out/etc/torrc
              cp ${./files/site.in} $out/etc/www-wasabito
          '';
        };

        default = self.portable;
        
        portable = 
        pkgs.stdenv.mkDerivation {
          name = "personal.raw";
          nativeBuildInputs = [ pkgs.squashfsTools ];

          buildCommand = ''
              closureInfo=${pkgs.closureInfo { rootPaths = [ self.rootfs ]; }}
              mkdir -p nix/store
              for i in $(< $closureInfo/store-paths); do
                cp -a "$i" "''${i:1}"
              done
              # archive the nix store
              mksquashfs nix ${self.rootfs}/* $out \
                -noappend \
                -keep-as-directory \
                -all-root -root-mode 755 \
                -b 1048576 -comp ${squash-compression}
          '';
        };


        devShells.default = pkgs.mkShell {
          buildInputs = [ self.default ];
        };
  };
}
