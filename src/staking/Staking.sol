// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/token/ERC721/IERC721Receiver.sol";

import { RewardERC20 } from "contracts/staking/RewardERC20.sol";

contract Staking {
    IERC721 private _stakerNFT;
    RewardERC20 private _rewardToken;

    uint256 private _scale;

    mapping(uint256 => address) private _stakers;

    uint256 public constant REWARD_AMOUNT = 10;

    mapping(uint256 => uint256) private _latestClaim;

    constructor(address staker, address reward) {
        _stakerNFT = IERC721(staker);
        _rewardToken = RewardERC20(reward);

        _scale = 10 ** _rewardToken.decimals();
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        _stakers[tokenId] = from;
        _latestClaim[tokenId] = block.timestamp;

        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(uint256 tokenId) external {
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

    function claimReward(uint256 tokenId) external {
        require(
            _stakers[tokenId] == msg.sender,
            "Staking: unauthorized access to token"
        );
        require(
            block.timestamp - _latestClaim[tokenId] > 24 hours,
            "Staking: no reward available to claim"
        );

        uint256 timeElapsed = block.timestamp - _latestClaim[tokenId];
        uint256 numOfDays = timeElapsed / 24 hours;

        _latestClaim[tokenId] = _latestClaim[tokenId] + (numOfDays * 24 hours);

        uint256 mintAmount = numOfDays * REWARD_AMOUNT * _scale;

        _rewardToken.mintTo(msg.sender, mintAmount);
    }

    function getLatestClaim(uint256 tokenId) external view returns (uint256) {
        return _latestClaim[tokenId];
    }
}
