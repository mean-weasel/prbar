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
- `#/receipt`
- `#/project`
- `#/repos`
- `#/studio`
- `#/trust`

The mockup centers the web product around:

- proof-of-work profiles
- PR and release receipts
- a showcase for apps, builders, and receipts worth watching
- user-curated app pages backed by selected GitHub repos and release receipts
- AI builder talent discovery
- private dashboard/source-selection workflows
- PRBar's Mac, iOS, and web app family
