// TODO: Contents of this file are copied from anoma.network/lib/posts.ts
// We need to find a way to unify the codebase.
import fs from "fs";
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import rehypeStringify from "rehype-stringify";
import rehypeSlug from "rehype-slug";
import remarkFrontmatter from "remark-frontmatter";
import rehypeKatex from "rehype-katex";
import remarkMath from "remark-math";
import remarkGfm from "remark-gfm";

export const parsePostContent = async (filePath) => {
  const contents = fs.readFileSync(filePath, "utf8");
  const html = await unified()
    .use(remarkParse)
    .use(remarkFrontmatter)
    .use(remarkRehype, { allowDangerousHtml: true })
    .use(rehypeStringify, { allowDangerousHtml: true })
    .use(remarkMath)
    .use(remarkGfm)
    .use(rehypeKatex)
    .use(rehypeSlug)
    .process(contents);
  return String(html);
};

export const createPostPreview = (slug, metadata) => {
  return {
    slug,
    title: metadata.title || "",
    image: metadata.image,
    imageCaption: metadata.imageCaption || "",
    imageAlt: metadata.imageAlt || "",
    excerpt: metadata.excerpt || "",
  };
};
