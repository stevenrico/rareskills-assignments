// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { StakerERC721 } from "contracts/staking/StakerERC721.sol";

import { Strings } from "@openzeppelin/utils/Strings.sol";

contract StakerERC721Test is Test {
    StakerERC721 private _staker;

    address private _owner;

    address private _userOne;
    address private _userTwo;
    address private _userThree;
    address private _userFour;

    address private _marketplace;

    uint256 public constant MINT_PRICE = 1 ether;
    uint256 public constant PUBLIC_MINT_INDEX = 11;
    uint256 public constant DISCOUNT_PRICE = 0.5 ether;
    uint96 public constant ROYALTY_FEE = 250;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        string memory data =
            vm.readFile("./test/merkle-tree/assets/StakerERC721.json");
        bytes memory root = vm.parseJson(data, "$.root");

        vm.prank(_owner);
        _staker =
        new StakerERC721(MINT_PRICE, PUBLIC_MINT_INDEX, DISCOUNT_PRICE, ROYALTY_FEE, bytes32(root));

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);
        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
        _userThree = vm.addr(103);
        vm.label(_userThree, "USER THREE");
        vm.deal(_userThree, 100 ether);
        _userFour = vm.addr(104);
        vm.label(_userFour, "USER FOUR");
        vm.deal(_userFour, 100 ether);

        _marketplace = vm.addr(200);
        vm.label(_marketplace, "MARKETPLACE");
        vm.deal(_marketplace, 100 ether);
    }

    function _itMintsAToken(address user, uint256 expectedAmount) private {
        vm.prank(user);
        _staker.mint{ value: MINT_PRICE }();

        assertEq(_staker.balanceOf(user), expectedAmount);
    }

    function _itRevertsWhenIncorrectAmountSent(address user) private {
        vm.expectRevert("StakerERC721: incorrect amount sent for mint");
        vm.prank(user);
        _staker.mint{ value: 0.5 ether }();
    }

    function _itRevertsWhenMaxSupplyIsReached(address user) private {
        vm.startPrank(user);

        for (uint256 i = PUBLIC_MINT_INDEX + 1; i <= 20; i++) {
            _staker.mint{ value: MINT_PRICE }();
        }

        vm.expectRevert("StakerERC721: tokens are sold out");
        _staker.mint{ value: MINT_PRICE }();

        vm.stopPrank();

        assertEq(_staker.balanceOf(user), 10);
    }

    function testMint() external {
        _itMintsAToken(_userOne, 1);
        _itRevertsWhenIncorrectAmountSent(_userOne);
        _itRevertsWhenMaxSupplyIsReached(_userOne);
    }

    function _getProof(uint256 ticketId) private returns (bytes32[] memory) {
        string memory data =
            vm.readFile("./test/merkle-tree/assets/StakerERC721.json");
        string memory key =
            string.concat("$.proofs.", Strings.toString(ticketId));

        return vm.parseJsonBytes32Array(data, key);
    }

    function _itRevertsWhenVerficationFails(
        address user,
        uint256 value,
        uint256 ticketId,
        uint256 expectedAmount
    ) private {
        bytes32[] memory proof = _getProof(ticketId);

        vm.expectRevert("StakerERC721: not eligible for discount");
        vm.prank(user);
        _staker.claim{ value: value }(proof, ticketId);

        assertEq(_staker.balanceOf(user), expectedAmount);
    }

    function _itRevertsWhenIncorrectAmountSentForClaim(
        address user,
        uint256 value,
        uint256 ticketId,
        uint256 expectedAmount
    ) private {
        bytes32[] memory proof = _getProof(ticketId);

        vm.expectRevert("StakerERC721: incorrect amount sent for mint");
        vm.prank(user);
        _staker.claim{ value: value }(proof, ticketId);

        assertEq(_staker.balanceOf(user), expectedAmount);
    }

    function _itMintsATokenWithADiscount(
        address user,
        uint256 value,
        uint256 ticketId,
        uint256 expectedAmount
    ) private {
        bytes32[] memory proof = _getProof(ticketId);

        vm.prank(user);
        _staker.claim{ value: value }(proof, ticketId);

        assertEq(_staker.balanceOf(user), expectedAmount);
    }

    function _itRevertsWhenUserHasAlreadyClaimed(
        address user,
        uint256 value,
        uint256 ticketId,
        uint256 expectedAmount
    ) private {
        bytes32[] memory proof = _getProof(ticketId);

        vm.expectRevert("StakerERC721: discount has been claimed");
        vm.prank(user);
        _staker.claim{ value: value }(proof, ticketId);

        assertEq(_staker.balanceOf(user), expectedAmount);
    }

    function testClaim() external {
        _itRevertsWhenVerficationFails(_userThree, DISCOUNT_PRICE, 1, 0);
        _itRevertsWhenIncorrectAmountSentForClaim(_userTwo, 0.2 ether, 1, 0);
        _itMintsATokenWithADiscount(_userTwo, DISCOUNT_PRICE, 1, 1);
        _itMintsATokenWithADiscount(_userTwo, DISCOUNT_PRICE, 2, 2);
        _itMintsATokenWithADiscount(_userTwo, DISCOUNT_PRICE, 3, 3);
        _itMintsATokenWithADiscount(_userThree, DISCOUNT_PRICE, 4, 1);
        _itMintsATokenWithADiscount(_userFour, DISCOUNT_PRICE, 5, 1);
        _itRevertsWhenUserHasAlreadyClaimed(_userTwo, DISCOUNT_PRICE, 1, 3);
    }

    function _itStartsAtZero() private {
        assertEq(_staker.totalSupply(), 0);
    }

    function _itIncrementsAfterMint(address user) private {
        uint256 currentSupply = _staker.totalSupply();

        vm.prank(user);
        _staker.mint{ value: MINT_PRICE }();

        assertEq(_staker.totalSupply(), currentSupply + 1);
    }

    function _itIncrementsAfterClaim(
        address user,
        uint256 value,
        uint256 ticketId,
        uint256 expectedAmount
    ) private {
        uint256 currentSupply = _staker.totalSupply();

        bytes32[] memory proof = _getProof(ticketId);

        vm.prank(user);
        _staker.claim{ value: value }(proof, ticketId);

        assertEq(_staker.totalSupply(), currentSupply + expectedAmount);
    }

    function testTotalSupply() external {
        _itStartsAtZero();
        _itIncrementsAfterMint(_userOne);
        _itIncrementsAfterClaim(_userTwo, DISCOUNT_PRICE, 1, 1);
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
        _staker.mint{ value: MINT_PRICE }();

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
        _staker.mint{ value: MINT_PRICE }();

        _itRevertsWhenCallerIsNotOwner(_userOne);
        _itWithdraws(_owner, 101 ether);

        vm.prank(_userOne);
        _staker.mint{ value: MINT_PRICE }();

        _itWithdrawsAfterOwnershipTransfer(_owner, _userTwo, 101 ether);
        _itRevertsWhenCallerIsNotOwner(_owner);
    }
}
