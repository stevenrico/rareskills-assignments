// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract ClaimReward is BaseSetup {
    address private _user;
    uint256 private _tokenId = PUBLIC_MINT_INDEX;

    uint256 private _stakeTimestamp;

    function setUp() public override {
        super.setUp();

        _user = _users[0];

        vm.startPrank(_user);

        __staker.mint{ value: MINT_PRICE }();
        __staker.approve(address(__staking), _tokenId);
        __staking.stake(_tokenId);

        vm.stopPrank();

        _stakeTimestamp = block.timestamp;
    }

    function testClaimRewardWhen24HoursHasPassed() external {
        uint256 timeToAdd = 30 hours;
        uint256 numOfDays = timeToAdd / 24 hours;

        uint256 latestClaim = __staking.getLatestClaim(_tokenId);

        vm.warp(_stakeTimestamp + timeToAdd);

        vm.prank(_user);
        __staking.claimReward(_tokenId);

        assertEq(__reward.balanceOf(_user), 10 * numOfDays * _scale);
        assertEq(
            __staking.getLatestClaim(_tokenId),
            latestClaim + numOfDays * 24 hours
        );
    }

    function testRevertWhen24HoursHasNotPassed() external {
        vm.warp(_stakeTimestamp + 12 hours);

        vm.expectRevert("Staking: no reward available to claim");
        vm.prank(_user);
        __staking.claimReward(_tokenId);
    }

    function testRevertIfCallerIsNotStaker() external {
        vm.expectRevert("Staking: unauthorized access to token");
        vm.prank(_users[1]);
        __staking.claimReward(_tokenId);
    }

    function testRevertWhenUserUnstakes() external {
        vm.startPrank(_user);

        __staking.unstake(_tokenId);

        vm.expectRevert("Staking: unauthorized access to token");
        __staking.claimReward(_tokenId);

        vm.stopPrank();
    }
}
