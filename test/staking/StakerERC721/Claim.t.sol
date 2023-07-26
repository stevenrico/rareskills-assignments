// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

import { Strings } from "@openzeppelin/utils/Strings.sol";

contract Claim is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testMintTokensWithDiscount() external {
        _itMintsTokenFor(_discountUsers[0], 1, 1);
        _itMintsTokenFor(_discountUsers[0], 2, 2);
        _itMintsTokenFor(_discountUsers[0], 3, 3);
        _itMintsTokenFor(_discountUsers[1], 4, 1);
        _itMintsTokenFor(_discountUsers[2], 5, 1);
    }

    function testRevertWhenTicketHasBeenUsed() external {
        address user = _discountUsers[0];
        uint256 ticketId = 1;

        _itMintsTokenFor(user, ticketId, 1);

        bytes32[] memory proof = _getProof(ticketId);

        vm.expectRevert("StakerERC721: discount has been claimed");
        vm.prank(user);
        __staker.claim{ value: DISCOUNT_PRICE }(proof, ticketId);

        assertEq(__staker.balanceOf(user), 1);
    }

    function _itMintsTokenFor(
        address user,
        uint256 ticketId,
        uint256 expectedAmount
    ) private {
        bytes32[] memory proof = _getProof(ticketId);

        vm.prank(user);
        __staker.claim{ value: DISCOUNT_PRICE }(proof, ticketId);

        assertEq(__staker.balanceOf(user), expectedAmount);
    }

    function testRevertWhenIncorrectAmountSentForClaim() external {
        address user = _discountUsers[0];
        uint256 ticketId = 1;

        bytes32[] memory proof = _getProof(ticketId);

        vm.expectRevert("StakerERC721: incorrect amount sent for mint");
        vm.prank(user);
        __staker.claim{ value: 0.2 ether }(proof, ticketId);

        assertEq(__staker.balanceOf(user), 0);
    }

    function testRevertWhenVerificationFails() external {
        address user = _discountUsers[1];
        uint256 ticketId = 1;

        bytes32[] memory proof = _getProof(ticketId);

        vm.expectRevert("StakerERC721: not eligible for discount");
        vm.prank(user);
        __staker.claim{ value: DISCOUNT_PRICE }(proof, ticketId);

        assertEq(__staker.balanceOf(user), 0);
    }
}
