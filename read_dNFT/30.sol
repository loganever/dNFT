pragma solidity >=0.8.0 <0.9.0;

contract dynamicNFT is ERC721("dynamic nft","dNFT"), Ownable {
    mapping(uint => address) tokenTypeToDataContract;
    mapping(uint => uint) tokenIdToType;
    
    event TokenType(uint , address , string );
    
    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(tokenIdToType[_tokenId] != 0)   {
            NFTData nftData = NFTData(tokenTypeToDataContract[tokenIdToType[_tokenId]]);    
            return nftData.getTokenURI(_tokenId);
        } else {
            return _tokenURIs[_tokenId];
        }
        
    }
    
    function mint(address _to, uint _tokenId, uint _tokenType, string memory _uri1, string memory _uri2) public payable onlyOwner {
        if(tokenTypeToDataContract[_tokenType] != address(0)) {
            tokenIdToType[_tokenId] = _tokenType; 
            NFTData nftData = NFTData(tokenTypeToDataContract[_tokenType]); 
            bool success = nftData.mint.value( msg.value)(_tokenId, _uri1, _uri2);
            require(success, "Data contract reverted");
        }
        _safeMint(_to, _tokenId);
    }
    
    
    function addType(uint _type, address _contractAddr, string memory _data) public onlyOwner {
        require(tokenTypeToDataContract[_type] == address(0), "Type already exists");
        tokenTypeToDataContract[_type] = _contractAddr;
        emit TokenType(_type, _contractAddr, _data);
    }
}