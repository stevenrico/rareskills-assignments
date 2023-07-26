// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract Stake is BaseSetup {
    address private _user;
    uint256 private _tokenId = PUBLIC_MINT_INDEX;

    function setUp() public override {
        super.setUp();

        _user = _users[0];

        vm.prank(_user);
        __staker.mint{ value: MINT_PRICE }();
    }

    function testStakeToken() external {
        _stakeToken(_user, _tokenId);

        assertEq(__staker.ownerOf(_tokenId), address(__staking));
        assertEq(__staking.getStaker(_tokenId), _user);
        assertEq(__staking.getLatestClaim(_tokenId), block.timestamp);
    }

    function testStakeTokenWithOnReceived() external {
        _stakeTokenWithOnReceived(_user, _tokenId);

        assertEq(__staker.ownerOf(_tokenId), address(__staking));
        assertEq(__staking.getStaker(_tokenId), _user);
        assertEq(__staking.getLatestClaim(_tokenId), block.timestamp);
    }

    function testRevertIfUserHasNotApproved() external {
        vm.expectRevert("ERC721: caller is not token owner or approved");
        vm.prank(_user);
        __staking.stake(_tokenId);
    }

    function _stakeToken(address user, uint256 tokenId) private {
        vm.startPrank(user);

        __staker.approve(address(__staking), tokenId);
        __staking.stake(tokenId);

        vm.stopPrank();
    }

    function _stakeTokenWithOnReceived(address user, uint256 tokenId) private {
        vm.startPrank(user);

        __staker.approve(address(__staking), tokenId);
        __staker.safeTransferFrom(user, address(__staking), tokenId);

        vm.stopPrank();
    }
}
