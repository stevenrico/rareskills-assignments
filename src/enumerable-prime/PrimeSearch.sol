// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { EnumPrimeERC721 } from "contracts/enumerable-prime/EnumPrimeERC721.sol";

import { Math } from "@openzeppelin/utils/math/Math.sol";

contract PrimeSearch {
    EnumPrimeERC721 private _enumPrime;

    constructor(address enumPrime) {
        _enumPrime = EnumPrimeERC721(enumPrime);
    }

    function search(address user) external view returns (uint256 count) {
        uint256 balance = _enumPrime.balanceOf(user);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = _enumPrime.tokenOfOwnerByIndex(user, i);

            if (_isPrime(tokenId)) {
                count++;
            }
        }
    }

    function _isPrime(uint256 num) private pure returns (bool) {
        if (num == 1) {
            return false;
        }

        if (num % 2 == 0) {
            return num == 2;
        }

        for (uint256 i = 3; i < num; i += 2) {
            if (num % i == 0) return false;
        }

        return true;
    }
}
