// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/token/common/ERC2981.sol";
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";

contract StakerERC721 is ERC721, ERC2981, Ownable2Step {
    uint256 private _mintPrice;

    uint256 public constant MAX_SUPPLY = 20;
    uint256 private _totalSupply;

    constructor(uint256 mintPrice, uint96 royaltyFee)
        ERC721("Staker", "STKR")
    {
        _mintPrice = mintPrice;

        _setDefaultRoyalty(address(this), royaltyFee);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable { }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "StakerERC721: unable to withdraw");

        (bool success,) = address(msg.sender).call{ value: balance }("");

        require(success, "StakerERC721: failed to withdraw");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
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
