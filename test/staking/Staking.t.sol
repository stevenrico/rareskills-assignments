// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { Staking } from "contracts/staking/Staking.sol";

import { StakerERC721 } from "contracts/staking/StakerERC721.sol";
import { RewardERC20 } from "contracts/staking/RewardERC20.sol";

contract StakingTest is Test {
    Staking private _staking;
    StakerERC721 private _stakerNFT;
    RewardERC20 private _rewardToken;

    uint256 private _scale;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    uint256 public constant MINT_PRICE = 1 ether;
    uint256 public constant PUBLIC_MINT_INDEX = 1;
    uint256 public constant DISCOUNT_PRICE = 0.5 ether;
    uint96 public constant ROYALTY_FEE = 250;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        vm.startPrank(_owner);

        _stakerNFT =
        new StakerERC721(MINT_PRICE, PUBLIC_MINT_INDEX, DISCOUNT_PRICE, ROYALTY_FEE, bytes32(""));
        _rewardToken = new RewardERC20();

        _scale = 10 ** _rewardToken.decimals();

        _staking = new Staking(address(_stakerNFT), address(_rewardToken));

        _rewardToken.grantMinterRole(address(_staking));

        vm.stopPrank();

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);

        vm.prank(_userOne);
        _stakerNFT.mint{ value: 1 ether }();

        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
    }

    function _stakeToken(address user, uint256 tokenId) private {
        vm.startPrank(user);

        _stakerNFT.approve(address(_staking), tokenId);
        _staking.stake(tokenId);

        vm.stopPrank();
    }

    function _stakeTokenWithOnReceived(address user, uint256 tokenId) private {
        vm.startPrank(user);

        _stakerNFT.approve(address(_staking), tokenId);
        _stakerNFT.safeTransferFrom(user, address(_staking), tokenId);

        vm.stopPrank();
    }

    function _itRevertsWithoutApproval(address user, uint256 tokenId) private {
        vm.expectRevert("ERC721: caller is not token owner or approved");
        vm.prank(user);
        _staking.stake(tokenId);
    }

    function _itTransfersOwnership(uint256 tokenId, address expectedOwner)
        private
    {
        assertEq(_stakerNFT.ownerOf(tokenId), expectedOwner);
    }

    function _itStoresStaker(uint256 tokenId, address expectedUser) private {
        assertEq(_staking.getStaker(tokenId), expectedUser);
    }

    function _itSetsLatestClaim(uint256 tokenId) private {
        assertEq(_staking.getLatestClaim(tokenId), block.timestamp);
    }

    function testStake() external {
        uint256 tokenId = 1;

        _itRevertsWithoutApproval(_userOne, tokenId);

        _stakeToken(_userOne, tokenId);

        _itTransfersOwnership(tokenId, address(_staking));
        _itStoresStaker(tokenId, _userOne);
        _itSetsLatestClaim(tokenId);
    }

    function testStakeWithOnReceived() external {
        uint256 tokenId = 1;

        _itRevertsWithoutApproval(_userOne, tokenId);

        _stakeTokenWithOnReceived(_userOne, tokenId);

        _itTransfersOwnership(tokenId, address(_staking));
        _itStoresStaker(tokenId, _userOne);
        _itSetsLatestClaim(tokenId);
    }

    function _itRevertsIfUserIsNotStaker(address user, bytes memory func)
        private
    {
        vm.expectRevert("Staking: unauthorized access to token");
        (bool success,) = address(user).call(func);

        assertFalse(success);
    }

    function _itRemovesStaker(uint256 tokenId) private {
        assertEq(_staking.getStaker(tokenId), address(0));
    }

    function testUnstake() external {
        uint256 tokenId = 1;

        _stakeToken(_userOne, tokenId);

        _itRevertsIfUserIsNotStaker(
            _userTwo, abi.encodeCall(_staking.unstake, tokenId)
        );

        vm.prank(_userOne);
        _staking.unstake(tokenId);

        _itTransfersOwnership(tokenId, _userOne);
        _itRemovesStaker(tokenId);
    }

    function _itRevertsWhen24hoursHasNotPassed(address user, uint256 tokenId)
        private
    {
        vm.expectRevert("Staking: no reward available to claim");
        vm.prank(user);
        _staking.claimReward(tokenId);
    }

    function _itMintsRewardWhen24HoursHasPassed(
        address user,
        uint256 tokenId,
        uint256 expectedReward
    ) private {
        vm.prank(user);
        _staking.claimReward(tokenId);

        assertEq(_rewardToken.balanceOf(user), expectedReward);
    }

    function _itUpdatesLatestClaim(uint256 tokenId, uint256 expectedTime)
        private
    {
        assertEq(_staking.getLatestClaim(tokenId), expectedTime);
    }

    function _itRevertsAfterUserUnstakes(address user, uint256 tokenId)
        private
    {
        vm.startPrank(user);

        _staking.unstake(tokenId);

        vm.expectRevert("Staking: unauthorized access to token");
        _staking.claimReward(tokenId);

        vm.stopPrank();
    }

    function testClaimReward() external {
        uint256 tokenId = 1;

        uint256 currentTimestamp = block.timestamp;

        _stakeToken(_userOne, tokenId);

        _itRevertsIfUserIsNotStaker(
            _userTwo, abi.encodeCall(_staking.claimReward, tokenId)
        );

        vm.warp(currentTimestamp + 12 hours);

        _itRevertsWhen24hoursHasNotPassed(_userOne, tokenId);

        uint256 timeToAdd = 30 hours;
        uint256 numOfDays = timeToAdd / 24 hours;

        uint256 currentLatestClaim = _staking.getLatestClaim(tokenId);

        vm.warp(currentTimestamp + timeToAdd);

        _itMintsRewardWhen24HoursHasPassed(
            _userOne, tokenId, 10 * numOfDays * _scale
        );
        _itUpdatesLatestClaim(
            tokenId, currentLatestClaim + (numOfDays * 24 hours)
        );

        _itRevertsAfterUserUnstakes(_userOne, tokenId);
    }
}
