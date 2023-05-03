// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
//AJP Stablecoinpresale(V1) contract https://bscscan.com/address/0x9A858D24d58dD7B2ACcC0409C5A2De8eA81182DE
//AJP Stablecoinpresale(V2) contract: https://bscscan.com/address/0x80F81420DF8b9d7DFBa925a954aC6304A1c69A36#code
//AJP StabecoinLatest(V3) contract https://bscscan.com/address/0x1dd6f0610B42f09048913B525B112d6984452E5C#code
//AJP Presale with Vesting v1 = https://bscscan.com/address/0xE8D9401250ccD8C8e662FD0C33239B908D2227B3
const hre = require("hardhat");

async function main() {
  const pancakeswapTestnetRouter = '0xD99D1c33F9fC3444f8101754aBC46c52416550D1'; //BSC DEX
  const pancakeswapMainnetRouter = '0x10ED43C718714eb63d5aA57B78B54704E256024E'; //BSC DEX
  const ajiraPayTreasury = '0x69949ac6ec279D1eA6176c55393EaEA43dEf8Dec';
  const ajiraPayMainnetTreasury = '0xb00375686741591FeB3541e1740E75FE21CD9f31'
  const ajiraPayPresaleDurationInDays = 35;
  const ajiraPayFinalMainnetAddress = '0xC55b03dC07EC7Bb8B891100E927E982540f0d181'
  const quickSwapRouter = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff' //polygon DEX
  const sushiswapRouter = '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506' //Arbitrum DEX
  const uniswapV2Router = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D' //ETHEREUM MAINNET DEX

  //Airdrop Distributor Contract
  //const AjiraPayAirdropDristributor = await hre.ethers.getContractFactory('AjiraPayAirdropDistributor');
  //Presale Contract
  //const AjiraPayPresaleContract = await hre.ethers.getContractFactory('AjiraPayFinancePreSale');
  //Ajira Pay Finace Token Contract
  //const AjiraPayFinanceToken = await hre.ethers.getContractFactory('AjiraPayFinanceToken');
  //Ajira Pay Finance Stable Coin Presale Contract 
  //const AjiraPayFinanceStablecoinPresale = await hre.ethers.getContractFactory('AjiraPayFinanceStablecoinPresale');
//AJIRA PAY V2 MAINNET ADDRESS->AFTER SECOND AUDIT : 0x9DBC0Ad09184226313FbDe094E7c3DD75c94f997
//AJIRA PAY KAVA MAINNET STAKING = 0x894E327f11b09ab87Af86876dCfCEF40eA086f34
  const AjiraPayFinanceV2 = await hre.ethers.getContractFactory('AjiraPayFinanceTokenV2');
  //const AjiraPayFinanceKava = await hre.ethers.getContractFactory('AjiraPayFinance');

  const minRewarCap = 1;
  const maxRewardCap = 1000;
  const tokenDecimals = 18;

  // const ajiraPayFinanceToken = await AjiraPayFinanceToken.deploy(pancakeswapMainnetRouter, ajiraPayMainnetTreasury);

  // await ajiraPayFinanceToken.deployed();
  
  // console.log("Ajira Pay Finance Token deployed to:", ajiraPayFinanceToken.address);

  // const ajiraPayPresaleContract = await AjiraPayPresaleContract.deploy(ajiraPayFinalMainnetAddress, ajiraPayMainnetTreasury,ajiraPayPresaleDurationInDays);

  // await ajiraPayPresaleContract.deployed();

  // console.log("Ajira Pay Finance Presale Contract deployed to:", ajiraPayPresaleContract.address);

  // const ajiraPayAirdropDristributor = await AjiraPayAirdropDristributor.deploy(ajiraPayFinalMainnetAddress,ajiraPayMainnetTreasury,minRewarCap,maxRewardCap,tokenDecimals);

  // await ajiraPayAirdropDristributor.deployed();

  // console.log("Ajira Pay Airdrop Distributor deployed to:", ajiraPayAirdropDristributor.address);

  // const ajiraPayStablecoinPresale = await AjiraPayFinanceStablecoinPresale.deploy(ajiraPayFinalMainnetAddress,ajiraPayMainnetTreasury);

  // await ajiraPayStablecoinPresale.deployed();

  // console.log("Ajira Pay Finance StableCoin presale contract deployed to:", ajiraPayStablecoinPresale.address);

    // const ajiraPayVestedPresale = await AjiraPayPresaleVesting.deploy(ajiraPayFinalMainnetAddress,ajiraPayMainnetTreasury);

    // await ajiraPayVestedPresale.deployed();

    // console.log("Ajira Pay Finance vested presale contract deployed to:", ajiraPayVestedPresale.address);

    const ajiraPayFinanceV2 = await AjiraPayFinanceV2.deploy(sushiswapRouter,ajiraPayMainnetTreasury);

    await ajiraPayFinanceV2.deployed();

    console.log("Ajira Pay Finance V2 Uniswap contract deployed to:", ajiraPayFinanceV2.address);

    // const ajiraPayFinance = await AjiraPayFinanceKava.deploy();

    // await ajiraPayFinance.deployed();

    // console.log("Ajira Pay Finance Kava contract deployed to:", ajiraPayFinance.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
