import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PRBar Prototype",
  description: "Client-only PRBar Builder Proof prototype",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="toc-collapsed">{children}</body>
    </html>
  );
}
