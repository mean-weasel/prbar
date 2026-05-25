# PRBar iOS Mockups

Interactive HTML prototype for the approved PRBar iOS app direction.

Open `mockups/ios/index.html` in a browser to review:

- Bottom navigation for Today / Activity / Releases / Cards / More
- More menu with Repos, Settings, Privacy, Sample Data, and About
- Today in Day / Week / Month ranges
- Activity detail from included repos
- GitHub Releases from included repos
- Repository inclusion controls
- Cards composer from activity or release sources
- Front/back card flip, with release evidence aggregated on the back
- Share sheet choices for front, back, both sides, captions, image saves, and messages
- Clean, Terminal, Launch, Hype, and Minimal share-card themes
- Edit Card sheet for style and privacy controls that update the preview

This prototype is fixture-backed and does not call GitHub. Native iOS implementation should wait until this package is reviewed.

Review links can open specific states with query parameters, for example `?tab=cards`, `?tab=cards&side=back`, or `?tab=cards&sheet=share`.
