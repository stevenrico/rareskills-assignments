// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract Withdraw is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testWithdraw() external {
        vm.prank(_users[0]);
        __staker.mint{ value: MINT_PRICE }();

        address owner = _owners[0];
        uint256 currentBalance = owner.balance;

        vm.prank(owner);
        __staker.withdraw();

        assertEq(owner.balance, currentBalance + 1 ether);
    }

    function testWithdrawAfterOwnershipTransfer() external {
        vm.prank(_users[0]);
        __staker.mint{ value: MINT_PRICE }();

        address owner = _owners[0];
        address newOwner = _owners[1];

        uint256 currentBalance = newOwner.balance;

        vm.prank(owner);
        __staker.transferOwnership(newOwner);

        vm.startPrank(newOwner);

        __staker.acceptOwnership();
        __staker.withdraw();

        vm.stopPrank();

        assertEq(__staker.owner(), newOwner);
        assertEq(newOwner.balance, currentBalance + 1 ether);

        _itRevertsWhenCallerIsNotOwner(owner);
    }

    function testRevertWhenBalanceIsZero() external {
        vm.expectRevert("StakerERC721: unable to withdraw");
        vm.prank(_owners[0]);
        __staker.withdraw();
    }

    function testRevertWhenCallerIsNotOwner() external {
        vm.prank(_users[0]);
        __staker.mint{ value: MINT_PRICE }();

        _itRevertsWhenCallerIsNotOwner(_users[0]);
    }

    function _itRevertsWhenCallerIsNotOwner(address user) private {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user);
        __staker.withdraw();
    }
}
