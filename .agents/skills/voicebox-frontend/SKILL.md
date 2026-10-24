---
name: voicebox-frontend
description: Use this skill for React frontend development in Voicebox, covering React 18, Vite, Tailwind CSS, Radix UI primitives, Motion animations, TanStack Query cache invalidation, Zustand stores, WaveSurfer.js audio visualization, and Biome linting.
---

# Voicebox Frontend Engineering Skill

## Goal

Provide architectural patterns, state management guidelines, and audio visualization best practices for the Voicebox UI application (`app/`).

## Key Technologies & Directory Structure

- `app/src/components/Generation/` — Generation form, engine & model selectors, seed controls, emotion tags, audio output card
- `app/src/components/Profiles/` — Voice profile cards, audio sample recording/upload, cloning management
- `app/src/components/Stories/` — Multi-track audio timeline editor for podcasts and conversations
- `app/src/components/ServerSettings/` — Model downloads, GPU device toggles, audio channel routing
- `app/src/stores/` — Zustand global state (`useGenerationFormStore`, `useAudioStore`, `useProfileStore`)
- `app/src/lib/api/` — Typed API client communicating with FastAPI at `localhost:17493`
- `app/src/lib/constants/` — Engine definitions, supported languages, model mappings

## 1. State Management & Data Fetching

### TanStack Query (React Query)
- Use queries for server data: profiles, generation history, model download status, system health.
- When generating audio (`POST /generate`), use `useMutation` with `onSuccess`:
  ```typescript
  const queryClient = useQueryClient();
  const mutation = useMutation({
    mutationFn: generateAudioApi,
    onSuccess: (newGeneration) => {
      // Invalidate history query so new generation appears immediately
      queryClient.invalidateQueries({ queryKey: ['generations'] });
      // Set as active playback track
      useAudioStore.getState().setActiveTrack(newGeneration);
    },
  });
  ```

### Zustand Stores
- Local interactive UI state (draft text inputs, active waveform scrubber position, volume, selected profile) lives in Zustand stores.
- Never duplicate server-persisted data into Zustand; keep server data in TanStack Query cache.

## 2. WaveSurfer.js Audio Visualization Pattern

Voicebox renders high-performance audio waveforms for generated speech and reference samples:
- Initialize WaveSurfer inside a `useEffect` on a container `ref`.
- Always clean up on unmount (`wavesurfer.destroy()`) to prevent audio context memory leaks.
- Handle zoom levels, scrubbing, and playhead position synchronization with `useAudioStore`.

```typescript
useEffect(() => {
  if (!containerRef.current || !audioUrl) return;

  const ws = WaveSurfer.create({
    container: containerRef.current,
    waveColor: '#4f46e5',
    progressColor: '#818cf8',
    cursorColor: '#c7d2fe',
    barWidth: 2,
    barGap: 1,
    barRadius: 2,
    height: 48,
    url: audioUrl,
  });

  return () => {
    ws.destroy();
  };
}, [audioUrl]);
```

## 3. UI Design & Styling Rules

- **Design System**: Dark-mode-first aesthetic with rich contrast, subtle borders, and smooth transitions.
- **Component Primitives**: Built on Radix UI (`@radix-ui/react-*`) with CVA (`class-variance-authority`) and `tailwind-merge`.
- **Accessibility**: All buttons, sliders, and audio controls must have descriptive `aria-label`s and full keyboard accessibility.

## 4. Linting & Typecheck Workflow

```bash
# Typecheck TypeScript without emitting JS
bun run typecheck

# Biome linter and formatter check
bun run lint
bun run format:check

# Auto-fix linting and formatting issues
bun run check:fix
```
