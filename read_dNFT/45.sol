// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

//import Open Zepplin contracts
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract NFT is ERC721 {

    using Strings for uint256;

    uint256 private _tokenIds;
    string public baseExtension = ".json";

    //create two URIs. 
    //the contract will switch between these two URIs
    string aUri = "URIaaaaaaaaaa";
    string bUri = "URIbbbbbbbbbb";
    
    constructor() ERC721("NAMEOFTOKEN", "TOKENSYMBOL") {}
    
    //use the mint function to create an NFT
    function mint()
    public
    returns (uint256)
    {
        _tokenIds += 1;
        _mint(msg.sender, _tokenIds);
        return _tokenIds;
    }
    
    //the token URI function will contain the logic to determine what URI to show
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        //if the block timestamp is divisible by 2 show the aURI
        if (block.timestamp % 2 == 0) {
            return bytes(aUri).length > 0
            ? string(abi.encodePacked(aUri, tokenId.toString(), baseExtension))
            : "";
        }else{
            return bytes(bUri).length > 0
                ? string(abi.encodePacked(bUri, tokenId.toString(), baseExtension))
                : "";
        }
            
    }
}