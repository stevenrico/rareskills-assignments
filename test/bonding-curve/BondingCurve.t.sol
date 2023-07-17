// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";

import { BondingCurveERC20 } from
    "contracts/bonding-curve/BondingCurveERC20.sol";

import { MockERC20 } from "../utils/MockERC20.sol";

contract BondingCurveTest is Test {
    BondingCurveERC20 private _bondingCurveToken;
    MockERC20 private _reserveToken;

    uint256 private _scale = 10 ** 18;

    address private _owner;

    address private _userOne;
    address private _userTwo;
    address private _userThree;
    address private _userFour;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        _reserveToken = new MockERC20("Reserve Token", "RSVT");

        _bondingCurveToken =
            new BondingCurveERC20(address(_reserveToken), 50, 100);

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);
        _mintAndApproveReserveTokens(_userOne);
        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
        _mintAndApproveReserveTokens(_userTwo);
        _userThree = vm.addr(103);
        vm.label(_userThree, "USER THREE");
        vm.deal(_userThree, 100 ether);
        _mintAndApproveReserveTokens(_userThree);
        _userFour = vm.addr(104);
        vm.label(_userFour, "USER FOUR");
        vm.deal(_userFour, 100 ether);
        _mintAndApproveReserveTokens(_userFour);
    }

    function _mintAndApproveReserveTokens(address user) private {
        uint256 amount = 100;

        vm.startPrank(user);

        _reserveToken.mint(amount);
        _reserveToken.approve(address(_bondingCurveToken), amount * _scale);

        vm.stopPrank();
    }

    function _itTransfersReserveTokens(uint256 expectedAmount) private {
        assertEq(
            _reserveToken.balanceOf(address(_bondingCurveToken)), expectedAmount
        );
    }

    function _itMintsTokens(address user, uint256 expectedAmount) private {
        assertEq(_bondingCurveToken.balanceOf(user), expectedAmount);
    }

    function _itMintsTokensWhenReserveBalanceIsZero() private {
        uint256 reserveTokens = 1 * _scale;

        vm.prank(_userOne);
        (bool success,) =
            address(_bondingCurveToken).call{ value: reserveTokens }("");

        assertTrue(success);
        _itTransfersReserveTokens(reserveTokens);
        _itMintsTokens(_userOne, 1_414_213_562_373_095_048);
    }

    function _itMintsTokensWhenReserveBalanceIsNonZero() private {
        uint256 reserveTokens = 1 * _scale;

        vm.prank(_userTwo);
        (bool success,) =
            address(_bondingCurveToken).call{ value: reserveTokens }("");

        assertTrue(success);
        _itTransfersReserveTokens(2 * _scale);
        _itMintsTokens(_userTwo, 585_786_437_626_904_949);
    }

    function testReceive() external {
        _itMintsTokensWhenReserveBalanceIsZero();
        _itMintsTokensWhenReserveBalanceIsNonZero();
    }
}
