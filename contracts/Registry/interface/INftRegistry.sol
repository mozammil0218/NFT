// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

/**
 * @dev Interface of Ekta Nft Registry.
 */
interface IEktaNftRegistry {
    function ektaRevenueWallet() external view returns (address);
    function saleRevenue(address saleAddress) external view returns (uint256, bool);
    function tradeRevenue(address tokenAddress) external view returns (uint256, uint256, bool);
}
