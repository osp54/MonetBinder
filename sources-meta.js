const fs = require('fs').promises;
const iconv = require('iconv-lite');
const path = require('path');

const sourceDir = path.join(__dirname, 'cmd_sources');
const outputFile = path.join(__dirname, 'sourcesmeta.json');
const releaseId = process.env.RELEASE_ID;

function getReleaseMetadata() {
  return fetch(`https://api.github.com/repos/osp54/MonetBinder/releases/${releaseId}`)
    .then(response => response.json())
    .then(data => data);
}

getReleaseMetadata()
  .then(release => {
    const processedResults = release.assets.map(asset => {
      const filePath = path.join(sourceDir, asset.name);
      return fs.readFile(filePath)
        .then(data => iconv.decode(data, 'cp1251'))
        .then(decodedData => JSON.parse(decodedData))
        .then(jsonData => ({
          name: jsonData.name,
          description: jsonData.description,
          author: jsonData.author || 'Неизвестен',
          download_link: asset.browser_download_url,
          download_count: asset.download_count,
        }))
        .catch(err => {
          console.error(`Error processing ${asset.name}: ${err}`);
          return null; // Return null for failed processing
        });
    });

    return Promise.allSettled(processedResults);
  })
  .then(results => {
    const successfulResults = results
      .filter(result => result.status === 'fulfilled')
      .map(result => result.value)
      .filter(Boolean)
      .sort((a, b) => b.download_count - a.download_count); // Sort by download_count in descending order

    fs.writeFile(outputFile, JSON.stringify(successfulResults, null, 2), 'utf-8')
      .then(() => console.log(`Successfully created sourcesmeta.json`))
      .catch(err => console.error('Error writing to file:', err));
  })
  .catch(err => {
    console.error(err);
  });