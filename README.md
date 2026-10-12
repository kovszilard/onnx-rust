# onnx-rust

A Rust project that packages an ML model for inference with [ONNX Runtime](https://onnxruntime.ai/),
using the [`ort`](https://crates.io/crates/ort) crate. It runs sentiment analysis on movie reviews.

The model is [DistilBERT fine-tuned on SST-2](https://huggingface.co/distilbert/distilbert-base-uncased-finetuned-sst-2-english),
a dataset of sentences from movie reviews. It classifies text as positive or negative:

```
POSITIVE (0.9999)  I love this movie!
NEGATIVE (0.0002)  This was a complete waste of time.
```

The number is the probability that the review is positive.

## Run with Docker

```sh
docker build -t onnx-rust .
docker run --rm onnx-rust
```

The build exports the model to ONNX, compiles the binary, and packages both into a slim image.

## Run with Nix

```sh
nix develop   # Rust toolchain + Python export tools

optimum-cli export onnx \
  --model distilbert-base-uncased-finetuned-sst-2-english \
  --task text-classification \
  distilbert_sst2_onnx/

cargo run --release
```

## How it works

1. [`tokenizers`](https://crates.io/crates/tokenizers) turns the text into token ids and an attention mask.
2. `ort` runs the ONNX model, which returns two logits: negative and positive.
3. The logits are converted to a probability: `1 / (1 + exp(negative - positive))`.
