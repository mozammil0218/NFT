const EktaNftRegistry = artifacts.require("EktaNftRegistry");
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
  // EktaNftRegistry params - ektaRevenueWallet
  await deployProxy(EktaNftRegistry, ["0xb9e2E2A041ecD3E9BF0C6b1247E66270F0F9e38E"], { deployer, kind: "uups" });
  // await upgradeProxy("0x25F9710dC1D9f8E0539902B5Eaa516e102Cee1e0", EktaNftRegistry, { deployer, kind: "uups" });
};
