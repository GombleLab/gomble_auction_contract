pragma solidity ^0.8.0;

import "./lib/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TestAuction is OwnableUpgradeable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;

    struct Bidding {
        uint256 id;
        address user;
        uint256 bidAmount;
        uint256 blockNumber;
        uint256 blockTimestamp;
    }

    struct AuctionInfo {
        uint256 id;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 numWinners;
        uint256[] tokenIds;
        bool set; // info set?
        bool ended;
    }

    event RegisterAuction(uint256 auctionId, uint256 startTimestamp, uint256 endTimestamp, uint256 numWinners, uint256[] tokenids);
    event Bid(uint256 auctionId, uint256 id, address user, uint256 bidAmount, uint256 blockNumber, uint256 blockTimestamp);
    event EndAuction(uint256 auctionId, uint256 numWinners);
    event TransferWinnerBadgeSuccessful(uint256 auctionId, address user, uint256 tokenId);
    event TransferWinnerBadgeFailed(uint256 auctionId, address user, uint256 tokenId);
    event WinnerRefundSuccessful(uint256 auctionId, address user, uint256 amount);
    event WinnerRefundFailed(uint256 auctionId, address user, uint256 amount);
    event BiddingRefund(address user, uint256 amount);
    event BiddingRefundFailed(address user, uint256 amount);

    mapping(uint256 => AuctionInfo) public auctionInfoMap;
    mapping(uint256 => Bidding[]) public topBiddingMap;
    mapping(uint256 => Bidding[]) public biddingMap;
    mapping(uint256 => uint256) public minimumBidMap;
    uint256 constant MINIMUM_GAP = 10 ** 17; // 0.1 BNB
    uint256 constant MINIMUM_BIDDING_AMOUNT = 10 ** 18; // 1 BNB
    IERC721 public winnerBadge;

    function initialize(address initialOwner, address _winnerBadge) external initializer {
        __Ownable_init(initialOwner);
        winnerBadge = IERC721(_winnerBadge);
    }

    function registerAuction(uint256 auctionId, uint256 startTimestamp, uint256 endTimestamp, uint256[] memory tokenIds, uint256 numWinners) external onlyOwner {
        require(numWinners <= 30, 'MAX 30');
        require(tokenIds.length == numWinners, 'Invalid Token Count');
        require(startTimestamp <= endTimestamp, 'Start > End');
        require(startTimestamp >= block.timestamp, 'Start < Now');
        require(auctionId != 0 && auctionInfoMap[auctionId].id != auctionId, 'Invalid Auction Id');
        auctionInfoMap[auctionId] = AuctionInfo({
            id: auctionId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            numWinners: numWinners,
            tokenIds: tokenIds,
            set: true,
            ended: false
        });
        minimumBidMap[auctionId] = MINIMUM_BIDDING_AMOUNT;
        emit RegisterAuction(auctionId, startTimestamp, endTimestamp, numWinners, tokenIds);
    }

    function bid(uint256 auctionId) external payable nonReentrant {
        require(msg.sender == tx.origin, 'Contract Not Allowed');
        AuctionInfo storage auctionInfo = auctionInfoMap[auctionId];
        require(auctionInfo.set, 'Invalid Auction');
        require(auctionInfo.startTimestamp <= block.timestamp && auctionInfo.endTimestamp >= block.timestamp, 'Not Auction Time');
        require(msg.value >= minimumBidMap[auctionId], "Insufficient Amount");

        Bidding[] storage topNBiddings = topBiddingMap[auctionId];

        Bidding memory newBid = Bidding({
            id: biddingMap[auctionId].length,
            user: msg.sender,
            bidAmount: msg.value,
            blockNumber: block.number,
            blockTimestamp: block.timestamp
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
        emit Bid(auctionId, newBid.id, newBid.user, newBid.bidAmount, newBid.blockNumber, newBid.blockTimestamp);
    }

    function endAuction(uint256 auctionId) external onlyOwner {
        AuctionInfo storage auctionInfo = auctionInfoMap[auctionId];
        require(auctionInfo.set, 'Invalid Auction');
        require(auctionInfo.endTimestamp < block.timestamp, 'Auction Not Over');
        require(!auctionInfo.ended, 'Auction Ended');
        Bidding[] storage biddings = topBiddingMap[auctionId];

        for(uint256 i; i < biddings.length; i++) {
            Bidding memory bidding = biddings[i];
            try winnerBadge.transferFrom(address(this), bidding.user, auctionInfo.tokenIds[i]) {
                emit TransferWinnerBadgeSuccessful(auctionId, bidding.user, auctionInfo.tokenIds[i]);
            } catch {
                emit TransferWinnerBadgeFailed(auctionId, bidding.user, auctionInfo.tokenIds[i]);
            }

            (bool refundSuccess, ) = bidding.user.call{value: bidding.bidAmount}("");
            if (refundSuccess) {
                emit WinnerRefundSuccessful(auctionId, bidding.user, bidding.bidAmount);
            } else {
                emit WinnerRefundFailed(auctionId, bidding.user, bidding.bidAmount);
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

    function transferWinnerBadge(address to, uint256 tokenId) external onlyOwner {
        winnerBadge.transferFrom(address(this), to, tokenId);
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
