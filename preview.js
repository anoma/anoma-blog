import fs from "fs";
import path from "path";
import minimist from "minimist";
import chalk from "chalk";
import open from "open";
import frontMatter from "front-matter";
import cors from "cors";
import express from "express";
import { parsePostContent, createPostPreview } from "./.scripts/posts.js";
const args = minimist(process.argv.slice(2));
const filename = args["f"] ?? args["_"][0];
const mediaDir = path.dirname(filename);
const httpPort = args["p"] ?? 8110;
const httpUrl = `http://localhost:${httpPort}/`;
const anomaUrl = "https://anoma.net/blog/preview";

const replaceSrcPath = (content) => {
  return content.replace(/src="/gi, `src="${httpUrl}/`);
};

const httpConsole = (message) => chalk.blue(message);

// Welcome!
console.log(chalk.bgRed(chalk.white(" Anoma Blog - Preview ")));

// Check if file argument was provided
if (!filename) {
  console.log(
    chalk.bgRed(
      "File path was not provided. Please call preview.js script as `node preview.js <filename>`",
    ),
  );
  process.exit(1);
}

// Check if the provided filepath exists
if (!fs.existsSync(filename)) {
  console.log(
    chalk.bgRed(
      "Invalid file provided. Please check if the following path is correct: " +
        filename,
    ),
  );
  process.exit(1);
}

// Starting HTTP server using express
console.log(chalk.bgBlueBright(` Starting HTTP Server on port ${httpPort} `));
const app = express();
let sseResponse;

app.use(
  cors({
    origin: "*",
    methods: ["GET", "OPTIONS"],
    allowedHeaders: ["Content-Type"],
  }),
);

app.use(express.static(mediaDir));
app.listen(httpPort, () => {
  console.log(
    httpConsole(`HTTP Server listening to http://localhost:${httpPort}`),
  );
});

app.get("/events", (req, res) => {
  sseResponse = res;
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  update(res);
  req.on("close", () => res.end());
});

const parseFileUpdates = async (filename) => {
  const updatedContents = fs.readFileSync(filename, "utf8");
  const { attributes } = frontMatter(updatedContents);
  const postInfo = createPostPreview(filename.replace(".md", ""), attributes);
  const postContent = replaceSrcPath(await parsePostContent(filename));
  return { postInfo, postContent, attributes };
};

const sendUpdatedBlogInfo = async (
  res,
  { attributes, postContent, postInfo },
) => {
  const msg = JSON.stringify({
    ...postInfo,
    image: httpUrl + "/" + attributes.image,
    content: postContent,
  });
  console.log(
    chalk.gray(
      `[${new Date().toLocaleDateString()} ${new Date().toLocaleTimeString()}]`,
    ) + httpConsole(` Updating Preview`),
  );
  res.write(`data: ${msg}\n\n`);
};

const watchFileForChanges = () => {
  fs.watchFile(
    filename,
    {
      persistent: true,
      interval: 200,
    },
    () => {
      if (sseResponse) {
        update(sseResponse);
      }
    },
  );
};

async function update(res) {
  sendUpdatedBlogInfo(res, await parseFileUpdates(filename));
}

watchFileForChanges();
open(anomaUrl);
