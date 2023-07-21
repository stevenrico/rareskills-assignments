// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { Staking } from "contracts/staking/Staking.sol";

import { StakerERC721 } from "contracts/staking/StakerERC721.sol";

contract StakingTest is Test {
    Staking private _staking;
    StakerERC721 private _stakerNFT;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    uint256 public constant MINT_PRICE = 1 ether;
    uint96 public constant ROYALTY_FEE = 250;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        _stakerNFT = new StakerERC721(MINT_PRICE, ROYALTY_FEE);

        _staking = new Staking(address(_stakerNFT));

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);

        vm.prank(_userOne);
        _stakerNFT.mint{ value: 1 ether }();

        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
    }

    function _stakeToken(address user, uint256 tokenId) private {
        vm.startPrank(user);

        _stakerNFT.approve(address(_staking), tokenId);
        _staking.stake(tokenId);

        vm.stopPrank();
    }

    function _itRevertsWithoutApproval(address user, uint256 tokenId) private {
        vm.expectRevert("ERC721: caller is not token owner or approved");
        vm.prank(user);
        _staking.stake(tokenId);
    }

    function _itTransfersOwnership(uint256 tokenId, address expectedOwner)
        private
    {
        assertEq(_stakerNFT.ownerOf(tokenId), expectedOwner);
    }

    function _itStoresStaker(uint256 tokenId, address expectedUser) private {
        assertEq(_staking.getStaker(tokenId), expectedUser);
    }

    function testStake() external {
        uint256 tokenId = 1;

        _itRevertsWithoutApproval(_userOne, tokenId);

        _stakeToken(_userOne, tokenId);

        _itTransfersOwnership(tokenId, address(_staking));
        _itStoresStaker(tokenId, _userOne);
    }

    function _itRevertsIfUserIsNotStaker(address user, uint256 tokenId)
        private
    {
        vm.expectRevert("Staking: unauthorized access to token");
        vm.prank(user);
        _staking.unstake(tokenId);
    }

    function _itRemovesStaker(uint256 tokenId) private {
        assertEq(_staking.getStaker(tokenId), address(0));
    }

    function testUnstake() external {
        uint256 tokenId = 1;

        _stakeToken(_userOne, tokenId);

        _itRevertsIfUserIsNotStaker(_userTwo, tokenId);

        vm.prank(_userOne);
        _staking.unstake(tokenId);

        _itTransfersOwnership(tokenId, _userOne);
        _itRemovesStaker(tokenId);
    }
}
