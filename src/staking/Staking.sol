// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/token/ERC721/IERC721Receiver.sol";

contract Staking {
    IERC721 private _stakerNFT;

    mapping(uint256 => address) private _stakers;

    constructor(address staker) {
        _stakerNFT = IERC721(staker);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(uint256 tokenId) external {
        _stakers[tokenId] = msg.sender;
        _stakerNFT.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function unstake(uint256 tokenId) external {
        require(
            _stakers[tokenId] == msg.sender,
            "Staking: unauthorized access to token"
        );

        delete _stakers[tokenId];

        _stakerNFT.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function getStaker(uint256 tokenId) external view returns (address) {
        return _stakers[tokenId];
    }
}
