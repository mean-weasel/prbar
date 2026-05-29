# PRBar Web Mockup

Static proof-first web product mockup for PRBar.

Open `index.html` through a local server so relative assets and scripts load consistently:

```bash
python3 -m http.server 4174 --directory mockups/web
```

Then visit `http://127.0.0.1:4174`.

Core hash routes:

- `#/home`
- `#/signup`
- `#/signin`
- `#/login`
- `#/logout`
- `#/onboarding`
- `#/connect-github`
- `#/profile`
- `#/user`
- `#/edit-profile`
- `#/repos`
- `#/account`

Archived/direct-review routes:

- `#/network`
- `#/boards`
- `#/talent`
- `#/dashboard`
- `#/card`
- `#/receipt`
- `#/project`
- `#/studio`
- `#/trust`

The mockup positions PRBar as the resume for AI-native builders and centers the product around:

- one Builder Proof page built from shipped work, with the builder card, receipts, app proof, and timeline fused into the same surface
- one Sources & Privacy page for GitHub connection, source selection, receipt editing, redaction, and trust controls
- basic account and onboarding pages for sign up, sign in, GitHub connection, profile editing, and account permissions
- a local mock session that toggles the header between sign-in/claim and profile/GitHub/logout states
- a persistent setup checklist on the user profile that tracks claim, GitHub, source selection, publish, and share steps
- editable local profile state that updates the account page, builder card, and public Builder Proof
- distinct signed-in owner and signed-out visitor states, including gated owner routes and a prospect CTA on public Builder Proof
- interactive source decisions, draft/published Builder Proof state, and local share feedback for the proof/card links
- a hidden-by-default review map for mockup navigation
- PRBar's Mac, iOS, and web app family
