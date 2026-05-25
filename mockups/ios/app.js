const rangeButtons = document.querySelectorAll("[data-range]");
const rangePanels = document.querySelectorAll("[data-range-panel]");
const themeButtons = document.querySelectorAll("[data-theme]");
const cardPreview = document.querySelector("[data-card-preview]");
const privacyToggle = document.querySelector("[data-privacy-toggle]");
const repoSheet = document.querySelector("[data-repo-sheet]");
const openRepoSheetButton = document.querySelector("[data-open-repo-sheet]");
const closeRepoSheetButton = document.querySelector("[data-close-repo-sheet]");

const themeCopy = {
  clean: {
    range: "This month",
    title: "42 merged PRs",
    caption: "A month of shipped work across 6 repos."
  },
  terminal: {
    range: "range=month",
    title: "git merged --count 42",
    caption: "shipping rhythm: strong"
  },
  launch: {
    range: "May 2026",
    title: "A month of shipped work",
    caption: "42 merged PRs moved the release forward."
  },
  hype: {
    range: "Big merge month",
    title: "42 PRs landed",
    caption: "High-velocity work across the stack."
  },
  minimal: {
    range: "May 2026",
    title: "42 merged",
    caption: "@neonwatty"
  }
};

rangeButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const range = button.dataset.range;
    rangeButtons.forEach((item) => item.classList.toggle("is-active", item === button));
    rangePanels.forEach((panel) => {
      panel.classList.toggle("is-active", panel.dataset.rangePanel === range);
    });
  });
});

themeButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const theme = button.dataset.theme;
    const copy = themeCopy[theme];
    themeButtons.forEach((item) => item.classList.toggle("is-active", item === button));
    cardPreview.className = `share-card ${theme}`;
    cardPreview.setAttribute("aria-label", `${button.textContent} share card preview`);
    cardPreview.querySelector("[data-card-range]").textContent = copy.range;
    cardPreview.querySelector("[data-card-title]").textContent = copy.title;
    cardPreview.querySelector("[data-card-caption]").textContent = copy.caption;
  });
});

privacyToggle?.addEventListener("change", () => {
  document.body.classList.toggle("privacy-hidden", !privacyToggle.checked);
});

openRepoSheetButton?.addEventListener("click", () => {
  repoSheet?.classList.add("is-open");
});

closeRepoSheetButton?.addEventListener("click", () => {
  repoSheet?.classList.remove("is-open");
});
