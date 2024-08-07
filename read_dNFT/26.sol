// SPDX-License-Identifier: MIT
<<<<<<< HEAD

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ChicToken.sol";

//0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61

contract ChicBoxNFT is ERC721, VRFConsumerBaseV2, KeeperCompatibleInterface, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private tokenIdCounter;

    event RandomWordsRequested (uint256 requestId);

    struct TokenDetail {
        uint256 creationTimestamp;
        uint256 randomSeed;
        bool isDevToken;
    }


    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 public s_randomWord;

    uint256 private s_upkeepInterval;
    uint256 private s_prevUpkeepTimestamp;
    string [] s_tokenUris = [
        "https://ipfs.io/ipfs/QmdqJovbm31rKcYvm1WyFMQUgNqu5Y5xW5kfLKQY1RSEpy/0.json",
        "https://ipfs.io/ipfs/QmdqJovbm31rKcYvm1WyFMQUgNqu5Y5xW5kfLKQY1RSEpy/1.json",
        "https://ipfs.io/ipfs/QmdqJovbm31rKcYvm1WyFMQUgNqu5Y5xW5kfLKQY1RSEpy/2.json",
        "https://ipfs.io/ipfs/QmdqJovbm31rKcYvm1WyFMQUgNqu5Y5xW5kfLKQY1RSEpy/3.json"
    ];
    mapping (uint256 => TokenDetail) private s_tokenDetails;
    uint256 private immutable i_maxUserSupply;
    uint256 private immutable i_nftLevelUpIntervalDays;
    ChicToken private immutable i_chicToken;


    constructor (
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane, // keyHash
        uint32 _callbackGasLimit,

        uint256 _upkeepInterval,
        uint256 _nftLevelUpIntervalDays,
        uint256 _maxUserSupply,
        address _chicTokenAddress
    ) ERC721 ("Dynamic Chic NFT", "dCHIC") VRFConsumerBaseV2 (_vrfCoordinatorV2) {

        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);

        s_upkeepInterval = _upkeepInterval;
        i_nftLevelUpIntervalDays = _nftLevelUpIntervalDays /* (* 1 days) */;
        s_prevUpkeepTimestamp = block.timestamp;
        i_maxUserSupply = _maxUserSupply;
        i_chicToken = ChicToken(_chicTokenAddress);
    }


    function setUpkeepInterval (uint256 _newInterval) public onlyOwner {
        require (_newInterval > 30, "ChicBoxNFT: Upkeep interval cannot be less than 30 seconds");
        s_upkeepInterval = _newInterval;
    }


    function safeMint (address _to) public {
        uint256 newId = tokenIdCounter.current();
        tokenIdCounter.increment();

        require (newId < i_maxUserSupply, "dNFT: Max supply limit has been reached.");
        require (i_chicToken.balanceOf(_to) >= 1 * 10 ** i_chicToken.decimals(), "dNFT: User must have atleast 1 CHIC.");

        s_tokenDetails[newId].creationTimestamp = block.timestamp;

        s_tokenDetails[newId].randomSeed = uint256(keccak256(abi.encodePacked(
            s_randomWord,
            block.timestamp,
            newId,
            block.prevrandao,
            _to
        ))) % 1000;

        s_tokenDetails[newId].isDevToken = false;
        s_randomWord /= 10;

        _safeMint(_to, newId);

    }


    function devMint (address _to) public onlyOwner() {
        uint256 newId = tokenIdCounter.current();
        tokenIdCounter.increment();
        s_tokenDetails[newId].creationTimestamp = block.timestamp;
        s_tokenDetails[newId].isDevToken = true;

        _safeMint(_to, newId);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool tokensMinted = tokenIdCounter.current() > 0;
        bool intervalPassed = block.timestamp - s_prevUpkeepTimestamp > s_upkeepInterval;
        bool allTokensEvolved = _computeTokenLevel(tokenIdCounter.current() - 1) >= 2;

        upkeepNeeded = intervalPassed && tokensMinted && (!allTokensEvolved);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        s_prevUpkeepTimestamp = block.timestamp;

        if(upkeepNeeded) {
            uint256 requestId = i_vrfCoordinator.requestRandomWords(
                i_gasLane,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                i_callbackGasLimit,
                NUM_WORDS
            );

            emit RandomWordsRequested(requestId);
        }
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWord = randomWords[0];
    }


    function getTokenDetails (uint256 _tokenId) public view returns (TokenDetail memory) {
        require (_tokenId >= 0 && _tokenId < tokenIdCounter.current(), "ChicBoxNFT: Token with supplied id doesn't exist.");
        return s_tokenDetails[_tokenId];
    }

    function getTimeLeftTillNextLevelUp (uint256 _tokenId) public view returns (uint256) {
        require (_tokenId >= 0 && _tokenId < tokenIdCounter.current(), "ChicBoxNFT: Token with supplied id doesn't exist.");
        require (_computeTokenLevel(_tokenId) < 2, "ChicBoxNFT: Token has already reached max level.");
        return _computeTokenLevel(_tokenId) == 0
                ? (s_tokenDetails[_tokenId].creationTimestamp + i_nftLevelUpIntervalDays - block.timestamp)
                : (s_tokenDetails[_tokenId].creationTimestamp + 2 * i_nftLevelUpIntervalDays - block.timestamp);
    }

    function getTimeTillNextUpkeep() public view returns (int256) {
        return int256( s_upkeepInterval - (block.timestamp - s_prevUpkeepTimestamp));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return s_tokenUris[_computeTokenLevel(_tokenId)];
    }

    function _computeTokenLevel (uint256 _id) internal view returns (uint256) {
        require (_id >= 0 && _id < tokenIdCounter.current(), "ChicBoxNFT: Token with supplied id doesn't exist.");
        if (s_tokenDetails[_id].isDevToken) {
            return 2;
        }
        else if (block.timestamp < (s_tokenDetails[_id].creationTimestamp + i_nftLevelUpIntervalDays)) {
            return 0;
        }
        else if (
            block.timestamp > (s_tokenDetails[_id].creationTimestamp + i_nftLevelUpIntervalDays) &&
            block.timestamp <= (s_tokenDetails[_id].creationTimestamp + 2 * i_nftLevelUpIntervalDays)
        ) {
            return 1;
        }
        else {
            return s_tokenDetails[_id].randomSeed < 700 ? 2 : 3;
        }
    }

    function getMaxUserSupply () public view returns (uint256) {
        return i_maxUserSupply;
    }

=======
pragma solidity ^0.8.15;

import "base64-sol/base64.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Dynamic NFT
/// @author mektigboy
/// @notice Mint NFTs from the "DynamicNFT" collection.
/// @dev Uses libraries from Chainlink and OpenZeppelin.
contract DynamicNFT is ERC721, Ownable {
    uint256 s_tokenCounter;
    string s_lowImageURI;
    string s_highImageURI;

    mapping(uint256 => int256) s_tokenIdToHighValue;

    AggregatorV3Interface internal immutable i_priceFeed;

    event NFTCreated(uint256 indexed tokenId, int256 highValue);

    constructor(
        address priceFeedAddress,
        string memory lowSVG,
        string memory highSVG
    ) ERC721("Dynamic NFT", "DHL") {
        s_tokenCounter = 0;
        s_lowImageURI = convertSVGToImageURI(lowSVG);
        s_highImageURI = convertSVGToImageURI(highSVG);
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function convertSVGToImageURI(string memory anySVG)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory base64SVGEncoded = Base64.encode(
            bytes(string(abi.encodePacked(anySVG)))
        );
        return string(abi.encodePacked(baseURL, base64SVGEncoded));
    }

    // Let the minters choose the value.
    function mintNFT(int256 highValue) public {
        s_tokenIdToHighValue[s_tokenCounter] = highValue;
        _safeMint(msg.sender, s_tokenCounter);
        emit NFTCreated(s_tokenCounter, highValue);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );
        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = s_lowImageURI;
        if (price+10 >= s_tokenIdToHighValue[tokenId]) {
            imageURI = s_highImageURI;
        }
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '","description":"An NFT that changes based on the Chainlink Feed.",',
                                '"attributes":[{"trait":"Epic","value":1000}],"image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getLowSVG() public view returns (string memory) {
        return s_lowImageURI;
    }

    function getHighSVG() public view returns (string memory) {
        return s_highImageURI;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
>>>>>>> e93cdff (add data)
}