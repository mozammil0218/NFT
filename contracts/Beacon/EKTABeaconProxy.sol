// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.10 <=0.8.13;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract EKTABeaconProxy is BeaconProxy {
    constructor(address beacon, bytes memory data) BeaconProxy(beacon,data){
    }
}
