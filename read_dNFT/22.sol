<<<<<<< HEAD
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/**
 * @dev A dynamic NFT, built with Tableland and Chainlink VRF for mutating an NFT at some time interval
 */
contract dynNFT is ERC721, IERC721Receiver, Ownable, AutomationCompatible {
    // General dNFT and Chainlink data
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter; // Counter for the current token ID
    uint256 lastTimeStamp; // Most recent timestamp at which the collection was updated
    uint256 interval; // Time (in seconds) for how frequently the NFTs should change
    mapping(uint256=>uint256) public stage; // Track the token ID to its current stage
    // Tableland-specific information
    uint256 private _flowersTableId; // A table ID -- stores NFT attributes
    uint256 private _tokensTableId; // A table ID -- stores the token ID and its current stage
    string private constant _FLOWERS_TABLE_PREFIX = "flowers"; // Table prefix for the flowers table
    string private constant _TOKENS_TABLE_PREFIX = "tokens"; // Table prefix for the tokens table
    string private _baseURIString; // The Tableland gateway URL

    constructor(string memory baseURIString) ERC721("dNFTs", "dNFT") {
        interval = 30; // Hardcode some interval value (in seconds) for when the dynamic NFT should "grow" into the next stage
        lastTimeStamp = block.timestamp; // Track the most recent timestamp for when a dynamic VRF update occurred
        _baseURIString = baseURIString;
    }

    /**
     * @dev Initializes Tableland tables that track & compose NFT metadata
     */
    function initTables() public onlyOwner {
        // Create a "flowers" table to track a predefined set of NFT traits, which will be composed based on VRF-mutated `stage`
        _flowersTableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id int primary key," // An ID for the trait row
                "stage text not null," // The trait for what flower growth stage (seed, purple_seedling, purple_blooms)
                "color text not null," // The value of the trait's color (unknown, purple, etc.)
                "cid text not null", // For each trait's image, store a pointer to the IPFS CID
                _FLOWERS_TABLE_PREFIX // Prefix (human readable name) for the table
            )
        );
        // Initalize values for the flowers table -- do this by creating an array of comma separated string values for each row
        string[] memory values = new string[](3);
        values[0] = "0,'seed','unknown','QmNpAiQZjkoLCb3MRR8jFJEDpw7YWcSSGMPLzyU5rvNTNg'"; // Notice the single quotes around text
        values[1] = "1,'purple_seedling','purple','QmRkq5EeKE5wKAuZNjaDFxtqpLQP3cFJVVWNu3sqy452uA'";
        values[2] = "2,'purple_blooms','purple','QmRkq5EeKE5wKAuZNjaDFxtqpLQP3cFJVVWNu3sqy452uA'";
        // Insert these values into the flowers table
        TablelandDeployments.get().mutate(
            address(this),
            _flowersTableId,
            SQLHelpers.toBatchInsert(
                _FLOWERS_TABLE_PREFIX,
                _flowersTableId,
                "id,stage,color,cid", // Columns to insert into, as a comma separated string of column names
                // Data to insert, where each array value is a comma-separated table row
                values
            )
        );
        // Create a "tokens" table to track the NFT token ID and its corresponding flower stage ID
        _tokensTableId = TablelandDeployments.get().create(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id int primary key," // Track the NFT token ID
                "stage_id int not null", // Dynamically track the current seed stage; maps to the "flowers" table
                _TOKENS_TABLE_PREFIX
=======
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DynamicNftUriGetter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/Base64.sol";

contract PolygonCubes is DynamicNftUriGetter {
    using Strings for uint256;
    using Strings for uint128;

    constructor() {
    }

    function _attributes() private view returns(string memory) {
        return string(
            abi.encodePacked(
                '[',
                    '{"trait_type":"Block Number","value":"',block.number.toString(),'"}'
                ']'
>>>>>>> e93cdff (add data)
            )
        );
    }

<<<<<<< HEAD
    /**
     * @dev Chainlink VRF function that gets called upon a defined time interval within Chainlink's Upkeep setup
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the `checkData` in this example. The `checkData` is defined when the Upkeep was registered.
    }

    /**
     * @dev If the conditions in `checkUpkeep` are met, then `performUpkeep` gets called and mutates the NFT's value
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        // Revalidate the upkeep
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            // Grow the flower for all flowers in the collection
            // Warning -- this is not an efficient since it will iterate across the entire collection; shown for demo purposes
            for(uint256 i; i < _tokenIdCounter.current(); i++) {
                growFlower(i);
            }
        }
        // We don't use the `performData` in this example. The `performData` is generated by the Keeper's call to your `checkUpkeep` function
    }

    /**
     * @dev If the conditions in `checkUpkeep` are met, then `performUpkeep` gets called and mutates the NFT's value
     *
     * to - the address the NFT should be minted to
     */
    function mint(address to) external {
        // Get the current value for the token supply and increment it
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        // Mint the NFT to the `to` address
        _safeMint(to, tokenId);
        // Insert the metadata into the "tokens" Tableland table with a default "seed" value
        // The seed is in the "flowers" table with a stage ID of `0` -- insert the token ID and this stage ID
        TablelandDeployments.get().mutate(
            address(this),
            _tokensTableId,
            SQLHelpers.toInsert(
                _TOKENS_TABLE_PREFIX,
                _tokensTableId,
                "id," // Token ID column
                "stage_id", // Flower stage column (i.e., it starts as a seed and then grows)
                // Data to insert -- the `tokenId` and `stage` as comma separated values
                string.concat(
                    Strings.toString(tokenId),
                    ",",
                    Strings.toString(0) // Value of `seed` is at `stage_id` `0`
                )
=======
    function _shape(bytes32 seed) private pure returns(string memory) {
        bytes16[2] memory xy = [bytes16(0), 0];
        assembly {
            mstore(xy, seed)
            mstore(add(xy, 16), seed)
        }
        
        return string(
            abi.encodePacked(
                "<rect fill='hsla(",(uint256(seed) % 360).toString(),",60%,55%,.95)' width='512' height='512' x='",(uint128(xy[0]) % 2048).toString(),"' y='",(uint128(xy[1]) % 2048).toString(),"'/>"
>>>>>>> e93cdff (add data)
            )
        );
    }

<<<<<<< HEAD
    /**
     * @dev Grow the flower -- that is, mutate the NFT's `stage` to the next available stage
     *
     * _tokenId - the token ID to mutate
     */
    function growFlower(uint256 _tokenId) public {
        // The maximum number of stages is set to `2`, so don't mutate an NFT if it's already hit its capacity
        if (stage[_tokenId] >= 2) {
            return;
        }
        // Get the current stage of the flower, and add 1, which moves it to the next stage
        uint256 newVal = stage[_tokenId] + 1;
        // Update the stage within the `stage` mapping
        stage[_tokenId] = newVal;
        // Update the stage within the Tableland "tokens" table, where the `stage_id` will change the `tokenURI` metadata response
        TablelandDeployments.get().mutate(
            address(this),
            _tokensTableId,
            SQLHelpers.toUpdate(
                _TOKENS_TABLE_PREFIX,
                _tokensTableId,
                string.concat("stage_id=", Strings.toString(newVal)), // Column to update
                // token to update
                string.concat(
                    "id=",
                    Strings.toString(_tokenId)
                )
            )
        );
    }

    /**
     * @dev Returns the base URI for NFT token metadata, which is set to the Tableland hosted gateway
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
    }

    /**
     * @dev Allows the contract's owner to update the `_baseURIString`, if needed
     */
    function setBaseURI(string memory baseURIString) external onlyOwner {
        _baseURIString = baseURIString;
    }

    /**
     * @dev Returns the NFT's metadata
     *
     * tokenId - the token ID for metadata retrieval
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Ensure the token exists
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // Set the `baseURI`
        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return "";
        }

        /**
         * A SQL query to JOIN two tables and compose the metadata across a 'tokens' and 'flowers' table in ERC-721 compliant schema
         *
         * Essentially, the metadata is built for each NFT using the tables. As values get updated via `growFlower`,
         * the associated metadata query will automatically read those values from the table; this `tokenURI` query
         * is future-proof upon table mutations.
         *
         * The query forms a `json_object` with two nested `json_object` values in a `json_array`. The top-level metadata fields include
         * the `name`, `image`, and `attributes`, where the `attributes` hold the composed data from the "tokens" and "flowers" tables.
         * For the `image`, there were images previously uploaded to IPFS and stored in the format `<IPFS_CID>/<stage>.jpg`.
         *
         *   select
         *   json_object(
         *       'name', 'Friendship Seed #' || <tokens_table>.id,
         *       'image', 'ipfs://' || cid || '/' || stage || '.jpg',
         *       'attributes', json_array(
         *           json_object(
         *               'display_type','string',
         *               'trait_type','Flower Stage',
         *               'value',stage
         *           ),
         *           json_object(
         *               'display_type','string',
         *               'trait_type','Flower Color',
         *               'value',color
         *           )
         *       )
         *   )
         *   from
         *   <tokens_table>
         *   join <flowers_table> on <tokens_table>.stage_id = <flowers_table>.id
         *   where <tokens_table>.id = <tokenId>
         *
         * The <tokens_table> and <flowers_table> are places in which the *actual* table name (`prefix_tableId_chainId`)
         * should be used. The rest of the statement should be URL encoded to ensure proper support from marketplaces
         * and browsers -- the end result of performing these steps is what is assigned to `query`.
         */

        // Create references to the Tableland table names (`prefix_tableId_chainId`) for the "tokens" and "flowers" tables
        string memory tokensTable = SQLHelpers.toNameFromId(_TOKENS_TABLE_PREFIX, _tokensTableId);
        string memory flowersTable = SQLHelpers.toNameFromId(_FLOWERS_TABLE_PREFIX, _flowersTableId);
        // Create the read query noted above, which forms the ERC-721 compliant metadata
        string memory query = string.concat(
            "select%20json_object%28'name'%2C'Friendship%20Seed%20%23'%7C%7C",
            tokensTable,
            ".id%2C'image'%2C'ipfs%3A%2F%2F'%7C%7Ccid%7C%7C'%2F'%7C%7Cstage%7C%7C'.jpg'%2C'attributes'%2Cjson_array%28json_object%28'display_type'%2C'string'%2C'trait_type'%2C'Flower%20Stage'%2C'value'%2Cstage%29%2Cjson_object%28'display_type'%2C'string'%2C'trait_type'%2C'Flower%20Color'%2C'value'%2Ccolor%29%29%29%20from%20",
            tokensTable,
            "%20join%20",
            flowersTable,
            "%20on%20",
            tokensTable,
            ".stage_id%20%3D%20",
            flowersTable,
            ".id%20where%20",
            tokensTable,
            ".id%3D"
        );
        // Return the `baseURI` with the appended query string, which composes the token ID with its metadata attributes
        return
            string(
                abi.encodePacked(
                    baseURI,
                    query,
                    Strings.toString(tokenId),
                    "%20group%20by%20",
                    tokensTable,
                    ".id"
                )
            );
    }

    /**
     * @dev Returns the total supply for the collection
     */
    function totalSupply() external view returns(uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Required in order for the contract to own the Tableland tables, which are ERC-721 tokens
     */
    function onERC721Received(address, address, uint256, bytes calldata) override external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
=======
    function _svg() private view returns(string memory) {
        string memory shapes = "";

        for (uint256 i = 16; i > 0;)
            shapes = string(
                abi.encodePacked(
                    shapes,
                    _shape(blockhash(block.number%10240 - i--)),
                    _shape(blockhash(block.number - i--)),
                    _shape(blockhash(block.number - i--)),
                    _shape(blockhash(block.number - i--)),
                    _shape(blockhash(block.number - i--)),
                    _shape(blockhash(block.number - i--)),
                    _shape(blockhash(block.number - i--)),
                    _shape(blockhash(block.number - i--))
                )
            );


        return string(
            abi.encodePacked(
                "<svg width='2048' height='2048' viewPort='0 0 2048 2048' style='background:#181a21' xmlns='http://www.w3.org/2000/svg'>",
                "<style>rect{transform:translate(-256px,-256px)}</style>",
                shapes,
                "</svg>"
            )
        );
    }

    function uri(uint256) public view override returns (string memory) {
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(string(abi.encodePacked(
                        '{"name":"Polygon Cubes",', 
                        '"description":"A dynamic NFT.",',
                        '"image_data":', '"', _svg(), '",',
                        '"attributes":', _attributes(), 
                        '}')))
                )
            );
    }
>>>>>>> e93cdff (add data)
}