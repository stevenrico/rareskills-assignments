// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { PrimeSearch } from "contracts/enumerable-prime/PrimeSearch.sol";

import { EnumPrimeERC721 } from "contracts/enumerable-prime/EnumPrimeERC721.sol";

contract PrimeSearchTest is Test {
    PrimeSearch private _primeSearch;
    EnumPrimeERC721 private _enumPrime;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        vm.startPrank(_owner);

        _enumPrime = new EnumPrimeERC721();
        _primeSearch = new PrimeSearch(address(_enumPrime));

        vm.stopPrank();

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);
        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);

        _mintTo(_userOne, 5);
        _mintTo(_userTwo, 15);
        _mintTo(_userOne, 20);
    }

    function _mintTo(address user, uint256 to) private {
        uint256 currentIndex = _enumPrime.totalSupply();

        vm.startPrank(user);

        for (uint256 i = currentIndex; i < to; i++) {
            _enumPrime.mint();
        }

        vm.stopPrank();
    }

    function _itReturnsNumberOfIdsThatArePrimeOwnedByUser(
        address user,
        uint256 expectedNum
    ) private {
        vm.prank(_owner);
        (uint256 num) = _primeSearch.search(user);

        assertEq(num, expectedNum);
    }

    function testSearch() external {
        _itReturnsNumberOfIdsThatArePrimeOwnedByUser(_userOne, 5);
        _itReturnsNumberOfIdsThatArePrimeOwnedByUser(_userTwo, 3);
    }
}
