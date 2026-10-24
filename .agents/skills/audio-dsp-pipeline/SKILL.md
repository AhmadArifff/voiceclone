---
name: audio-dsp-pipeline
description: Use this skill for any audio digital signal processing (DSP) in Voicebox, including Spotify Pedalboard effects (reverb, chorus, delay, compressor, pitch shift, filters), audio normalization, crossfade chunking for long scripts, sample rate conversions, and generation versioning.
---

# Audio DSP & Effects Pipeline Skill

## Goal

Provide reference architecture, parameter specifications, and implementation patterns for digital signal processing (DSP), audio post-processing, and versioning in Voicebox.

## Key Files & Modules

- `backend/utils/effects.py` — Core Spotify Pedalboard DSP engine (`EFFECT_REGISTRY`, `apply_effects_chain`, `validate_effects_chain`)
- `backend/utils/audio.py` — Audio I/O, RMS normalization (`normalize_audio`), resampling (`resample_audio`), format conversion
- `backend/routes/effects.py` — REST API endpoints for applying effect chains, creating versions, and preset management
- `backend/database/models.py` — `GenerationVersion` table and relationship to `Generation`

## 1. Supported Pedalboard DSP Effects

All effects are serialized as a JSON list of dictionaries with type and parameters:

```json
[
  { "type": "highpass", "params": { "cutoff_frequency_hz": 80.0 } },
  { "type": "compressor", "params": { "threshold_db": -18.0, "ratio": 3.5, "attack_ms": 10.0, "release_ms": 100.0 } },
  { "type": "reverb", "params": { "room_size": 0.35, "wet_level": 0.2, "dry_level": 0.8, "width": 1.0 } },
  { "type": "gain", "params": { "gain_db": 1.5 } }
]
```

### Registry & Parameter Ranges

| Effect Type | Class | Key Parameters & Defaults | Valid Range |
|-------------|-------|--------------------------|-------------|
| `chorus` | `Chorus` | `rate_hz: 1.0`, `depth: 0.5`, `feedback: 0.0`, `centre_delay_ms: 7.0`, `mix: 0.5` | rate: 0.01–20Hz, delay: 0.5–50ms |
| `reverb` | `Reverb` | `room_size: 0.5`, `damping: 0.5`, `wet_level: 0.33`, `dry_level: 0.4`, `width: 1.0` | 0.0–1.0 |
| `delay` | `Delay` | `delay_seconds: 0.3`, `feedback: 0.3`, `mix: 0.3` | seconds: 0.01–2.0, feedback: 0.0–0.95 |
| `compressor` | `Compressor` | `threshold_db: -20.0`, `ratio: 4.0`, `attack_ms: 10.0`, `release_ms: 100.0` | thresh: -60..0dB, ratio: 1..20 |
| `gain` | `Gain` | `gain_db: 0.0` | -40.0 to +40.0 dB |
| `highpass` | `HighpassFilter` | `cutoff_frequency_hz: 80.0` | 20.0 to 8000.0 Hz |
| `lowpass` | `LowpassFilter` | `cutoff_frequency_hz: 8000.0` | 200.0 to 20000.0 Hz |
| `pitch_shift`| `PitchShift` | `semitones: 0.0` | -12.0 to +12.0 semitones |

## 2. Processing Pipeline Workflow

```mermaid
graph TD
    Raw[Raw Audio Array float32] --> Norm[normalize_audio: RMS -20dB + peak limit 0.85]
    Norm --> Trim{needs_trim?}
    Trim -- Yes --> SilenceTrim[trim_silence / trim_edge_silence]
    Trim -- No --> Chain[Build Pedalboard from JSON Chain]
    SilenceTrim --> Chain
    Chain --> BoardRun[board(audio, sample_rate)]
    BoardRun --> OutFile[Save to disk WAV/FLAC 48kHz]
    OutFile --> DB[Insert into generation_versions]
```

### Core Code Pattern: Applying Effects

```python
from backend.utils.effects import apply_effects_chain, validate_effects_chain
from backend.utils.audio import load_audio, save_audio

# 1. Validate JSON payload
is_valid, errors = validate_effects_chain(effects_chain)
if not is_valid:
    raise ValueError(f"Invalid effects chain: {errors}")

# 2. Load clean audio
audio, sr = load_audio(clean_audio_path)

# 3. Process through Pedalboard DSP
processed_audio = apply_effects_chain(audio, sr, effects_chain)

# 4. Save processed version
save_audio(processed_path, processed_audio, sr)
```

## 3. Best Practices & Guardrails

1. **Always Preserve Clean Master Audio**: Never overwrite the original clean generation file. Processed variants must be saved to a separate version file path linked via `GenerationVersion`.
2. **Audio Data Type**: Ensure all audio arrays are converted to `np.float32` before DSP operations to prevent clipping distortion and type mismatches in Pedalboard.
3. **Sample Rate Consistency**:
   - Voice models output at different native sample rates (e.g. Kokoro: 24kHz, LuxTTS: 48kHz, Chatterbox: 24kHz, Whisper: 16kHz).
   - Pass the actual sample rate to `board(audio, sample_rate)` so time-based parameters (delay ms, filter Hz, chorus rate) compute with mathematical accuracy.
4. **Crossfade for Long-Form Chunking**: When stitching chunks for long texts, use a 30ms-50ms linear or cosine crossfade window to prevent click/pop artifacts at chunk boundaries.
5. **Silence Trimming**: Check `ModelConfig.needs_trim`. Some engines generate trailing or leading hallucinated silence that must be trimmed before effects.
