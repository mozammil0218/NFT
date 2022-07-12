// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract EKTA_ERC1155 is Initializable, UUPSUpgradeable, ERC1155Upgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {

    bool public enableWhitelisting;

    mapping(address => bool) public whitelisted;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event WhitelistStatusUpdated(bool enable);
    event AccountWhitelistUpdated(address indexed account, bool status);
    event AccountsWhitelistUpdated(address[] indexed account, bool status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory uri) public initializer {
        __ERC1155_init_unchained(uri);
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev check wheather the account is whitelisted or not
     * @param account address
     * @return bool
     */
    function isWhitelisted(address account) view external returns(bool) {
        return whitelisted[account];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev update base uri by called with UPDATER_ROLE
     * @param newuri.
     */
    function setURI(string memory newuri) external onlyRole(UPDATER_ROLE) {
        _setURI(newuri);
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

    /**
     * @dev mint nft for a specific id by caller with MINTER_ROLE
     * @param account.
     * @param id.
     * @param amount.
     * @param data.
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyRole(MINTER_ROLE) nonReentrant {
        _mint(account, id, amount, data);
    }

    /**
     * @dev mint multiple nft for multiple ids by caller with MINTER_ROLE
     * @param to.
     * @param ids.
     * @param amounts.
     * @param data.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyRole(MINTER_ROLE) nonReentrant {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Include specific address for Whitelisting
     * @param account - whitelisting address
     */
    function includeInWhitelist(address account) external onlyRole(UPDATER_ROLE) nonReentrant {
        require(account != address(0), "ERC721: Account cant be zero address");
        require(!whitelisted[account], "ERC721: Account is already whitelisted");
        whitelisted[account] = true;
        emit AccountWhitelistUpdated(account, true);
    }
    
    /**
     * @dev Exclude specific address from Whitelisting
     * @param account - whitelisting address
     */
    function excludeFromWhitelist(address account) external onlyRole(UPDATER_ROLE) nonReentrant {
        require(account != address(0), "ERC721: Account cant be zero address");
        require(whitelisted[account], "ERC721: Account is not whitelisted");
        whitelisted[account] = false;
        emit AccountWhitelistUpdated(account, false);
    }
    
    /**
     * @dev Include multiple address for Whitelisting
     * @param accounts - whitelisting addresses
     */
    function includeAllInWhitelist(address[] memory accounts) external onlyRole(UPDATER_ROLE) nonReentrant {
        for (uint256 account = 0; account < accounts.length; account++) {
            if(!whitelisted[accounts[account]]) {
              whitelisted[accounts[account]] = true;
            }
       }
       emit AccountsWhitelistUpdated(accounts, true);
    }
    
    /**
     * @dev Exclude multiple address from Whitelisting
     * @param accounts - whitelisting address
     */
    function excludeAllFromWhitelist(address[] memory accounts) external onlyRole(UPDATER_ROLE) nonReentrant {
        for (uint256 account = 0; account < accounts.length; account++) {
             if(whitelisted[accounts[account]]) {
              whitelisted[accounts[account]] = false;
            }
       }
        emit AccountsWhitelistUpdated(accounts, true);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}