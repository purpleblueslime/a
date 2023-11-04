# build rchef for chef
FROM rust:1.72.0 AS chef
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL sparse
WORKDIR /chef
ADD https://github.com/booleancoercion/rchef/archive/refs/heads/main.tar.gz main.tar.gz
RUN tar -xvf main.tar.gz
WORKDIR /chef/rchef-main
RUN cargo build -r && ./target/release/rchef --version

# download zig
FROM ubuntu:23.10 AS zig
ARG ZIG_VERSION=0.11.0
RUN apt-get update && apt-get -qq install -y --no-install-recommends xz-utils
WORKDIR /zig
ADD https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz /tmp
RUN tar -xvf /tmp/zig-linux-x86_64-${ZIG_VERSION}.tar.xz
RUN mv zig-linux-x86_64-${ZIG_VERSION}/ zig

FROM ubuntu:23.10
ENV DEBIAN_FRONTEND noninteractive
RUN rm /etc/dpkg/dpkg.cfg.d/excludes

# bats for testing
COPY --from=bats/bats /opt/bats/ /opt/bats/
RUN ln -s /opt/bats/bin/bats /usr/local/bin/

# chef
COPY --from=chef /chef/rchef-main/target/release/rchef /usr/bin

# zig
COPY --from=zig /zig/zig /opt/zig/
RUN ln -s /opt/zig/zig /usr/local/bin/

# apt
RUN <<EOS
cat > /etc/apt/apt.conf.d/01norecommend <<'EOF'
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

apt-get update
# git for `spago install`
apt-get -qq install -y git
# bc
apt-get -qq install -y bc
# brainfuck
apt-get -qq install -y beef
# c
apt-get -qq install -y gcc
# c++
apt-get -qq install -y g++
# dc
apt-get -qq install -y dc
# elixir
apt-get -qq install -y elixir
# go
apt-get -qq install -y golang
# haskell
apt-get -qq install -y ghc
# js
apt-get -qq install -y nodejs npm
# nim
apt-get -qq install -y nim
# python
apt-get -qq install -y python3 python3-pip
# r
apt-get -qq install -y r-base
# ruby
apt-get -qq install -y ruby
# rust
apt-get -qq install -y rustc
apt-get clean
rm -rf /var/lib/apt/lists/*
EOS

# malbolge
ADD https://raw.githubusercontent.com/bipinu/malbolge/master/malbolge.c malbolge.c
RUN gcc malbolge.c && mv a.out /usr/local/bin/malbolge && rm malbolge.c

# nadesiko, purescript
RUN npm install -g nadesiko3core purescript spago

# whitespace
RUN mkdir -p ~/.pip && printf '[global]\nbreak-system-packages = true\n'  > ~/.pip/pip.conf && pip install whitespace

WORKDIR /workspaces/a
CMD ["/usr/bin/env", "bash"]
