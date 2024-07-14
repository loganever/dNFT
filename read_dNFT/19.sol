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
            )
        );
    }

    function _shape(bytes32 seed) private pure returns(string memory) {
        bytes16[2] memory xy = [bytes16(0), 0];
        assembly {
            mstore(xy, seed)
            mstore(add(xy, 16), seed)
        }
        
        return string(
            abi.encodePacked(
                "<rect fill='hsla(",(uint256(seed) % 360).toString(),",60%,55%,.95)' width='512' height='512' x='",(uint128(xy[0]) % 2048).toString(),"' y='",(uint128(xy[1]) % 2048).toString(),"'/>"
            )
        );
    }

    function _svg() private view returns(string memory) {
        string memory shapes = "";

        for (uint256 i = 16; i > 0;)
            shapes = string(
                abi.encodePacked(
                    shapes,
                    _shape(blockhash(block.number - i--)),
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
                        '"description":"A dynamic NFT, changing dynamically based on the 16 most recent blocks on the chain.\\n',
                            'Every cube is representing a block, positioned and colored based on the block hash.\\n\\n',
                            'All of the item metadata of this NFT lives on the blockchain.",',  
                        '"image_data":', '"', _svg(), '",',
                        '"attributes":', _attributes(), 
                        '}')))
                )
            );
    }
}