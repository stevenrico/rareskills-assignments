// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";

import { GodMode } from "contracts/god-mode/GodMode.sol";

contract GodModeTest is Test {
    GodMode private _godMode;

    address private _god;
    address private _user;

    function setUp() public {
        _god = vm.addr(100);
        vm.label(_god, "GOD");
        vm.deal(_god, 100 ether);
        _user = vm.addr(101);
        vm.label(_user, "USER");
        vm.deal(_user, 100 ether);

        _godMode = new GodMode(_god);
    }
}
