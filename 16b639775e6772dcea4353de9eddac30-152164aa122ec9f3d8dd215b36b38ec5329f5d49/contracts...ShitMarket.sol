// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract ShitMarket is ERC721A, Ownable, ReentrancyGuard 
{
    using Strings for uint256;

    string private baseURI;
    string private baseExtension = ".json";
    string private HiddenUri;

    bytes32 private OgRoot;
    string public provenanceHash;

    uint256 public preSaleStartTime = 1651226400;
    uint256 public publicSaleStartTime = 1651258800;

    uint256 public mintPrice = 0.002 ether;
    uint256 public mintPriceOg = 0.001 ether;

    uint256 public MAX_SUPPLY =5555 ;
    uint256 public MAX_MINT_PerTX =2 ;
    uint256 public MAX_MINT_PerOG =2 ;

//sales start and reveal 
    bool  public  _isSaleActive = false    ;
    bool private _isHIdden = false;
    mapping(address => uint256) public mintCountPerAdd;

 
    constructor
    (
        string memory SM,
        string memory _initBaseURI,
        string memory _initHiddenUri,
        string memory _initProvenanceHash,
        bytes32[] memory _ogRoot
    )
     ERC721A(ShitMarket ,ShitMarket)
    {
        setBaseURI(_initBaseURI);
        setHiddenURI(_initHiddenUri);
        setProvenanceHash(_initProvenanceHash);
        setOgRoot(_ogRoot[0]);
    }

     modifier callerIsUser()
      {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
      }

//internal
        function _baseURI() internal view virtual override returns(string memory) 
        {
        return baseURI;
        }

//presale
        function preSaleMint(uint256 _mintAmount, bytes32[] calldata _proof) external payable callerIsUser nonReentrant
    {
        require(isContractActive, "Contract is not Active");
        require(_mintAmount > 0, "At least 1 NFT is needed");
        require(preSaleStartTime != 0 && block.timestamp >= preSaleStartTime, "presale has not started yet");
        require(publicSaleStartTime != 0 && block.timestamp < publicSaleStartTime, "presale has ended");
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");

        uint256 mintedCount = mintCountPerAdd[msg.sender];
        uint256 wlPrice = mintPrice;
        {
            if (isOGlisted(_proof)) 
            {
              require(_mintAmount + mintedCount <= maxMintPerOG, "Exceed Minting Limit");
              OgPrice = mintPriceOG;
            } 
            else 
            {
              require(false, "This Address is not whitelisted");
            }
        }
        
        uint256 calculatedMintPrice = wlPrice * _mintAmount;
        require(msg.value >= calculatedMintPrice, "Insufficient Funds");
        
        mintCountPerAdd[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // public sales
    function mint(uint256 _mintAmount) external payable nonReentrant {
        require(isContractActive, "Contract is not Active");
        require(publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime, "public sale has not started yet");
        require(_mintAmount > 0, "At least 1 NFT is needed");
        require(_mintAmount <= maxMintAmountPerTx, "Max Mint Amount Exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");

        uint256 calculatedMintPrice = mintPrice * _mintAmount;
        require(msg.value >= calculatedMintPrice, "Insufficient Funds");

        _safeMint(msg.sender, _mintAmount);
    }
    function isOGlisted(bytes32[] calldata _proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, ogRoot, leaf);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (isHidden == true) {
            return HiddenUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ?
            string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) :
            "";
    }

    function getMintedCountPerAdd(address user) public view returns(uint256) {
        uint256 count = mintCountPerAdd[user];
        return count;
    }

     //only Owner	
    
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
          provenanceHash = _provenanceHash;
    }
    
    function giveaway(address to, uint256 _mintAmount) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");
        require(_mintAmount <= maxSupply, 'Minting would exceed total supply');
        _safeMint(to, _mintAmount);
    }

    function reservedMint(uint256 _mintAmount) public onlyOwner {
        require(_mintAmount <= maxSupply, 'Minting would exceed total supply');
        require(totalSupply() + _mintAmount <= maxSupply, "Minting would exceed total supply");
        _safeMint(msg.sender, _mintAmount);
    }

    function setContractActive(bool _state) public onlyOwner {
        isContractActive = _state;
    }

    function setHiddenURI(string memory _URI) public onlyOwner {
        HiddenUri = _URI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }
    
    function setOGMintPrice(uint256 _newPrice) public onlyOwner {
        mintPriceOG = _newPrice;
    }

    function setMaxMintAmountPerTx(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _newmaxMintAmount;
    }

    function setMaxMintAmountPerOG(uint256 _limit) public onlyOwner {
        maxMintPerOG = _limit;
    }

    function setOgRoot(bytes32 _root) public onlyOwner {
        ogRoot = _root;
    }

    function setPreSaleStartTime(uint256 _startTime) public onlyOwner {
        preSaleStartTime = _startTime;
    }

    function setPublicSaleStartTime(uint256 _startTime) public onlyOwner {
        publicSaleStartTime = _startTime;
    }

    function reveal() public onlyOwner {
        isHidden = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call {
            value: address(this).balance
        }("");
        require(success);
    }
}
