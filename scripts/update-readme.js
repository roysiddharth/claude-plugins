#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const marketplace = JSON.parse(
  fs.readFileSync(path.join(root, ".claude-plugin/marketplace.json"), "utf8")
);
const marketplaceName = marketplace.name;

const rows = marketplace.plugins.map((p) => {
  const install = `\`claude plugin install ${p.name}@${marketplaceName}\``;
  return `| ${p.name} | ${install} | ${p.description} |`;
});

const table = [
  "| Plugin | Install | Description |",
  "|--------|---------|-------------|",
  ...rows,
].join("\n");

const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");
const updated = readme.replace(
  /<!-- plugins-table -->[\s\S]*?<!-- \/plugins-table -->/,
  `<!-- plugins-table -->\n${table}\n<!-- /plugins-table -->`
);

fs.writeFileSync(path.join(root, "README.md"), updated);
console.log(`Updated README with ${rows.length} plugin(s).`);
