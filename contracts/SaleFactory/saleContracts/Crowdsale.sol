// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Crowdsale is Initializable {
    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    // Tokens purchased
    uint256 public tokensPurchased;

    // Max tokens for sale
    uint256 public maxTokensForSale;

    // tracking user purchase
    mapping(address => uint256) public userPurchase;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value
    );

    /**
     * @param _rate Number of token units a buyer gets per wei
     * @param _maxTokensForSale Tokens for sale
     */
    function __Crowdsale_init_unchained(
        uint256 _rate,
        uint256 _maxTokensForSale
    ) internal onlyInitializing {
        require(_rate > 0, "Rate cant be 0");
        require(_maxTokensForSale > 0, "Tokens for sale cant be 0");

        rate = _rate;
        maxTokensForSale = _maxTokensForSale;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    receive() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) internal {
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = _getTokenAmount(weiAmount);

        _preValidatePurchase(_beneficiary, weiAmount, tokenAmount);

        // update state
        weiRaised += weiAmount;
        userPurchase[_beneficiary] += tokenAmount;
        tokensPurchased += tokenAmount;

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return (_weiAmount / rate);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount)
        internal
        virtual
    {
        require(_beneficiary != address(0), "Address cant be zero address");
        require(_weiAmount != 0, "Amount cant be 0");

        require(_tokenAmount * rate == _weiAmount, "Invalid wei amount");
        require(
            tokensPurchased + _tokenAmount <= maxTokensForSale,
            "Buy Token: Sale reached max tokens for sale."
        );
    }

    /**
     * @dev Change Rate.
     * @param newRate Crowdsale rate
     */
    function _changeRate(uint256 newRate) internal virtual {
        rate = newRate;
    }
}