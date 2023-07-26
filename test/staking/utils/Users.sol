// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Vm } from "@forge-std/Vm.sol";

import { Strings } from "@openzeppelin/utils/Strings.sol";

contract Users {
    Vm private constant _vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 private _userGroupIndex = 1000;

    struct UserGroup {
        string name;
        uint256 index;
    }

    mapping(uint256 id => UserGroup userGroup) private _userGroups;

    function _createUserGroup(string memory name) internal returns (uint256) {
        require(
            bytes(name).length != 0, "User Setup: user groups require a name"
        );

        uint256 id = _userGroupIndex;

        _userGroups[id] = UserGroup(name, id);

        _userGroupIndex += 1000;

        return id;
    }

    function _createUserGroup(
        string memory name,
        uint256 numOfUsers,
        uint256 etherAmount
    ) internal returns (uint256, address[] memory) {
        require(
            bytes(name).length != 0, "User Setup: user groups require a name"
        );

        uint256 id = _userGroupIndex;

        _userGroups[id] = UserGroup(name, id);

        address[] memory users = new address[](numOfUsers);

        for (uint256 i = 0; i < numOfUsers; i++) {
            address user = _createUser(id, etherAmount);
            users[i] = user;
        }

        _userGroupIndex += 1000;

        return (id, users);
    }

    function _getUserGroups() internal view returns (UserGroup[] memory) {
        require(
            _userGroupIndex > 1000,
            "User Setup: no user groups have been created"
        );

        uint256 length = (_userGroupIndex - 1000) / 1000;

        UserGroup[] memory userGroups = new UserGroup[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 id = (i + 1) * 1000;

            userGroups[i] = _userGroups[id];
        }

        return userGroups;
    }

    function _getUserGroupById(uint256 id)
        internal
        view
        returns (UserGroup memory)
    {
        return _userGroups[id];
    }

    function _createUser(uint256 groupId, uint256 etherAmount)
        internal
        returns (address)
    {
        UserGroup storage group = _userGroups[groupId];

        require(group.index > 0, "User Setup: user group does not exist");

        uint256 privateKey = group.index;
        group.index++;

        address user = _vm.addr(privateKey);
        _vm.label(
            user,
            string.concat(
                "[", group.name, "|", Strings.toString(privateKey), "]"
            )
        );
        _vm.deal(user, etherAmount);

        return user;
    }

    function _createUser(
        uint256 groupId,
        uint256 etherAmount,
        string calldata customLabel
    ) internal returns (address) {
        UserGroup storage group = _userGroups[groupId];

        require(group.index > 0, "User Setup: user group does not exist");

        uint256 privateKey = group.index;
        group.index++;

        address user = _vm.addr(privateKey);
        _vm.label(user, string.concat("[", group.name, "|", customLabel, "]"));
        _vm.deal(user, etherAmount);

        return user;
    }
}
