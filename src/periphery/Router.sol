// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { IPair } from "contracts/core/interfaces/IPair.sol";
import { Utils } from "contracts/libraries/Utils.sol";

/**
 * @title Router
 * @author Steven Rico
 * @notice The 'Router' contract is used to:
 *
 * - Add liquidity
 * - Remove liquidity
 *
 * @dev The 'Router' contract interacts with:
 *
 * - Pair (src/core/Pair.sol)
 * - ERC20 tokens using OpenZeppelin (contracts/token/ERC20/ERC20.sol)
 *
 * It uses 'SafeERC20.safeTransferFrom(token, from, to, value);' for transfers.
 */
contract Router {
    address private _pair;

    /**
     * @dev Set the value for {pair}.
     */
    constructor(address pair) {
        _pair = pair;
    }

    /**
     * @dev Returns the address of the Pair.
     *
     * @return pair             The address of the Pair.
     */
    function getPair() external view returns (address) {
        return _pair;
    }

    /**
     * @dev Transfers token A and token B to Pair and mints liquidity tokens to
     * the liquidity provider.
     *
     * @custom:resource Uniswap Doc:
     * https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#addliquidity
     *
     * @param tokenA            A pool token.
     * @param tokenB            A pool token.
     * @param amountA           The amount of token A to add as liquidity.
     * @param amountB           The amount of token B to add as liquidity.
     * @param recipient         Recipient of the liquidty tokens.
     *
     * @return sentA            The amount of token A sent to the pool.
     * @return sentB            The amount of token B sent to the pool.
     * @return liquidityTokens  The amount of liquidity tokens minted to the recipient.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address recipient
    )
        external
        returns (uint256 sentA, uint256 sentB, uint256 liquidityTokens)
    {
        address pair = _pair;

        SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, pair, amountA);
        SafeERC20.safeTransferFrom(IERC20(tokenB), msg.sender, pair, amountB);

        sentA = amountA;
        sentB = amountB;

        liquidityTokens = IPair(pair).mint(recipient);
    }

    /**
     * @dev Swap tokens by sending an exact amount in and receive an amount out
     * greater than the given minimum.
     *
     * Formula:
     *
     * amountOut        amount of tokens to be sent out
     * amountIn         amount of tokens to be sent in
     * reserveOut       amount of tokens owned by the contract; of the token to be sent out
     * reserveIn        amount of tokens owned by the contract; of the token to be sent in
     *
     * amountOut = amountIn * (reserveOut / (amountIn + reserveIn))
     *
     * @custom:resource Uniswap Doc:
     * https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-01#swapexacttokensfortokens
     *
     * @param amountIn          The amount of tokens sent in for the swap.
     * @param amountOutMin      The min amount of tokens to be sent out from the swap.
     * @param tokens            Array of address of the tokens in the swap; tokens[0] = input token; tokens[1] = output token
     * @param recipient         The recipient of the swapped tokens.
     *
     * @return sentIn           The amount of tokens sent in for the swap.
     * @return sentOut          The amount of tokens sent out from the swap.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata tokens,
        address recipient
    ) external returns (uint256 sentIn, uint256 sentOut) {
        require(amountIn > 0, "Router: Insufficient input amount");

        (address inputToken, address outputToken) = (tokens[0], tokens[1]);

        (uint256 reserveIn, uint256 reserveOut) =
            Utils.getReserves(_pair, inputToken, outputToken);

        require(
            reserveIn > 0 && reserveOut > 0, "Router: Insufficient liquidity"
        );

        uint256 amountOut = Utils.calculateAmountOut(amountIn, reserveIn, reserveOut);

        require(amountOut > amountOutMin, "Router: Insufficient output amount");

        SafeERC20.safeTransferFrom(
            IERC20(inputToken), msg.sender, _pair, amountIn
        );

        (address tokenA,) = Utils.sortTokens(inputToken, outputToken);

        (uint256 amountAOut, uint256 amountBOut) = inputToken == tokenA
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));

        IPair(_pair).swap(amountAOut, amountBOut, recipient);

        sentIn = amountIn;
        sentOut = amountOut;
    }

    /**
     * @dev Swap tokens by sending an exact amount in and receive an amount out
     * greater than the given minimum.
     *
     * Formula:
     *
     * amountOut        amount of tokens to be sent out
     * amountIn         amount of tokens to be sent in
     * reserveOut       amount of tokens owned by the contract; of the token to be sent out
     * reserveIn        amount of tokens owned by the contract; of the token to be sent in
     *
     * amountIn = amountOut * (reserveIn / (amountOut - reserveOut))
     *
     * @custom:resource Uniswap Doc:
     * https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-01#swaptokensforexacttokens
     *
     * @param amountOut         The amount of tokens sent out from the swap.
     * @param amountInMax       The max amount of tokens to be sent in for the swap.
     * @param tokens            Array of address of the tokens in the swap; tokens[0] = input token; tokens[1] = output token
     * @param recipient         The recipient of the swapped tokens.
     *
     * @return sentIn           The amount of tokens sent in for the swap.
     * @return sentOut          The amount of tokens sent out from the swap.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata tokens,
        address recipient
    ) external returns (uint256 sentIn, uint256 sentOut) {
        require(amountOut > 0, "Router: Insufficient output amount");

        (address inputToken, address outputToken) = (tokens[0], tokens[1]);

        (uint256 reserveIn, uint256 reserveOut) =
            Utils.getReserves(_pair, inputToken, outputToken);

        require(
            reserveIn > 0 && reserveOut > 0, "Router: Insufficient liquidity"
        );

        // [Q] Why is it necessary to add 1?
        uint256 amountIn = Utils.calculateAmountIn(amountOut, reserveIn, reserveOut);

        require(amountIn < amountInMax, "Router: Excessive input amount");

        SafeERC20.safeTransferFrom(
            IERC20(inputToken), msg.sender, _pair, amountIn
        );

        (address tokenA,) = Utils.sortTokens(inputToken, outputToken);

        (uint256 amountAOut, uint256 amountBOut) = inputToken == tokenA
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));

        IPair(_pair).swap(amountAOut, amountBOut, recipient);

        sentIn = amountIn;
        sentOut = amountOut;
    }
}
