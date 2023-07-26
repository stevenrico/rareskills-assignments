// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract Mint is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testMint() external {
        address user = _users[0];

        vm.prank(user);
        __staker.mint{ value: MINT_PRICE }();

        assertEq(__staker.balanceOf(user), 1);
    }

    function testRevertWhenIncorrectAmountSent() external {
        address user = _users[0];

        vm.expectRevert("StakerERC721: incorrect amount sent for mint");
        vm.prank(user);
        __staker.mint{ value: 0.5 ether }();

        assertEq(__staker.balanceOf(user), 0);
    }

    function testRevertWhenMaxSupplyIsReached() external {
        address user = _users[0];

        vm.startPrank(user);

        for (uint256 i = PUBLIC_MINT_INDEX; i <= 20; i++) {
            __staker.mint{ value: MINT_PRICE }();
        }

        vm.expectRevert("StakerERC721: tokens are sold out");
        __staker.mint{ value: MINT_PRICE }();

        vm.stopPrank();

        assertEq(__staker.balanceOf(user), 10);
    }
}
