pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract lockerNFTData is ERC721 {

    mapping(uint => string[2]) tokenUri;
    mapping(uint => uint) amountUsedToMint;
    mapping(uint => bool) isWithdrawn;
    
    address tokenContractAddr;
    IERC721 tokenContract;
    
    constructor(address _tokenContract) {
        tokenContractAddr = _tokenContract;    
        tokenContract = IERC721(_tokenContract);
    }
    
    function tokenURI(uint _tokenId) external view returns (string memory)  {
        if(isWithdrawn[_tokenId]) {
            return tokenUri[_tokenId][0];
        } else {
            return tokenUri[_tokenId][1];
        }
    }
    
    function mint(uint _tokenId, string memory _notWithdrawn, string memory _withdrawn) public payable returns (bool){
        require(msg.sender == tokenContractAddr, "Sorry Human, You can't call this function");
        require(amountUsedToMint[_tokenId] == 0, "Token Already Exists"); //`NOT A GOOD` way to check :P
        require(msg.value > 0, "Should lock some amount to perform this action");
        tokenUri[_tokenId] = [_notWithdrawn, _withdrawn];
        amountUsedToMint[_tokenId] = msg.value;
        return true;
    }
    
    function withdraw(uint _tokenId) public {
        require(tokenContract.ownerOf(_tokenId) == msg.sender, "You are not the owner... Try polyjuice potion maybe??");
        require(isWithdrawn[_tokenId] == false, "Already Withdrawn");
        isWithdrawn[_tokenId] = true;
        (bool success, bytes memory data) = payable(msg.sender).call.value( amountUsedToMint[_tokenId])("");
        
        require(success, "Withdraw failed");
    }
    
}