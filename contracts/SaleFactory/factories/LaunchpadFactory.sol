// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../Beacon/EKTABeaconProxy.sol";
import "../saleContracts/PrivateSale.sol";


contract LaunchpadFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    address public saleBeacon;
    address public saleBeaconProxy;
    address public ektaNftRegistry;

    event CreatePrivateSale(address token);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address beacon, address beaconProxy, address nftRegistry) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        saleBeacon = beacon;
        saleBeaconProxy = beaconProxy;
        ektaNftRegistry = nftRegistry;
    }

    /**
     * @dev deploy private sale contract.
     * @param rate - provide EKTA per NFT.
     * @param maxTokensForSale - max nft for private sale.
     * @param openingTime - sale opening time.
     * @param closingTime - sale ending time.
     * @param whitelist - enable/disable whitelist.
     * @param _salt - unique to avoid shadowing.
     *
     * Emits a {CreatePrivateSale} event, indicating the sale address
     */
    function createPrivateSale(uint256 rate, uint256 maxTokensForSale, uint256 openingTime, uint256 closingTime, bool whitelist, uint _salt) external whenNotPaused nonReentrant {
        address beaconProxy = deployProxy(getSaleData(rate, maxTokensForSale, openingTime, closingTime, whitelist, ektaNftRegistry), _salt);
        PrivateSale token = PrivateSale(payable(beaconProxy));
        emit CreatePrivateSale(address(token));
        token.transferOwnership(msg.sender);
    }

    /**
     * @dev Update nft registry address.
     * @param _ektaNftRegistry.
     */
    function updateNftRegistry(address _ektaNftRegistry) external onlyOwner {
        require(_ektaNftRegistry != address(0), "Factory: Cant be zero address");
        ektaNftRegistry = _ektaNftRegistry;
    }

    /**
     * @dev Update beacon address by owner.
     * @param _saleBeacon.
     */
    function updateBeacon(address _saleBeacon) external onlyOwner {
        require(_saleBeacon != address(0), "Factory: Cant be zero address");
        saleBeacon = _saleBeacon;
    }

    /**
     * @dev Update beacon proxy address by owner.
     * @param _saleBeaconProxy.
     */
    function updateBeaconProxy(address _saleBeaconProxy) external onlyOwner {
        require(_saleBeaconProxy != address(0), "Factory: Cant be zero address");
        saleBeaconProxy = _saleBeaconProxy;
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
    function unpause() external onlyOwner{
        _unpause();
    }
    
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /** 
     * @dev adding constructor arguments to bytecode
     *
     * @param rate.
     * @param maxTokensForSale.
     * @param openingTime.
     * @param closingTime.
     * @param whitelist.
     */
    function getSaleData(uint256 rate, uint256 maxTokensForSale, uint256 openingTime, uint256 closingTime, bool whitelist, address nftRegistry) 
        view 
        internal 
        returns(bytes memory) 
    {
        return abi.encodeWithSelector(PrivateSale(payable(saleBeaconProxy)).initialize.selector, rate, maxTokensForSale, openingTime, closingTime, whitelist, nftRegistry);
    }

    // deploying BeaconProxy contract with create2
    function deployProxy(bytes memory data, uint salt) 
        internal 
        returns(address proxy)
    {
        bytes memory bytecode = getCreationBytecode(data);
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }

    // adding constructor arguments to BeaconProxy bytecode
    function getCreationBytecode(bytes memory _data) 
        internal 
        view 
        returns (bytes memory) 
    {
        return abi.encodePacked(
            type(EKTABeaconProxy).creationCode, 
            abi.encode(saleBeacon, _data)
        );
    }
}