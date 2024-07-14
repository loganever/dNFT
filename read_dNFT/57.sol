pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TimeBasedNFTData is ERC721{

    mapping(uint => string[2]) tokenUri;

    address tokenContract;

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }


    function tokenURI(uint _tokenId) external view returns (string memory)  {
        uint8 hour = uint8((block.timestamp / 60 / 60) % 24);

        //calculate AM/PM in IST
        hour = hour + 5;

        if(hour > 24) {
            hour = hour - 24;
        }

        if(hour < 12 ) {
            return tokenUri[_tokenId][0];
        } else {
            return tokenUri[_tokenId][1];
        }

    }

    //TODO add restriction
    function mint(uint _tokenId, string memory _amURI, string memory _pmURI) public returns (bool){
        require(msg.sender == tokenContract, "Sorry Human, You can't call this function");
        tokenUri[_tokenId] = [_amURI, _pmURI];
        return true;
    }
}