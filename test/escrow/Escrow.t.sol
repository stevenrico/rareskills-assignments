// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";

import { Escrow } from "contracts/escrow/Escrow.sol";

import { MockERC20 } from "../utils/MockERC20.sol";

contract EscrowTest is Test {
    Escrow private _escrow;
    MockERC20 private _token;

    uint256 private _scale = 10 ** 18;

    address private _owner;

    address private _buyer;
    address private _seller;
    address private _unauthorized;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        vm.startPrank(_owner);

        _escrow = new Escrow();
        _token = new MockERC20("Token", "TKN");

        vm.stopPrank();

        _buyer = vm.addr(101);
        vm.label(_buyer, "BUYER");
        vm.deal(_buyer, 100 ether);

        vm.prank(_buyer);
        _token.mint(50);

        _seller = vm.addr(102);
        vm.label(_seller, "SELLER");
        vm.deal(_seller, 100 ether);
        _unauthorized = vm.addr(103);
        vm.label(_unauthorized, "UNAUTHORIZED");
        vm.deal(_unauthorized, 100 ether);
    }

    function _itStoresADeposit(
        address buyer,
        address token,
        address seller,
        uint256 expectedAmount
    ) private {
        vm.startPrank(buyer);

        _escrow.deposit(token, seller, expectedAmount);
        Escrow.Deposit memory deposit = _escrow.getDeposit(token, seller);

        vm.stopPrank();

        assertEq(deposit.depositor, buyer);
        assertEq(deposit.amount, expectedAmount);
        assertEq(deposit.createdAt, block.timestamp);
    }

    function _itTransfersToEscrow(
        MockERC20 token,
        address escrow,
        uint256 expectedAmount
    ) private {
        assertEq(token.balanceOf(escrow), expectedAmount);
    }

    function testDeposit() external {
        uint256 amount = 50 * _scale;

        vm.prank(_buyer);
        _token.approve(address(_escrow), amount);

        _itStoresADeposit(_buyer, address(_token), _seller, amount);
        _itTransfersToEscrow(_token, address(_escrow), amount);
    }

    function _itRevertsWithIncorrectTokenContract(address seller) private {
        vm.expectRevert("Escrow: deposit does not exist");
        vm.prank(seller);
        _escrow.withdraw(address(0));
    }

    function _itRevertsWithIncorrectSeller(address seller, address token)
        private
    {
        vm.expectRevert("Escrow: deposit does not exist");
        vm.prank(seller);
        _escrow.withdraw(token);
    }

    function _itRevertsBeforeThreeDays(address seller, address token) private {
        vm.expectRevert("Escrow: not able to withdraw");
        vm.prank(seller);
        _escrow.withdraw(token);
    }

    function _itTransfersAmountAfterThreeDays(
        address seller,
        MockERC20 token,
        uint256 expectedAmount
    ) private {
        vm.warp(block.timestamp + 3 days);

        vm.prank(seller);
        _escrow.withdraw(address(token));

        assertEq(token.balanceOf(seller), expectedAmount);
    }

    function testWithdraw() external {
        uint256 amount = 50 * _scale;

        vm.warp(block.timestamp + 5 days);

        vm.startPrank(_buyer);

        _token.approve(address(_escrow), amount);
        _escrow.deposit(address(_token), _seller, amount);

        vm.stopPrank();

        _itRevertsWithIncorrectTokenContract(_seller);
        _itRevertsWithIncorrectSeller(_unauthorized, address(_token));
        _itRevertsBeforeThreeDays(_seller, address(_token));
        _itTransfersAmountAfterThreeDays(_seller, _token, amount);
    }
}
