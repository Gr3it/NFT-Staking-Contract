// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MAX_MINT_PER_ADDRESS;

    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) public nbOfNFTsMintedBy;

    constructor(uint256 _maxSupply, uint256 _maxMintPerAddress)
        ERC721("Crypto Empire", "EMPIRE")
    {
        MAX_SUPPLY = _maxSupply;
        MAX_MINT_PER_ADDRESS = _maxMintPerAddress;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function MintToken(uint256 _quantity) external {
        require(
            _tokenIdCounter.current() + _quantity <= MAX_SUPPLY,
            "Mint quantity exceeds max supply"
        );
        require(
            nbOfNFTsMintedBy[msg.sender] + _quantity <= MAX_MINT_PER_ADDRESS,
            "Mint quantity exceeds allowance for this address"
        );
        require(_quantity > 0, "Need to mint at least 1 NFT");

        _mintQuantity(_quantity);
    }

    function _mintQuantity(uint256 _quantity) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            nbOfNFTsMintedBy[msg.sender]++;
            _mint(msg.sender, _tokenIdCounter.current());
        }
    }
}
