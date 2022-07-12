const Exchange = artifacts.require("Exchange");
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
  // await deployer.deploy(Exchange);
  await deployProxy(Exchange, ["0xb9e2E2A041ecD3E9BF0C6b1247E66270F0F9e38E", 20], { deployer, kind: "uups" });
};
