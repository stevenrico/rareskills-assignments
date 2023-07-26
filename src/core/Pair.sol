// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LiquidityTokenERC20 } from "contracts/core/LiquidityTokenERC20.sol";

/**
 * @notice Pair contract is used to manage trading pairs
 */

contract Pair is LiquidityTokenERC20 {
    address private _tokenA;
    address private _tokenB;

    constructor(address tokenA, address tokenB) {
        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    function getTokens() external view returns (address, address) {
        return (_tokenA, _tokenB);
    }
}
