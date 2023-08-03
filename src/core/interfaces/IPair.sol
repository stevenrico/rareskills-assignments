// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPair {
    // [Q] Why is the recipient not included?
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);
    event Burn(address indexed sender, address indexed recipient, uint256 amountA, uint256 amountB);
    event Swap(address indexed sender, address indexed recipient, uint256 amountAIn, uint256 amountAOut, uint256 amountBIn, uint256 amountBOut);

    function getTokens() external view returns (address, address);
    function getReserves() external view returns (uint112 reserveA, uint112 reserveB, uint32 blockTimestampLast);
    function getPriceCumulatives() external view returns (uint256 priceACumulative, uint256 priceBCumulative);

    function mint(address recipient) external returns (uint256 liquidtyTokens);
    function burn(address recipient) external returns (uint256 amountA, uint256 amountB);

    function swap(uint256 amountAOut, uint256 amountBOut, address recipient) external;
}
