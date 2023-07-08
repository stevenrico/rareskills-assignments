// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

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

    function _itRevertsWhenUserIsNotAdmin(bytes memory func) private {
        vm.expectRevert(
            "AccessControl: account 0xe6b3367318c5e11a6eed3cd0d850ec06a02e9b90 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
        );
        (bool success,) = address(_user).call(func);

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
        _itRevertsWhenUserIsNotAdmin(
            abi.encodeCall(_sanction.addToSanctionList, _unauthorizedUser)
        );
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
        _itRevertsWhenUserIsNotAdmin(
            abi.encodeCall(_sanction.removeFromSanctionList, _unauthorizedUser)
        );
        _itRemovesUserFromSanctionList(_unauthorizedUser);
    }

    function _itRevertsWhenUserIsOnSanctionList(address user, bytes memory func)
        private
    {
        vm.prank(_adminUser);
        _sanction.addToSanctionList(user);

        vm.expectRevert(
            "Unauthorized: account 0xe6b3367318c5e11a6eed3cd0d850ec06a02e9b90 is on the sanction list"
        );
        (bool success,) = address(user).call(func);

        assertFalse(success);
    }

    function _itDoesNotAllowUnauthorizedUserToMint(address user) private {
        assertEq(_sanction.balanceOf(user), 0);
    }

    function _itAllowsAuthorizedUserToMint(address user) private {
        vm.prank(user);
        _sanction.mint(100);

        assertEq(_sanction.balanceOf(user), 100);
    }

    function testMint() external {
        _itRevertsWhenUserIsOnSanctionList(
            _unauthorizedUser, abi.encodeCall(_sanction.mint, 100)
        );
        _itDoesNotAllowUnauthorizedUserToMint(_unauthorizedUser);

        _itAllowsAuthorizedUserToMint(_authorizedUser);
    }

    function _itDoesNotAllowUnauthorizedUserToBurn(address user) private {
        assertEq(_sanction.balanceOf(user), 100);
    }

    function _itAllowsAuthorizedUserToBurn(address user) private {
        vm.prank(user);
        _sanction.burn(100);

        assertEq(_sanction.balanceOf(user), 0);
    }

    function testBurn() external {
        vm.prank(_unauthorizedUser);
        _sanction.mint(100);

        vm.prank(_authorizedUser);
        _sanction.mint(100);

        _itRevertsWhenUserIsOnSanctionList(
            _unauthorizedUser, abi.encodeCall(_sanction.burn, 100)
        );
        _itDoesNotAllowUnauthorizedUserToBurn(_unauthorizedUser);

        _itAllowsAuthorizedUserToBurn(_authorizedUser);
    }

    function _itDoesNotAllowUnauthorizedUserToTransfer(
        address user,
        address recipient
    ) private {
        assertEq(_sanction.balanceOf(user), 100);
        assertEq(_sanction.balanceOf(recipient), 0);
    }

    function _itAllowsAuthorizedUserToTransfer(address user, address recipient)
        private
    {
        vm.prank(user);
        _sanction.transfer(recipient, 50);

        assertEq(_sanction.balanceOf(user), 50);
        assertEq(_sanction.balanceOf(recipient), 50);
    }

    function testTransfer() external {
        vm.prank(_unauthorizedUser);
        _sanction.mint(100);

        vm.prank(_authorizedUser);
        _sanction.mint(100);

        _itRevertsWhenUserIsOnSanctionList(
            _unauthorizedUser, abi.encodeCall(_sanction.transfer, (_user, 50))
        );
        _itDoesNotAllowUnauthorizedUserToTransfer(_unauthorizedUser, _user);

        _itAllowsAuthorizedUserToTransfer(_authorizedUser, _user);
    }

    function _itDoesNotAllowUnauthorizedUserToTransferFrom(
        address user,
        address recipient
    ) private {
        assertEq(_sanction.balanceOf(user), 100);
        assertEq(_sanction.balanceOf(recipient), 0);
    }

    function _itAllowsAuthorizedUserToTransferFrom(
        address user,
        address recipient
    ) private {
        vm.prank(recipient);
        _sanction.transferFrom(user, recipient, 50);

        assertEq(_sanction.balanceOf(user), 50);
        assertEq(_sanction.balanceOf(recipient), 50);
    }

    function testTransferFrom() external {
        vm.startPrank(_user);
        _sanction.mint(100);

        _sanction.approve(_unauthorizedUser, 50);
        _sanction.approve(_authorizedUser, 50);

        vm.stopPrank();

        _itRevertsWhenUserIsOnSanctionList(
            _unauthorizedUser,
            abi.encodeCall(
                _sanction.transferFrom, (_user, _unauthorizedUser, 50)
            )
        );
        _itDoesNotAllowUnauthorizedUserToTransferFrom(_user, _unauthorizedUser);

        _itAllowsAuthorizedUserToTransferFrom(_user, _authorizedUser);
    }
}
