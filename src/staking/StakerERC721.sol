// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";

contract StakerERC721 is ERC721 {
    uint256 private _mintPrice;

    uint256 public constant MAX_SUPPLY = 20;
    uint256 private _totalSupply;

    constructor(uint256 mintPrice) ERC721("Staker", "STKR") {
        _mintPrice = mintPrice;
    }

    function mint() external payable {
        require(
            msg.value == _mintPrice, "Staker: incorrect amount sent for mint"
        );

        _totalSupply++;
        
        require(_totalSupply <= MAX_SUPPLY, "Staker: tokens are sold out");


        _safeMint(msg.sender, _totalSupply);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}
