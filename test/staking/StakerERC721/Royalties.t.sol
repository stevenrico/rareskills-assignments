// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract Royalties is BaseSetup {
    uint256 private _salePrice = 1 ether;

    function setUp() public override {
        super.setUp();

        vm.prank(_users[0]);
        __staker.mint{ value: MINT_PRICE }();
    }

    function testRoyaltyInfo() external {
        vm.prank(_marketplace);
        (address receiver, uint256 royalty) =
            __staker.royaltyInfo(1, _salePrice);

        assertEq(receiver, address(__staker));
        assertEq(royalty, _salePrice * ROYALTY_FEE / 10_000);
    }

    function testReceiveRoyaltyFromMarketplace() external {
        vm.startPrank(_marketplace);

        (address receiver, uint256 royalty) =
            __staker.royaltyInfo(1, _salePrice);
        (bool success,) = receiver.call{ value: royalty }("");

        vm.stopPrank();

        uint256 expectedBalance =
            MINT_PRICE + (_salePrice * ROYALTY_FEE / 10_000);

        assertTrue(success);
        assertEq(__staker.getBalance(), expectedBalance);
    }
}
