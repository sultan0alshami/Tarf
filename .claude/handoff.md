# Tarf — Swarm Launch Handoff (rev. 2026-06-01)

## State
- `main` clean @ `2f2c242`, 58 tests green, `flutter analyze` clean. Flutter SDK at `C:\dev\flutter\bin` (prepend to PATH).
- Six phase plans on disk: `docs/superpowers/plans/2026-06-01-tarf-phase{1..6}-*.md` (~85 TDD tasks).
- Ten specialist agents in `.claude/agents/`. maxTurns raised: implementers (flutter/platform/firebase/web/release) = 150, test = 80, integrator = 80.

## Why attempt #1 failed (fixed)
Launched 4 agents in worktrees with `maxTurns: 30`. Each hit the turn ceiling on Task 0–1 and the worktree path (`.claude/worktrees/agent-*/app/…`) conflicted with the plans' absolute `C:\…\EyeCure_20\app\…` paths, wasting the budget on re-mapping. Fix: raised maxTurns; run Flutter phases on `main` (paths valid); only P5 (non-Flutter) uses a worktree; commit per task; resume protocol.

## Execution model
- **App/Flutter phases run SERIALLY on `main`** — absolute plan paths are valid, commits land directly, no merge needed. Only ONE main agent at a time.
- **P5 (website/extension/CI — non-Flutter, independent) runs in its OWN worktree, in parallel**, merged to main when done.
- **Every agent commits per task.** If it nears its turn/context limit it STOPS after its last committed task and ends with `RESUME_AT: <task#>`; the orchestrator dispatches a fresh agent to continue. No work lost.
- Dispatch app phases with `model: opus` (quality + efficient orientation). Tell each: read ONLY the current task + the files it touches — do NOT re-read the whole plan.

## Launch sequence
1. **NOW (parallel):** `flutter-engineer` → P1 audio on `main` (bg) ‖ `web-engineer` → P5 distribution in a worktree (bg).
2. **After P1 (serial on main):** `release-engineer` P6 → `firebase-engineer` P4 (Tasks 0–8; STOP before Task 9) → `platform-engineer` P2 → `flutter-engineer` P3 → `firebase-engineer` P4 Task 9 (last).
3. `code-reviewer` + `test-engineer` gate each phase; `integrator` merges P5 and reconciles `pubspec.yaml`/ARBs at the end.

## Why P4 stops at Task 8
Task 9 routes all six controllers + main.dart through the new repository — must merge AFTER P1 (sound settings) and P3 (multi-timer, prayer location) land their persisted fields.
