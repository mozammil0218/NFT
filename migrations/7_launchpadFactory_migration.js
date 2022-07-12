const LaunchpadFactory = artifacts.require("LaunchpadFactory");
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
  // LaunchpadFactory params - beacon address, proxy address, ektanft registry
  await deployProxy(LaunchpadFactory, ["0x5b4c0Cb715d9bde99D8A2e03Cd2e002d58104C71", "0xe22b7325A3fA424A598015721c6d3155A889d2f7", "0xABcF18C43B8dD7255e1c67180Ba7b489dfB5A66F"], { deployer, kind: "uups" });
  // await upgradeProxy("0x25F9710dC1D9f8E0539902B5Eaa516e102Cee1e0", LaunchpadFactory, { deployer, kind: "uups" });
};
