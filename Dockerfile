FROM debian:bullseye-slim as base
RUN apt-get update -qqy
RUN apt-get install -qqy librocksdb-dev=6.11.4-3

### Electrum Rust Server ###
FROM base as electrs-build
RUN apt-get install -qqy cargo clang cmake build-essential

# Install electrs
WORKDIR /build/electrs
COPY . .
ENV ROCKSDB_INCLUDE_DIR=/usr/include
ENV ROCKSDB_LIB_DIR=/usr/lib
RUN cargo install --locked --path .

FROM base as result
# Copy the binaries
COPY --from=electrs-build /root/.cargo/bin/electrs /usr/bin/electrs

WORKDIR /
