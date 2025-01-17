// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAMM {
    //事件定义
    event AddLiquidity(address indexed provider, uint256 amount0, uint256 amount1,uint256 liquidity);
    event RemoveLiquidity(address indexed provider, uint256 amount0, uint256 amount1,uint256 liquidity);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed tokenIn);

    //错误定义
    error InsufficientLiquidity();
    error InsufficientAmount();
    error InvalidToken();
    error InvalidK();
    error TransferFailed();

    // 核心功能
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1, uint256 liquidity);

    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    // 查询功能
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
    function getTokens() external view returns (address token0, address token1);
    function quote(uint256 amountIn, address tokenIn) external view returns (uint256 amountOut);
}
