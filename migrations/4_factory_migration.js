const MarketplaceFactory = artifacts.require("MarketplaceFactory");
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer, network, accounts) {
  // operator, erc721 beacon address, erc721 proxy address, erc1155 beacon address, erc1155 proxy address
  await deployProxy(MarketplaceFactory, ["0x217373AB5e0082B2Ce622169672ECa6F4462319C", "0xD86B3C1c5126e7bA15Ee73816eEaa56AC6db5c61", "0xbCEEa710C332e0DB84dd498a4A46b2AD1AdA57a3", "0xd9d8Ed59dB0c202e23da97A05e0FB47fb78C4134", "0xfbEb50896cDe08EF8e7A1102Db5033dfB9822e02"], { deployer, kind: "uups" });
};
