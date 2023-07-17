// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount * (10 ** uint256(decimals())));
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount * (10 ** uint256(decimals())));
    }
}
