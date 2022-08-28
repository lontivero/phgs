# Portable Hidden Git Server

A minimalistic and reproducible, ready to deploy and immutable [git daemon](https://git-scm.com/book/en/v2/Git-on-the-Server-Git-Daemon) service published as a [Tor onion service](https://community.torproject.org/onion-services/).

## What is this

This project contains a [Nix Flake](https://xeiaso.net/blog/series/nix-flakes) that once built generates a [systemd portable service](https://systemd.io/PORTABLE_SERVICES/) 
(a single file under the name `personal.raw`) that can be "plug" to any Linux that supports systemd. The `personal.raw` file is just a 
compressed read-only filesystem for Linux containing all what is needed (`git`, `tor`, `nginx` and all their dependencies, and the config files too)


## How to build

```console
$ nix build .#portable
```

Then you have to "attach" the portable service to the systemd system:

```console
# mv result /var/lib/portables/personal.raw
# portablectl attach --enable --now personal
```

And that's it. You can verify `personal.tor-server.service`, `personal.git-server.service` and `personal.nginx.service` are working properly with:

```console
systemctl status personal.tor-server.service
systemctl status personal.git-server.service
systemctl status personal.nginx.service
```

**Note:** it is possible to browse the generated filesystem by building a different flake output called `rootfs`:

```console
nix build .#rootfs
```

After that the `result` link will contain the directory tree instead of the squashed filesystem.

## What next

* nginx server to provide git over http.
* support https (certbot)
* use systemd private network's to isolate network communication
* map ports to standard ones with iptable
* make all this more configurable (ips, ports, hidden service private keys)

----

This is heavily "inspired" on the work of [Xe](https://xeiaso.net/)'s [Nix Flakes: Packages and How to Use Them](https://xeiaso.net/blog/nix-flakes-2-2022-02-27) and Дамјан Георгиевски's [Tiny Tiny RSS](https://github.com/gdamjan/tt-rss-service)
