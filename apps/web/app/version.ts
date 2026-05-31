const fallbackMarketingVersion = "1.2.1";
const fallbackBuildNumber = "";

export const appVersion = {
  marketingVersion: process.env.NEXT_PUBLIC_PRBAR_VERSION || fallbackMarketingVersion,
  buildNumber: process.env.NEXT_PUBLIC_PRBAR_BUILD_NUMBER || fallbackBuildNumber,
};

export function appVersionDisplayValue() {
  return appVersion.buildNumber
    ? `${appVersion.marketingVersion} (${appVersion.buildNumber})`
    : appVersion.marketingVersion;
}
