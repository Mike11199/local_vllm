## What is vLLM?

**vLLM** is an optimized serving engine for large language models, originally developed by researchers at UC Berkeley.

### Key Features

- **PagedAttention** → memory-efficient attention mechanism that makes very long contexts (e.g., 128k tokens) practical and fast.
- **High performance** → achieves higher tokens/sec compared to llama.cpp or vanilla Hugging Face Transformers.
- **Scalable** → can batch requests, stream tokens, and serve multiple users simultaneously.
- **OpenAI-compatible API** → exposes `/v1/chat/completions` so you can use it directly with tools like LM Studio, Cline, Open WebUI, or LangChain.
- **Model support** → runs models from Hugging Face in FP16/BF16 as well as quantized formats (GPTQ, AWQ). Multimodal models (e.g., Pixtral, LLaVA) are supported too.

### Why use vLLM?

- If you want **long context windows (64k–128k)** without massive slowdowns.
- If you need **multimodal vision+text** reasoning to actually work (OCR, charts, screenshots).
- If you’re serving **multiple users or tools** and need batching + throughput.
- If you want a **drop-in local replacement for OpenAI’s API**.

# Running vLLM with Pixtral-12B (Vision + Long Context)

- Spin up a **local OpenAI-compatible API** powered by **vLLM**.  
- Supports **PagedAttention** (fast long-context) and **multimodal inputs** (images + text).

---

## Prerequisites

- Python **3.9+**
- NVIDIA GPU (e.g., **RTX 4090/5090**, A10G, A100)
- Recent NVIDIA drivers (CUDA installed)

---

## Setup

```bash
# Create virtual environment
python -m venv .venv
# On macOS/Linux:
source .venv/bin/activate
# On Windows (PowerShell):
# .\.venv\Scripts\Activate.ps1

# Install vLLM
pip install --upgrade pip vllm

# (Optional) if your model is private on Hugging Face:
pip install huggingface_hub
huggingface-cli login
```

---

## Run (Python, Pixtral-12B)

### Standard (Pixtral-12B, **32k** context)

```bash
python run_vllm.py --model mistralai/Pixtral-12B-2409 --max_len 32768 --dtype bfloat16
```

### Quantized build (GPTQ / AWQ)

```bash
python run_vllm.py --model your-hf-user/Pixtral-12B-GPTQ-Q5 --dtype auto --max_len 32768
```

**Notes**

- `--max_len` sets context length (use `131072` for full **128k**; larger = more VRAM, slower).
- `--dtype bfloat16` for full precision; use `--dtype auto` for quantized models.

---

## Test the API

### Basic text test

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"mistralai/Pixtral-12B-2409",
    "messages":[{"role":"user","content":"Say hello"}],
    "temperature":0
  }'
```

### Image + text test

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"mistralai/Pixtral-12B-2409",
    "messages":[
      {"role":"user","content":[
        {"type":"text","text":"Describe the image in one sentence."},
        {"type":"image_url","image_url":{"url":"file:///ABSOLUTE/PATH/to/image.png"}}
      ]}
    ],
    "temperature":0
  }'
```


---

## Integrations (GUI / Clients)

Point any OpenAI-compatible client at your local server:

- **Base URL:** `http://localhost:8000/v1`
- **Model name:** the exact string you passed to `--model`

Works with:

- **LM Studio** → Add **Custom/OpenAI** provider with the Base URL above.
- **Cline (VS Code)** → Provider: OpenAI-compatible, same Base URL + model.
- **Open WebUI** → Set OpenAI Base URL to your local endpoint.

---

## Optional: Docker (no Python env)

**One-liner**

```bash
docker run --gpus all -p 8000:8000 --ipc=host \
  -e HF_TOKEN=${HF_TOKEN} \
  vllm/vllm-openai:latest \
  --model mistralai/Pixtral-12B-2409 \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --trust-remote-code \
  --gpu-memory-utilization 0.95
```

**Dockerfile**

```dockerfile
FROM vllm/vllm-openai:latest
ENV VLLM_MODEL=mistralai/Pixtral-12B-2409 \
    VLLM_DTYPE=bfloat16 \
    VLLM_PORT=8000 \
    VLLM_MAX_LEN=32768
EXPOSE 8000
CMD ["bash","-lc","python -m vllm.entrypoints.openai.api_server \
  --model ${VLLM_MODEL} \
  --host 0.0.0.0 --port ${VLLM_PORT} \
  --dtype ${VLLM_DTYPE} \
  --max-model-len ${VLLM_MAX_LEN} \
  --trust-remote-code \
  --gpu-memory-utilization 0.95"]
```

---

## Troubleshooting

- **Slow at very long context (e.g., 128k)** → that’s expected; increase only when needed.
- **Out of memory** → use a **quantized** model (`--dtype auto`), reduce `--max_len`, or lower image resolution.
- **Permission error on images (Windows)** → ensure the `file:///` path is absolute and accessible.

---
