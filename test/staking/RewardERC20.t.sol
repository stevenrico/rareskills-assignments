// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test } from "@forge-std/Test.sol";
import { console } from "@forge-std/Console.sol";
import { RewardERC20 } from "contracts/staking/RewardERC20.sol";

import { Staking } from "contracts/staking/Staking.sol";

contract RewardERC20Test is Test {
    RewardERC20 private _rewardToken;
    Staking private _staking;

    uint256 private _scale = 10 ** 18;

    address private _owner;

    address private _userOne;
    address private _userTwo;

    function setUp() public {
        _owner = vm.addr(100);
        vm.label(_owner, "OWNER");
        vm.deal(_owner, 100 ether);

        vm.prank(_owner);
        _rewardToken = new RewardERC20();

        _staking = new Staking(address(0), address(_rewardToken));

        _userOne = vm.addr(101);
        vm.label(_userOne, "USER ONE");
        vm.deal(_userOne, 100 ether);

        _userTwo = vm.addr(102);
        vm.label(_userTwo, "USER TWO");
        vm.deal(_userTwo, 100 ether);
    }

    function _itRevertsWhenCallerIsNotAdmin(address user)  private{
        vm.expectRevert(
            "AccessControl: account 0xe6b3367318c5e11a6eed3cd0d850ec06a02e9b90 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        vm.prank(user);
        _rewardToken.grantMinterRole(user);
    }

    function _itGrantsMinterRole(address user, address account) private {
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(user);
        _rewardToken.grantMinterRole(account);

        assertTrue(_rewardToken.hasRole(role, account));
    } 

    function testGrantMinterRole() external {
        _itRevertsWhenCallerIsNotAdmin(_userOne);
        _itGrantsMinterRole(_owner, address(_staking));
    }

    function _mintTokensTo(address user, uint256 amount) private {
        vm.prank(address(_staking));
        _rewardToken.mintTo(user, amount);
    }

    function _itRevertsWhenCallerIsNotMinter(address user, uint256 amount)
        private
    {
        vm.expectRevert(
            "AccessControl: account 0x88c0e901bd1fd1a77bda342f0d2210fdc71cef6b is missing role 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
        );
        vm.prank(user);
        _rewardToken.mintTo(user, amount);
    }

    function _itMintsToUser(address user, uint256 expectedAmount) private {
        assertEq(_rewardToken.balanceOf(user), expectedAmount);
    }

    function testMintTo() external {
        uint256 mintAmount = 1 * _scale;

        vm.prank(_owner);
        _rewardToken.grantMinterRole(address(_staking));

        _itRevertsWhenCallerIsNotMinter(_userTwo, mintAmount);

        _mintTokensTo(_userOne, mintAmount);

        _itMintsToUser(_userOne, mintAmount);
    }
}
