pragma solidity ^0.6.6;

import "./IERC20.sol";

pragma solidity ^0.6.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface ICzzSwap is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

interface IRouter {
    function getAddress() external returns(address ads); 
    // function getAmountsOut(IERC20 _srcToken, IERC20 _dstToken, uint256 _srcAmount)
    //     external view returns (uint256 dstAmount);
    function swapSTD2Token(uint256 _srcAmount, address _dstToken, uint256 _minDstAmount)
        external payable returns (uint256 dstAmount);
    function swapToken2STD(address _srcToken, uint256 _srcAmount, uint256 _minDstAmount)
        external returns (uint256 dstAmount);
}