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
}
