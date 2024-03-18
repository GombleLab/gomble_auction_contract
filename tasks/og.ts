import {task} from "hardhat/config";
import {ContractConfig, network} from "./types";
import {bnbMainnetConfig, bnbTestnetConfig} from "./constant";

const OG_SPACESHIP_ADDRESS = '0x027163A126eEDB6d1156bb69d0Cf6b74b50fbfC2';

task('og-bulkMint')
  .setAction(async ({}, hre) => {
    const og = await hre.ethers.getContractAt('OGSpaceship', OG_SPACESHIP_ADDRESS);
    const tokenIds = [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
      30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
      40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
      50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
      60, 61, 62, 63, 64, 65, 66, 67, 68, 69
    ];
    const uris = tokenIds.map(tokenId => `https://baseUrl.com/${tokenId}`);
    const result = await og.bulkMint('0xbE7582a8F090e64d2E2Ae225540D498f6747c23f',
      tokenIds,
      uris
      );
    console.log(`tx hash ${result.hash}`);
  });

task('og-transferOwnership')
  .setAction(async ({}, hre) => {
      const og = await hre.ethers.getContractAt('OGSpaceship', OG_SPACESHIP_ADDRESS);
      const result = await og.transferOwnership('');
      console.log(`tx hash ${result.hash}`);
  });