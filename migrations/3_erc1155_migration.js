const EKTA_ERC1155 = artifacts.require("EKTA_ERC1155");
const beaconproxy = artifacts.require("EKTABeaconProxy");
const beacon = artifacts.require("EKTABeacon");

module.exports = async function (deployer) {
  // Deploy ERC1155
  await deployer.deploy(EKTA_ERC1155);
  const implInstance = await EKTA_ERC1155.deployed();

  // Deploy beacon
  await deployer.deploy(beacon, implInstance.address);
  const beconInstance = await beacon.deployed();

  // Deploy beacon proxy
  const uri = 'http://15.164.229.216/metadata/{id}.json';
  const data = implInstance.contract.methods.initialize(uri).encodeABI();
  await deployer.deploy(beaconproxy, beconInstance.address, data);
};