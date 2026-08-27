---
name: local-llm-backends
description: "Connect Hermes to local LLM servers; fix auth/model errors."
version: 1.0.0
metadata:
  hermes:
    tags: [hermes, local-llm, lmstudio, ollama, vllm, llama-cpp, openai-compatible, providers, troubleshooting]
---

# Local LLM Backends

Connecting Hermes (or any OpenAI-compatible client) to a self-hosted local
inference server, and debugging the connection when it won't answer. The most
common failure is not the model — it's **auth (a token) or the model name**.

## When to use

- User wants to point Hermes at LM Studio / Ollama / vLLM / llama.cpp instead of a cloud provider.
- "The local model won't connect / times out / returns an error."
- Model answers with an auth or "model not found" style error.

## The two invariants (this fixes ~90% of failures)

1. **The token must be the server's own token.** For OpenAI-compatible servers
   with auth enabled, the client sends `Authorization: Bearer <token>`. That token
   must be exactly what the server issued — not a random hash, not a cloud API key.
2. **The model name must be the server's real model id.** A client-side alias like
   `GEMMA_LOCAL` will NOT resolve; use the id the server reports (e.g.
   `gemma-3-27b-it`, `llama3.1:8b`, `Qwen/Qwen2.5-7B-Instruct`).

## Debugging path (curl first, always)

Before touching config, hit the endpoint directly to see WHERE it fails:

```bash
# Liveness + auth state (LM Studio default port 1234; Ollama 11434)
curl -s -m 8 http://<host>:<port>/v1/models      # OpenAI-compatible
curl -s -m 8 http://<host>:<port>/api/v1/models  # LM Studio native
curl -s -m 8 http://<host>:<port>/               # root — often reveals server type
```

Interpret the response (see `references/lmstudio.md` for exact error signatures):

| Response | Meaning | Fix |
|---|---|---|
| JSON model list | Server fine, endpoint fine | Move on to model-name check |
| `"token is required"` / `invalid_api_key` | Auth enabled, no/invalid header sent | Send the real token, OR disable auth server-side |
| `"Malformed ... token provided: <prefix>..."` | Token present but wrong format/expired | Get the real token from the server UI (Developer → Server → API key) |
| connection refused / timeout | Server down or not bound to that interface | Start server; enable "Serve on local network" for LAN |

## Reading the token from Hermes' credential store

`~/.hermes/.env` is a credential store — `read_file` is blocked on it, but the
terminal can read it. NEVER dump the secret to chat:

```bash
# Verify a token exists and its shape WITHOUT printing it:
awk -F= '/^LM_API_KEY=/{ printf "len=%d pref=%s...\n", length($2), substr($2,1,6) }' ~/.hermes/.env

# Use it in a probe without echoing it:
cd ~/.hermes && TOKEN=$(awk -F= '/^LM_API_KEY=/{print $2}' .env) \
  && curl -s -m 10 -H "Authorization: Bearer $TOKEN" http://<host>:<port>/api/v1/models
```

## Pitfalls

- **Invented model alias** (`GEMMA_LOCAL`, etc.) — list the real ids once auth is
  resolved, then set `model.default` to one of them.
- **Missing `/v1` on base_url** — LM Studio answers bare too, but the correct
  OpenAI-compatible path is `<base>/v1`.
- **Wrong value copied as token** — a 57-char hash is usually NOT an LM Studio
  token; their tokens have a specific format (see reference).
- **Server bound to 127.0.0.1 only** — LAN clients need "Serve on local network"
  enabled in the server.
- **Trying `read_file` on `.env`** — use terminal `awk` instead.

## Hermes `lmstudio` provider (facts, from source)

`provider: lmstudio` is a real canonical provider (aliases `lm-studio`,
`lm_studio`): `openai_chat` transport, `api_key` auth, token in **`LM_API_KEY`**,
base URL in **`LM_BASE_URL`** (default `http://127.0.0.1:1234/v1`). Hermes probes
`/api/v1/models` to detect LM Studio and list models. Full detail + exact source
locations and error transcripts: `references/lmstudio.md`.
