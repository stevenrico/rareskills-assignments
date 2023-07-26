// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

import { Strings } from "@openzeppelin/utils/Strings.sol";

contract MintTo is BaseSetup {
    function setUp() public override {
        super.setUp();

        vm.prank(_owners[0]);
        __reward.grantMinterRole(address(__staking));
    }

    function testMintTo() external {
        address user = _users[0];
        uint256 mintAmount = 1 * _scale;

        vm.prank(address(__staking));
        __reward.mintTo(user, mintAmount);

        assertEq(__reward.balanceOf(user), mintAmount);
    }

    function testRevertWhenCallerIsNotMinter() external {
        address user = _users[0];
        uint256 mintAmount = 1 * _scale;

        string memory errorMsg = string.concat(
            "AccessControl: account ",
            Strings.toHexString(user),
            " is missing role 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
        );

        vm.expectRevert(bytes(errorMsg));
        vm.prank(user);
        __reward.mintTo(user, mintAmount);
    }
}
