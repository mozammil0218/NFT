// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Initializable {
    uint256 public openingTime;
    uint256 public closingTime;

    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen() {
        // solium-disable-next-line security/no-block-members
        require(
            block.timestamp >= openingTime && block.timestamp <= closingTime,
            "Crowdsale has not started or has been ended"
        );
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function __TimedCrowdsale_init_unchained(
        uint256 _openingTime,
        uint256 _closingTime
    ) internal onlyInitializing {
        // solium-disable-next-line security/no-block-members
        require(
            _openingTime >= block.timestamp,
            "OpeningTime must be greater than current timestamp"
        );
        require(
            _closingTime >= _openingTime,
            "Closing time cant be before opening time"
        );

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > closingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal {
        closingTime = newClosingTime;
        emit TimedCrowdsaleExtended(closingTime, newClosingTime);
    }
}