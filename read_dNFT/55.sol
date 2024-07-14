//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract TestNFT is ERC721URIStorage,Ownable{

  uint public counter;

  constructor() ERC721("NFT","NFT"){
      counter = 0;
  }

  function createNFTS(string memory tokenURI) onlyOwner public returns (uint){
      uint tokenId = counter;
      _safeMint(msg.sender, tokenId);
      _setTokenURI(tokenId, tokenURI);
      counter++;

      return tokenId;
  }

  function setTokenURI(uint tokenId, string memory tokenURI) onlyOwner public{
      _setTokenURI(tokenId, tokenURI);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (block.number % 3 == 0) {
            return "https://ipfs.io/ipfs/QmP3TpPig2St3nTwvi9TFAGdv6YTew5k4pmC1yFtaLwFFo";
        }
        else{
            return "https://ipfs.io/ipfs/QmP3TpPig2St3nTwvi9TFAGdv6YTew5k4pmC1yFtaLwFFo";
        }
    }

  function burn(uint256 tokenId) public virtual{
      require(_isApprovedOrOwner(msg.sender,tokenId),"You are not the owner or approved!");
      super._burn(tokenId);
  }

}
