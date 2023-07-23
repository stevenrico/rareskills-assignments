// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { EnumPrimeERC721 } from "contracts/enumerable-prime/EnumPrimeERC721.sol";

contract EnumPrimeERC721Test is Test {
    EnumPrimeERC721 private _enumPrime;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        vm.prank(_owner);
        _enumPrime = new EnumPrimeERC721();

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);
        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
    }

    function _mintTo(address user, uint256 to) private {
        uint256 currentIndex = _enumPrime.totalSupply();

        vm.startPrank(user);

        for (uint256 i = currentIndex; i <= to; i++) {
            _enumPrime.mint();
        }

        vm.stopPrank();
    }

    function _itMintsAToken(address user, uint256 expectedAmount) private {
        vm.prank(user);
        _enumPrime.mint();

        assertEq(_enumPrime.balanceOf(user), expectedAmount);
    }

    function _itRevertsWhenMaxSupplyIsReached(address user) private {
        _mintTo(user, 19);

        vm.expectRevert("EnumPrimeERC721: tokens are sold out");
        vm.prank(user);
        _enumPrime.mint();

        assertEq(_enumPrime.balanceOf(user), 20);
    }

    function testMint() external {
        _itMintsAToken(_userOne, 1);
        _itRevertsWhenMaxSupplyIsReached(_userOne);
    }
}
