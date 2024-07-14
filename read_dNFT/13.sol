<<<<<<< HEAD
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

error ERC721Metadata__URI_QueryFor_NonExistentToken();

contract DynamicOnchainNft is ERC721 {
    // Events
    event CreatedNFT(uint256 indexed tokenId, int256 breakpointPrice);

    // NFT variables
    uint256 private s_tokenCounter; // Defaults to 0
    string private s_sadTokenUri;
    string private s_happyTokenUri;
    mapping(uint256 => int256) private s_tokenIdToBreakpointPrice;

    // Interface
    AggregatorV3Interface internal immutable i_priceFeed;

    constructor(address priceFeedAddress, string memory happyTokenUri, string memory sadTokenUri) ERC721("Dynamic On-chain NFT", "DON") {
        s_happyTokenUri = happyTokenUri;
        s_sadTokenUri = sadTokenUri;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function mintNft(int256 breakpointPrice) public {
        s_tokenIdToBreakpointPrice[s_tokenCounter] = breakpointPrice;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++ ;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory theUri) {
        if(!_exists(tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }

        (,int256 price, , ,) = i_priceFeed.latestRoundData();
        uint256 decimals = uint256(i_priceFeed.decimals());
        int256 priceWithoutDecimals = price / int256(10**decimals);
        theUri = s_happyTokenUri;
        if(priceWithoutDecimals < s_tokenIdToBreakpointPrice[tokenId]){
            theUri = s_sadTokenUri;
        }
    }

    function getPriceFeed() public view returns(AggregatorV3Interface){
        return i_priceFeed;
    }

    function getLatestPriceOfAsset() public view returns(uint256){
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        uint256 decimals = uint256(i_priceFeed.decimals());
        return uint256(price) / (10**decimals);
    }

    function getHappyTokenUri() public view returns (string memory) {
        return s_happyTokenUri;
    }

    function getSadTokenUri() public view returns (string memory) {
        return s_sadTokenUri;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getBreakPointPrice(uint256 tokenId) public view returns(int256){
        return s_tokenIdToBreakpointPrice[tokenId];
    }
}

=======
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IWeatherFeed.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Consensus2021ChainlinkWeatherNFT is ERC721, Ownable, ChainlinkClient {
    using Strings for string;
    bool public overRide;
    string public overRideWeather;
    uint256 public tokenCounter; 
    address public weatherFeedAddress; 
    uint256 public response;

    bytes32 public jobId;
    address public oracle;
    uint256 public fee; 

    mapping(bytes32 => address) public requestIdToAttemptee;
    mapping(string => string) public weatherToWeatherURI;
    mapping(uint256 => string) public overRideTokenIdToWeatherURI;
    mapping(uint256 => bool) public tokenIdTaken;
    event attemptedPassword(bytes32 requestId);

    constructor(address _link, address _weatherFeed, address _oracle, bytes32 _jobId, uint256 _fee) public
        ERC721("Consensus2021ChainlinkWeatherNFT", "wNFT")
    {   
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        weatherFeedAddress = _weatherFeed;
        weatherToWeatherURI["Thunderstorm"] = "https://ipfs.io/ipfs/QmP3TpPig2St3nTwvi9TFAGdv6YTew5k4pmC1yFtaLwFFo";
        weatherToWeatherURI["Drizzle"] = "https://ipfs.io/ipfs/QmP3TpPig2St3nTwvi9TFAGdv6YTew5k4pmC1yFtaLwFFo";
        weatherToWeatherURI["Rain"] = "https://ipfs.io/ipfs/QmP3TpPig2St3nTwvi9TFAGdv6YTew5k4pmC1yFtaLwFFo";
        weatherToWeatherURI["Snow"] = "https://ipfs.io/ipfs/QmaeYdJ8EydzUGdGQGkPNkSBEQUmwRmAv2QWq1VTfsfrdk";
        weatherToWeatherURI["Atmosphere"] = "https://ipfs.io/ipfs/QmbNEeSa8pZrepYhGnnhSCmABZXymvc7YR5JKFT7TuYuYY";
        weatherToWeatherURI["Clear"] = "https://ipfs.io/ipfs/QmcKEV1xJQ3ZCyPsDPJHsuEZnF95hNZf8S3rBEvzCKwjof";
        weatherToWeatherURI["Clouds"] = "https://ipfs.io/ipfs/QmbNEeSa8pZrepYhGnnhSCmABZXymvc7YR5JKFT7TuYuYY";
        overRide = true;
        overRideTokenIdToWeatherURI[0] = weatherToWeatherURI["Rain"];
        overRideTokenIdToWeatherURI[1] = weatherToWeatherURI["Clear"];
        overRideTokenIdToWeatherURI[2] = weatherToWeatherURI["Clouds"];
        overRideTokenIdToWeatherURI[3] = weatherToWeatherURI["Snow"];
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function mintWeatherNFT() public onlyOwner{
        _safeMint(msg.sender, tokenCounter);
        tokenCounter = tokenCounter + 1;
    }

    function setOverRide(uint256 _overRide) public onlyOwner {
        if (_overRide == 0){
            overRide = false;
        }
        if (_overRide == 1){
            overRide = true;
        }
    }

    function setWeatherURI(string memory weather, string memory tokenUri, uint256 tokenId) public onlyOwner {
        weatherToWeatherURI[weather] = tokenUri;
        overRideTokenIdToWeatherURI[tokenId] = tokenUri;
    }

    function tokenURI(uint256 tokenId) public view override (ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(overRide == true){
            return overRideTokenIdToWeatherURI[tokenId % 4];
        }
        return weatherToWeatherURI[IWeatherFeed(weatherFeedAddress).weather()%2+1];
    }

    function attemptPassword(string memory password) public returns (bytes32 requestId){
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add("password", password);
        requestId = sendChainlinkRequestTo(oracle, req, fee);
        requestIdToAttemptee[requestId] = msg.sender;
        emit attemptedPassword(requestId);
    }

    function fulfill(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId)
    {   
        response = _data;
        if(response == 0){
            require(tokenIdTaken[0] == false, "This token is taken!");
            safeTransferFrom(ownerOf(0), requestIdToAttemptee[_requestId], 0);
            tokenIdTaken[0] = true; 
        }
        if (response == 1){
                require(tokenIdTaken[1] == false, "This token is taken!");
                safeTransferFrom(ownerOf(1), requestIdToAttemptee[_requestId], 1);
                tokenIdTaken[1] = true; 
        }
        if (response == 2){
                require(tokenIdTaken[2] == false, "This token is taken!");
                safeTransferFrom(ownerOf(2), requestIdToAttemptee[_requestId], 2);
                tokenIdTaken[2] = true; 
        }
        if (response == 3){
                require(tokenIdTaken[3] == false, "This token is taken!");
                safeTransferFrom(ownerOf(3), requestIdToAttemptee[_requestId], 3);
                tokenIdTaken[3] = true; 
        }
    }    

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
>>>>>>> e93cdff (add data)
