// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PairBase } from "./Base.t.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

import { Pair } from "contracts/core/Pair.sol";
import { Utils } from "contracts/libraries/Utils.sol";

contract SwapTest is PairBase {
    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 amountAIn,
        uint256 amountAOut,
        uint256 amountBIn,
        uint256 amountBOut
    );

    function setUp() public override {
        super.setUp();
    }

    function testSwapOfTokenAForTokenB() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 traderBalanceA = _tokenDistributions[tokenA][trader];
        uint256 traderBalanceB = _tokenDistributions[tokenB][trader];

        uint256 amountAIn = traderBalanceA;
        // [Q] Is there a risk of error?
        uint256 amountBOut =
            Utils.calculateAmountOut(amountAIn, reserveA, reserveB);

        vm.startPrank(trader);

        // [Q] Should I test for `event Transfer(...)`?
        IERC20(tokenA).transfer(address(PairX), amountAIn);

        vm.expectEmit(true, true, false, true, address(PairX));
        emit Swap(trader, trader, amountAIn, 0, 0, amountBOut);

        PairX.swap(0, amountBOut, trader);

        vm.stopPrank();

        uint256 expectedAmountA = reserveA + amountAIn;
        uint256 expectedAmountB = reserveB - amountBOut;

        assertEq(IERC20(tokenA).balanceOf(address(PairX)), expectedAmountA);
        assertEq(IERC20(tokenB).balanceOf(address(PairX)), expectedAmountB);

        _itUpdatesReserves(PairX, expectedAmountA, expectedAmountB);

        assertEq(IERC20(tokenA).balanceOf(trader), 0);
        assertEq(IERC20(tokenB).balanceOf(trader), traderBalanceB + amountBOut);
    }

    function testSwapOfTokenBForTokenA() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 traderBalanceA = _tokenDistributions[address(tokenA)][trader];
        uint256 traderBalanceB = _tokenDistributions[address(tokenB)][trader];

        uint256 amountBIn = traderBalanceB;
        // [Q] Is there a risk of error?
        uint256 amountAOut =
            Utils.calculateAmountOut(amountBIn, reserveB, reserveA);

        vm.startPrank(trader);

        // [Q] Should I test for `event Transfer(...)`?
        IERC20(tokenB).transfer(address(PairX), amountBIn);

        vm.expectEmit(true, true, false, true, address(PairX));
        emit Swap(trader, trader, 0, amountAOut, amountBIn, 0);

        PairX.swap(amountAOut, 0, trader);

        vm.stopPrank();

        uint256 expectedAmountA = reserveA - amountAOut;
        uint256 expectedAmountB = reserveB + amountBIn;

        assertEq(IERC20(tokenA).balanceOf(address(PairX)), expectedAmountA);
        assertEq(IERC20(tokenB).balanceOf(address(PairX)), expectedAmountB);

        _itUpdatesReserves(PairX, expectedAmountA, expectedAmountB);

        assertEq(IERC20(tokenA).balanceOf(trader), traderBalanceA + amountAOut);
        assertEq(IERC20(tokenB).balanceOf(trader), 0);
    }

    function testRevertWhenBothAmountOutAreZero() external {
        address trader = _traders[0];

        vm.expectRevert("Pair: Insufficient output amount");
        vm.prank(trader);
        PairX.swap(0, 0, trader);
    }

    function testRevertWhenPairHasZeroLiquidity() external {
        address trader = _traders[0];

        uint256 amountOut = 1000 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(amountOut, 0, trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(0, amountOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenPairHasLowLiquidity() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, tokenA, address(PairX), 5);
        _addLiquidity(liquidityProvider, tokenB, address(PairX), 5);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountOut = 1000 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(amountOut, 0, trader);

        vm.expectRevert("Pair: Insufficient liquidity");
        PairX.swap(0, amountOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenRecipientIsInvalid() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountOut = 50 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(amountOut, 0, address(tokenA));

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(0, amountOut, address(tokenA));

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(amountOut, 0, address(tokenB));

        vm.expectRevert("Pair: Invalid recipient");
        PairX.swap(0, amountOut, address(tokenB));

        vm.stopPrank();
    }

    function testRevertWhenAmountInIsZero() external {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountOut = 50 * 10 ** 18;

        vm.startPrank(trader);

        vm.expectRevert("Pair: Insufficient input amount");
        PairX.swap(amountOut, 0, trader);

        vm.expectRevert("Pair: Insufficient input amount");
        PairX.swap(0, amountOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenAmountInIsNotEnoughForSwapOfTokenAForTokenB()
        external
    {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountBOut = _tokenDistributions[tokenB][trader];
        uint256 amountAIn =
            Utils.calculateAmountIn(amountBOut, reserveA, reserveB);

        vm.startPrank(trader);

        IERC20(tokenA).transfer(address(PairX), amountAIn / 2);

        vm.expectRevert("Pair: K");
        PairX.swap(0, amountBOut, trader);

        vm.stopPrank();
    }

    function testRevertWhenAmountInIsNotEnoughForSwapOfTokenBForTokenA()
        external
    {
        (address tokenA, address tokenB) = PairX.getTokens();

        address liquidityProvider = _liquidityProviders[0];

        uint256 reserveA =
            _addLiquidity(liquidityProvider, tokenA, address(PairX), 100);
        uint256 reserveB =
            _addLiquidity(liquidityProvider, tokenB, address(PairX), 100);

        vm.prank(liquidityProvider);
        PairX.mint(liquidityProvider);

        address trader = _traders[0];

        uint256 amountAOut = _tokenDistributions[tokenA][trader];
        uint256 amountBIn =
            Utils.calculateAmountIn(amountAOut, reserveB, reserveA);

        vm.startPrank(trader);

        IERC20(tokenB).transfer(address(PairX), amountBIn / 2);

        vm.expectRevert("Pair: K");
        PairX.swap(amountAOut, 0, trader);

        vm.stopPrank();
    }
}
