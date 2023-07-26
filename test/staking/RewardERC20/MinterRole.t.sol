// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseSetup } from "../BaseSetup.t.sol";

import { Strings } from "@openzeppelin/utils/Strings.sol";

contract MinterRole is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testGrantMinterRole() external {
        bytes32 role = keccak256("MINTER_ROLE");

        address account = address(__staking);

        vm.prank(_owners[0]);
        __reward.grantMinterRole(account);

        assertTrue(__reward.hasRole(role, account));
    }

    function testRevertWhenCallerIsNotAdmin() external {
        address account = _users[0];

        string memory errorMsg = string.concat(
            "AccessControl: account ",
            Strings.toHexString(account),
            " is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );

        vm.expectRevert(bytes(errorMsg));
        vm.prank(account);
        __reward.grantMinterRole(account);
    }
}
