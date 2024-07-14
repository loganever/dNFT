// SPDX-License-Identifier:MIT

pragma solidity >0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract dynamicNFT is ERC721{

    uint256 public tokenCounter;
    string private lowUri;
    string private highUri;
    string private constant base64Encoded="data:image/svg+xml;base64,";
    AggregatorV3Interface internal immutable priceFeed;
    mapping(uint256=>int256) private tokenIdToHighValue;

    event NFTCreated(uint256 indexed tokenId, uint256 highValue);

    constructor(address _priceFeed, string memory lowSVG, string memory highSVG) ERC721("DynamicNFT", "DSN"){
        tokenCounter=0;
        lowUri=svgToImageUri(lowSVG);
        highUri=svgToImageUri(highSVG);
        priceFeed=AggregatorV3Interface(_priceFeed);
    }

    function mint(uint256 _value)public {
        _safeMint(msg.sender, tokenCounter);
        tokenCounter++;
        emit NFTCreated(tokenCounter, _value);
    }

    function svgToImageUri(string memory _svg)public pure returns(string memory){
        string memory svgEncoded=Base64.encode(bytes(string(abi.encodePacked(_svg))));
        return string(abi.encodePacked(base64Encoded, svgEncoded));
    }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        string memory imageURI = lowUri;
        if (price >= tokenIdToHighValue[tokenId]) {
            imageURI = highUri;
        }
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function getLowUri()public view returns(string memory){
        return lowUri;
    }

    function getHighUri()public view returns(string memory){
        return highUri;
    }

    function getpriceFeed()public view returns(AggregatorV3Interface){
        return priceFeed;
    }
}