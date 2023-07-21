// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/access/AccessControl.sol";

contract RewardERC20 is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Reward", "RWRD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function grantMinterRole(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function mintTo(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(to, amount);
    }
}
