// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

import { IPair } from "contracts/core/interfaces/IPair.sol";
import { UQ112x112 } from "contracts/libraries/UQ112x112.sol";
import { LiquidityTokenERC20 } from "contracts/core/LiquidityTokenERC20.sol";

/**
 * @title Pair
 * @author Steven Rico
 * @notice The 'Pair' contract is used to:
 *
 * - mint liquidity tokens
 * - burn liquidity tokens
 * - perform swaps between token A and token B
 *
 * @dev The 'Pair' contract inherits from 'IPair' and 'LiquidityTokenERC20'.
 *
 * It uses 'SafeERC20.safeTransfer(token, to, value);' for transfers.
 */
contract Pair is IPair, LiquidityTokenERC20 {
    using UQ112x112 for uint224;

    address private _tokenA;
    address private _tokenB;

    // Resource: https://uniswap.org/whitepaper.pdf (Page 4 - 2.2.1 Precision)
    uint112 private _reserveA; // uses single storage slot, accessible via getReserves
    uint112 private _reserveB; // uses single storage slot, accessible via getReserves
    uint32 private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    // Works with: src/libraries/Oracle.sol
    uint256 private _priceACumulativeLast;
    uint256 private _priceBCumulativeLast;

    /**
     * @dev Set the value for {tokenA} and {tokenB}.
     */
    constructor(address tokenA, address tokenB) {
        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    /**
     * @dev Returns the address of token A and token B.
     *
     * @return tokenA           The address of token A.
     * @return tokenB           The address of token B.
     */
    function getTokens()
        external
        view
        returns (address tokenA, address tokenB)
    {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /**
     * @dev Returns the amount of reserve A and reserve B.
     *
     * @return reserveA         The amount of reserve A.
     * @return reserveB         The amount of reserve B.
     */
    function getReserves()
        public
        view
        returns (uint112 reserveA, uint112 reserveB, uint32 blockTimestampLast)
    {
        reserveA = _reserveA;
        reserveB = _reserveB;
        blockTimestampLast = _blockTimestampLast;
    }

    /**
     * @dev Returns the cumulative price of token A and token B.
     *
     * @return priceACumulative         The cumulative price of token A.
     * @return priceBCumulative         The cumulative price of token B.
     */
    function getPriceCumulatives()
        public
        view
        returns (uint256 priceACumulative, uint256 priceBCumulative)
    {
        priceACumulative = _priceACumulativeLast;
        priceBCumulative = _priceBCumulativeLast;
    }

    /**
     * @dev Updates the values of {reserveA} and {reserveB}.
     *
     * @param balanceA          The balance of token A owned by the contract.
     * @param balanceB          The balance of token B owned by the contract.
     */
    function _update(
        uint256 balanceA,
        uint256 balanceB,
        uint112 reserveA,
        uint112 reserveB
    ) private {
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;

        unchecked {
            timeElapsed = blockTimestamp - _blockTimestampLast; // overflow is desired
        }

        if (timeElapsed > 0 && reserveA != 0 && reserveB != 0) {
            /**
             * [Q1] How much of a token with 18 decimals can your contract store?
             *
             * [A1] Max number of uint112 divided by 1e18:
             *
             * max112 = type(uint112).max => 5192296858534827628530496329220095
             *
             * result = max112 / 1e18 => 5192296858534827
             *
             * [Q2], what's the reason for:
             *   (X) = uint256(UQ112x112.encode(reserveA).uqdiv(reserveB)) * timeElapsed
             * Instead of:
             *   (Y) = uint256(UQ112x112.encode(reserveA * timeElapsed).uqdiv(reserveB))
             *
             * [A2] If (Y) max number in reserveA would be limited to:
             *
             * max112 = type(uint112).max => 5192296858534827628530496329220095
             * max32 = type(uint32).max => 4294967295
             *
             * maxReserveA = max112 / max32 => 1208925819896104151482368
             *
             * [Q2.1] Find the smallest uint type:
             *
             * 1208925819896104151482368 = 2^n - 1
             *
             * n = log2(1208925819896104151482368 + 1)
             * n = 80.00000000033590
             *
             * [A2.1] uint88
             *
             * Resource: https://docs.soliditylang.org/en/v0.8.20/types.html#integers
             */
            _priceACumulativeLast += uint256(
                UQ112x112.encode(reserveA).uqdiv(reserveB)
            ) * timeElapsed;
            _priceBCumulativeLast += uint256(
                UQ112x112.encode(reserveB).uqdiv(reserveA)
            ) * timeElapsed;
        }

        _reserveA = uint112(balanceA);
        _reserveB = uint112(balanceB);
        _blockTimestampLast = blockTimestamp;
    }

    /**
     * @dev Mints liquidity tokens to the liquidity provider.
     *
     * Formula:
     *
     * l            amount of liquidity tokens to mint
     * tokenA       amount of token A sent by liquidity provider
     * tokenB       amount of token B sent by liquidity provider
     * reserveA     amount of token A owned by the contract
     * reserveB     amount of token B owned by the contract
     * s            total supply of liquidty tokens
     *
     * When 's == 0':
     *
     * l = (tokenA * tokenB) ^ 0.5
     *
     * When 's > 0':
     *
     * l = Math.min((tokenA * s / reserveA), (tokenB * s / reserveB))
     *
     * @param recipient         The recipient of the liquidty tokens.
     *
     * @return liquidityTokens  The amount of liquidity tokens minted to the recipient.
     */
    function mint(address recipient)
        external
        returns (uint256 liquidityTokens)
    {
        (uint112 reserveA, uint112 reserveB,) = getReserves();

        uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(_tokenB).balanceOf(address(this));
        uint256 amountA = balanceA - reserveA;
        uint256 amountB = balanceB - reserveB;

        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            liquidityTokens = Math.sqrt(amountA * amountB);
        } else {
            liquidityTokens = Math.min(
                amountA * totalSupply / reserveA,
                amountB * totalSupply / reserveB
            );
        }

        _mint(recipient, liquidityTokens);

        _update(balanceA, balanceB, reserveA, reserveB);

        emit Mint(msg.sender, amountA, amountB);
    }

    /**
     * @dev Burns liquidity tokens from the liquidity provider.
     *
     * Formula:
     *
     * l            amount of liquidity tokens to burn
     * a            amount of tokens to be sent to the liquidity provider
     * b            amount of tokens owned by the contract
     * s            total supply of liquidty tokens
     *
     * a = b * (l / s)
     *
     * @param recipient         The recipient of the liquidty tokens.
     *
     * @return amountA          The amount of token A sent to the recipient.
     * @return amountB          The amount of token B sent to the recipient.
     */
    function burn(address recipient)
        external
        returns (uint256 amountA, uint256 amountB)
    {
        uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(_tokenB).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        uint256 totalSupply = totalSupply();

        amountA = balanceA * liquidity / totalSupply;
        amountB = balanceB * liquidity / totalSupply;

        require(
            amountA > 0 && amountB > 0, "Pair: insufficient liquidity burned"
        );

        _burn(address(this), liquidity);

        SafeERC20.safeTransfer(IERC20(_tokenA), recipient, amountA);
        SafeERC20.safeTransfer(IERC20(_tokenB), recipient, amountB);

        balanceA = IERC20(_tokenA).balanceOf(address(this));
        balanceB = IERC20(_tokenB).balanceOf(address(this));

        (uint112 reserveA, uint112 reserveB,) = getReserves();

        _update(balanceA, balanceB, reserveA, reserveB);

        emit Burn(msg.sender, recipient, amountA, amountB);
    }

    /**
     * @dev Swap token A and token B.
     *
     * Formula:
     *
     * balanceA     amount of tokens A owned by the contract, after swap
     * balanceB     amount of tokens B owned by the contract, after swap
     * currentK     constant K from 'xy = K', after the swap
     * reserveA     amount of tokens A owned by the contract, before swap
     * reserveB     amount of tokens B owned by the contract, before swap
     * previousK    constant K from 'xy = K', before the swap
     *
     * currentK = balanceA * balanceB
     * previousK = reserveA * reserveB
     *
     * Check that K remains constant:
     *
     * currentK == previousK
     *
     * @param amountAOut        The amount of token A to send to the recipient; if amountAOut != 0 than amountBOut == 0.
     * @param amountBOut        The amount of token B to send to the recipient; if amountBOut != 0 than amountAOut == 0.
     * @param recipient         The recipient of the tokens.
     */
    function swap(uint256 amountAOut, uint256 amountBOut, address recipient)
        external
    {
        require(
            amountAOut > 0 || amountBOut > 0, "Pair: Insufficient output amount"
        );

        (uint112 reserveA, uint112 reserveB,) = getReserves();

        require(
            amountAOut < reserveA && amountBOut < reserveB,
            "Pair: Insufficient liquidity"
        );

        uint256 balanceA;
        uint256 balanceB;

        {
            address tokenA = _tokenA;
            address tokenB = _tokenB;

            require(
                recipient != tokenA && recipient != tokenB,
                "Pair: Invalid recipient"
            );

            /**
             * For swapExactTokensForTokens:        (/src/periphery/Router.sol:106)
             * - amountIn has NOT been reduced
             * - amountOut has been reduced by 0.03%
             *
             * For swapTokensForExactTokens:        (/src/periphery/Router.sol:167)
             * - amountIn has been increased by 0.03%
             * - amountOut has NOT been reduced
             *
             * So balanceA and balanceB have the fee already included.
             */
            if (amountAOut > 0) {
                SafeERC20.safeTransfer(IERC20(tokenA), recipient, amountAOut);
            }
            if (amountBOut > 0) {
                SafeERC20.safeTransfer(IERC20(tokenB), recipient, amountBOut);
            }

            balanceA = IERC20(tokenA).balanceOf(address(this));
            balanceB = IERC20(tokenB).balanceOf(address(this));
        }

        uint256 amountAIn = balanceA > reserveA - amountAOut
            ? balanceA - (reserveA - amountAOut)
            : 0;
        uint256 amountBIn = balanceB > reserveB - amountBOut
            ? balanceB - (reserveB - amountBOut)
            : 0;

        require(
            amountAIn > 0 || amountBIn > 0, "Pair: Insufficient input amount"
        );

        {
            /**
             * There's an extra 0.03% fee in the balances, remove the fee in order to compare
             * with previous K.
             *
             * [Q] Why 'balance - (amountIn * 3)'?
             *
             * [A] For 'calculateAmountOut' (/src/libraries/Utils.sol:34) and
             * 'calculateAmountIn' (/src/libraries/Utils.sol:62) the fee is applied to the token
             * being SENT IN to the swap, so we use 'amountIn' to calculate the adjustment.
             *
             * reserveA = 1000e18
             * reserveB = 1000e18
             *
             * amountAIn = 10e18
             * amountBOut = 9871580343970612988
             *
             * balanceA = 1010e18
             * balanceB = 990128419656029387012
             *
             * Calculations for 'balance - (amountIn * 3)':
             *
             * adjustedBalanceA = (1010e18 * 1000) - (10e18 * 3) => 1009970000000000000000000
             * adjustedBalanceB = 990128419656029387012 * 1000 => 990128419656029387012000
             *
             * previousK = (1000e18 * 1000e18) * 1000^2 => 1e48
             * currentK = 9_800 * 9_901.284196560295 => 1.00000000000000000000050964e48
             */
            uint256 adjustedBalanceA = (balanceA * 1000) - (amountAIn * 3);
            uint256 adjustedBalanceB = (balanceB * 1000) - (amountBIn * 3);

            uint256 previousK = (uint256(reserveA) * reserveB) * 1000 ** 2;
            uint256 currentK = adjustedBalanceA * adjustedBalanceB;

            // [Q] Should it be `currentK == previousK`?
            require(previousK <= currentK, "Pair: K");
        }

        _update(balanceA, balanceB, reserveA, reserveB);

        emit Swap(
            msg.sender, recipient, amountAIn, amountAOut, amountBIn, amountBOut
        );
    }
}
