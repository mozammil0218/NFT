// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TimedCrowdsale.sol";

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
abstract contract FinalizableCrowdsale is Initializable, TimedCrowdsale {
    bool public isFinalized;

    event Finalized();

    function __FinalizableCrowdsale_init_unchained() internal onlyInitializing {
        isFinalized = false;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() internal {
        require(!isFinalized, "Already Finalized");
        require(hasClosed(), "Crowdsale is not yet closed");
        emit Finalized();

        isFinalized = true;
    }

    function _updateFinalization() internal {
        isFinalized = false;
    }
}