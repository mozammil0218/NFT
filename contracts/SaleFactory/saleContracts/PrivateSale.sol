// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./FinalizableCrowdsale.sol";
import "../../Registry/interface/INftRegistry.sol";

contract PrivateSale is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, Crowdsale, TimedCrowdsale, FinalizableCrowdsale {
    
    address public ektaNftRegistry;
    bool public fundWithdrawn;
    
    bool public enableWhitelisting;
    mapping(address => bool) public whitelisted;

    string public constant name = "PrivateSale";

    event WhitelistStatusUpdated(bool enable);
    event AccountWhitelistUpdated(address indexed account, bool status);
    event AccountsWhitelistUpdated(address[] indexed account, bool status);

    function initialize(
        uint256 rate,
        uint256 maxTokensForSale,
        uint256 openingTime,
        uint256 closingTime,
        bool whitelist,
        address nftRegistry
    ) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __Crowdsale_init_unchained(rate, maxTokensForSale);
        __TimedCrowdsale_init_unchained(openingTime, closingTime);
        __FinalizableCrowdsale_init_unchained();

        enableWhitelisting = whitelist;
        ektaNftRegistry = nftRegistry;
    }

    /**
     * @dev check wheather the account is whitelisted or not
     * @param account address
     * @return bool
     */
    function isWhitelisted(address account) external view returns (bool) {
        return whitelisted[account];
    }

    /**
     * @param _beneficiary Address performing the token purchase
     */
    function buyToken(address _beneficiary)
        external
        payable
        onlyWhileOpen
        whenNotPaused
    {   
        (, bool saleable) = IEktaNftRegistry(ektaNftRegistry).saleRevenue(address(this));
        require(saleable, "This sale is not saleable");
        if (enableWhitelisting) {
            require(
                whitelisted[_beneficiary],
                "Buy Token: Address not whitelisted"
            );
        }
        buyTokens(_beneficiary);
    }

    /**
     * @dev Finalize the sale, and withdraw funds raised
     */
    function finalizeSale()
        external
        onlyOwner
        whenNotPaused
    {
        finalize();
        withdrawFundRaised();
    }

    /**
     * @dev extend sale
     * @param newClosingTime.
     */
    function extendSale(uint256 newClosingTime)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        _extendTime(newClosingTime);
        _updateFinalization();
        fundWithdrawn = false;
    }

    /**
     * @dev Update rate
     * @param newRate.
     */
    function changeRate(uint256 newRate)
        external
        virtual
        onlyOwner
        onlyWhileOpen
        whenNotPaused
    {
        require(newRate > 0, "Rate: Amount cannot be 0");
        _changeRate(newRate);
    }

    /**
     * @dev Update Enable Whitelisting
     * @param enable bool
     */
    function updateEnableWhitelisting(bool enable) external onlyOwner {
        require(enableWhitelisting != enable, "Already in same status");
        enableWhitelisting = enable;
        emit WhitelistStatusUpdated(enable);
    }

    /**
     * @dev Include specific address for Whitelisting
     * @param account whitelisting address
     */
    function includeInWhitelist(address account) external onlyOwner {
        require(account != address(0), "Account cant be zero address");
        require(!whitelisted[account], "Account is already whitelisted");
        whitelisted[account] = true;
        emit AccountWhitelistUpdated(account, true);
    }

    /**
     * @dev Exclude specific address from Whitelisting
     * @param account whitelisting address
     */
    function excludeFromWhitelist(address account) external onlyOwner {
        require(account != address(0), "Account cant be zero address");
        require(whitelisted[account], "Account is not whitelisted");
        whitelisted[account] = false;
        emit AccountWhitelistUpdated(account, false);
    }

    /**
     * @dev Include multiple address for Whitelisting
     * @param accounts whitelisting addresses
     */
    function includeAllInWhitelist(address[] memory accounts)
        external
        onlyOwner
    {
        for (uint256 account = 0; account < accounts.length; account++) {
            if (!whitelisted[accounts[account]]) {
                whitelisted[accounts[account]] = true;
            }
        }
        emit AccountsWhitelistUpdated(accounts, true);
    }

    /**
     * @dev Exclude multiple address from Whitelisting
     * @param accounts whitelisting address
     */
    function excludeAllFromWhitelist(address[] memory accounts)
        external
        onlyOwner
    {
        for (uint256 account = 0; account < accounts.length; account++) {
            if (whitelisted[accounts[account]]) {
                whitelisted[accounts[account]] = false;
            }
        }
        emit AccountsWhitelistUpdated(accounts, true);
    }

    /**
     * @dev Pause `contract` - pause events.
     */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Pause `contract` - pause events.
     */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev owner can withdraw remaining bnb from contract
     */
    function withdrawBnbFromContract() external onlyOwner whenNotPaused {
        require(isFinalized, "Withdraw BNB: Not yet Finalized"); 
        require(fundWithdrawn, "Withdraw BNB: Fund not yet withdrawn"); 
        uint256 bnbBalance = address(this).balance; 
        address payable _owner = payable(msg.sender);        
        _owner.transfer(bnbBalance);
    }

    /**
     * @dev owner can withdraw bnb raised
     * % of ektaRevenue is deducted
     */
    function withdrawFundRaised() internal whenNotPaused {
        require(isFinalized, "Withdraw Fund: Not yet Finalized");
        require(!fundWithdrawn, "Withdraw Fund: Already withdrawn");
        
        (uint256 ektaRevenuePercentage, bool saleable) = IEktaNftRegistry(ektaNftRegistry).saleRevenue(address(this)); 
        require(saleable, "This sale is not saleable");

        fundWithdrawn = true;

        // send revenue to ekta
        uint256 ektaRevenueAmount = (weiRaised * ektaRevenuePercentage) / 10**4;
        address payable ektaRevenueWallet = payable(IEktaNftRegistry(ektaNftRegistry).ektaRevenueWallet());
        ektaRevenueWallet.transfer(ektaRevenueAmount);

        // send remaining revenue to owner
        uint256 bnbBalance = weiRaised - ektaRevenueAmount; 
        address payable _owner = payable(msg.sender);        
        _owner.transfer(bnbBalance);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}