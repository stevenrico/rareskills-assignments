// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract Unstake is BaseSetup {
    address private _user;
    uint256 private _tokenId = PUBLIC_MINT_INDEX;

    function setUp() public override {
        super.setUp();

        _user = _users[0];

        vm.startPrank(_user);

        __staker.mint{ value: MINT_PRICE }();
        __staker.approve(address(__staking), _tokenId);
        __staking.stake(_tokenId);

        vm.stopPrank();
    }

    function testUnstakeToken() external {
        vm.prank(_user);
        __staking.unstake(_tokenId);

        assertEq(__staker.ownerOf(_tokenId), _user);
        assertEq(__staking.getStaker(_tokenId), address(0));
    }

    function testRevertIfCallerIsNotStaker() external {
        vm.expectRevert("Staking: unauthorized access to token");
        vm.prank(_users[1]);
        __staking.unstake(_tokenId);
    }
}
