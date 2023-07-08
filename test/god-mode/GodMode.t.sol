// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";

import { GodMode } from "contracts/god-mode/GodMode.sol";

contract GodModeTest is Test {
    GodMode private _godMode;

    address private _god;
    address private _user;
    address private _recipient;

    address private _approved;

    function setUp() public {
        _god = vm.addr(100);
        vm.label(_god, "GOD");
        vm.deal(_god, 100 ether);
        _user = vm.addr(101);
        vm.label(_user, "USER");
        vm.deal(_user, 100 ether);
        _recipient = vm.addr(102);
        vm.label(_recipient, "RECIPIENT");
        vm.deal(_recipient, 100 ether);

        _godMode = new GodMode(_god);

        _approved = vm.addr(200);
        vm.label(_approved, "APPROVED");
        vm.deal(_approved, 100 ether);
    }

    function _itUpdatesAllowanceOf(
        address owner,
        address spender,
        uint256 expectedAmount
    ) private {
        assertEq(_godMode.allowance(owner, spender), expectedAmount);
    }

    function _itAllowsGodUserToTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 currentBalanceOfFrom = _godMode.balanceOf(from);
        uint256 currentBalanceOfTo = _godMode.balanceOf(to);

        vm.prank(_god);
        bool success = _godMode.transferFrom(from, to, amount);

        assertTrue(success);
        assertEq(_godMode.balanceOf(from), currentBalanceOfFrom - amount);
        assertEq(_godMode.balanceOf(to), currentBalanceOfTo + amount);

        _itUpdatesAllowanceOf(from, _god, currentBalanceOfFrom - amount);
        _itUpdatesAllowanceOf(to, _god, currentBalanceOfTo + amount);
    }

    function testMint() external {
        uint256 mintAmount = 100;

        vm.prank(_user);
        _godMode.mint(mintAmount);

        _itUpdatesAllowanceOf(_user, _god, mintAmount);
        _itAllowsGodUserToTransferFrom(_user, _recipient, 50);
    }

    function testBurn() external {
        uint256 mintAmount = 100;
        uint256 burnAmount = 50;

        vm.startPrank(_user);

        _godMode.mint(mintAmount);
        _godMode.burn(burnAmount);

        vm.stopPrank();

        _itUpdatesAllowanceOf(_user, _god, mintAmount - burnAmount);
        _itAllowsGodUserToTransferFrom(_user, _recipient, 50);
    }

    function testTransfer() external {
        uint256 mintAmount = 100;
        uint256 transferAmount = 50;

        vm.startPrank(_user);

        _godMode.mint(mintAmount);
        _godMode.transfer(_recipient, transferAmount);

        vm.stopPrank();

        _itUpdatesAllowanceOf(_user, _god, mintAmount - transferAmount);
        _itUpdatesAllowanceOf(_recipient, _god, transferAmount);

        _itAllowsGodUserToTransferFrom(_user, _recipient, transferAmount);
        _itAllowsGodUserToTransferFrom(_recipient, _user, transferAmount);
    }

    function testTransferFrom() external {
        uint256 mintAmount = 100;
        uint256 transferAmount = 50;

        vm.startPrank(_user);

        _godMode.mint(mintAmount);
        _godMode.approve(_approved, mintAmount);

        vm.stopPrank();

        vm.prank(_approved);
        _godMode.transferFrom(_user, _recipient, transferAmount);

        _itUpdatesAllowanceOf(_user, _god, mintAmount - transferAmount);
        _itUpdatesAllowanceOf(_recipient, _god, transferAmount);

        _itAllowsGodUserToTransferFrom(_user, _recipient, transferAmount);
        _itAllowsGodUserToTransferFrom(_recipient, _user, transferAmount);
    }
}
