// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from
    "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";

contract EnumPrimeERC721 is ERC721Enumerable {
    uint256 public constant MAX_SUPPLY = 20;

    constructor() ERC721("Enum Prime", "PRIME") { }

    function mint() external {
        uint256 currentSupply = totalSupply();

        require(
            currentSupply < MAX_SUPPLY, "EnumPrimeERC721: tokens are sold out"
        );

        _safeMint(msg.sender, currentSupply + 1);
    }
}
