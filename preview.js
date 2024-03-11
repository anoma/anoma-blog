import fs from "fs";
import path from "path";
import minimist from "minimist";
import chalk from "chalk";
import open from "open";
import frontMatter from "front-matter";
import express from "express";
import { parsePostContent, createPostPreview } from "./.scripts/posts.js";

import { WebSocketServer } from "ws";
const args = minimist(process.argv.slice(2));
const filename = args["f"] ?? args["_"][0];
const mediaDir = path.dirname(filename);
const wsPort = 8118;
const httpPort = args["p"] ?? 8110;
const httpUrl = `http://localhost:${httpPort}`;

const replaceSrcPath = (content) => {
  return content.replace(/src="/gi, `src="${httpUrl}/`);
};

console.log(chalk.bgRed(chalk.white(" Anoma Blog - Preview ")));
if (!filename) {
  console.log(
    chalk.bgRed(
      "File path was not provided. Please call preview.js script as `node preview.js <filename>`"
    )
  );
  process.exit(1);
}

if (!fs.existsSync(filename)) {
  console.log(
    chalk.bgRed(
      "Invalid file provided. Please check if the following path is correct: " +
        filename
    )
  );
  process.exit(1);
}

const wsConsole = (message) => chalk.magenta(message);
const httpConsole = (message) => chalk.blue(message);

console.log(chalk.bgBlueBright(` Starting HTTP Server on port ${httpPort} `));
const app = express();
app.use(express.static(mediaDir));
app.listen(httpPort, () => {
  console.log(
    httpConsole(`HTTP Server listening to http://localhost:${httpPort}`)
  );
});

console.log(
  chalk.bgMagenta(chalk.black(` Starting Websocket Server on port ${wsPort} `))
);
const previewContentWs = new WebSocketServer({ port: wsPort });
const sendUpdatedBlogInfo = async (clients) => {
  const updatedContents = fs.readFileSync(filename, "utf8");
  const { attributes } = frontMatter(updatedContents);
  const postInfo = createPostPreview(filename.replace(".md", ""), attributes);
  const postContent = replaceSrcPath(await parsePostContent(filename));
  const msg = JSON.stringify({
    ...postInfo,
    image: httpUrl + "/" + attributes.image,
    content: postContent,
  });
  clients.forEach((client) => {
    console.log(
      chalk.gray(
        `[${new Date().toLocaleDateString()} ${new Date().toLocaleTimeString()}]`
      ) + wsConsole(` Updating Preview`)
    );
    client.send(msg);
  });
};

previewContentWs.on("connection", (socket) => {
  if (socket) {
    sendUpdatedBlogInfo([socket]);
  }
});

previewContentWs.on("listening", () => {
  console.log(wsConsole(`Webserver started at port ${wsPort}`));
  console.log(wsConsole("Watching for changes on file: " + filename));
  fs.watchFile(
    filename,
    {
      persistent: true,
      interval: 200,
    },
    () => {
      console.log(chalk.gray("Detected changes for " + filename));
      sendUpdatedBlogInfo(previewContentWs.clients);
    }
  );

  const anomaUrl = "https://anoma.net/blog/preview";
  open(anomaUrl);
});
