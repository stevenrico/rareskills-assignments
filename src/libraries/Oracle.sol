// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IPair } from "contracts/core/Pair.sol";
import { UQ112x112 } from "./UQ112x112.sol";

library OracleLibrary {
    using UQ112x112 for uint224;
    
    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (uint256 priceACumulative, uint256 priceBCumulative)
    {
        uint32 blockTimestamp = currentBlockTimestamp();
        (priceACumulative, priceBCumulative) = IPair(pair).getPriceCumulatives();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserveA, uint112 reserveB, uint32 blockTimestampLast) =
            IPair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            uint32 timeElapsed;

            unchecked {
                timeElapsed = blockTimestamp - blockTimestampLast;
            }

            priceACumulative += uint256(
                UQ112x112.encode(reserveA).uqdiv(reserveB)
            ) * timeElapsed;
            priceBCumulative += uint256(
                UQ112x112.encode(reserveB).uqdiv(reserveA)
            ) * timeElapsed;
        }
    }
}
