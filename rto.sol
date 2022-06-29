// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract DMVxV_1 is VRFConsumerBaseV2{
    VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
    uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
    uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    mapping(address=> bool) public Admins;
    address[] admins;
    address payable MasterAdmin;
    address public DealerNFTContractAddress;
    uint256 internal prevRandomNumber;
    uint256 zone;
    uint256 public number;

    modifier MasterAdminOnly() {
        require(msg.sender == MasterAdmin, "Not Owner!");
        _;
    }

    modifier AdminOnly() {
        require(Admins[msg.sender]);
        _;
    }

    struct Vehicle {
        string manufacturingDetails;
        string insuranceDetails;
        uint256 registrationNumber;
        string priceBreakup;
        bool registered;
        bool insuranceActive;
        Owner[] owners;
        Dealer dealer;
        string saleDetails;
    }
    Vehicle vehicle;

    struct Owner {
        uint ownerNumber;
        string ownerName;
        string[] IdDocs;
        address ownerAddress;
    }
    Owner owner;
    
    struct Dealer {
        string regId;
        address walletAddress;
    }
    Dealer dealer;

    mapping(string => Vehicle) VehicleRecord;
    Vehicle[] vehicleArray;
    uint256 vehicleCount;

    constructor(address _DealerNFTContract, uint256 _zone, uint64 subscriptionId)  VRFConsumerBaseV2(vrfCoordinator) {
        MasterAdmin = payable(msg.sender);
        zone = _zone;
        vehicleCount = 0;
        setDealerNFTContract(_DealerNFTContract);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }
    function setDealerNFTContract(address ContractAddress) public MasterAdminOnly {
        DealerNFTContractAddress = ContractAddress;
    }
    
    function addAdmin(address _adminToAdd) public MasterAdminOnly {
        require(Admins[_adminToAdd] == false, "Admin Already Added!");
        Admins[_adminToAdd] = true;
        admins.push(_adminToAdd);
    }

    function removeAdmin(address _adminToRemove) public MasterAdminOnly {
        Admins[_adminToRemove] = false;
        for(uint i = 0; i < admins.length; i++){
            if (admins[i] == _adminToRemove) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
            }
        }
    }

    function newRegistrationRecord(
        string memory _manufacturingDetails,
        string memory _priceBreakup,
        string memory _saleDetails,
        string memory _OwnerName,
        string[] memory _DocsNumber,
        address _ownerAddress,
        string memory _regId
    ) public {
        requestRandomWords();
        IERC721 token = IERC721(DealerNFTContractAddress);
        uint c = token.balanceOf(msg.sender);
        require(c == 1, "Not a registered Dealer");
        dealer = Dealer(_regId, msg.sender);
        owner.ownerNumber = 1;
        owner.ownerName = _OwnerName;
        owner.ownerAddress = _ownerAddress;
        owner.IdDocs = _DocsNumber;
        vehicle.owners.push(owner);
        vehicle.manufacturingDetails = _manufacturingDetails;
        vehicle.priceBreakup = _priceBreakup;
        vehicle.registered = false;
        vehicle.insuranceActive = false;
        vehicle.registrationNumber = number;
        vehicle.insuranceDetails = "";
        vehicle.saleDetails = _saleDetails; 
    }

    function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    uint i = 0;
    s_randomWords = randomWords;
    if(prevRandomNumber == randomWords[0]){
      i = 1;
    }
    number = getLetters(randomWords[i]);
  }


  function getLetters(uint256 _randomword) pure internal returns(uint){
    
    uint numone = _randomword;
    uint a = numone % 100;
    if(a == 0) {
      a = numone % 10000;
      a = a / 100;
    }
    uint b = numone % 1000000;
    b = b / 10000;
    if(b == 0) {
      b = numone % 10000000000;
      b = b / 100000000;
    }
    uint a_new = getinRangeforLetters(a);
    uint b_new = getinRangeforLetters(b);
    uint numtwo = _randomword;
    uint c = (_randomword % 10) + 19;
    numtwo = numtwo / (10 ** c );
    uint x = numtwo % 10000;

    uint y = ((a_new * 1000000) + (b_new * 10000) + x);

    return y;
  }
  
  function getinRangeforLetters(uint x) pure internal returns(uint){
    if(x < 65){
      while(x < 65){
        x = x + 26; 
      }
    }
    if(x > 90){
      while(x > 90){
        x = x - 13; 
      }
    }
    return x;


  }
}
