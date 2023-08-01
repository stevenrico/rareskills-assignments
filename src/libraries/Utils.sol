// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IPair } from "contracts/core/interfaces/IPair.sol";

library Utils {
    function sortTokens(address token0, address token1)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        (tokenA, tokenB) = token0 < token1 ? (token0, token1) : (token1, token0);
    }

    function getReserves(address pair, address token0, address token1)
        internal
        returns (uint256 reserve0, uint256 reserve1)
    {
        (address tokenA,) = sortTokens(token0, token1);
        (uint256 reserveA, uint256 reserveB) = IPair(pair).getReserves();
        (reserve0, reserve1) =
            token0 == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);
    }

    function calculateAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Utils: Insufficient input amount");
        require(
            reserveIn > 0 && reserveOut > 0, "Utils: Insufficient liquidity"
        );

        uint256 numerator = reserveOut * amountIn;
        uint256 denominator = reserveIn + amountIn;

        amountOut = numerator / denominator;
    }

    function calculateAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Utils: Insufficient output amount");
        require(
            reserveIn > 0 && reserveOut > 0, "Utils: Insufficient liquidity"
        );

        uint256 numerator = reserveIn * amountOut;
        uint256 denominator = reserveOut - amountOut;

        amountIn = (numerator / denominator) + 1;
    }
}
