// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { BaseTest } from "../../BaseTest.sol";

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Utils } from "contracts/libraries/Utils.sol";

contract SwapExactTokensForTokens is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testSwapExactTokensForTokens() external {
        address liquidityProvider = _liquidityProviders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        uint256 amountA = _tokenDistributions[tokenA][liquidityProvider];
        uint256 amountB = _tokenDistributions[tokenB][liquidityProvider];

        vm.startPrank(liquidityProvider);

        IERC20(tokenA).approve(address(RouterX), amountA);
        IERC20(tokenB).approve(address(RouterX), amountB);

        (uint256 reserveA, uint256 reserveB,) = RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, liquidityProvider
        );

        vm.stopPrank();

        address trader = _traders[0];

        address[] memory tokens = new address[](2);

        tokens[0] = tokenA;
        tokens[1] = tokenB;

        uint256 traderBalanceA = _tokenDistributions[tokenA][trader];
        uint256 traderBalanceB = _tokenDistributions[tokenB][trader];

        uint256 amountAIn = traderBalanceA;
        uint256 amountBOut =
            Utils.calculateAmountOut(amountAIn, reserveA, reserveB);

        {
            // [ERROR] Stack too deep
            uint256 oneToken = 1 * _scales[tokenB];

            uint256 amountBMin = amountBOut - oneToken;

            vm.startPrank(trader);

            IERC20(tokenA).approve(address(RouterX), amountAIn);

            RouterX.swapExactTokensForTokens(
                amountAIn, amountBMin, tokens, trader
            );

            vm.stopPrank();
        }

        uint256 expectedAmountA = reserveA + amountAIn;
        uint256 expectedAmountB = reserveB - amountBOut;

        assertEq(IERC20(tokenA).balanceOf(address(PairX)), expectedAmountA);
        assertEq(IERC20(tokenB).balanceOf(address(PairX)), expectedAmountB);

        assertEq(IERC20(tokenA).balanceOf(trader), 0);
        assertEq(IERC20(tokenB).balanceOf(trader), traderBalanceB + amountBOut);
    }

    function testRevertWhenAmountInIsZero() external {
        address trader = _traders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        address[] memory tokens = new address[](2);

        tokens[0] = tokenA;
        tokens[1] = tokenB;

        vm.expectRevert("Router: Insufficient input amount");
        vm.prank(trader);
        RouterX.swapExactTokensForTokens(0, 0, tokens, trader);
    }

    function testRevertWhenPairHasZeroLiquidity() external {
        address trader = _traders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        address[] memory tokens = new address[](2);

        tokens[0] = tokenA;
        tokens[1] = tokenB;

        uint256 amountAIn = 1000 * _scales[tokenA];

        vm.expectRevert("Router: Insufficient liquidity");
        vm.prank(trader);
        RouterX.swapExactTokensForTokens(amountAIn, 0, tokens, trader);
    }

    function testRevertWhenAmountOutWillNotBeGreaterThanMin() external {
        address liquidityProvider = _liquidityProviders[0];

        (address tokenA, address tokenB) =
            Utils.sortTokens(address(TokenOne), address(TokenTwo));

        uint256 amountA = _tokenDistributions[tokenA][liquidityProvider];
        uint256 amountB = _tokenDistributions[tokenB][liquidityProvider];

        vm.startPrank(liquidityProvider);

        IERC20(tokenA).approve(address(RouterX), amountA);
        IERC20(tokenB).approve(address(RouterX), amountB);

        (uint256 reserveA, uint256 reserveB,) = RouterX.addLiquidity(
            tokenA, tokenB, amountA, amountB, liquidityProvider
        );

        vm.stopPrank();

        address trader = _traders[0];

        address[] memory tokens = new address[](2);

        tokens[0] = tokenA;
        tokens[1] = tokenB;

        uint256 amountAIn = 1000 * _scales[tokenA];
        uint256 amountBOut =
            Utils.calculateAmountOut(amountAIn, reserveA, reserveB);

        uint256 oneToken = 1 * _scales[tokenB];

        uint256 amountBMin = amountBOut + oneToken;

        vm.expectRevert("Router: Insufficient output amount");
        vm.prank(trader);
        RouterX.swapExactTokensForTokens(amountAIn, amountBMin, tokens, trader);
    }
}
