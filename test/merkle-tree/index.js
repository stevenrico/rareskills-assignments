import { StandardMerkleTree } from "@openzeppelin/merkle-tree"
import path from "path"
import { fileURLToPath } from "url"
import fs from "fs"

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const values = [
  ["0x88c0e901bd1fd1a77bda342f0d2210fdc71cef6b", "1", "5"],
  ["0x7231c364597f3bfdb72cf52b197cc59111e71794", "6", "2"],
  ["0x043aed06383f290ee28fa02794ec7215ca099683", "8", "3"],
]

function generateRootAndProofs(values) {
  const tree = StandardMerkleTree.of(values, ["address", "uint256", "uint256"])

  const proofs = {}

  for (const [i, v] of tree.entries()) {
    const address = v[0]

    proofs[address] = tree.getProof(i)
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
