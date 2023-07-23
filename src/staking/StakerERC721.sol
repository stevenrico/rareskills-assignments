// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/token/common/ERC2981.sol";
import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";

import { MerkleProof } from "@openzeppelin/utils/cryptography/MerkleProof.sol";

contract StakerERC721 is ERC721, ERC2981, Ownable2Step {
    uint256 private _mintPrice;
    uint256 private _discountPrice;

    bytes32 private _root;

    uint256 public constant MAX_SUPPLY = 20;
    uint256 private _totalSupply;
    uint256 private _publicMintIndex;

    constructor(
        uint256 mintPrice,
        uint256 publicMintIndex,
        uint256 discountPrice,
        uint96 royaltyFee,
        bytes32 root
    ) ERC721("Staker", "STKR") {
        _mintPrice = mintPrice;
        _publicMintIndex = publicMintIndex;
        _discountPrice = discountPrice;

        _setDefaultRoyalty(address(this), royaltyFee);

        _root = root;
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
            msg.value == _mintPrice, "StakerERC721: incorrect amount sent for mint"
        );
        require(_publicMintIndex <= MAX_SUPPLY, "StakerERC721: tokens are sold out");

        _safeMint(msg.sender, _publicMintIndex);

        _totalSupply++;
        _publicMintIndex++;
    }

    function claim(bytes32[] calldata proof, uint256 index, uint256 amount)
        external
        payable
    {
        require(
            _verify(proof, msg.sender, index, amount),
            "StakerERC721: not eligible for discount"
        );
        require(
            msg.value == _mintPrice * amount / 2,
            "StakerERC721: incorrect amount sent for mint"
        );

        uint256 limit = index + amount;

        require(limit < _publicMintIndex, "StakerERC721: tokens are sold out");

        for (uint256 i = index; i < limit; i++) {
            _safeMint(msg.sender, i);
        }

        _totalSupply += amount;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function _verify(
        bytes32[] calldata proof,
        address user,
        uint256 index,
        uint256 amount
    ) private view returns (bool) {
        bytes32 leaf =
            keccak256(bytes.concat(keccak256(abi.encode(user, index, amount))));

        return MerkleProof.verify(proof, _root, leaf);
    }
}
