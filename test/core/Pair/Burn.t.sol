// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PairBase } from "./Base.t.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

import { Utils } from "contracts/libraries/Utils.sol";

contract BurnTest is PairBase {
    event Burn(
        address indexed sender,
        address indexed recipient,
        uint256 amountA,
        uint256 amountB
    );

    function setUp() public override {
        super.setUp();
    }

    function testBurn() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address recipient = _liquidityProviders[0];

        uint256 amountA = _addLiquidity(recipient, tokenA, address(PairX), 100);
        uint256 amountB = _addLiquidity(recipient, tokenB, address(PairX), 100);

        vm.startPrank(recipient);

        uint256 liquidityTokens = PairX.mint(recipient);

        PairX.transfer(address(PairX), liquidityTokens);

        vm.expectEmit(true, true, false, true, address(PairX));
        emit Burn(recipient, recipient, amountA, amountB);

        PairX.burn(recipient);

        vm.stopPrank();

        assertEq(IERC20(tokenA).balanceOf(recipient), amountA);
        assertEq(IERC20(tokenB).balanceOf(recipient), amountB);

        assertEq(PairX.balanceOf(recipient), 0);
        assertEq(PairX.balanceOf(address(PairX)), 0);

        _itUpdatesReserves(PairX, 0, 0);
    }

    function testBurnAfterASwap() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        uint256 amountA =
            _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        uint256 amountB =
            _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        uint256 liquidityTokens = PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountAIn = _tokenDistributions[tokenA][trader];
        uint256 amountBOut =
            Utils.calculateAmountOut(amountAIn, amountA, amountB);

        vm.startPrank(trader);

        IERC20(tokenA).transfer(address(PairX), amountAIn);

        PairX.swap(0, amountBOut, trader);

        vm.stopPrank();

        vm.startPrank(liquidityProvider);

        PairX.transfer(address(PairX), liquidityTokens);

        vm.expectEmit(true, true, false, true, address(PairX));
        emit Burn(
            liquidityProvider,
            liquidityProvider,
            amountA + amountAIn,
            amountB - amountBOut
        );

        PairX.burn(liquidityProvider);

        vm.stopPrank();

        assertEq(
            IERC20(tokenA).balanceOf(liquidityProvider), amountA + amountAIn
        );
        assertEq(
            IERC20(tokenB).balanceOf(liquidityProvider), amountB - amountBOut
        );

        assertEq(PairX.balanceOf(liquidityProvider), 0);
        assertEq(PairX.balanceOf(address(PairX)), 0);

        _itUpdatesReserves(PairX, 0, 0);
    }

    function testRevertWhenZeroLiquiditySentIn() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address recipient = _liquidityProviders[0];

        _addLiquidity(recipient, tokenA, address(PairX), 100);
        _addLiquidity(recipient, tokenB, address(PairX), 100);

        vm.startPrank(recipient);

        PairX.mint(recipient);

        vm.expectRevert("Pair: insufficient liquidity burned");
        PairX.burn(recipient);

        vm.stopPrank();
    }
}
