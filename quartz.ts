import { loadQuartzConfig, loadQuartzLayout } from "./quartz/plugins/loader/config-loader"
import * as ExternalPlugin from "./.quartz/plugins"
import { LocalFrontmatter } from "./quartz/plugins/transformers/localFrontmatter"
import { FileTrieNode } from "./quartz/util/fileTrie"

ExternalPlugin.Explorer({
  filterFn: (node: FileTrieNode) => {
    const slug = node.slug.toLowerCase()
    return !slug.startsWith("media") && !slug.startsWith("tags")
  },
  mapFn: (node: FileTrieNode) => {
    const name = node.displayName.toLowerCase()
    if (name.startsWith("part 1")) node.displayName = "Part 1 - Drawing"
    if (name.startsWith("part 2")) node.displayName = "Part 2 - Animation"
    return node
  },
  sortFn: (a: FileTrieNode, b: FileTrieNode) => {
    const aName = a.displayName.toLowerCase()
    const bName = b.displayName.toLowerCase()
    const aRank = aName.includes("part 1")
      ? 10
      : aName.includes("part 2")
        ? 20
        : aName.includes("useful links")
          ? 30
          : aName.includes("special thanks")
            ? 40
            : 0
    const bRank = bName.includes("part 1")
      ? 10
      : bName.includes("part 2")
        ? 20
        : bName.includes("useful links")
          ? 30
          : bName.includes("special thanks")
            ? 40
            : 0
    const rankDifference = aRank - bRank
    if (rankDifference !== 0) return rankDifference
    if (a.isFolder !== b.isFolder) return a.isFolder ? -1 : 1
    return a.displayName.localeCompare(b.displayName, undefined, {
      numeric: true,
      sensitivity: "base",
    })
  },
})

const config = await loadQuartzConfig()
config.plugins.transformers.unshift(LocalFrontmatter())
export default config
export const layout = await loadQuartzLayout()
