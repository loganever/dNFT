pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract priceBasedNFTData is ERC721{

    mapping(uint => string[2]) tokenUri;
    mapping(uint => uint) priceTarget;
    
    
    using SafeMath for uint;
    IERC721 tokenContract;
    constructor(address _tokenContract) {
        tokenContract = IERC721(_tokenContract);
    }
    
    function tokenURI(uint _tokenId) external view returns (string memory)  {
        uint chainId;
        AggregatorV3Interface priceFeed;
        assembly {
            chainId := chainid()
        }

        if(chainId == 1) { //Mainnet
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        } else if (chainId == 137) { //MATIC mainnet
            priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        } else if(chainId == 4) { //rinkeby
            priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        }

        (   uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound ) = priceFeed.latestRoundData();

        if(uint(price).div(10**18) <= priceTarget[_tokenId]) {
            return tokenUri[_tokenId][0];
        } else {
            return tokenUri[_tokenId][1];
        }

    }
    
    
    function mint(uint _tokenId, string memory _lessThanTarget, string memory _greaterThanTarget) public returns (bool){
        require(msg.sender == address(tokenContract), "Sorry Human, You can't call this function");
        priceTarget[_tokenId] = 10000; //1000 USD //default value
        tokenUri[_tokenId] = [_lessThanTarget, _greaterThanTarget];
        return true;
    }
    
    function changePriceTarget(uint _tokenId, uint _priceOfETHInUsd) public {
        require(msg.sender == tokenContract.ownerOf(_tokenId), "401 : Not allowed, Try Alohomora");
        priceTarget[_tokenId] = _priceOfETHInUsd;
    }
    
    function test() public view returns (int) {
        AggregatorV3Interface priceFeed;
        uint chainId;
        assembly {
            chainId := chainid()
        }

        if(chainId == 1) { //Mainnet
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        } else if (chainId == 137) { //MATIC mainnet
            priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        } else if(chainId == 4) { //rinkeby
            priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        }

        (   uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound ) = priceFeed.latestRoundData();
            
            return price;
    }
    
}