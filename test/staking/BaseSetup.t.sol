// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { UsersSetup } from "./utils/UsersSetup.t.sol";

import { Staking } from "contracts/staking/Staking.sol";
import { StakerERC721 } from "contracts/staking/StakerERC721.sol";
import { RewardERC20 } from "contracts/staking/RewardERC20.sol";

import { Strings } from "@openzeppelin/utils/Strings.sol";

contract BaseSetup is UsersSetup {
    Staking internal __staking;
    StakerERC721 internal __staker;
    RewardERC20 internal __reward;

    address[] internal _owners;

    address[] internal _users;
    address[] internal _discountUsers;

    address internal _marketplace;

    uint256 internal _scale;

    uint256 public constant MINT_PRICE = 1 ether;
    uint256 public constant PUBLIC_MINT_INDEX = 11;
    uint256 public constant DISCOUNT_PRICE = 0.5 ether;
    uint96 public constant ROYALTY_FEE = 250;

    function setUp() public virtual {
        (, address[] memory owners) = _createUserGroup("OWNER", 2, 100 ether);
        _owners = owners;

        string memory data =
            vm.readFile("./test/merkle-tree/assets/StakerERC721.json");
        bytes memory root = vm.parseJson(data, "$.root");

        vm.startPrank(_owners[0]);

        __staker =
        new StakerERC721(MINT_PRICE, PUBLIC_MINT_INDEX, DISCOUNT_PRICE, ROYALTY_FEE, bytes32(root));
        __reward = new RewardERC20();

        _scale = 10 ** __reward.decimals();

        __staking = new Staking(address(__staker), address(__reward));

        __reward.grantMinterRole(address(__staking));

        vm.stopPrank();

        (, address[] memory users) = _createUserGroup("USER", 2, 100 ether);
        _users = users;

        (, address[] memory discountUsers) =
            _createUserGroup("DISCOUNT USER", 3, 100 ether);
        _discountUsers = discountUsers;

        uint256 marketplace = _createUserGroup("MARKETPLACE");
        _marketplace = _createUser(marketplace, 100 ether);
    }

    function _getProof(uint256 ticketId) internal returns (bytes32[] memory) {
        string memory data =
            vm.readFile("./test/merkle-tree/assets/StakerERC721.json");
        string memory key =
            string.concat("$.proofs.", Strings.toString(ticketId));

        return vm.parseJsonBytes32Array(data, key);
    }
}
