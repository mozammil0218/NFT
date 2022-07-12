// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../tokens/ERC721.sol";
import "../tokens/ERC1155.sol";
import "../../Beacon/EKTABeaconProxy.sol";

contract MarketplaceFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    address public erc721Beacon;
    address public erc1155Beacon;
    address public ERC721;
    address public ERC1155;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    string public constant name = "ERC721 Token Factory";

    enum tokenType
    {
        ERC721,
        ERC1155
    }

    event Create721(address token);
    event Create1155(address token);

    /**
     * @dev Initializes the contract.
     *
     * @param operator cannot be the zero address.
     * @param _erc721Beacon, address of the beacon implementation.
     * @param _erc721BeaconProxy, address of the beacon implementation.
     * @param _erc1155Beacon, address of the beacon implementation.
     * @param _erc1155BeaconProxy, address of the beacon implementation.
     */
    function initialize(address operator, address _erc721Beacon, address _erc721BeaconProxy, address _erc1155Beacon, address _erc1155BeaconProxy) public initializer {
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        require(operator != address(0), "Factory: Address cant be zero address");
        require(_erc721Beacon != address(0) && _erc1155Beacon!= address(0), "Factory: Beacon address cant be zero address");
        require(_erc721BeaconProxy != address(0) && _erc1155BeaconProxy!= address(0), "Factory: Beacon Proxy address cant be zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, operator);
        _setupRole(PAUSER_ROLE, msg.sender);

        erc721Beacon = _erc721Beacon;
        erc1155Beacon = _erc1155Beacon;
        ERC721 = _erc721BeaconProxy;
        ERC1155 = _erc1155BeaconProxy;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Creates an ERC721 token by the caller with OPERATOR_ROLE.
     *
     * @param _tokenName.
     * @param _tokenSymbol.
     * @param _baseUri.
     * @param _salt.
     * 
     * Emits a {Create721} event indicating the token address.
     */
    function createERC721Token(string memory _tokenName, string memory _tokenSymbol, string memory _baseUri, uint _salt) 
        external 
        onlyRole(OPERATOR_ROLE) 
        whenNotPaused 
        nonReentrant 
    {
        address beaconProxy = deployProxy(getERC721Data(_tokenName, _tokenSymbol), _salt, tokenType.ERC721);
        EKTA_ERC721 token = EKTA_ERC721(address(beaconProxy));
        emit Create721(address(token));

        token.transferOwnership(msg.sender);
        token.grantRole(token.DEFAULT_ADMIN_ROLE(), msg.sender);
        token.grantRole(token.UPDATER_ROLE(), msg.sender);
        token.grantRole(token.PAUSER_ROLE(), msg.sender);
        token.grantRole(token.MINTER_ROLE(), msg.sender);
        token.updateBaseURI(_baseUri);
    }

    /**
     * @dev Creates an ERC1155 token by the caller with OPERATOR_ROLE.
     *
     * @param _uri.
     * @param _salt.
     * 
     * Emits a {Create1155} event indicating the token address.
     */
    function createERC1155Token(string memory _uri, uint _salt) 
        external 
        onlyRole(OPERATOR_ROLE) 
        whenNotPaused 
        nonReentrant 
    {
        address beaconProxy = deployProxy(getERC1155Data(_uri), _salt, tokenType.ERC1155);
        EKTA_ERC1155 token = EKTA_ERC1155(address(beaconProxy));
        emit Create1155(address(token));

        token.transferOwnership(msg.sender);
        token.grantRole(token.DEFAULT_ADMIN_ROLE(), msg.sender);
        token.grantRole(token.UPDATER_ROLE(), msg.sender);
        token.grantRole(token.PAUSER_ROLE(), msg.sender);
        token.grantRole(token.MINTER_ROLE(), msg.sender);
    }

    /**
     * @dev Pause the contract (stopped state)
     * by caller with PAUSER_ROLE.
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
     * Emits a {Unpaused} event.
     */
    function unpause() external onlyRole(PAUSER_ROLE){
        _unpause();
    }

    /**
     * @dev Update beacon address by owner.
     *
     * @param _erc721Beacon.
     * @param _erc1155Beacon.
     */
    function updateBeacon(address _erc721Beacon, address _erc1155Beacon) external onlyRole(UPDATER_ROLE) {
        require(_erc721Beacon != address(0) && _erc1155Beacon != address(0), "Factory: Cant be zero address");
        erc721Beacon = _erc721Beacon;
        erc1155Beacon = _erc1155Beacon;
    }

    /**
     * @dev Update beacon proxy address by owner.
     *
     * @param _erc721BeaconProxy.
     * @param _erc1155BeaconProxy.
     */
    function updateBeaconProxy(address _erc721BeaconProxy, address _erc1155BeaconProxy) external onlyRole(UPDATER_ROLE) {
        require(_erc721BeaconProxy != address(0) && _erc1155BeaconProxy != address(0), "Factory: Cant be zero address");
        ERC721 = _erc721BeaconProxy;
        ERC1155 = _erc1155BeaconProxy;
    }

    /** 
     * @dev adding constructor arguments to bytecode
     *
     * @param _name.
     * @param _symbol.
     */
    function getERC721Data(string memory _name, string memory _symbol) 
        view 
        internal 
        returns(bytes memory) 
    {
        return abi.encodeWithSelector(EKTA_ERC721(address(ERC721)).initialize.selector, _name, _symbol);
    }

    /** 
     * @dev adding constructor arguments to bytecode
     *
     * @param _uri.
     */
    function getERC1155Data(string memory _uri) 
        view 
        internal 
        returns(bytes memory)
    {
        return abi.encodeWithSelector(EKTA_ERC1155(address(ERC1155)).initialize.selector, _uri);
    }

    // returns address of the contract with provided arguments
    function getERC721Address(string memory _name, string memory _symbol, uint _salt)
        public
        view
        returns (address)
    {
        bytes memory bytecode = getCreationBytecode(getERC721Data(_name, _symbol), tokenType.ERC721);

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    // returns address of the contract with provided arguments
    function getERC1155Address(string memory _uri, uint _salt)
        public
        view
        returns (address)
    {
        bytes memory bytecode = getCreationBytecode(getERC1155Data(_uri), tokenType.ERC1155);

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    // adding constructor arguments to BeaconProxy bytecode
    function getCreationBytecode(bytes memory _data, tokenType _tokenType) 
        internal 
        view 
        returns (bytes memory) 
    {
        return abi.encodePacked(
            type(EKTABeaconProxy).creationCode, 
            abi.encode(keccak256(abi.encodePacked(_tokenType)) == keccak256(abi.encodePacked(tokenType.ERC721)) 
                ? erc721Beacon 
                : erc1155Beacon, _data
            )
        );
    }

    // deploying BeaconProxy contract with create2
    function deployProxy(bytes memory data, uint salt, tokenType _tokenType) 
        internal 
        returns(address proxy)
    {
        bytes memory bytecode = getCreationBytecode(data, _tokenType);
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }
}