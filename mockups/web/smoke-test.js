const { chromium } = require("/Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright");

const baseUrl = "http://127.0.0.1:4181/";
const viewport = { width: 390, height: 844 };

const routes = [
  ["#/home", "Show the world your receipts."],
  ["#/network", "People and projects first."],
  ["#/profile", "Receipts beat resumes."],
  ["#/receipt", "SideProject Radar v2.1"],
  ["#/project", "SideProject Radar operating history."],
  ["#/boards", "Momentum Boards"],
  ["#/talent", "Who can help me ship this?"],
  ["#/dashboard", "Receipt Command Center"],
  ["#/repos", "Choose which repos count."],
  ["#/studio", "Edit the evidence."],
  ["#/trust", "Clear rules for GitHub proof."],
];

async function assertNoHorizontalOverflow(page, route) {
  const overflow = await page.evaluate(() => {
    const documentWidth = document.documentElement.scrollWidth;
    const bodyWidth = document.body ? document.body.scrollWidth : 0;
    const viewportWidth = document.documentElement.clientWidth;

    return {
      bodyWidth,
      documentWidth,
      overflow: Math.max(documentWidth, bodyWidth) - viewportWidth,
      viewportWidth,
    };
  });

  if (overflow.overflow > 1) {
    throw new Error(
      `${route} has horizontal overflow: document=${overflow.documentWidth}, body=${overflow.bodyWidth}, viewport=${overflow.viewportWidth}`
    );
  }
}

async function assertBodyIncludes(page, route, expectedText) {
  const bodyText = await page.locator("body").innerText();

  if (!bodyText.includes(expectedText)) {
    throw new Error(`${route} is missing expected text: ${expectedText}`);
  }
}

async function main() {
  const browser = await chromium.launch();

  try {
    const page = await browser.newPage({ viewport });

    for (const [route, expectedText] of routes) {
      await page.goto(`${baseUrl}${route}`, { waitUntil: "networkidle" });
      await assertBodyIncludes(page, route, expectedText);
      await assertNoHorizontalOverflow(page, route);
    }

    await page.goto(`${baseUrl}#/boards`, { waitUntil: "networkidle" });
    await page.locator("[data-board='projects']").click();
    const boardText = await page.locator("body").innerText();

    if (!boardText.includes("Active projects") && !boardText.includes("SideProject Radar")) {
      throw new Error("#/boards project board did not render active project content");
    }

    await page.goto(`${baseUrl}#/talent`, { waitUntil: "networkidle" });
    await page.locator("[data-filter='available']").click();
    await assertBodyIncludes(page, "#/talent available filter", "@nora.ship");
  } finally {
    await browser.close();
  }

  console.log("PRBar web prototype smoke test passed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
