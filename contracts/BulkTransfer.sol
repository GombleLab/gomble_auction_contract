pragma solidity ^0.8.0;
import "./interfaces/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BulkTransfer is OwnableUpgradeable, IERC721Receiver {
    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    function bulkNftTransfer(address token, address[] memory targets, uint256[] memory tokenIds) external onlyOwner {
        require(targets.length == tokenIds.length, 'Invalid Size');

        for(uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).safeTransferFrom(address(this), targets[i], tokenIds[i]);
        }
    }

    function withdraw(address token, address to, uint256[] memory tokenIds) external onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(token).safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
