pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}
