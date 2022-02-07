pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract TestNFT is ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public cost = 1 ether;
    uint16 public maxSupply = 2000;
    uint8 public maxMintAmount = 5;
    uint8 public maxMintAmountOg = 3;


    bool public paused = false;

    mapping(address => bool) public whitelistedWallet;
    mapping(address => bool) public whitelistedMinted;
    mapping(address => bool) public ogWallet;
    mapping(address => uint) public ogMintedAmount;
    

    constructor(string memory _name, string memory _symbol, string memory _initBaseURI ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    modifier baseCheck (uint8 _mintAmount){
        require(!paused);
        require(_mintAmount > 0 && _mintAmount <= maxMintAmount);             
        require(totalSupply() + _mintAmount <= maxSupply);
        require(msg.value >= cost * _mintAmount);
        _;
    }

    /* 
    public
    1 nft per 1 transaction
    */
    function publicMint(address _mintWallet) public payable baseCheck(1) {
        _safeMint(_mintWallet, totalSupply() + 1); 
    }
    
    /* 
    whitelist
    no more than 1 nft for wallet
    */
    function whitelistMint(address _mintWallet) public payable baseCheck(1) {
        require(whitelistedWallet[_mintWallet], "You aren't on the whitelist");
        require(!whitelistedMinted[_mintWallet], "You alredy minted your NFT");

        _safeMint(_mintWallet, totalSupply() + 1);
        whitelistedMinted[_mintWallet] = true;
    }

    /*
    og mint
    og - role for special members of project 
    no more then 3 nft per wallet 
    1-3 nft per transaction
    */
    function ogMint(address _mintWallet, uint8 _mintAmount) public payable baseCheck(_mintAmount) {
        require(ogWallet[_mintWallet], "You aren't on the OG");
        require(ogMintedAmount[_mintWallet] <= maxMintAmountOg, "You alredy minted max of NFT");
        require(ogMintedAmount[_mintWallet] + _mintAmount <= maxMintAmountOg, "You can't mint so much of NFT");    // нужна ли верхняя проверка если есть это 
        
        for (uint8 i = 1; i <= _mintAmount; i++) {
            _safeMint(_mintWallet, totalSupply() + 1);
        }    

        ogMintedAmount[_mintWallet] += _mintAmount;
    }



    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory tokenIds = new uint[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }


    function setCost(uint _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint8 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setMaxMintAmountOg(uint8 _newMaxOgMintAmount) public onlyOwner {
        maxMintAmountOg = _newMaxOgMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    } 

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pauseMint(bool _state) public onlyOwner {
        paused = _state;
    }
 
    function whitelistUser(address _wallet) public onlyOwner {
        whitelistedWallet[_wallet] = true;
    }
 
    function removeWhitelistUser(address _wallet) public onlyOwner {
        whitelistedWallet[_wallet] = false;
    }

    function ogUser(address _wallet) public onlyOwner {
        ogWallet[_wallet] = true;
    }

    function removeOgUser(address _wallet) public onlyOwner {
        ogWallet[_wallet] = true;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
