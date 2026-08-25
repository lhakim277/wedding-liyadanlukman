import type { Metadata, Viewport } from "next";
import { Montserrat, Playfair_Display, Pinyon_Script } from "next/font/google";
import "./globals.css";

const montserrat = Montserrat({
  variable: "--font-montserrat",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  display: "swap",
});

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  style: ["normal", "italic"],
  display: "swap",
});

const pinyon = Pinyon_Script({
  variable: "--font-pinyon",
  subsets: ["latin"],
  weight: ["400"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "The Wedding of Liya & Lukman",
  description:
    "Undangan Pernikahan Miinatul Mauliyati Zahroh & Lukman Hakim — Minggu, 6 September 2026",
  keywords: [
    "Wedding Invitation",
    "Liya and Lukman",
    "Lukman Hakim",
    "Miinatul Mauliyati Zahroh",
    "Undangan Pernikahan",
  ],
  authors: [{ name: "Liya & Lukman" }],
  openGraph: {
    title: "The Wedding of Liya & Lukman",
    description:
      "Undangan Pernikahan Miinatul Mauliyati Zahroh & Lukman Hakim — Minggu, 6 September 2026",
    images: ["/wedding/cover-ref.jpg"],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="id"
      className={`${montserrat.variable} ${playfair.variable} ${pinyon.variable} h-full antialiased`}
    >
      <body className="min-h-full">{children}</body>
    </html>
  );
}
