// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";

import { Sanction } from "../src/Sanction.sol";
import { ISanctionEvents } from "../src/ISanction.sol";

contract SanctionTest is ISanctionEvents, Test {
    Sanction private _sanction;

    address private _adminUser;
    address private _user;

    address private _authorizedUser;
    address private _unauthorizedUser;

    function setUp() public {
        _adminUser = vm.addr(100);
        vm.label(_adminUser, "ADMIN");
        vm.deal(_adminUser, 100 ether);
        _user = vm.addr(101);
        vm.label(_user, "USER");
        vm.deal(_user, 100 ether);

        _sanction = new Sanction(_adminUser);

        _authorizedUser = vm.addr(200);
        vm.label(_authorizedUser, "AUTHORIZED_USER");
        vm.deal(_authorizedUser, 100 ether);

        _unauthorizedUser = vm.addr(201);
        vm.label(_unauthorizedUser, "UNAUTHORIZED_USER");
        vm.deal(_unauthorizedUser, 100 ether);
    }

    function _itRevertsWhenUserIsNotAdmin(bytes4 selector) private {
        vm.expectRevert(
            "AccessControl: account 0xe6b3367318c5e11a6eed3cd0d850ec06a02e9b90 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        (bool success,) = address(_user).call(
            abi.encodeWithSelector(selector, _unauthorizedUser)
        );

        assertFalse(success);
    }

    function _itAddsUserToSanctionList(address user) private {
        vm.startPrank(_adminUser);

        vm.expectEmit(true, true, false, true);
        emit SanctionListUpdate(_adminUser, user, "ADD");

        _sanction.addToSanctionList(user);

        assertEq(_sanction.checkSanctionList(user), true);

        vm.stopPrank();
    }

    function testAddToSanctionList() external {
        _itRevertsWhenUserIsNotAdmin(_sanction.addToSanctionList.selector);
        _itAddsUserToSanctionList(_unauthorizedUser);
    }

    function _itRemovesUserFromSanctionList(address user) private {
        vm.startPrank(_adminUser);

        _sanction.addToSanctionList(user);

        vm.expectEmit(true, true, false, true);
        emit SanctionListUpdate(_adminUser, user, "REMOVE");

        _sanction.removeFromSanctionList(user);

        assertEq(_sanction.checkSanctionList(user), false);

        vm.stopPrank();
    }

    function testRemoveFromSanctionList() external {
        _itRevertsWhenUserIsNotAdmin(_sanction.removeFromSanctionList.selector);
        _itRemovesUserFromSanctionList(_unauthorizedUser);
    }
}
