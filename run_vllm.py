import os
import argparse
import subprocess
import sys

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--model", default=os.getenv("VLLM_MODEL", "mistralai/Pixtral-12B-2409"))
    p.add_argument("--port", default=os.getenv("VLLM_PORT", "8000"))
    p.add_argument("--host", default=os.getenv("VLLM_HOST", "0.0.0.0"))
    p.add_argument("--max_len", type=int, default=int(os.getenv("VLLM_MAX_LEN", "32768")))
    p.add_argument("--dtype", default=os.getenv("VLLM_DTYPE", "bfloat16"))  # use "auto" for GPTQ/AWQ
    p.add_argument("--gpu_memory_utilization", default=os.getenv("VLLM_GPU_UTIL", "0.95"))
    p.add_argument("--trust_remote_code", action="store_true", default=True)
    args = p.parse_args()

    cmd = [
        sys.executable, "-m", "vllm.entrypoints.openai.api_server",
        "--model", args.model,
        "--host", args.host,
        "--port", str(args.port),
        "--max-model-len", str(args.max_len),
        "--dtype", args.dtype,
        "--gpu-memory-utilization", args.gpu_memory_utilization
    ]
    if args.trust_remote_code:
        cmd.append("--trust-remote-code")

    print("Launching vLLM with:", " ".join(cmd))
    os.execvp(cmd[0], cmd)

if __name__ == "__main__":
    main()
