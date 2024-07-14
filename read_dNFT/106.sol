// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
* Dynamic NFTs Smart Contract
* This contract allows us to return live the metadata (properties) of the NFTs (in this case the properties of my NFTs are level and life)
* The dependencies that our contract inherits from Oppen Zepelin are:
* - The ERC-721 dependency
* - The counters dependency: SC that allows us to implement accounting functions (increase/decrement a counter, get the current value of the counter,...)
* - The Strings dependency: SC that is used to manipulate strings
* - The Base64 dependency: SC that allows us to format in base64
*/
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract DynamicNFTs is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private s_tokenIdCounter;

    // The imported @String.sol dependency will be used for numbers of the type @uint128 and @uint256
    using Strings for uint256;
    using Strings for uint128;

    /**
    * This @struct will be used to build the metadata of the NFTs
    * An @uint128 type is used for the @level and @life variables, since this way we save space by executing
    * both variables in the same memory slot (in our case it is enough that the size is @uint128)
    */
    struct DataNFT {
        string name;
        string description;
        string imageIPFS;
        uint128 level;
        uint128 life;
    }

    // This mapping is used to associate the NFTs with their respective data
    mapping(uint256 => DataNFT) public tokensData;

    // For this case I used some self-made Deers NFTs
    constructor() ERC721("Deers", "DR") {}

    function safeMint(string memory p_name, string memory p_description, string memory p_imageIPFS, uint128 p_level, uint128 p_life) public {
        s_tokenIdCounter.increment();
        uint256 currentId = s_tokenIdCounter.current();

        tokensData[currentId] = DataNFT(
            p_name,
            p_description,
            p_imageIPFS,
            p_level,
            uint128(block.timestamp) + p_life
        );

        _safeMint(msg.sender, currentId);
    }

    function incrementLevel(uint256 p_tokenId) public {
        tokensData[p_tokenId].level++;
    }

    function decrementLevel(uint256 p_tokenId) public {
        require(tokensData[p_tokenId].level > 0, "Level is zero");
        tokensData[p_tokenId].level--;
    }

    // This function returns the URL of the metadata. We override it with the Smart Contract ERC-721.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return getTokenURI(tokenId);
    }

    function getTokenURI(uint256 p_tokenId) internal view returns (string memory){
        DataNFT memory data = tokensData[p_tokenId];

        // With these variables we can know the hours, minutes and seconds that our NFT has left to live
        uint256 diffSeconds = data.life - uint128(block.timestamp);
        uint256 _hours = diffSeconds / 1 hours;
        uint256 _minutes = (diffSeconds % 1 hours) / 1 minutes;
        uint256 _seconds = ((diffSeconds % 1 hours) % 1 minutes) / 1 seconds;

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "', data.name, '",',
                '"description": "', data.description, '",',
                '"image": "ipfs://',  data.imageIPFS, '",',
                '"attributes": [',
                    '{',
                        '"trait_type": "Level",',
                        '"value": "', data.level.toString(), '"',
                    '},',
                    '{',
                        '"trait_type": "Life",',
                        '"value": "', _hours.toString(), ':', _minutes.toString(), ':', _seconds.toString(), '"'
                    '}',
                ']'
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }
}