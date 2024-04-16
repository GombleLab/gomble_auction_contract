pragma solidity ^0.8.0;

interface IAuction {
    function bid(uint256 auctionId) external payable;
}
