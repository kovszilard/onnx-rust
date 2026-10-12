# Stage 1: download the model from Hugging Face and convert it to ONNX
FROM python:3.12-slim AS model
RUN pip install --no-cache-dir \
      --extra-index-url https://download.pytorch.org/whl/cpu \
      torch "optimum-onnx[onnxruntime]" accelerate
RUN optimum-cli export onnx \
      --model distilbert-base-uncased-finetuned-sst-2-english \
      --task text-classification \
      /distilbert_sst2_onnx/

# Stage 2: build the Rust example
FROM rust:1-trixie AS build
WORKDIR /src
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

# Stage 3: minimal runtime image (onnxruntime is linked statically)
FROM debian:trixie-slim
WORKDIR /app
COPY --from=build /src/target/release/onnx-rust ./
COPY --from=model /distilbert_sst2_onnx ./distilbert_sst2_onnx
CMD ["./onnx-rust"]
