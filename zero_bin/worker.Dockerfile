FROM rustlang/rust:nightly-bullseye-slim as builder

# Install jemalloc
RUN apt-get update && apt-get install -y libjemalloc2 libjemalloc-dev make

RUN \
  mkdir -p ops/src     && touch ops/src/lib.rs && \
  mkdir -p worker/src  && echo "fn main() {println!(\"YO!\");}" > worker/src/main.rs

COPY Cargo.toml .
RUN sed -i "2s/.*/members = [\"ops\", \"worker\"]/" Cargo.toml
COPY Cargo.lock .

COPY ops/Cargo.toml ./ops/Cargo.toml
COPY worker/Cargo.toml ./worker/Cargo.toml

RUN cargo build --release --bin worker 

COPY ops ./ops
COPY worker ./worker
RUN \
  touch ops/src/lib.rs && \
  touch worker/src/main.rs

RUN cargo build --release --bin worker 

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates libjemalloc2
COPY --from=builder ./target/release/worker /usr/local/bin/worker
CMD ["worker"]
