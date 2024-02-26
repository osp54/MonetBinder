const fs = require('fs');
const iconv = require('iconv-lite'); // Install using npm install iconv-lite
const path = require('path');

const repo = process.env.GITHUB_REPOSITORY;

const sourceDir = path.join(__dirname, 'cmd_sources');
const outputFile = path.join(__dirname, 'sourcesmeta.json');

function generateDownloadLink(fileName) {
  return `https://raw.githubusercontent.com/${repo}/cmd_sources/${fileName}`;
}

function parseJsonFiles() {
  const results = [];
  fs.readdirSync(sourceDir).forEach(fileName => {
    const filePath = path.join(sourceDir, fileName);
    const data = iconv.decode(fs.readFileSync(filePath), 'cp1251'); // Read in cp1251
    const jsonData = JSON.parse(data);
    results.push({
      name: jsonData.name,
      description: jsonData.description,
      author: jsonData.author,
      download_link: generateDownloadLink(fileName),
    });
  });
  return results;
}

const metaData = parseJsonFiles();
fs.writeFileSync(outputFile, JSON.stringify(metaData, null, 2), 'utf-8'); // Write in utf-8

console.log(`Successfully created sourcesmeta.json`);