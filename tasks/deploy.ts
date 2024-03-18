import {task} from "hardhat/config";
import {ContractConfig, network} from "./types";
import {bnbMainnetConfig, bnbTestnetConfig} from "./constant";

task('deploy-auction')
  .setAction(async ({}, hre) => {

    const network = hre.network.name as network;
    let config: ContractConfig
    if (network == 'bnb_mainnet') {
      config = bnbMainnetConfig;
    } else if (network == 'bnb_testnet') {
      config = bnbTestnetConfig;
    } else {
      throw new Error(`INVALID NETWORK ${network}`);
    }

    const auction = await hre.ethers.deployContract('Auction');
    await auction.waitForDeployment();
    console.log(`Auction deployed to ${auction.target}`);

    const tx = await auction.initialize(config.auction.owner, config.auction.og);
    await tx.wait();
    console.log(`Auction initialized at ${tx.hash}`);
  });

task('deploy-og')
  .setAction(async ({}, hre) => {

    const network = hre.network.name as network;
    let config: ContractConfig
    if (network == 'bnb_mainnet') {
      config = bnbMainnetConfig;
    } else if (network == 'bnb_testnet') {
      config = bnbTestnetConfig;
    } else {
      throw new Error(`INVALID NETWORK ${network}`);
    }

    const og = await hre.ethers.deployContract('OGSpaceship', [
      config.og.name,
      config.og.symbol
    ]);
    await og.waitForDeployment();
    console.log(`OGSpacesShip deployed to ${og.target}`);
    const tx = await og.initialize(config.og.owner);
    await tx.wait();
    console.log(`OGSpacesShip initialized at ${tx.hash}`);
  });
