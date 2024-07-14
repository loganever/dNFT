// SPDX-License-Identifier: MIT
<<<<<<< HEAD
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract DynamicNFT is VRFConsumerBase, ERC721Enumerable, Ownable{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint8;

    // VRF Variables
    bytes32 public keyHash;
    uint256 public  fee;
    uint256 public randomResult;

    // ERC721 Variables

    // Token Data
    uint256 public TOKEN_PRICE;
    uint256 public MAX_TOKENS;
    uint256 public MAX_MINTS;

    // Metadata
    string public _baseTokenURI;

    // Maps
    mapping(uint256 => uint256) public randomMap; // maps a tokenId to a random number
    mapping(bytes32 => uint256) public requestMap; // maps a requestId to a tokenId

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: sepolia
     * Chainlink VRF Coordinator address: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     * LINK token address:                	0x779877A7B0D9E8603169DdbD7836e478b4624789
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor(
        address _link,
        address _coordinator,
        bytes32 _keyhash,
        uint256 _fee,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 tokenPrice,
        uint256 maxTokens,
        uint256 maxMints
    )
    VRFConsumerBase(_coordinator, _link)
    ERC721(name, symbol)
    {
        // Chainlink setters
        keyHash = _keyhash;
        fee = _fee;

        // ERC721 setters
        setTokenPrice(tokenPrice);
        setMaxTokens(maxTokens);
        setMaxMints(maxMints);
        setBaseURI(baseURI);
    }

    /* ========== ERC721 FUNCTIONS ========== */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxMints(uint256 maxMints_) public onlyOwner {
        MAX_MINTS = maxMints_;
    }

    function setTokenPrice(uint256 tokenPrice_) public onlyOwner {
        TOKEN_PRICE = tokenPrice_;
    }

    function setMaxTokens(uint256 maxTokens_) public onlyOwner {
        MAX_TOKENS = maxTokens_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mintTokens(uint256 numberOfTokens) public payable {
        require(numberOfTokens <= MAX_MINTS, "Can only mint max purchase of tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);

                // request a random number from VRF oracle
                bytes32 requestId = getRandomNumber();
                // map request to tokenId
                requestMap[requestId] = mintIndex;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // construct metdata from tokenId
        return constructTokenURI(tokenId);
    }

    function constructTokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        // get random number from map
        uint256 randomNumber = getRandomNumber();
        // build tokenURI from randomNumber
        string memory randomTokenURI = string(abi.encodePacked(_baseTokenURI, randomNumber.toString(), ".png"));

        // metadata
        string memory name = string(abi.encodePacked("token #", tokenId.toString()));
        string memory description = "A dynamic NFT";

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', randomTokenURI, '"}')
                    )
                )
            )
        );
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        // constrain random number between 1-10
        uint256 modRandom = randomResult % 10 + 1;
        // get tokenId that created the request
        uint256 tokenId = requestMap[requestId];
        // store random result in token image map
        randomMap[tokenId] = modRandom;
=======
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

contract DynamicSvgNft is ERC721 {
    // mint
    // store SVG information somewhere
    // some logic to say "Show X Image" or "Show Y Image", switching the token URI

    uint256 private s_tokenCounter;
    string private i_lowImageURI;
    string private i_highImageURI;

    mapping(uint256 => int256) private s_tokenIdToHighValue;
    AggregatorV3Interface internal immutable i_priceFeed;
    event CreatedNFT(uint256 indexed tokenId, int256 highValue);

    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("Dynamic SVG NFT", "DSN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_lowImageURI = svgToImageURI(lowSvg);
        i_highImageURI = svgToImageURI(highSvg);
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function mintNft(int256 highValue) public {
        s_tokenIdToHighValue[s_tokenCounter] = highValue;
        emit CreatedNFT(s_tokenCounter, highValue);
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = i_lowImageURI;
        if (price >= s_tokenIdToHighValue[tokenId]) {
            imageURI = i_highImageURI;
        }
        else{
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
        
        // string concatenations, make JSON file on chain, name like in ERC721.sol, abi.encodePacked from Ethereum CheatSheet
    }

    function getLowSVG() public view returns (string memory) {
        return i_lowImageURI;
    }

    function getHighSVG() public view returns (string memory) {
        return i_highImageURI;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
>>>>>>> e93cdff (add data)
    }
}