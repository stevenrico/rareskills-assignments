// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@math/UD60x18.sol";

/**
 * @title BondingCurveERC20
 * @author Steven Rico
 *
 * @notice This contract allows users to mint and burn an ERC20 token that uses
 * a bonding curve to determine price. When users mint, the supply and price
 * increases. When users burn the supply and price decreases.
 *
 * @dev The bonding curve uses a linear curve to determine price.
 *
 * Formula:
 *
 * p = token price
 * m = slope
 * s = token supply
 * n = exponent
 *
 * p = m(s)^n
 */

contract BondingCurveERC20 is ERC20 {
    uint256 public constant SCALE = 10 ** 18;
    uint256 public constant RATIO_SCALE = 10 ** 16;

    IERC20 public ReserveToken;

    uint256 private _reserveRatio;
    uint256 private _slope;

    constructor(
        address reserveToken,
        uint256 reserveRatio,
        uint256 slope
    ) ERC20("Bonding Curve", "BC20") {
        ReserveToken = IERC20(reserveToken);

        _reserveRatio = reserveRatio;
        _slope = slope;
    }

    /**
     * @dev Receives reserve tokens and mints ERC20 tokens.
     */

    receive() external payable {
        uint256 tokenSupply = totalSupply();
        uint256 reserveBalance = ReserveToken.balanceOf(address(this));

        bool success =
            ReserveToken.transferFrom(msg.sender, address(this), msg.value);

        if (success) {
            uint256 purchaseAmount = _calculatePurchaseAmount(
                tokenSupply, reserveBalance, _reserveRatio, _slope, msg.value
            );

            _mint(msg.sender, purchaseAmount);
        }
    }

    /**
     * @dev Calculates the amount of tokens to mint for the amount of reserve
     * tokens sent.
     *
     * Formulas used to calculate purchase amount in different scenarios:
     *
     * a = purchase amount
     * s = token supply
     * b = reserve balance
     * r = reserve ratio
     * m = slope ratio
     * d = deposit
     *
     * Formula, when tokenSupply == 0 || reserveBalance == 0:
     *
     * a = (d / (r * m))^r
     *
     * Formula, when tokenSupply > 0 || reserveBalance > 0:
     *
     * a = s * ((1 + (d / b))^r - 1)
     *
     * Libraries:
     * - PRB Math: https://github.com/PaulRBerg/prb-math
     *
     * @param tokenSupply       total supply of tokens
     * @param reserveBalance    total balance of reserve tokens
     * @param reserveRatio      reserve ratio, range 0 - 100
     * @param slopeRatio        slope ratio, range 0 - 100
     * @param depositAmount     deposit of reserve tokens
     *
     * @return purchaseAmount   amount of tokens to transfer
     */

    function _calculatePurchaseAmount(
        uint256 tokenSupply,
        uint256 reserveBalance,
        uint256 reserveRatio,
        uint256 slopeRatio,
        uint256 depositAmount
    ) private pure returns (uint256) {
        if (depositAmount == 0) {
            return 0;
        }

        UD60x18 udDepositAmount = ud(depositAmount);
        UD60x18 udReserveRatio = ud(reserveRatio * RATIO_SCALE);

        if (tokenSupply == 0 || reserveBalance == 0) {
            UD60x18 udSlopeRatio = ud(slopeRatio * RATIO_SCALE);

            UD60x18 base = udDepositAmount.div(udReserveRatio.mul(udSlopeRatio));

            UD60x18 result = base.pow(udReserveRatio);

            return result.intoUint256();
        } else {
            UD60x18 udReserveBalance = ud(reserveBalance);
            UD60x18 udTokenSupply = ud(tokenSupply);
            UD60x18 one = ud(1 * SCALE);
    
            UD60x18 base = one.add(udDepositAmount.div(udReserveBalance));
    
            UD60x18 result = base.pow(udReserveRatio);
            result = result.sub(one);
            result = udTokenSupply.mul(result);
    
            return result.intoUint256();
        }
    }
}
