#!/bin/sh
set -eu
export PATH="/usr/local/sbin:/usr/local/bin:/usr/pkg/sbin:/usr/pkg/bin:/usr/pkg/gnu/bin:$PATH"
uname -a
case "$(uname -s)" in
  FreeBSD|DragonFly)
    pkg update -f
    pkg upgrade -y
    pkg install -y rust
    ;;
  OpenBSD) pkg_add -I rust ;;
  NetBSD)
    command -v pkgin >/dev/null 2>&1 || pkg_add pkgin
    repositories=${PKG_PATH:-$(sed -n 's/^PKG_PATH=//p' /etc/pkg_install.conf)}
    [ -n "$repositories" ]
    mkdir -p /usr/pkg/etc/pkgin
    printf '%s\n' "$repositories" | tr ';' '\n' > /usr/pkg/etc/pkgin/repositories.conf
    pkgin -y update
    pkgin -y upgrade
    pkgin -y install rust
    ;;
  *) exit 2 ;;
esac
# Use guest-local storage so Cargo file locks and timestamps do not depend on NFS.
work=$(mktemp -d /var/tmp/socket-pktinfo.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
cp Cargo.toml "$work/"
cp -R src tests "$work/"
mkdir -p "$work/cargo-home" "$work/tmp"
export CARGO_HOME="$work/cargo-home" TMPDIR="$work/tmp" CARGO_BUILD_JOBS=2
cd "$work"
rustc --version
cargo --version
cargo test --test loopback -- --nocapture
cargo test --lib
cargo test --doc
