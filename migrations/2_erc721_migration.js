const beaconproxy = artifacts.require("EKTABeaconProxy");
const beacon = artifacts.require("EKTABeacon");
const impl = artifacts.require("EKTA_ERC721");

module.exports = async function (deployer, network, accounts) {
    // Deploy implementation
    await deployer.deploy(impl);
    const implinstance = await impl.deployed();

    // Deploy beacon
    await deployer.deploy(beacon,implinstance.address);
    const beconinstance = await beacon.deployed();

    // Deploy proxy
    const tokenname = 'Test';
    const tokensymbol = 'test';
    const data = implinstance.contract.methods.initialize(tokenname,tokensymbol).encodeABI();
    await deployer.deploy(beaconproxy, beconinstance.address, data);


    // // Following is used for upgrade
    // // Deploy updated implementation
    // await deployer.deploy(impl);
    // const implInstance2 = await impl.deployed();

    // // Upgrade beacon
    // let beaconInstance = await beacon.at("0xc23b6B3Dcf1846639D50b0b5a8446cB149780987")
    // await beaconInstance.upgradeTo(implInstance2.address);
};