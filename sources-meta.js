const fs = require('fs');
const path = require('path');

const owner = process.env.GITHUB_REPOSITORY_OWNER;
const repo = process.env.GITHUB_REPOSITORY;
const sha = process.env.GITHUB_SHA;

const sourceDir = path.join(__dirname, 'cmd_sources');
const outputFile = path.join(__dirname, 'sourcesmeta.json');

function generateDownloadLink(fileName) {
  return `https://raw.githubusercontent.com/${owner}/${repo}/${sha}/cmd_sources/${fileName}`;
}

function parseJsonFiles() {
  const results = [];
  fs.readdirSync(sourceDir).forEach(fileName => {
    const filePath = path.join(sourceDir, fileName);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    results.push({
      name: data.name,
      description: data.description,
      author: data.author,
      download_link: generateDownloadLink(fileName),
    });
  });
  return results;
}

const metaData = parseJsonFiles();
fs.writeFileSync(outputFile, JSON.stringify(metaData, null, 2));

console.log(`Successfully created sourcesmeta.json`);
