const beaconproxy = artifacts.require("EKTABeaconProxy");
const beacon = artifacts.require("EKTABeacon");
const PrivateSale = artifacts.require("PrivateSale");

module.exports = async function (deployer) {
    // Deploy implementation
    await deployer.deploy(PrivateSale);
    const implInstance = await PrivateSale.deployed();

    // Deploy beacon
    await deployer.deploy(beacon, implInstance.address);
    const beconInstance = await beacon.deployed();

    // Deploy proxy
    // initialize params - rate, maxTokensForSale, openingTime, closingTime, enable whitelist, ekta nft registry
    const data = implInstance.contract.methods.initialize(1, 10, 1652337303, 1652423703, false, "0xABcF18C43B8dD7255e1c67180Ba7b489dfB5A66F").encodeABI();
    await deployer.deploy(beaconproxy, beconInstance.address, data);
};
