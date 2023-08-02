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
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        (address tokenA,) = sortTokens(token0, token1);
        (uint256 reserveA, uint256 reserveB,) = IPair(pair).getReserves();
        (reserve0, reserve1) =
            token0 == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);
    }

    /**
     * @dev Calculates the amount to be sent out from a swap, including a fee
     *
     * With a 0.03% fee:
     * Without Fee:     49504950495049504950
     * With Fee:        49357901719853064942
     *
     * This calculates a reduction of 0.03% that the user receives from the swap,
     * meaning the token SENT IN is accepted as the fee in the swap.
     */
    function calculateAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Utils: Insufficient input amount");
        require(
            reserveIn > 0 && reserveOut > 0, "Utils: Insufficient liquidity"
        );

        uint256 amountInWithFee = amountIn * 997;

        uint256 numerator = reserveOut * amountInWithFee;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        amountOut = numerator / denominator;
    }

    /**
     * @dev Calculates the amount to be sent in for a swap, including a fee
     *
     * With a 0.03% fee:
     * Without Fee:     50505050505050505051
     * With Fee:        50657021569759784404
     *
     * This calculates an addition of 0.03% that the user sends into the swap,
     * meaning the token SENT IN is accepted as the fee in the swap.
     */
    function calculateAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Utils: Insufficient output amount");
        require(
            reserveIn > 0 && reserveOut > 0, "Utils: Insufficient liquidity"
        );

        uint256 numerator = (reserveIn * amountOut) * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        amountIn = (numerator / denominator) + 1;
    }
}
