// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

contract TotalSupply is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testTotalSupplyAtInstantiation() external {
        assertEq(__staker.totalSupply(), 0);
    }

    function testTotalSupplyAfterMint() external {
        vm.prank(_users[0]);
        __staker.mint{ value: MINT_PRICE }();

        assertEq(__staker.totalSupply(), 1);
    }

    function testTotalSupplyAfterClaim() external {
        address user = _discountUsers[0];
        uint256 ticketId = 1;

        bytes32[] memory proof = _getProof(ticketId);

        vm.prank(user);
        __staker.claim{ value: DISCOUNT_PRICE }(proof, ticketId);

        assertEq(__staker.totalSupply(), 1);
    }
}
