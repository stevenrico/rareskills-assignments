// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    /* solhint-disable */
    uint224 constant Q112 = 2 ** 112;
    /* solhint-enable */

    /**
     * @dev Encode a uint112 as a UQ112x112
     *
     * y = 25
     * -- in binary: 11001
     * Q112 = 2 ** 112 => 5192296858534827628530496329220096 (length: 34)
     * -- in binary: 100...0 (113 digits)
     *
     * z = y * Q112 => 129807421463370690713262408230502400 (length: 36)
     * -- in binary: 1100_100...0 (113 digits)
     */
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    /**
     * @dev Divide a UQ112x112 by a uint112, returning a UQ112x112
     *
     * x = 129807421463370690713262408230502400
     * -- in binary: 1100_100...0 (113 digits)
     * y = 50
     * -- in binary: 110010
     *
     * z = x / y => 2596148429267413814265248164610048
     * -- in binary: 100...0 (112 digits)
     *
     * decimal = z / 2 ** 112 => Error
     */
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
