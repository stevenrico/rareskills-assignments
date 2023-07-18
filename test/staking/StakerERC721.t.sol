// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { StakerERC721 } from "contracts/staking/StakerERC721.sol";

contract StakerERC721Test is Test {
    StakerERC721 private _staker;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        _staker = new StakerERC721(1 ether);

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);
        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
    }

    function _itMintsAToken(address user, uint256 expectedAmount) private {
        vm.prank(user);
        _staker.mint{ value: 1 ether }();

        assertEq(_staker.balanceOf(user), expectedAmount);
    }

    function _itRevertsWhenIncorrectAmountSent(address user) private {
        vm.expectRevert("Staker: incorrect amount sent for mint");
        vm.prank(user);
        _staker.mint{ value: 0.5 ether }();
    }

    function _itRevertsWhenMaxSupplyIsReached(address user) private {
        vm.startPrank(user);

        for (uint256 i = 1; i <= 19; i++) {
            _staker.mint{ value: 1 ether}();
        }
        
        vm.expectRevert("Staker: tokens are sold out");
        _staker.mint{ value: 1 ether}();

        vm.stopPrank();

        assertEq(_staker.balanceOf(user), 20);
    }

    function testMint() external {
        _itMintsAToken(_userOne, 1);
        _itRevertsWhenIncorrectAmountSent(_userOne);
        _itRevertsWhenMaxSupplyIsReached(_userOne);
    }

    function _itStartsAtZero() private {
        assertEq(_staker.totalSupply(), 0);
    }

    function _itIncrementsAfterMint() private {
        uint256 currentSupply = _staker.totalSupply();

        vm.prank(_userOne);
        _staker.mint{ value: 1 ether}();
    
        assertEq(_staker.totalSupply(), currentSupply + 1);
    }

    function testTotalSupply() external {
        _itStartsAtZero();
        _itIncrementsAfterMint();
    }
}
