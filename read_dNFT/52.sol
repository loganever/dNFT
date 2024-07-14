pragma solidity 0.7.4;

contract ERC721_DynamicURI is ERC721A, Ownable {


    //author = atak.eth


    using Strings for uint256;
    string baseURI;    

    uint256 public maximumSupply = 100;

    //Every token at least have this many states
    uint256 public globalMinState = 20;

    //Block between each state
    uint256 public blocksPerState = 1800;

    //Previous tokens held by the wallet
    mapping(address => uint256[]) internal ownersPreviousTokens;
    //Last transfered block for each NFT
    mapping(uint256 => uint256) internal lastTransferedBlock;
    //Exclusive tokens with more states than usual
    mapping(uint256 => uint256) public tokenMaxState;


 
    
    
    
    constructor() ERC721A("DynamicURI", "DynamicURI") {
        currentIndex++;
    }

    function changeMaxStateOfToken(uint256 _tokenId, uint256 _newMax) public onlyOwner{
        tokenMaxState[_tokenId] = _newMax;
    }

    function changeGlobalMinState(uint256 _newCount) public onlyOwner{
        globalMinState = _newCount;
    }

    function changeBlocksPerState(uint256 _newCount) public onlyOwner{
        blocksPerState = _newCount;
    }

    function getTokenState(uint256 tokenId) public view returns(uint256){

        uint256 blocksSinceLastTransfer = block.number - lastTransferedBlock[tokenId];
        uint256 stateCount = blocksSinceLastTransfer / blocksPerState;
        uint256 currentTokenState;


        if(stateCount == 0){
            stateCount=1;
        }else if(stateCount <= globalMinState){
            currentTokenState = stateCount;
        }else if(stateCount <= tokenMaxState[tokenId]){
            currentTokenState = stateCount;
        }else if(tokenMaxState[tokenId] == 0){
            currentTokenState = globalMinState;
        }else{
            currentTokenState = tokenMaxState[tokenId];
        }

        return currentTokenState;

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){

        return string(abi.encodePacked(baseURI, tokenId.toString(), "_", getTokenState(tokenId).toString(), ".json"));

    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        
        bool previouslyOwned = false;

        for(uint256 i = 0; i < ownersPreviousTokens[to].length; i++){
            if((ownersPreviousTokens[to])[i] == tokenId){
                previouslyOwned = true;
            }
        }

        

        if(previouslyOwned){
            lastTransferedBlock[tokenId] = block.number;
        }else{
            ownersPreviousTokens[to].push(tokenId);

            if(getTokenState(tokenId) > 0){
                lastTransferedBlock[tokenId] += blocksPerState;
            }
            
        }

        safeTransferFrom(from, to, tokenId, '');
    }




    function mint(uint256 amount) external onlyOwner {
        uint256 supply = currentIndex;

        require(supply + amount <= maximumSupply, "Exceeds maximum supply");

        for(uint256 i = currentIndex; i <= amount+currentIndex; i++){
            lastTransferedBlock[i] = block.number;
        }

        _safeMint(msg.sender, amount);
    }


    


    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

}