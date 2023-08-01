// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Pair } from "contracts/core/Pair.sol";

contract PairBase is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function _itUpdatesReserves(
        Pair pair,
        uint256 expectedAmountA,
        uint256 expectedAmountB
    ) internal {
        (uint256 reserveA, uint256 reserveB,) = pair.getReserves();

        assertEq(reserveA, expectedAmountA);
        assertEq(reserveB, expectedAmountB);
    }

    function _addLiquidity(
        address liquidityProvider,
        address token,
        address pair,
        uint256 ratio
    ) internal returns (uint256 amount) {
        uint256 totalDistribution =
            _tokenDistributions[token][liquidityProvider];
        amount = totalDistribution * ratio / 100;

        vm.prank(liquidityProvider);
        IERC20(token).transfer(pair, amount);
    }
}
