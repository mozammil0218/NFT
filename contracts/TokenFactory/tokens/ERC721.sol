// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract EKTA_ERC721 is Initializable, UUPSUpgradeable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string private baseURI;

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

    function initialize(string memory nftName, string memory nftSymbol) public initializer {
        __ERC721_init_unchained(nftName, nftSymbol);
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
    }

    /**
     * @dev check wheather the account is whitelisted or not
     * @param account address
     * @return bool
     */
    function isWhitelisted(address account) view external returns(bool){
        return whitelisted[account];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev token uri of particular token id
     * @param tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev update base uri by called with UPDATER_ROLE
     * @param _baseUri.
     */
    function updateBaseURI(string memory _baseUri) external onlyRole(UPDATER_ROLE) nonReentrant {
        baseURI = _baseUri;
    }

    /**
     * @dev transfer from after approval
     * @param from.
     * @param to.
     * @param tokenId.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant {
        if(enableWhitelisting) require(whitelisted[to], "Account is not whitelisted");

        super.transferFrom(from, to, tokenId);
    }
    
    /**
     * @dev Update Enable Whitelisting
     * @param enable - bool
     */
    function updateEnableWhitelisting(bool enable) external onlyRole(UPDATER_ROLE) nonReentrant {
        require(enableWhitelisting != enable , "ERC721: Already in same status");
        enableWhitelisting = enable;
        emit WhitelistStatusUpdated(enable);
    }
    
    /**
     * @dev Include specific address for Whitelisting
     * @param account whitelisting address
     */
    function includeInWhitelist(address account) external onlyRole(UPDATER_ROLE) nonReentrant {
        require(account != address(0), "ERC721: Account cant be zero address");
        require(!whitelisted[account], "ERC721: Account is already whitelisted");
        whitelisted[account] = true;
        emit AccountWhitelistUpdated(account, true);
    }
    
    /**
     * @dev Exclude specific address from Whitelisting
     * @param account whitelisting address
     */
    function excludeFromWhitelist(address account) external onlyRole(UPDATER_ROLE) nonReentrant {
        require(account != address(0), "ERC721: Account cant be zero address");
        require(whitelisted[account], "ERC721: Account is not whitelisted");
        whitelisted[account] = false;
        emit AccountWhitelistUpdated(account, false);
    }
    
    /**
     * @dev Include multiple address for Whitelisting
     * @param accounts whitelisting addresses
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
     * @param accounts whitelisting address
     */
    function excludeAllFromWhitelist(address[] memory accounts) external onlyRole(UPDATER_ROLE) nonReentrant {
        for (uint256 account = 0; account < accounts.length; account++) {
             if(whitelisted[accounts[account]]) {
              whitelisted[accounts[account]] = false;
            }
       }
        emit AccountsWhitelistUpdated(accounts, true);
    }

    /**
     * @dev Mint single nft
     * @param to - account
     * @param uri - token uri
     */
    function safeMint(address to, string memory uri) external onlyRole(MINTER_ROLE) nonReentrant {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Mint multiple nft
     * @param to - account
     * @param uris - token uris
     */
    function mintBatch(address to, string[] memory uris) external onlyRole(MINTER_ROLE) nonReentrant {
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);
        }
    }

    /**
     * @dev Mint multiple nft and transfer
     * @param to - accounts
     * @param uris - token uris
     */
    function mintBatchAndTransfer(address[] memory to, string[] memory uris) external onlyRole(MINTER_ROLE) nonReentrant {
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to[i], tokenId);
            _setTokenURI(tokenId, uris[i]);
        }
    }

    /**
     * @dev Burn multiple nft
     * @param tokenIds - array of token ids
     */
    function burnBatch(uint256[] memory tokenIds) external onlyRole(MINTER_ROLE) nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
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

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
