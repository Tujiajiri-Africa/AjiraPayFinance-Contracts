// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  //const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  //const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  //const lockedAmount = hre.ethers.utils.parseEther("1");

  //const Lock = await hre.ethers.getContractFactory("Lock");
  //const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

  const pancakeswapTestnetRouter = '0x6725F303b657a9451d8BA641348b6761A6CC7a17';
  const pancakeswapMainnetRouter = '0x10ED43C718714eb63d5aA57B78B54704E256024E';
  const ajiraPayTreasury = '0x4F6c0B945D00f55B6D5a7cEd1eCAA0690675527A';

  //Airdorop Distributor
  const AjiraPayAirdropDristributor = await hre.ethers.getContractFactory('AjiraPayAirdropDistributor');
  const minRewarCap = 1;
  const maxRewardCap = 1000;
  const tokenDecimals = 18;

  const AjiraPayFinanceToken = await hre.ethers.getContractFactory('AjiraPayFinanceToken')
  const ajiraPayFinanceToken = await AjiraPayFinanceToken.deploy(pancakeswapMainnetRouter, ajiraPayTreasury);

  await ajiraPayFinanceToken.deployed();
  //await ajiraPayFinanceToken.initDex(pancakeswapTestnetRouter);
  console.log("Ajira Pay Finance Token deployed to:", ajiraPayFinanceToken.address);

  const ajiraPayAirdropDristributor = await AjiraPayAirdropDristributor.deploy(ajiraPayFinanceToken.address,minRewarCap,maxRewardCap,tokenDecimals);

  await ajiraPayAirdropDristributor.deployed();

  console.log("Ajira Pay Airdrop Distributor deployed to:", ajiraPayAirdropDristributor.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
