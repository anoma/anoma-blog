# Anoma Blog

Welcome to the Anoma Blog documentation. This guide contains all the necessary information to contribute to [anoma.net/blog](https://anoma.net/blog) efficiently and effectively.

## Getting Started

To begin contributing to the Anoma Blog, clone this repository to your local machine. Detailed setup instructions and prerequisites are provided below to ensure a smooth start.

## Motivation

The Anoma Blog's previous iteration utilized [Ghost CMS](https://ghost.org), an excellent open-source platform. However, team feedback highlighted issues such as occasional interface lags and markdown rendering inconsistencies. Additionally, Ghost CMS's lack of support for content export in formats other than HTML limited our flexibility in repurposing content. To address these challenges, we have migrated to a new system designed for enhanced performance and versatility.

## Basic Structure

The repository is organized to manage blog posts efficiently, and its defined using the structure below

### `/categories.json`

Manage blog categories by editing existing ones or adding new categories. Only categories listed in this file can be used in blog posts. For instance:

```json
{
  "distributed-systems": "Distributed Systems",
  "ecosystem": "Ecosystem",
  "security": "Security"
}
```

In the example above, only `distributed-systems`, `ecosystem`, and `security` can be applied to blog posts.

### `/authors.json`

It includes a list of authors approved to be displayed on the website, with names corresponding to specific folders at the repository's root.

This file allows you to update or add author names as they should appear on the blog. It contains the only authors who will be displayed in the website, with names corresponding to specific folders at the repository's root.

### `/avatars.json`

Modify or add author avatars by updating this file. Avatars must be placed in the `/<author>/media` folder. For example:

```json
{
  "jane": "avatar.png",
  "doe": "avatar.jpg"
}
```

In the example above, avatars will be located at `/jane/media/avatar.png` and `/doe/media/avatar.jpg` respectively:

### `/<author>/<posts>.md`

Store each author's blog posts in this folder structure, where the filename maps to the blog URL, such as `anoma.net/blog/this-is-a-post` for a post stored at `/john/this-is-a-post.md`. Note that filenames should be lowercase and end with the `.md` extension.

Examples

- ❌ `/john/This is a post`: don't use spaces or capital letters
- ❌ `/john/this-is-a-post`: `.md` extension is missing
- ✅ `john/correct-file-structure.md`: all the characters in lowercase and file ending with a `.md extension`

### `/<author>/media`

Folder that will store all media files used by an author. If you're creating a post in `/john/lorem-ipsum.md`, all the images, videos, audios should be stored in `/john/media/` directory. You can reference medias in your markdown as `media/name-of-the-image.jpg`

## Suggested Workflow

We use GitHub for version control and deployment management. To facilitate reviews and maintain high-quality content, we recommend the following workflow:

1. Each author creates a branch named `<author>/<post-name>` for their article (e.g., `jane/very-cool-post-title`).
2. Upon completing the draft, create a Pull Request for peer review.
3. Once reviewed and approved, the article should be merged into the `main` branch.

**Note**: Only posts in the main branch with a `publish_date` defined will be deployed to the Anoma blog. Each deployment to the main branch also triggers a blog deployment.

## CLI Helpers

We've developed a few CLI scripts to streamline common tasks. Below are the installation requirements and usage instructions for them.

### Requirements

- NodeJS (v20.x or higher): [NodeJS Official Site](https://nodejs.org/en)
- NPM (v10.x or higher): [NPM Documentation](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

To see if you already have Node.js and npm installed and check the installed version, run the following commands:

```
node -v
npm -v
```

### Initializing

After installing the required software, you should run the command `npm install` in the repository root to install additional dependencies.

### Creating a new Blog Post

While you can manually copy and paste the `/template.md` file, it's easier to generate a new post using the following command in the repository's root:

```bash
node create.js

```

It will start the prompt with instructions to create a new post file.

### Previewing changes

It's possible to preview the markdown file in your favourite markdown editor, but if you want to see it directly how it would look in the Anoma website, you can run the following command in the repository's root:

```bash
node preview.js <author>/<post-filename>
```

Example:

```bash
node preview.js john/post-file-to-preview.md
```

## FAQ

### How to create a Draft?

To create a draft, simply omit the `publish_date` in your post. Drafts committed to the main branch will not be published until a publish date is added.

### Adding Code Snippets

Use triple backticks followed by the language name for code snippets. Supported languages include bash, elixir, erlang, haskell, lisp, prolog, python, rust, wolfram.

Example:

````elixir
```elixir
IO.puts("Hello, World!")
```
````

Please open an issue if you need to add a different programming language. The full list of available programming languages can be found in the [Prism documentation](https://prismjs.com/#supported-languages)

### Using LaTeX

You can add math expressions in different ways:

- use `$` for inline expressions. Ex: `$1 + 1$`
- use `$$` for expressions with multiple lines. Expression block will be aligned to the left. Example:

```
$$ a + b $$
```

- add a line break to use \$\$ to align the expression block to the center:

```
$$
a + b
$$
```

- You can also define a whole block as a math expression using three backticks followed by `math`. Example:

````
```math
a + b
```
````

### Using Mermaid Charts

Mermaid diagrams can be added defining a `mermaid` definition to the code block. Example:

````
```mermaid
graph TD;
A-->B;
A-->C;
B-->D;
C-->D;
```
````

### HTML Usage

Basic HTML tags are supported and will be rendered on the blog. For example, to include an image with a caption:

```html
<figure>
  <img src="media/my-image.jpg" alt="my image alt text" />
  <figcaption>This is the caption that will appear below the image</figcaption>
</figure>
```
