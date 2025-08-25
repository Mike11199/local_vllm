## Notes

- Experimenting with Cline and a local LLM.
- Had most success with https://huggingface.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF which works with Cline. Other models won't use the Cline tools correctly.
- Could get vLLM working but kept getting bugs with messaging needing render templates - so easiest just to keep using LM studio and not use this repo.

<img width="1368" height="385" alt="image" src="https://github.com/user-attachments/assets/31662036-8b12-4799-bced-4d0b2f7a3413" />
<img width="1825" height="1038" alt="image" src="https://github.com/user-attachments/assets/05dd5511-20a4-4f03-97c3-2562b4656f29" />


## Quickstart

```
docker build -f Dockerfile.quant -t vllm-pixtral-quant .
./start.sh quant
```

---

## What is vLLM?

**vLLM** is an optimized serving engine for large language models (UC Berkeley).
It provides **PagedAttention** (efficient long‑context), **high throughput**, and an **OpenAI‑compatible API**, and runs HF models (BF16/FP16, GPTQ/AWQ) including multimodal variants like Pixtral.

---

# vLLM + Pixtral‑12B (Vision + Long Context)

Spin up a **local OpenAI‑compatible API** powered by **vLLM**.  
Supports **PagedAttention** (fast long‑context) and **multimodal inputs** (images + text).

This repo includes **two Dockerfiles** you created:

- `Dockerfile.full` → Full precision (**BF16**) Pixtral‑12B (`mistralai/Pixtral-12B-2409`)
- `Dockerfile.quant` → **Quantized** (**4‑bit GPTQ W4A16**) Pixtral‑12B (`nintwentydo/pixtral-12b-2409-W4A16-G128`)

---

## 1) Build the images

```bash
# Full precision (BF16)
docker build -f Dockerfile.full -t vllm-pixtral-full .

# Quantized (W4A16 GPTQ, recommended)
docker build -f Dockerfile.quant -t vllm-pixtral-quant .
```

---

## 2) Run (pretrained from Hugging Face)

> These Dockerfiles are built **without a CMD** to avoid ENTRYPOINT clashes.  
> We pass server flags at run time so it’s explicit and flexible.

### Linux/macOS (bash)

```bash
# Full precision
docker run --gpus all --ipc=host -p 8000:8000 \
  -e HF_TOKEN=${HF_TOKEN} \
  vllm-pixtral-full \
  --model mistralai/Pixtral-12B-2409 \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --trust-remote-code \
  --gpu-memory-utilization 0.90

# Quantized (W4A16)
docker run --gpus all --ipc=host -p 8000:8000 \
  -e HF_TOKEN=${HF_TOKEN} \
  vllm-pixtral-quant \
  --model nintwentydo/pixtral-12b-2409-W4A16-G128 \
  --host 0.0.0.0 --port 8000 \
  --dtype auto \
  --max-model-len 32768 \
  --trust-remote-code \
  --gpu-memory-utilization 0.90
```

The server exposes an **OpenAI‑compatible API** at:  
`http://localhost:8000/v1`

---

## 3) Run with a **manual local model** (no HF download)

Mount your local model directory and override `--model` with the container path.

### Linux/macOS (bash)

```bash
docker run --gpus all --ipc=host -p 8000:8000 \
  -v /ABS/PATH/TO/model:/models/custom:ro \
  vllm-pixtral-quant \
  --model /models/custom \
  --host 0.0.0.0 --port 8000 \
  --dtype auto \
  --max-model-len 32768 \
  --trust-remote-code \
  --gpu-memory-utilization 0.90
```

> The container path must be **Linux‑style** (e.g., `/models/custom`). The `:ro` mount keeps it read‑only.

---

## 4) Start script

Use the provided **`start.sh`** to run either image quickly.

```bash
./start.sh quant         # runs vllm-pixtral-quant (W4A16) on port 8000
./start.sh full          # runs vllm-pixtral-full (BF16) on port 8000
./start.sh quant 9000    # same, but bind API to port 9000
./start.sh local /abs/path/to/model-dir   # run local model (quant image) on port 8000
```

---

## 5) Test the API

**List Models**

```bash
curl http://localhost:8000/v1/models
```

**Test Paged Attention**

```bash
curl -s http://localhost:8000/metrics | grep -i -E 'cache|kv|paged'
```

**Basic text (quant model id):**

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"nintwentydo/pixtral-12b-2409-W4A16-G128",
    "messages": [
      {"role":"system","content":"Be concise. Reply with a short greeting only."},
      {"role":"user","content":"Say hello"}
    ],
    "temperature": 0,
    "max_tokens": 16
  }'
```

---

## 6) Connect from GUIs

### Cline (VS Code)

- **Provider:** OpenAI‑compatible (Custom)
- **Base URL:** `http://localhost:8000/v1`
- **API Key:** any string (ignored by vLLM)
- **Model:** `mistralai/Pixtral-12B-2409` (or `nintwentydo/pixtral-12b-2409-W4A16-G128`)

### LM Studio

- **Providers → Add Custom (OpenAI)**
  - Base URL: `http://localhost:8000/v1`
  - API Key: any string
  - Model: same as above
- You can attach images for models that support vision.

---
