// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./library/LibOrder.sol";
import "./library/LibBidOrder.sol";
import "../Registry/interface/INftRegistry.sol";

contract Exchange is Initializable, UUPSUpgradeable, EIP712Upgradeable, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    string public constant name = "Exchange";

    address public ektaNftRegistry;
    
    IERC20Upgradeable constant public WEKTA = IERC20Upgradeable(0x32CBEA3f063B9803011267dc8e539aa26f1AEA76);

    mapping(bytes32 => bytes4) public OrderStatus;
    mapping(address => bool) public blacklisted;

    bytes4 constant public FIXED_SALE_CLASS = bytes4(keccak256("FIXED"));
    bytes4 constant public CLOSED_AUCTION_SALE_CLASS = bytes4(keccak256("CLOSED_AUCTION"));
    bytes4 constant public OPEN_AUCTION_SALE_CLASS = bytes4(keccak256("OPEN_AUCTION"));

    bytes4 constant public NEW_ORDER_CLASS = bytes4(keccak256("NEW"));
    bytes4 constant public COMPLETED_ORDER_CLASS = bytes4(keccak256("COMPLETED"));
    bytes4 constant public CANCELLED_ORDER_CLASS = bytes4(keccak256("CANCELLED"));

    bytes4 constant public ASSET_TYPE_ERC721 = bytes4(keccak256("ERC721"));
    bytes4 constant public ASSET_TYPE_ERC1155 = bytes4(keccak256("ERC1155"));

    event OrderCreated(LibOrder.Order order, bytes32 hash, address signer);
    event Buy(address seller, address buyer, address tokenAddress, uint256 tokenId);
    event OrderCancelled(LibOrder.Order order);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address nftRegistry) public initializer {
        // initializing
        __Pausable_init_unchained();  
        __Ownable_init_unchained();  
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();
        __EIP712_init_unchained("Order", "1");
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);

        ektaNftRegistry = nftRegistry;
    }

    /**
     * @dev Check if address is blacklisted
     * @param account - Address.
     * @return bool.
     */
    function isBlacklisted(address account) view external returns(bool) {
        return blacklisted[account];
    }

    /**
     * @dev Creates a sell order
     * @param order - Object of sell order.
     * @param signature.
     *
     * Emits a {OrderCreated} event, indicating the order, unique key and the signer.
     */
    function createOrder(LibOrder.Order memory order, bytes calldata signature) external whenNotPaused nonReentrant {
        require(!blacklisted[msg.sender], "Exchange: Blackisted");

        // saleType and tokenType validation
        require(order.tokenType == ASSET_TYPE_ERC721 || order.tokenType == ASSET_TYPE_ERC1155, "Exchange: Invalid token type");
        require(order.saleType == FIXED_SALE_CLASS || order.saleType == CLOSED_AUCTION_SALE_CLASS || order.saleType == OPEN_AUCTION_SALE_CLASS, "Exchange: Invalid sale type");

        // startTime and endTime validation
        if(order.saleType == CLOSED_AUCTION_SALE_CLASS || order.saleType == OPEN_AUCTION_SALE_CLASS)
            require(order.startTime > block.timestamp, "Exchange: start time must be greater than current time");
        if(order.saleType == CLOSED_AUCTION_SALE_CLASS) require(order.endTime > order.startTime, "Exchange: end time must be greater than start time");

        // verify signature
        bytes32 structHash = LibOrder.genOrderHash(order);
        bytes32 hashTypedData = _hashTypedDataV4(structHash);
        address signer = verifySignature(hashTypedData, signature);
        require(signer == order.seller, "Exchange: Order is not signed by the seller");

        // get unique key
        bytes32 hashKey = LibOrder.genHashKey(order);
        // existing order validation
        require(OrderStatus[hashKey] == 0x00000000, "Exchange: Order already exists");
        // update order status
        OrderStatus[hashKey] = NEW_ORDER_CLASS;

        emit OrderCreated(order, hashKey, signer);
    }

    /**
     * @dev Completes fixed sale order
     * @param order - Object of sell order.
     *
     * Emits a {Buy} event, indicating the seller, token address and token id.
     */
    function completeFixedSale(LibOrder.Order memory order) external payable whenNotPaused nonReentrant {
        require(!blacklisted[msg.sender] && !blacklisted[order.seller], "Exchange: Blackisted");

        // validate token registry
        (uint256 ektaRevenuePercentage, uint256 royaltyPercentage, bool tradable) = IEktaNftRegistry(ektaNftRegistry).tradeRevenue(order.tokenAddress);
        require(tradable, "This sale is not tradable");

        // get unique key
        bytes32 hashKey = LibOrder.genHashKey(order);

        // check for order status
        validateOrderStatus(hashKey);

        require(msg.value >= order.price, "Exchange: Wrong amount");

        // update order status
        OrderStatus[hashKey] = COMPLETED_ORDER_CLASS;

        emit Buy(order.seller, msg.sender, order.tokenAddress, order.tokenId);

        // block scope to avoid variable shadowing
        // take revenue and send to ekta revenue wallet
        uint256 revenueAmount = calculateRevenue(order.price, ektaRevenuePercentage);
        {
            (bool success, ) = payable(IEktaNftRegistry(ektaNftRegistry).ektaRevenueWallet()).call{value: revenueAmount}("");
            require(success, "Exchange: Revenue transfer failed");
        }

        // block scope to avoid variable shadowing
        // take royalty and send to royalty wallet
        uint256 royaltyAmount = calculateRevenue(order.price, royaltyPercentage);
        {
            (bool success, ) = payable(getRoyaltyWallet(order.tokenAddress)).call{value: royaltyAmount}("");
            require(success, "Exchange: Revenue transfer failed");
        }

        // reduce revenue and royalty amount
        order.price = order.price - revenueAmount - royaltyAmount;

        // block scope to avoid variable shadowing
        // transfer EKTA to seller
        {
            (bool success, ) = payable(order.seller).call{value: order.price}("");
            require(success, "Exchange: EKTA transfer failed");
        }

        // transfer token from seller to buyer
        if(order.tokenType == ASSET_TYPE_ERC721) IERC721Upgradeable(order.tokenAddress).safeTransferFrom(order.seller, msg.sender, order.tokenId);
        if(order.tokenType == ASSET_TYPE_ERC1155) IERC1155Upgradeable(order.tokenAddress).safeTransferFrom(order.seller, msg.sender, order.tokenId, order.tokenAmount, "");
    }

    /**
     * @dev Completes bid order
     * @param bidOrder - Object of bid order.
     * @param signature.
     *
     * Emits a {Buy} event, indicating the seller, token address and token id.
     */
    function completeBidding(LibBidOrder.BidOrder memory bidOrder, bytes calldata signature) external whenNotPaused nonReentrant {
        require(!blacklisted[msg.sender] && !blacklisted[bidOrder.buyer], "Exchange: Blackisted");
        require(msg.sender == bidOrder.seller, "Caller is not seller");

        // validate endTime for closed auction
        if(bidOrder.saleType == CLOSED_AUCTION_SALE_CLASS) require(block.timestamp > bidOrder.endTime, "Exchange: Sale not ended yet");

        // validate token registry
        (uint256 ektaRevenuePercentage, uint256 royaltyPercentage, bool tradable) = IEktaNftRegistry(ektaNftRegistry).tradeRevenue(bidOrder.tokenAddress);
        require(tradable, "This sale is not tradable");
        
        // verify signature
        bytes32 structHash = LibBidOrder.genBidOrderHash(bidOrder);
        bytes32 hashTypedData = _hashTypedDataV4(structHash);
        address signer = verifySignature(hashTypedData, signature);
        require(signer == bidOrder.buyer, "Exchange: Buy order is not signed by the buyer");

        // get unique key
        LibOrder.Order memory order = LibOrder.Order(
            bidOrder.tokenType, 
            bidOrder.saleType, 
            bidOrder.seller, 
            bidOrder.tokenAddress, 
            bidOrder.tokenId, 
            bidOrder.tokenAmount, 
            bidOrder.price, 
            bidOrder.startTime, 
            bidOrder.endTime, 
            bidOrder.nonce
        );
        bytes32 hashKey = LibOrder.genHashKey(order);

        // check for order status
        validateOrderStatus(hashKey);

        // update order status
        OrderStatus[hashKey] = COMPLETED_ORDER_CLASS;

        emit Buy(bidOrder.seller, bidOrder.buyer, bidOrder.tokenAddress, bidOrder.tokenId);

        // take revenue and send to ekta revenue wallet
        uint256 revenueAmount = calculateRevenue(bidOrder.bidAmount, ektaRevenuePercentage);
        {
            WEKTA.safeTransferFrom(bidOrder.buyer, IEktaNftRegistry(ektaNftRegistry).ektaRevenueWallet(), revenueAmount);
        }

        // take royalty and send to royalty wallet
        uint256 royaltyAmount = calculateRevenue(bidOrder.bidAmount, royaltyPercentage);
        {
            WEKTA.safeTransferFrom(bidOrder.buyer, msg.sender, royaltyAmount);
        }
        
        // reduce revenue and royalty amount
        bidOrder.bidAmount = bidOrder.bidAmount - revenueAmount - royaltyAmount;

        // transfer remaining WEKTA to seller
        {
            LibBidOrder.BidOrder memory bidOrderData = bidOrder;
            WEKTA.safeTransferFrom(bidOrderData.buyer, msg.sender, bidOrderData.bidAmount);
        }

        // transfer token from seller to buyer
        {
            LibBidOrder.BidOrder memory bidOrderData = bidOrder;
            if(order.tokenType == ASSET_TYPE_ERC721) IERC721Upgradeable(bidOrderData.tokenAddress).safeTransferFrom(
                msg.sender, bidOrderData.buyer, bidOrderData.tokenId
            );
            if(order.tokenType == ASSET_TYPE_ERC1155) IERC1155Upgradeable(bidOrderData.tokenAddress).safeTransferFrom(
                msg.sender, bidOrderData.buyer, bidOrderData.tokenId, bidOrderData.tokenAmount, ""
            );
        }
    }

    /**
     * @dev Cancel order
     * @param order - Object of order.
     *
     * Emits a {OrderCancelled} event, indicating the order that is cancelled.
     */
    function cancelOrder(LibOrder.Order memory order) external whenNotPaused nonReentrant {
        require(!blacklisted[msg.sender] && !blacklisted[order.seller], "Exchange: Blackisted");
        require(msg.sender == order.seller, "Exchange: Order can be cancelled only by the seller");
        // get unique key
        bytes32 hashKey = LibOrder.genHashKey(order);

        // check for order status
        validateOrderStatus(hashKey);
        // update order status
        OrderStatus[hashKey] = COMPLETED_ORDER_CLASS;

        emit OrderCancelled(order);
    }

    /**
     * @dev Include address in blacklist by UPDATER_ROLE.
     *
     * @param account.
     */
    function includeInBlacklist(address account) external onlyRole(UPDATER_ROLE) {
        require(account != address(0), "Exchange: Cant be zero address");
        require(!blacklisted[account], "Exchange: Account is already blacklisted");
        blacklisted[account] = true;
    }

    /**
     * @dev Exclude address from blacklist by UPDATER_ROLE.
     *
     * @param account.
     */
    function excludeFromBlacklist(address account) external onlyRole(UPDATER_ROLE) {
        require(account != address(0), "Exchange: Cant be zero address");
        require(blacklisted[account], "Exchange: Account is not blacklisted");
        blacklisted[account] = false;
    }

    /**
     * @dev Bulk Include address in blacklist by UPDATER_ROLE.
     *
     * @param accounts.
     */
    function includeAllInBlacklist(address[] memory accounts) external onlyRole(UPDATER_ROLE) {
        for (uint256 account = 0; account < accounts.length; account++) {
            if(!blacklisted[accounts[account]]) blacklisted[accounts[account]] = true;
       }
    }

    /**
     * @dev Bulk exclude address in blacklist by UPDATER_ROLE.
     *
     * @param accounts.
     */
    function excludeAllFromBlacklist(address[] memory accounts) external onlyRole(UPDATER_ROLE) {
        for (uint256 account = 0; account < accounts.length; account++) {
            if(blacklisted[accounts[account]]) blacklisted[accounts[account]] = false;
       }
    }

    /**
     * @dev Pause the contract (stopped state)
     * by caller with PAUSER_ROLE.
     *
     * - The contract must not be paused.
     * 
     * Emits a {Paused} event.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract (normal state)
     * by caller with PAUSER_ROLE.
     *
     * - The contract must be paused.
     * 
     * Emits a {Unpaused} event.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    receive() external payable {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Internal function to validate order status.
     * @param hashKey - order hash.
     */
    function validateOrderStatus(bytes32 hashKey) view internal {
        require(OrderStatus[hashKey] == NEW_ORDER_CLASS, "Exchange: Order is not created yet");
        require(OrderStatus[hashKey] != COMPLETED_ORDER_CLASS, "Exchange: Order is already completed");
        require(OrderStatus[hashKey] != CANCELLED_ORDER_CLASS, "Exchange: Order is already cancelled");
    }

    /**
     * @dev Internal function to get royalty wallet(partner address).
     * @param tokenAddress - contract address.
     * @return address - contract owner address.
     */
    function getRoyaltyWallet(address tokenAddress) view internal returns(address){
        return OwnableUpgradeable(tokenAddress).owner();
    }

    /**
     * @dev Internal function to calculate revenue.
     * @param price.
     * @return uint256 - revenue amount.
     */
    function calculateRevenue(uint256 price, uint256 percentage) pure internal returns(uint256) {
        return (price * percentage) / 10**4;
    }

    /**
     * @dev Internal function to verify the signature.
     * @param hash - bytes of signature params.
     * @param signature.
     * @return address - signer address
     */
    function verifySignature(bytes32 hash, bytes calldata signature) internal pure returns(address) {
        return ECDSAUpgradeable.recover(hash, signature);
    }
}