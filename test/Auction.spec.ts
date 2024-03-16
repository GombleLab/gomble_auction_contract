import {expect} from "chai";
import {ethers} from "hardhat";
import {
  Auction, Auction__factory,
  Betting, Betting__factory, OGSpaceship, OGSpaceship__factory,
} from "../typechain-types";
import type {Signer} from "ethers";
import {AbiCoder} from "ethers";
import {advanceBlock, getRandomUint256, makeBettingMessage} from "./utils";

interface AuctionInfo {
  auctionId: number,
  numWinners: number,
  tokenIds: number[],
}

describe("Auction Contract Test", function () {
  const auctionInfos: AuctionInfo[] = [
    {
      auctionId: 1,
      numWinners: 10,
      tokenIds: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    },
    {
      auctionId: 2,
      numWinners: 20,
      tokenIds: [
        10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29
      ],
    },
    {
      auctionId: 3,
      numWinners: 30,
      tokenIds: [
        30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
        50, 51, 52, 53, 54, 55, 56, 57, 58, 59
      ],
    }
  ];
  const baseUrl = `https://baseUrl.com/`;
  const tokenIds = auctionInfos.reduce((acc, auctionInfo) => acc.concat(auctionInfo.tokenIds), []);
  const uris = tokenIds.map(tokenId => `${baseUrl}${tokenId}`);
  let ogSpacesShip: OGSpaceship;
  let auction: Auction;
  let owner: Signer;
  let user1: Signer;
  let user2: Signer;
  let user3: Signer;
  let user4: Signer;
  let user5: Signer;
  let user6: Signer;

  beforeEach(async () => {
    [owner, user1, user2, user3, user4, user5, user6] = await ethers.getSigners();
    ogSpacesShip = await new OGSpaceship__factory(owner).deploy('OG SPACESHIP', 'OG SPACESHIP');
    await ogSpacesShip.waitForDeployment();
    await ogSpacesShip.initialize(await owner.getAddress());
    auction = await new Auction__factory(owner).deploy();
    await auction.waitForDeployment();
    await auction.initialize(await owner.getAddress(), await ogSpacesShip.getAddress());
    await ogSpacesShip.bulkMint(
      await auction.getAddress(),
      tokenIds,
      uris
    );
  });

  describe("registerAuction", () => {
    it("success to register", async () => {
      const nowBlockNumber = await ethers.provider.getBlockNumber();
      const firstAuctionInfo = auctionInfos[0];
      const startBlock = nowBlockNumber + 10;
      const endBlock = startBlock + 10;
      await auction.registerAuction(firstAuctionInfo.auctionId, startBlock, endBlock, firstAuctionInfo.tokenIds, firstAuctionInfo.numWinners);
      const auctionInfo = await auction.auctionInfoMap(firstAuctionInfo.auctionId);
      expect(auctionInfo.id).to.eq(firstAuctionInfo.auctionId);
      expect(auctionInfo.startBlock).to.eq(startBlock);
      expect(auctionInfo.endBlock).to.eq(endBlock);
      expect(auctionInfo.numWinners).to.eq(firstAuctionInfo.numWinners);
    });

    // TODO: 실패 케이스
  });

  describe("bid", () => {
    let nowBlockNumber;
    let auctionId;
    let numWinners;
    const diff = 10;
    let startBlock;
    let endBlock;
    beforeEach(async () => {
      nowBlockNumber = await ethers.provider.getBlockNumber();
      auctionId = 1;
      numWinners = 3;
      startBlock = nowBlockNumber + diff;
      endBlock = startBlock + diff;
      await auction.registerAuction(auctionId, startBlock, endBlock, [0, 1, 2], numWinners);
      await advanceBlock(diff);
    });

    it("failed: invalid auction", async () => {
      await expect(auction.connect(user1).bid(3, {value: ethers.parseEther('1')})).to.be.revertedWith('Invalid Auction');
    });

    it("failed: not auction time", async () => {
      await advanceBlock(diff*2);
      await expect(auction.connect(user1).bid(auctionId, {value: ethers.parseEther('1')})).to.be.revertedWith('Not Auction Time');
    });

    it("failed: insufficient amount", async () => {
      await auction.connect(user1).bid(auctionId, {value: ethers.parseEther('1')});
      await expect(auction.connect(user2).bid(auctionId, {value: ethers.parseEther('1')})).to.be.revertedWith('Insufficient Amount');
    });

    /*
    1. user1 bid 0.1 -> minimumBid 0.1 / bidding size 1 / user1
    2. user2 bid 0.2 -> minimumBid 0.1 / bidding size 2 / user2, user1
    3. user3 bid 0.5 -> minimumBid 0.1 / bidding size 3 / user3, user2, user1
    4. user4 bid 0.3 -> minimumBid 0.2 / bidding size 3 / user3, user4, user2
    5. user5 bid 0.6 -> minimumBid 0.3 / bidding size 3 / user5, user3, user4
    6. user6 bid 0.2 -> fail
     */
    it("scenario", async () => {
      await auction.connect(user1).bid(auctionId, {value: ethers.parseEther('0.1')});
      expect(await auction.minimumBidMap(auctionId)).to.eq(ethers.parseEther('0.1'));
      expect((await auction.getTopBiddings(auctionId)).length).to.eq(1);
      expect(Array.from(await auction.getTopBiddings(auctionId))[0].user).to.eq(await user1.getAddress());

      await auction.connect(user2).bid(auctionId, {value: ethers.parseEther('0.2')});
      expect(await auction.minimumBidMap(auctionId)).to.eq(ethers.parseEther('0.1'));
      expect((await auction.getTopBiddings(auctionId)).length).to.eq(2);
      expect(Array.from(await auction.getTopBiddings(auctionId))[0].user).to.eq(await user2.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[1].user).to.eq(await user1.getAddress());

      await auction.connect(user3).bid(auctionId, {value: ethers.parseEther('0.5')});
      expect(await auction.minimumBidMap(auctionId)).to.eq(ethers.parseEther('0.1'));
      expect((await auction.getTopBiddings(auctionId)).length).to.eq(3);
      expect(Array.from(await auction.getTopBiddings(auctionId))[0].user).to.eq(await user3.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[1].user).to.eq(await user2.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[2].user).to.eq(await user1.getAddress());

      await auction.connect(user4).bid(auctionId, {value: ethers.parseEther('0.3')});
      expect(await auction.minimumBidMap(auctionId)).to.eq(ethers.parseEther('0.2'));
      expect((await auction.getTopBiddings(auctionId)).length).to.eq(3);
      expect(Array.from(await auction.getTopBiddings(auctionId))[0].user).to.eq(await user3.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[1].user).to.eq(await user4.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[2].user).to.eq(await user2.getAddress());

      await auction.connect(user5).bid(auctionId, {value: ethers.parseEther('0.6')});
      expect(await auction.minimumBidMap(auctionId)).to.eq(ethers.parseEther('0.3'));
      expect((await auction.getTopBiddings(auctionId)).length).to.eq(3);
      expect(Array.from(await auction.getTopBiddings(auctionId))[0].user).to.eq(await user5.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[1].user).to.eq(await user3.getAddress());
      expect(Array.from(await auction.getTopBiddings(auctionId))[2].user).to.eq(await user4.getAddress());

      await expect(auction.connect(user6).bid(auctionId, {value: ethers.parseEther('0.2')})).to.be.revertedWith('Insufficient Amount');
    });

    // TODO: 실패 케이스
  });

  describe("endAuction", () => {
    it("failed: invalid auction", async () => {
      await expect(auction.endAuction(30)).to.be.revertedWith('Invalid Auction');
    });

    it("failed: auction not over", async () => {
      const nowBlockNumber = await ethers.provider.getBlockNumber();
      const auctionInfo = auctionInfos[0];
      const diff = 10;
      const startBlock = nowBlockNumber + diff;
      const endBlock = startBlock + diff;
      await auction.registerAuction(auctionInfo.auctionId, startBlock, endBlock, auctionInfo.tokenIds, auctionInfo.numWinners);
      await expect(auction.endAuction(auctionInfo.auctionId)).to.be.revertedWith('Auction Not Over');
    });

    it("failed: auction ended", async () => {
      const nowBlockNumber = await ethers.provider.getBlockNumber();
      const auctionInfo = auctionInfos[0];
      const diff = 10;
      const startBlock = nowBlockNumber + diff;
      const endBlock = startBlock + diff;
      await auction.registerAuction(auctionInfo.auctionId, startBlock, endBlock, auctionInfo.tokenIds, auctionInfo.numWinners);
      await advanceBlock(endBlock - startBlock + diff);
      await auction.endAuction(auctionInfo.auctionId);
      await expect(auction.endAuction(auctionInfo.auctionId)).to.be.revertedWith('Auction Ended');
    });

    it("numWinners > top biddings", async () => {
      const nowBlockNumber = await ethers.provider.getBlockNumber();
      const auctionInfo = auctionInfos[0];
      const diff = 10;
      const startBlock = nowBlockNumber + diff;
      const endBlock = startBlock + diff;
      await auction.registerAuction(auctionInfo.auctionId, startBlock, endBlock, auctionInfo.tokenIds, auctionInfo.numWinners);
      await advanceBlock(endBlock - startBlock);

      await auction.connect(user1).bid(auctionInfo.auctionId, {value: ethers.parseEther('0.1')});
      await auction.connect(user2).bid(auctionInfo.auctionId, {value: ethers.parseEther('0.2')});
      await auction.connect(user3).bid(auctionInfo.auctionId, {value: ethers.parseEther('0.3')});
      await auction.connect(user4).bid(auctionInfo.auctionId, {value: ethers.parseEther('0.4')});

      await advanceBlock(diff);
      await auction.endAuction(auctionInfo.auctionId);

      expect((await auction.auctionInfoMap(1)).ended).to.be.true;
      expect(await ogSpacesShip.ownerOf(auctionInfo.tokenIds[0])).to.eq(await user4.getAddress());
      expect(await ogSpacesShip.ownerOf(auctionInfo.tokenIds[1])).to.eq(await user3.getAddress());
      expect(await ogSpacesShip.ownerOf(auctionInfo.tokenIds[2])).to.eq(await user2.getAddress());
      expect(await ogSpacesShip.ownerOf(auctionInfo.tokenIds[3])).to.eq(await user1.getAddress());
    });
  });

  describe("getter", () => {
    it('getBiddingHistory', async () => {
      const auctionInfo = auctionInfos[0];
      const nowBlockNumber = await ethers.provider.getBlockNumber();
      const diff = 100;
      const startBlock = nowBlockNumber + diff;
      const endBlock = startBlock + diff;
      await auction.registerAuction(auctionInfo.auctionId, startBlock, endBlock, auctionInfo.tokenIds, auctionInfo.numWinners);
      await advanceBlock(diff);

      const biddingCount = 50;
      for(let index = 0; index < biddingCount; index++) {
        await auction.connect(user1).bid(auctionInfo.auctionId, {value: ethers.parseEther(String(0.1 * (index + 1)))});
      }

      expect(await auction.getBiddingHistorySize(auctionInfo.auctionId)).to.eq(biddingCount);
      expect((await auction.getBiddingHistory(auctionInfo.auctionId)).length).to.eq(biddingCount);
      expect((await auction.getPartialBiddingHistory(auctionInfo.auctionId, 10, 20)).length).to.eq(10);
    });
  });
});
