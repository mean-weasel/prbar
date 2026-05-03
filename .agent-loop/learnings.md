# Autopilot Loop Learnings

## 2026-05-02

- The skill's CLI `init` is useful, but the generated charter is intentionally blank; the agent still needs to immediately fill target users, non-goals, scope, verification, and assumptions.
- Keeping `.agent-loop/state.json` concise works best when detailed narration goes into per-iteration reports instead of the state file.
- A separate learnings log is useful for meta observations about the loop itself; mixing these into product state would make the judge signal noisier.
- Strict CI guards created a productive repair loop: formatting failed before build, and tests caught a wrong expectation derived from manually summing scratch data.
- The loop needs an explicit convention for whether generated `.agent-loop` artifacts should be committed after each iteration.
- Repeated manual total mistakes suggest the loop should favor fixture-derived expected values or helper assertions over hand-summed numbers in tests.
- When the user changes the iteration budget, the agent should update the persisted loop budget immediately so state matches the active charter.
- Small UI iterations are easier to judge when paired with a model-level test for the data shown in the UI.
- A provider boundary can be useful before real credentials/API work; it gives the loop a testable next step without blocking on external services.
- SwiftUI `some View` edits are prone to small composition mistakes; fast local build verification catches them before they become loop-state noise.
