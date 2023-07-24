// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

contract Escrow {
    uint256 public constant WITHDRAWAL_DELAY = 3 days;

    struct Deposit {
        address depositor;
        uint256 amount;
        uint256 createdAt;
    }

    mapping(address => mapping(address => Deposit)) private _deposits;

    function deposit(address token, address seller, uint256 amount) external {
        bool success =
            IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (success) {
            _deposits[token][seller] =
                Deposit(msg.sender, amount, block.timestamp);
        }
    }

    function getDeposit(address token, address seller)
        external
        view
        returns (Deposit memory)
    {
        return _deposits[token][seller];
    }
}
