// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract EKTABeacon is UpgradeableBeacon {
    constructor(address impl) UpgradeableBeacon(impl) {
    }
}
