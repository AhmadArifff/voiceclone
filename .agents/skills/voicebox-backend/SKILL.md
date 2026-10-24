---
name: voicebox-backend
description: Use this skill for Python FastAPI backend engineering in Voicebox, covering TTS/STT backend protocols, model configs, serial GPU task queue, SQLAlchemy SQLite persistence, hardware acceleration detection (MLX, CUDA, ROCm, DirectML, CPU), and backend style guide compliance.
---

# Voicebox Backend Engineering Skill

## Goal

Provide architectural standards, coding conventions, and integration patterns for the Python FastAPI server in Voicebox, strictly complying with `backend/STYLE_GUIDE.md`.

## Key Files & Structure

- `backend/app.py` — FastAPI application factory, CORS setup, lifespan handlers
- `backend/server.py` — Sidecar entry point, parent-PID watchdog, frozen-build environment configuration
- `backend/models.py` — Pydantic request/response schemas
- `backend/database/models.py` — SQLAlchemy ORM models (`VoiceProfile`, `Generation`, `GenerationVersion`, `AudioChannel`)
- `backend/backends/__init__.py` — Protocols (`TTSBackend`, `STTBackend`), `ModelConfig` registry, lazy double-checked locking factory
- `backend/services/generation.py` — High-level generation service orchestrating prompts, queues, and audio post-processing
- `backend/services/task_queue.py` — Serial FIFO task queue preventing GPU contention and out-of-memory (OOM) errors

## 1. Style & Code Hygiene (`backend/STYLE_GUIDE.md`)

- **Python Version**: Target Python 3.12+ natively. Do NOT use `from __future__ import annotations` or `typing.List`/`typing.Dict`. Use native built-in generics: `list[str]`, `dict[str, Any]`, `tuple[int, str]`, and union syntax `str | None`.
- **Formatting**: Enforced by Ruff. 120 character max line length, 4 spaces indent, trailing commas on multi-line signatures/collections, double quotes `"` by default.
- **Imports**: Grouped into three blocks (stdlib, third-party, local). Use relative imports inside `backend` (`from .database import get_db`). Heavy libraries (torch, transformers, mlx) must use lazy imports inside functions with `# lazy: heavy import` comment.
- **Docstrings**: Google-style docstrings required on all public classes, functions, and modules.

## 2. TTS Backend Protocol & Registry Contract

Every new or modified TTS engine must satisfy `TTSBackend`:

```python
@runtime_checkable
class TTSBackend(Protocol):
    async def load_model(self, model_name: str) -> None: ...
    async def create_voice_prompt(self, audio_path: str, reference_text: str | None = None) -> Any: ...
    async def combine_voice_prompts(self, voice_prompts: list[Any]) -> Any: ...
    async def generate(
        self,
        text: str,
        voice_prompt: Any,
        language: str | None = None,
        model_name: str | None = None,
        instruct_text: str | None = None,
        speed: float = 1.0,
        **kwargs: Any,
    ) -> tuple[np.ndarray, int]: ...
    def unload_model(self) -> None: ...
    def is_loaded(self) -> bool: ...
    def _get_model_path(self, model_name: str) -> Path: ...
```

### Hardware Detection Hierarchy

`backend/backends/base.py` detects acceleration at startup:
1. `darwin` + `arm64` -> **Apple Silicon MLX** (Metal / Neural Engine)
2. `torch.cuda.is_available()` -> **NVIDIA CUDA**
3. `torch.version.hip is not None` -> **AMD ROCm**
4. Intel Arc XPU (`intel_extension_for_pytorch`)
5. DirectML (`torch_directml`)
6. Fallback -> **CPU**

## 3. Serial Task Queue for GPU Safety

Inference is compute-heavy. Running concurrent generations will crash VRAM:
- All generation requests MUST route through `backend/services/task_queue.py`.
- CPU-to-GPU memory transfer and actual inference run inside `asyncio.to_thread` to avoid blocking FastAPI's event loop.

## 4. Useful Development Commands

```bash
# Start backend directly in dev mode with reload
bun run dev:server
# or
uvicorn backend.main:app --reload --port 17493

# Run backend linter & formatter
ruff check backend/
ruff format backend/

# Run pytest test suite
pytest backend/tests/
```
