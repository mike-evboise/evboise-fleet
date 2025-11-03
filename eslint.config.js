import next from "eslint-config-next";

/**
 * Next.js 15 Flat ESLint Config
 * Disables the `no-html-link-for-pages` rule that blocks valid <a> tags like mailto: or favicon.
 */
export default [
  next(),
  {
    rules: {
      "@next/next/no-html-link-for-pages": "off",
    },
  },
];
