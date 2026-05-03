# Autopilot Loop Learnings

## 2026-05-02

- The skill's CLI `init` is useful, but the generated charter is intentionally blank; the agent still needs to immediately fill target users, non-goals, scope, verification, and assumptions.
- Keeping `.agent-loop/state.json` concise works best when detailed narration goes into per-iteration reports instead of the state file.
- A separate learnings log is useful for meta observations about the loop itself; mixing these into product state would make the judge signal noisier.
- Strict CI guards created a productive repair loop: formatting failed before build, and tests caught a wrong expectation derived from manually summing scratch data.
- The loop needs an explicit convention for whether generated `.agent-loop` artifacts should be committed after each iteration.

