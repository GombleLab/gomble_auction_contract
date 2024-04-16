pragma solidity ^0.8.0;

import "../interfaces/IAuction.sol";

contract BidCallContractMocked {
    address public auctionAddress;
    constructor(
        address auction
    ) public {
        auctionAddress = auction;
    }

    function bid(uint256 auctionId) external payable {
        IAuction(auctionAddress).bid(auctionId);
    }
}
