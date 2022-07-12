// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract EktaNftRegistry is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {

    address public ektaRevenueWallet;

    /**
     * @dev SaleRevenue is struct used for private sale
     * ektaRevenuePercentage - revenue percentage for ekta to be considered in private sale
     * saleable - check if private sale is active with registry
     */
    struct SaleRevenue {
        uint256 ektaRevenuePercentage;
        bool saleable;
    }

    /**
     * @dev TradeRevenue is struct used for exchange
     * ektaRevenuePercentage - revenue percentage for ekta to be considered in all trades
     * royaltyPercentage - revenue percentage for partner to be considered in all trades
     * tradable - check if contract is active with registry for trading
     */
    struct TradeRevenue {
        uint256 ektaRevenuePercentage;
        uint256 royaltyPercentage;
        bool tradable;
    }

    mapping(address => SaleRevenue) public saleRevenue;
    mapping(address => TradeRevenue) public tradeRevenue;

    function initialize(address _ektaRevenueWallet) public initializer {
        // initializing
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        ektaRevenueWallet = _ektaRevenueWallet;
    }

    /**
     * @dev Set ekta revenue wallet
     * @param walletAddress - ekta revenue wallet address
     */
    function setEktaRevenueWallet(
        address walletAddress
    ) external onlyOwner {
        require(walletAddress != address(0), "Address cant be zero address");
        ektaRevenueWallet = walletAddress;
    }

    /**
     * @dev Set sale revenue details
     * @param _saleAddress - sale contract address
     * @param _ektaRevenuePercentage - revenue for ekta
     * @param _saleable - bool to check if token is saleable
     */
    function setSaleRevenue(
        address _saleAddress,
        uint256 _ektaRevenuePercentage,
        bool _saleable
    ) external onlyOwner {
        saleRevenue[_saleAddress].ektaRevenuePercentage = _ektaRevenuePercentage;
        saleRevenue[_saleAddress].saleable = _saleable;
    }

    /**
     * @dev Set trade revenue details
     * @param _tokenAddress - token contract address
     * @param _ektaRevenuePercentage - revenue for ekta
     * @param _royaltyPercentage - revenue for partner
     * @param _tradable - bool to check if token is tradable
     */
    function setTradeRevenue(
        address _tokenAddress,
        uint256 _ektaRevenuePercentage,
        uint256 _royaltyPercentage,
        bool _tradable
    ) external onlyOwner {
        tradeRevenue[_tokenAddress].ektaRevenuePercentage = _ektaRevenuePercentage;
        tradeRevenue[_tokenAddress].royaltyPercentage = _royaltyPercentage;
        tradeRevenue[_tokenAddress].tradable = _tradable;
    }

    /**
     * @dev Pause the contract (stopped state)
     * Emits a {Paused} event.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (normal state)
     * Emits a {Unpaused} event.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}