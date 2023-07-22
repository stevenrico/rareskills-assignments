// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { StakerERC721 } from "contracts/staking/StakerERC721.sol";

contract StakerERC721Test is Test {
    StakerERC721 private _staker;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    address private _marketplace;

    uint256 public constant MINT_PRICE = 1 ether;
    uint96 public constant ROYALTY_FEE = 250;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        vm.prank(_owner);
        _staker = new StakerERC721(MINT_PRICE, ROYALTY_FEE);

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);
        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);

        _marketplace = vm.addr(200);
        vm.label(_marketplace, "MARKETPLACE");
        vm.deal(_marketplace, 100 ether);
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
            _staker.mint{ value: 1 ether }();
        }

        vm.expectRevert("Staker: tokens are sold out");
        _staker.mint{ value: 1 ether }();

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
        _staker.mint{ value: 1 ether }();

        assertEq(_staker.totalSupply(), currentSupply + 1);
    }

    function testTotalSupply() external {
        _itStartsAtZero();
        _itIncrementsAfterMint();
    }

    function _itReturnsRoyaltyInfoForSale(address receiver, uint256 royalty)
        private
    {
        assertEq(receiver, address(_staker));
        assertEq(royalty, 0.025 ether);
    }

    function _itReceivesRoyaltiesFromMarketplace(
        address receiver,
        uint256 royalty
    ) private {
        vm.prank(_marketplace);
        (bool success,) = receiver.call{ value: royalty }("");

        assertTrue(success);
        assertEq(_staker.getBalance(), 1.025 ether);
    }

    function testRoyalties() external {
        vm.prank(_userOne);
        _staker.mint{ value: 1 ether }();

        uint256 salePrice = 1 ether;

        vm.prank(_marketplace);
        (address receiver, uint256 royalty) = _staker.royaltyInfo(1, salePrice);

        _itReturnsRoyaltyInfoForSale(receiver, royalty);
        _itReceivesRoyaltiesFromMarketplace(receiver, royalty);
    }

    function _itRevertsWhenBalanceIsZero(address user) private {
        vm.expectRevert("StakerERC721: unable to withdraw");
        vm.prank(user);
        _staker.withdraw();
    }

    function _itRevertsWhenCallerIsNotOwner(address user) private {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user);
        _staker.withdraw();
    }

    function _itWithdraws(address user, uint256 expectedAmount) private {
        vm.prank(user);
        _staker.withdraw();

        assertEq(user.balance, expectedAmount);
    }

    function _itWithdrawsAfterOwnershipTransfer(
        address oldOwner,
        address newOwner,
        uint256 expectedAmount
    ) private {
        vm.prank(oldOwner);
        _staker.transferOwnership(newOwner);

        vm.startPrank(newOwner);

        _staker.acceptOwnership();
        _staker.withdraw();

        vm.stopPrank();

        assertEq(_staker.owner(), newOwner);
        assertEq(newOwner.balance, expectedAmount);
    }

    function testWithdraw() external {
        _itRevertsWhenBalanceIsZero(_owner);

        vm.prank(_userOne);
        _staker.mint{ value: 1 ether }();

        _itRevertsWhenCallerIsNotOwner(_userOne);
        _itWithdraws(_owner, 101 ether);

        vm.prank(_userOne);
        _staker.mint{ value: 1 ether }();

        _itWithdrawsAfterOwnershipTransfer(_owner, _userTwo, 101 ether);
        _itRevertsWhenCallerIsNotOwner(_owner);
    }
}
