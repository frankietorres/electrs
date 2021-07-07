FROM debian:bullseye-slim as base
RUN apt-get update -qqy
RUN apt-get install -qqy librocksdb-dev=6.11.4-3 wget

### Electrum Rust Server ###
FROM base as electrs-build
RUN apt-get install -qqy cargo clang cmake build-essential

# Install electrs
WORKDIR /build/electrs
COPY . .
ENV ROCKSDB_INCLUDE_DIR=/usr/include
ENV ROCKSDB_LIB_DIR=/usr/lib
RUN cargo install --locked --path .

### Bitcoin Core ###
FROM base as bitcoin-build
# Download
WORKDIR /build/bitcoin
ARG BITCOIND_VERSION=22.0
RUN wget -q https://bitcoincore.org/bin/bitcoin-core-$BITCOIND_VERSION/bitcoin-$BITCOIND_VERSION-x86_64-linux-gnu.tar.gz
RUN tar xvf bitcoin-$BITCOIND_VERSION-x86_64-linux-gnu.tar.gz
RUN mv -v bitcoin-$BITCOIND_VERSION/bin/bitcoind .
RUN mv -v bitcoin-$BITCOIND_VERSION/bin/bitcoin-cli .

FROM base as result
# Copy the binaries
COPY --from=electrs-build /root/.cargo/bin/electrs /usr/bin/electrs
COPY --from=bitcoin-build /build/bitcoin/bitcoind /build/bitcoin/bitcoin-cli /usr/bin/
RUN bitcoind -version && bitcoin-cli -version

### Electrum ###
# Clone latest Electrum wallet and a few test tools
WORKDIR /build/
RUN apt-get install -qqy git libsecp256k1-0 python3-cryptography python3-setuptools python3-pip jq curl
RUN git clone --recurse-submodules https://github.com/spesmilo/electrum/ && cd electrum/ && git log -1
RUN python3 -m pip install -e electrum/

RUN electrum version --offline
WORKDIR /
