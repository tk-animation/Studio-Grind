import YAML from "yaml"
import { Root } from "mdast"
import { QuartzTransformerPlugin } from "../types"

function toStringArray(value: unknown): string[] | undefined {
  if (value == null) return undefined
  if (Array.isArray(value)) return value.map(String)
  return String(value)
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean)
}

export const LocalFrontmatter: QuartzTransformerPlugin = () => ({
  name: "LocalFrontmatter",
  markdownPlugins() {
    return [
      () => (tree: Root, file) => {
        const source = String(file.value)
        const match = source.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)
        if (!match) return

        const parsed = (YAML.parse(match[1]) ?? {}) as Record<string, unknown>
        const title = parsed.title ? String(parsed.title) : (file.stem ?? "Untitled")
        const tags = toStringArray(parsed.tags ?? parsed.tag)
        const aliases = toStringArray(parsed.aliases ?? parsed.alias)
        const cssclasses = toStringArray(parsed.cssclasses ?? parsed.cssclass)

        file.data.frontmatter = {
          ...parsed,
          title,
          ...(tags ? { tags } : {}),
          ...(aliases ? { aliases } : {}),
          ...(cssclasses ? { cssclasses } : {}),
        }

        const frontmatterEnd = match[0].length
        tree.children = tree.children.filter(
          (node) => (node.position?.start.offset ?? frontmatterEnd) >= frontmatterEnd,
        )
      },
    ]
  },
})
