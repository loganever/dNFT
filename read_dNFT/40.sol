// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IIPDB.sol";

/**
 * @title IPDBNft
 */
contract IPDBNft is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private token_id_counter;
    string public contract_base_uri = "ipfs://";
    address public IPDB = 0x1Aa65998a6751464FACD2f62Fa28e5B0034496ca;
    address metadata_db;
    mapping(uint256 => bool) public token_freezed;
    // IPDB Contract
    IIPDB private ipdb;
    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {
        ipdb = IIPDB(IPDB);
        metadata_db = msg.sender;
    }

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return token_id_counter.current();
    }
    
    /*
        This method will allow change entire metadata IPDB database
    */
    function fixIPDB(address _newAddress) external onlyOwner {
        metadata_db = _newAddress;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        (string memory _tknMetadata,) = ipdb.get(metadata_db, Strings.toString(_tokenId));
        return string(abi.encodePacked(contract_base_uri, _tknMetadata));
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /*
        This method will mint a new token
    */
    function dropNFT() external onlyOwner {
        token_id_counter.increment();
        uint256 newTokenId = token_id_counter.current();
        _mint(msg.sender, newTokenId);
    }
}