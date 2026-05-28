# PRBar Web Mockup

Static proof-first web product mockup for PRBar.

Open `index.html` through a local server so relative assets and scripts load consistently:

```bash
python3 -m http.server 4174 --directory mockups/web
```

Then visit `http://127.0.0.1:4174`.

The prototype uses hash routes:

- `#/home`
- `#/network`
- `#/boards`
- `#/talent`
- `#/dashboard`
- `#/profile`
- `#/card`
- `#/receipt`
- `#/project`
- `#/repos`
- `#/studio`
- `#/trust`

The mockup positions PRBar as the resume for AI-native builders and centers the product around:

- proof resumes built from shipped work
- interactive builder cards for a first shareable proof link
- PR and release receipts
- a simple showcase for apps with receipts
- user-curated app pages backed by selected GitHub repos and release receipts
- optional AI builder talent discovery
- private dashboard/source-selection workflows
- PRBar's Mac, iOS, and web app family
