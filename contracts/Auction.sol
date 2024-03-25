pragma solidity ^0.8.0;

import "./lib/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "hardhat/console.sol";
contract Auction is OwnableUpgradeable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;

    struct Bidding {
        uint256 id;
        address user;
        uint256 bidAmount;
        uint256 blockNumber;
    }

    struct AuctionInfo {
        uint256 id;
        uint256 startBlock;
        uint256 endBlock;
        uint256 numWinners;
        uint256[] tokenIds;
        bool set; // info set?
        bool ended;
    }

    event RegisterAuction(uint256 auctionId, uint256 startBlock, uint256 endBlock, uint256 numWinners, uint256[] tokenids);
    event Bid(uint256 auctionId, uint256 id, address user, uint256 bidAmount, uint256 blockNumber);
    event EndAuction(uint256 auctionId, uint256 numWinners);
    event TransferSuccessful(uint256 auctionId, address user, uint256 tokenId);
    event TransferFailed(uint256 auctionId, address user, uint256 tokenId);
    event BiddingRefund(address user, uint256 amount);
    event BiddingRefundFailed(address user, uint256 amount);

    mapping(uint256 => AuctionInfo) public auctionInfoMap;
    mapping(uint256 => Bidding[]) public topBiddingMap;
    mapping(uint256 => Bidding[]) public biddingMap;
    mapping(uint256 => uint256) public minimumBidMap;
    uint256 constant MINIMUM_GAP = 10 ** 15; // 0.1 BNB TODO: 0.001 Testnet, 0.1 Mainnet
    uint256 constant MINIMUM_BIDDING_AMOUNT = 10 ** 16; // 1 BNB TODO: 0.01 Testnet, 1 Mainnet
    IERC721 public ogSpaceship;

    function initialize(address initialOwner, address _ogSpaceship) external initializer {
        __Ownable_init(initialOwner);
        ogSpaceship = IERC721(_ogSpaceship);
    }

    function registerAuction(uint256 auctionId, uint256 startBlock, uint256 endBlock, uint256[] memory tokenIds, uint256 numWinners) external onlyOwner {
        require(numWinners <= 30, 'MAX 30');
        require(tokenIds.length == numWinners, 'Invalid Token Count');
        require(startBlock <= endBlock, 'Start > End');
        require(startBlock >= block.number, 'Start < Now');
        require(auctionId != 0 && auctionInfoMap[auctionId].id != auctionId, 'Invalid Auction Id');
        auctionInfoMap[auctionId] = AuctionInfo({
            id: auctionId,
            startBlock: startBlock,
            endBlock: endBlock,
            numWinners: numWinners,
            tokenIds: tokenIds,
            set: true,
            ended: false
        });
        minimumBidMap[auctionId] = MINIMUM_BIDDING_AMOUNT;
        emit RegisterAuction(auctionId, startBlock, endBlock, numWinners, tokenIds);
    }

    function bid(uint256 auctionId) external payable nonReentrant {
        AuctionInfo storage auctionInfo = auctionInfoMap[auctionId];
        require(auctionInfo.set, 'Invalid Auction');
        require(auctionInfo.startBlock <= block.number && auctionInfo.endBlock >= block.number, 'Not Auction Time');
        require(msg.value >= minimumBidMap[auctionId], "Insufficient Amount");

        Bidding[] storage topNBiddings = topBiddingMap[auctionId];

        Bidding memory newBid = Bidding({
            id: biddingMap[auctionId].length,
            user: msg.sender,
            bidAmount: msg.value,
            blockNumber: block.number
        });

        bool inserted = false;
        for (uint256 i = 0; i < topNBiddings.length; i++) {
            if (topNBiddings[i].bidAmount < newBid.bidAmount) {
                topNBiddings.push();
                for (uint256 j = topNBiddings.length - 1; j > i; j--) {
                    topNBiddings[j] = topNBiddings[j - 1];
                }
                topNBiddings[i] = newBid;
                inserted = true;
                break;
            }
        }

        if (!inserted && topNBiddings.length < auctionInfo.numWinners) {
            topNBiddings.push(newBid);
        }
        if (topNBiddings.length == auctionInfo.numWinners) {
            minimumBidMap[auctionId] = topNBiddings[topNBiddings.length - 1].bidAmount.add(MINIMUM_GAP);
        }
        if (topNBiddings.length > auctionInfo.numWinners) {
            Bidding memory outbid = topNBiddings[topNBiddings.length - 1];
            (bool success, ) = outbid.user.call{value: outbid.bidAmount}("");
            if (success) {
                emit BiddingRefund(outbid.user, outbid.bidAmount);
            } else {
                emit BiddingRefundFailed(outbid.user, outbid.bidAmount);
            }
            topNBiddings.pop();
            minimumBidMap[auctionId] = topNBiddings[topNBiddings.length - 1].bidAmount.add(MINIMUM_GAP);
        }

        biddingMap[auctionId].push(newBid);
        emit Bid(auctionId, newBid.id, newBid.user, newBid.bidAmount, newBid.blockNumber);
    }

    function endAuction(uint256 auctionId) external onlyOwner {
        AuctionInfo storage auctionInfo = auctionInfoMap[auctionId];
        require(auctionInfo.set, 'Invalid Auction');
        require(auctionInfo.endBlock < block.number, 'Auction Not Over');
        require(!auctionInfo.ended, 'Auction Ended');
        Bidding[] storage biddings = topBiddingMap[auctionId];

        for(uint256 i; i < biddings.length; i++) {
            try ogSpaceship.transferFrom(address(this), biddings[i].user, auctionInfo.tokenIds[i]) {
                emit TransferSuccessful(auctionId, biddings[i].user, auctionInfo.tokenIds[i]);
            } catch {
                emit TransferFailed(auctionId, biddings[i].user, auctionInfo.tokenIds[i]);
            }
        }
        auctionInfo.ended = true;
        emit EndAuction(auctionId, biddings.length);
    }

    function getTopBiddings(uint256 auctionId) external view returns (Bidding[] memory) {
        return topBiddingMap[auctionId];
    }

    function getTopNBiddingHistory(uint256 auctionId, uint256 n) external view returns (Bidding[] memory) {
        Bidding[] storage biddings = biddingMap[auctionId];

        // n이 실제 입찰 수보다 많을 경우, 실제 입찰 수를 사용
        if (n > biddings.length) {
            n = biddings.length;
        }

        Bidding[] memory topNBiddings = new Bidding[](n);
        for (uint256 i = 0; i < n; i++) {
            topNBiddings[i] = biddings[biddings.length - 1 - i];
        }
        return topNBiddings;
    }

    function getBiddingHistory(uint256 auctionId) external view returns (Bidding[] memory) {
        return biddingMap[auctionId];
    }

    // from <= index < to
    function getPartialBiddingHistory(uint256 auctionId, uint256 from, uint256 to) external view returns (Bidding[] memory) {
        require(from < to, "Invalid Range: from >= to");

        Bidding[] storage biddings = biddingMap[auctionId];
        require(from < biddings.length, "Invalid Range: 'from' is out of bounds");
        require(to <= biddings.length, "Invalid Range: 'to' is out of bounds");
        uint256 length = to - from;

        Bidding[] memory partialBiddings = new Bidding[](length);
        for (uint256 i = 0; i < length; i++) {
            partialBiddings[i] = biddings[biddings.length - 1 - (from + i)];
        }

        return partialBiddings;
    }

    function getBiddingHistorySize(uint256 auctionId) external view returns (uint256) {
        return biddingMap[auctionId].length;
    }

    function transferOgSpaceship(address to, uint256 tokenId) external onlyOwner {
        ogSpaceship.transferFrom(address(this), to, tokenId);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            to.call{value: address(this).balance}("");
        } else {
            to.call{value: amount}("");
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
