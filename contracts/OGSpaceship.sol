pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OGSpaceship is ERC721URIStorage, OwnableUpgradeable {

    constructor(
        string memory name,
        string memory symbol
    ) public ERC721(name, symbol){}

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    function bulkMint(address to, uint256[] memory tokenIds, string[] memory uris) external onlyOwner {
        require(tokenIds.length == uris.length, 'Invalid Size');

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
            _setTokenURI(tokenIds[i], uris[i]);
        }
    }

    function bulkSetTokenURI(uint256[] memory tokenIds, string[] memory uris) external onlyOwner {
        require(tokenIds.length == uris.length, 'Invalid Size');

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);
        }
    }

    function _msgSender() internal view override(Context, ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

    function _contextSuffixLength() internal view override(Context, ContextUpgradeable) returns (uint256) {
        return super._contextSuffixLength();
    }
}
