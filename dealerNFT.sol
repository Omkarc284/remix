// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

contract dealerNFT is ERC721URIStorage{
    uint256 public tokenCounter;
    uint256 public price;
    address payable owner;
    struct Dealer {
        string RegisteredName;
        string Brand;
        string regId;
        string vehicleCat;
        string addr;
        address walletAddress;
    }
    Dealer[] public Dealers;
    Dealer public dealer;
    event CreateddealerNFT(uint256 indexed tokenId, string tokenURI);
    constructor() ERC721 ("DEALERSHIP_REG8", "DR#8") {
        owner = payable(msg.sender);
        tokenCounter = 0;
        price = 1000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner!");
        _;
    }

    modifier canMint() {
        require(balanceOf(msg.sender) == 0, "Only one per company");
        _;
    }

    function create(string memory _regName, string memory _brand, string memory _regId, string memory _vehicleCat, string memory _addr) public payable canMint {
        require(msg.value >= price, "Insufficient Value");
        bool isDuplicate = checkForDuplicate(_regId);
        address dealerAddress = msg.sender;
        require(!isDuplicate, "Already Exists");
        dealer = Dealer(_regName, _brand, _regId, _vehicleCat, _addr, dealerAddress);
        Dealers.push(dealer);
        _safeMint(msg.sender, tokenCounter);
        string memory tokenURI = generateSVG(dealer);
        _setTokenURI(tokenCounter, tokenURI);
        emit CreateddealerNFT(tokenCounter, tokenURI);
        tokenCounter = tokenCounter + 1;
    }

    function checkForDuplicate(string memory _regId) public view returns(bool){
        uint256 i;
        for(i = 0; i < tokenCounter; i++ ){
            Dealer memory _dealer = Dealers[i];
            if (keccak256(abi.encodePacked((_dealer.regId))) == keccak256(abi.encodePacked((_regId)))){
                return true;
            }
        }
        return false;
    }

    function searchByRegId(string memory _regId) public view returns(Dealer memory _dealer) {
        uint256 i;
        for(i = 0; i < tokenCounter; i++ ){
            _dealer = Dealers[i];
            if (keccak256(abi.encodePacked((_dealer.regId))) == keccak256(abi.encodePacked((_regId)))){
                return _dealer;
            }
        }
        
    }

    function searchByAddress(address holder) public view returns(Dealer memory _dealer) {
        uint256 i;
        for(i = 0; i < tokenCounter; i++ ){
            _dealer = Dealers[i];
            if (keccak256(abi.encodePacked((_dealer.walletAddress))) == keccak256(abi.encodePacked((holder)))){
                return Dealers[i];
            }
        }
        
    }

    function generateSVG(Dealer memory svgInfo) internal pure returns (string memory){
        string memory svg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='350' width='350'><rect width='350' height='350' style='fill:rgb(0, 150, 255);stroke-width:3;stroke:rgb(0,0,0)'></rect><text x='10%' y='20%' fill='white' font-size='1em'>Company Name: </text><text x='10%' y='30%' fill='white' font-size='1em'>", svgInfo.RegisteredName," </text><text x='10%' y='45%' fill='white' font-size='1em'> Brand Name:</text><text x='10%' y='55%' fill='white' font-size='1em'>", svgInfo.Brand,"</text><text x='10%' y='70%' fill='white' font-size='1em'>Reg No:</text><text x='10%' y='80%' fill='white' font-size='1em'>", svgInfo.regId,"</text></svg>"));
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = generateTokenURI(svgInfo, imageURI);
        return tokenURI;
    }

    function generateTokenURI(Dealer memory svgInfo, string memory _imageURI) internal pure returns (string memory) {
        string memory name = getName(svgInfo.RegisteredName);
        string memory description = getDescription(svgInfo.Brand, svgInfo.vehicleCat);
        string memory attributes = getAttributes(svgInfo);
        string memory data = Base64.encode(bytes(string(abi.encodePacked(name,description,attributes,'"image":"', _imageURI, '"}'))));
        return  string(abi.encodePacked(
            'data:application/json;base64,',
            data
        ));
    }


    function svgToImageURI(string memory svg) public pure returns (string memory){
        string memory baseUrl = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(svg));
        string memory imageURI = string(abi.encodePacked(baseUrl, svgBase64Encoded));
        return imageURI;
    }

    function getName(string memory _name) internal pure returns (string memory) {
        return string(abi.encodePacked('{"name": "', _name,'",' ));
    }

    function getDescription(string memory _brand, string memory _vehicleCat) internal pure returns (string memory) {
        return string(abi.encodePacked('"description": "An authorized and registered dealership of ', _brand, '. Vehicle Category: ', _vehicleCat,'.",'));
    }

    function getAttributes(Dealer memory info) internal pure returns (string memory) {
        return string(abi.encodePacked('"attributes": [{"trait_type": "Brand", "value": "', info.Brand,'"}, {"trait_type": "Vehicle_Category", "value": "', info.vehicleCat,'"},{"trait_type": "Dealer_ID", "value": "', info.regId,'"}, {"trait_type": "Address", "value": "', info.addr,'"}],'));
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}
