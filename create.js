import enquirer from "enquirer";
import chalk from "chalk";
import fs from "fs";
import slugify from "slugify";
const authors = JSON.parse(fs.readFileSync("./authors.json"));
const categories = JSON.parse(fs.readFileSync("./categories.json"));

function getYamlHeader(obj) {
  return (
    `---\n` +
    Object.keys(obj).reduce((str, key) => {
      return str + `${key}: ${obj[key]}\n`;
    }, "") +
    `---\n`
  );
}

console.log(chalk.red("=========================="));
console.log(chalk.red("  Anoma Blog - New Post  "));
console.log(chalk.red("==========================\n"));

const answers = await enquirer.prompt([
  {
    type: "input",
    name: "title",
    message: "Post title? (required)",
    validate: (value) => value.length > 3,
  },
  {
    type: "autocomplete",
    name: "category",
    message: "Category? (required)",
    limit: 10,
    initial: 0,
    choices: Object.keys(categories),
  },
  {
    type: "autocomplete",
    name: "author",
    message: "Author? (required)",
    limit: 10,
    initial: 0,
    choices: Object.keys(authors),
  },
  {
    type: "autocomplete",
    name: "co_authors",
    message: "Co-Authors? (select with <space> if any)",
    limit: 10,
    multiple: true,
    required: false,
    result: (value) => value.join(","),
    choices: Object.keys(authors),
  },
  {
    type: "input",
    name: "excerpt",
    message: "Excerpt? (you can add it later)",
    required: false,
  },
]);

const { title, category, excerpt, author, co_authors } = answers;
const titleSlug = slugify(title).toLowerCase();
const targetPath = `./${author}/${titleSlug}.md`;
const markdown =
  getYamlHeader({
    title,
    category,
    co_authors,
    publish_date: "",
    image: "media/",
    imageAlt: "",
    imageCaption: "",
    excerpt,
  }) + `<Post content starts here!>`;

if (fs.existsSync(targetPath)) {
  console.log(chalk.bgRed("Aborting: a post with this title already exists"));
  throw "";
}

fs.writeFileSync(targetPath, markdown);
console.log("\n==========================================");
console.log(`A new post was created 🎉: ${targetPath}`);
console.log("==========================================\n\n");
