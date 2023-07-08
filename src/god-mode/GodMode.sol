// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/access/AccessControl.sol";

contract GodMode is ERC20, AccessControl {
    bytes32 public constant GOD_ROLE = keccak256("GOD_ROLE");

    constructor(address god) ERC20("GodMode", "GOD") {
        _grantRole(GOD_ROLE, god);
    }
}
