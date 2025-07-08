// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleDEX {
    address public owner;
    IToken public tokenA;
    IToken public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(uint256 amountA, uint256 amountB);
    event LiquidityRemoved(uint256 amountA, uint256 amountB);
    event Swapped(address indexed user, string direction, uint256 amountIn, uint256 amountOut);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(address _tokenA, address _tokenB) {
        owner = msg.sender;
        tokenA = IToken(_tokenA);
        tokenB = IToken(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer B failed");
        reserveA += amountA;
        reserveB += amountB;
        emit LiquidityAdded(amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient reserves");
        reserveA -= amountA;
        reserveB -= amountB;
        require(tokenA.transfer(msg.sender, amountA), "Withdraw A failed");
        require(tokenB.transfer(msg.sender, amountB), "Withdraw B failed");
        emit LiquidityRemoved(amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Invalid input");
        uint256 amountBOut = getAmountOut(amountAIn, reserveA, reserveB);
        require(tokenA.transferFrom(msg.sender, address(this), amountAIn), "Transfer A failed");
        require(tokenB.transfer(msg.sender, amountBOut), "Transfer B failed");
        reserveA += amountAIn;
        reserveB -= amountBOut;
        emit Swapped(msg.sender, "A->B", amountAIn, amountBOut);
    }

    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Invalid input");
        uint256 amountAOut = getAmountOut(amountBIn, reserveB, reserveA);
        require(tokenB.transferFrom(msg.sender, address(this), amountBIn), "Transfer B failed");
        require(tokenA.transfer(msg.sender, amountAOut), "Transfer A failed");
        reserveB += amountBIn;
        reserveA -= amountAOut;
        emit Swapped(msg.sender, "B->A", amountBIn, amountAOut);
    }

    function getPrice(address _token) external view returns (uint256) {
        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA;
        } else if (_token == address(tokenB)) {
            return (reserveA * 1e18) / reserveB;
        } else {
            revert("Invalid token address");
        }
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }
}
