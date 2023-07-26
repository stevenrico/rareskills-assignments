import { StandardMerkleTree } from "@openzeppelin/merkle-tree"
import path from "path"
import { fileURLToPath } from "url"
import fs from "fs"

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const values = [
  ["1", "0xf6c0eB696e44d15E8dceb3B63A6535e469Be6C62"],
  ["2", "0xf6c0eB696e44d15E8dceb3B63A6535e469Be6C62"],
  ["3", "0xf6c0eB696e44d15E8dceb3B63A6535e469Be6C62"],
  ["4", "0x738cebC8ea48635272B2BDE7b7321fD0D6c580d9"],
  ["5", "0x76D76E706f1AB8839738d303C0AB41B4DCE0fc42"],
]

function generateRootAndProofs(values) {
  const tree = StandardMerkleTree.of(values, ["uint256", "address"])

  const proofs = {}

  for (const [i, v] of tree.entries()) {
    const ticketId = v[0]

    proofs[ticketId] = tree.getProof(i)
  }

  return { root: tree.root, proofs }
}

async function writeToFile(filename, data) {
  const filePath = path.resolve(__dirname, `./assets/${filename}.json`)

  await fs.writeFileSync(filePath, JSON.stringify(data))

  console.log(
    `\n[Merkle Tree]\n- Write to file complete.\n- Location: ${filePath}`
  )
}

async function main() {
  const data = generateRootAndProofs(values)

  const filename = "StakerERC721"

  await writeToFile(filename, data)
}

main()
