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
- For a fixed user-requested loop count, stop-state should distinguish "batch complete" from "no valuable work remains".
- Empty-state loops are good late-batch tasks because they improve UX without expanding scope into external dependencies.
- Commit each loop for auditability and rollback, but open PRs for coherent batches of loops so review stays product-shaped instead of iteration-shaped.
- Live-provider work is easiest to review when network construction, decoding, bucketing, and provider selection each land as separate tested loops.
- After a batch PR merges, verify the PR's check rollup and record the exact pass/fail state before summarizing the loop; "merged" alone is not enough audit evidence.
