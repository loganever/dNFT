// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DynamicNFT002 is ERC721Enumerable, Ownable {

  constructor() ERC721("BoxingNFT", "BoxN") {}

  // Array of Uris for the new assets metadata
  string[] levelUri;

  // create mapping of the Item for changing the asset
  struct Item { uint256 level; }

  // mapping  get filled with boxes erverytime someone claims a box
  mapping (uint256 => Item) public items;

  // mint function which sets the nft in initial state
  function mintNFT(string[] memory _levelURI) public {
    uint256 supply = totalSupply();

    // Set state to level 1
    Item memory newItem = Item(1);
    levelUri = _levelURI;

    // Add +1 to the supply of NFTs
    items[supply + 1] = newItem;
    _safeMint(msg.sender, supply + 1);
  }

  // Retrieve particular asset
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    // checks if this token exists
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

    // if level is not bigger than array
    return levelUri[block.number%levelUri.length];
  }

  // Change the Items's level
  function changeNFT(uint256 _tokenId, uint256 _level) public {
    //require(msg.sender == ownerOf(_tokenId), "You are not the owner of this NFT.");

    // dont allow higher level than array index
    Item storage currentItem = items[_tokenId];
    currentItem.level = _level;
  }

  string _contractURI = "";
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
    _transfer(from, to, tokenId);
  }
}