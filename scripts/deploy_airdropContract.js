// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const ajiraPayTokenAddress = '0xE9680C408202d0f949C672E0fe304f4A78C9c591';
  const minRewarCap = 1;
  const maxRewardCap = 1000;
  const tokenDecimals = 18;
  const AjiraPayAirdropDristributor = await hre.ethers.getContractFactory('AjiraPayAirdropDistributor')
  const ajiraPayAirdropDristributor = await AjiraPayAirdropDristributor.deploy(ajiraPayTokenAddress,minRewarCap,maxRewardCap,tokenDecimals);

  await ajiraPayAirdropDristributor.deployed();

  console.log("Ajira Pay deployed to:", ajiraPayAirdropDristributor.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
