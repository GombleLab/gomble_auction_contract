import {task} from "hardhat/config";
import {ContractConfig, network} from "./types";
import {bnbMainnetConfig, bnbTestnetConfig} from "./constant";

const AUCTION_ADDRESS = '0x538629A9Eb540f1E9977db5e2462215d5058C431';

task('auction-registerAuction')
  .setAction(async ({}, hre) => {
    const auction = await hre.ethers.getContractAt('Auction', AUCTION_ADDRESS);
    const tokenIds = [
      70
    ];
    const nowBlock = await hre.ethers.provider.getBlockNumber();
    console.log(`nowBlock ${nowBlock}`);
    const result = await auction.registerAuction(
      1,
      nowBlock + 10,
      nowBlock + 1000,
      tokenIds,
      1
    );
    console.log(`tx hash ${result.hash}`);
  });

task('auction-bid')
  .setAction(async ({}, hre) => {
    const auction = await hre.ethers.getContractAt('Auction', AUCTION_ADDRESS);
    const result = await auction.bid(1, {
      value: 3n * 10n ** 17n
    });
    console.log(`tx hash ${result.hash}`);
  });

task('auction-endAuction')
  .setAction(async ({}, hre) => {
    const auction = await hre.ethers.getContractAt('Auction', AUCTION_ADDRESS);
    const result = await auction.endAuction(1);
    console.log(`tx hash ${result.hash}`);
  });

task('auction-owner')
  .setAction(async ({}, hre) => {
    const auction = await hre.ethers.getContractAt('Auction', AUCTION_ADDRESS);
    const result = await auction.owner();
    console.log(`tx hash ${result}`);
  });
