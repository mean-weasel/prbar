const leaderboardData = {
  daily: [
    { rank: 1, handle: "@maya.codes", prs: "9 PRs", releases: "1 rel", streak: "9 days" },
    { rank: 2, handle: "@jules.dev", prs: "7 PRs", releases: "0 rel", streak: "4 days" },
    { rank: 3, handle: "@rio.ai", prs: "6 PRs", releases: "2 rel", streak: "6 days" },
    { rank: 4, handle: "@nora.ship", prs: "5 PRs", releases: "1 rel", streak: "3 days" },
  ],
  weekly: [
    { rank: 1, handle: "@maya.codes", prs: "42 PRs", releases: "4 rel", streak: "9 days" },
    { rank: 2, handle: "@jules.dev", prs: "31 PRs", releases: "2 rel", streak: "7 days" },
    { rank: 3, handle: "@rio.ai", prs: "24 PRs", releases: "5 rel", streak: "5 days" },
    { rank: 4, handle: "@devon.codes", prs: "21 PRs", releases: "2 rel", streak: "11 days" },
  ],
  monthly: [
    { rank: 1, handle: "@jules.dev", prs: "118 PRs", releases: "11 rel", streak: "18 days" },
    { rank: 2, handle: "@maya.codes", prs: "104 PRs", releases: "8 rel", streak: "9 days" },
    { rank: 3, handle: "@nora.ship", prs: "88 PRs", releases: "7 rel", streak: "13 days" },
    { rank: 4, handle: "@rio.ai", prs: "73 PRs", releases: "9 rel", streak: "5 days" },
  ],
};

const talent = [
  {
    handle: "@nora.ship",
    copy: "Cursor, SaaS dashboards, 3 releases this month. Open to launch sprint work.",
    tags: ["available", "saas", "cursor"],
  },
  {
    handle: "@devon.codes",
    copy: "Claude Code, iOS, 11-day streak. Strong release-card history.",
    tags: ["available", "mobile", "claude"],
  },
  {
    handle: "@rhea.builds",
    copy: "AI app builder, onboarding flows, founder-friendly weekly shipping cadence.",
    tags: ["saas", "mobile", "founder"],
  },
];

const leaderboard = document.querySelector(".leaderboard");
const boardButtons = document.querySelectorAll("[data-board]");
const talentGrid = document.querySelector(".talent-grid");
const talentButtons = document.querySelectorAll("[data-filter]");

function renderBoard(range) {
  leaderboard.innerHTML = leaderboardData[range]
    .map(
      (row) => `
        <article class="leader-row">
          <strong>#${row.rank}</strong>
          <div>
            <strong>${row.handle}</strong>
            <span>Verified GitHub</span>
          </div>
          <strong>${row.prs}</strong>
          <span>${row.releases}</span>
          <span>${row.streak}</span>
        </article>
      `
    )
    .join("");
}

function renderTalent(filter) {
  const rows = filter === "all" ? talent : talent.filter((person) => person.tags.includes(filter));

  talentGrid.innerHTML = rows
    .map(
      (person) => `
        <article class="talent-card">
          <h3>${person.handle}</h3>
          <p>${person.copy}</p>
          <div class="talent-tags">
            ${person.tags.map((tag) => `<span>${tag}</span>`).join("")}
          </div>
        </article>
      `
    )
    .join("");
}

boardButtons.forEach((button) => {
  button.addEventListener("click", () => {
    boardButtons.forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
    renderBoard(button.dataset.board);
  });
});

talentButtons.forEach((button) => {
  button.addEventListener("click", () => {
    talentButtons.forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
    renderTalent(button.dataset.filter);
  });
});

renderBoard("daily");
renderTalent("all");
