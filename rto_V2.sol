// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

contract DMVxV_4 {
    string public stateCode;
    mapping(address=> bool) public Admins;
    address[] public admins;
    address payable MasterAdmin;
    address public DealerNFTContractAddress;

    modifier DealerOnly() {
        IERC721 token = IERC721(DealerNFTContractAddress);
        uint c = token.balanceOf(msg.sender);
        require(c == 1, "Not a registered Dealer");
        _;
    }

    modifier MasterAdminOnly() {
        require(msg.sender == MasterAdmin, "Not Owner!");
        _;
    }

    modifier AdminOnly() {
        require(Admins[msg.sender]);
        _;
    }

    struct Vehicle {
        uint256 zone;
        string manufacturingDetails;
        string insuranceDetails;
        string registrationNumber;
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

    constructor(address _DealerNFTContract, string memory _state) {
        MasterAdmin = payable(msg.sender);
        stateCode = _state;
        vehicleCount = 0;
        setDealerNFTContract(_DealerNFTContract);
        Admins[msg.sender] = true;
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
        uint256 _zone,
        string memory _manufacturingDetails,
        string memory _priceBreakup,
        string memory _saleDetails,
        string memory _OwnerName,
        string[] memory _DocsNumber,
        address _ownerAddress,
        string memory _registrationNum,
        string memory _regId
    ) public {
        IERC721 token = IERC721(DealerNFTContractAddress);
        uint c = token.balanceOf(msg.sender);
        require(c == 1, "Not a registered Dealer");
        dealer = Dealer(_regId, msg.sender);
        owner.ownerNumber = 1;
        owner.ownerName = _OwnerName;
        owner.ownerAddress = _ownerAddress;
        owner.IdDocs = _DocsNumber;
        vehicle.dealer = dealer;
        vehicle.zone = _zone;
        vehicle.owners.push(owner);
        vehicle.manufacturingDetails = _manufacturingDetails;
        vehicle.priceBreakup = _priceBreakup;
        vehicle.insuranceActive = false;
        vehicle.registrationNumber = _registrationNum;
        vehicle.insuranceDetails = "";
        vehicle.saleDetails = _saleDetails;
        vehicle.registered = true;
        vehicleArray.push(vehicle);
        VehicleRecord[_registrationNum] = vehicle;
        vehicleCount++;
    }

    function AllVehicles() public view AdminOnly returns ( Vehicle[] memory )  {
        return vehicleArray;
    }

    function DealersVehicle(address dealerAddress) public view returns (Vehicle[] memory Varray) {
        Varray = new Vehicle[](vehicleCount);
        uint j = 0;
        uint i = 0;
        while( i < vehicleCount) {
            if (vehicleArray[i].dealer.walletAddress == dealerAddress){
                Varray[j] = vehicleArray[i];
                j++;
            }
            i = i++;
        }
        return Varray;
    }

    function ZoneVehicles(uint256 m_zone) public view AdminOnly returns (Vehicle[] memory Varray) {
        Varray = new Vehicle[](vehicleCount);
        Vehicle memory targetvehicle;
        uint i = 0;
        uint j = 0;
        while(i < vehicleCount){
            targetvehicle = vehicleArray[i];
            if(targetvehicle.zone == m_zone){
                Varray[j] = targetvehicle;
                j++;
            }
            i++;
        }
        return Varray;
    }

    function VehicleByRegistration(string memory m_regnum) public view returns(Vehicle memory) {
        return VehicleRecord[m_regnum];
    }

    function ApproveInsurance(string memory m_regnum, string memory m_insuranceDetails) public {
        VehicleRecord[m_regnum].insuranceDetails = m_insuranceDetails;
        VehicleRecord[m_regnum].insuranceActive = true;
        for(uint i = 0; i < vehicleCount; i++){
            if(keccak256(abi.encodePacked((vehicleArray[i].registrationNumber))) == keccak256(abi.encodePacked((m_regnum)))){
                vehicleArray[i].insuranceActive = true;
                vehicleArray[i].insuranceDetails = m_insuranceDetails;
            }
        }
    }

    function SuspendRegistration(string memory m_regnum) public AdminOnly {
        VehicleRecord[m_regnum].registered = false;
        for(uint i = 0; i < vehicleCount; i++){
            if(keccak256(abi.encodePacked((vehicleArray[i].registrationNumber))) == keccak256(abi.encodePacked((m_regnum)))){
                vehicleArray[i].registered = false;
            }
        }
    }

    function RevokeSuspension(string memory m_regnum) public AdminOnly {
        VehicleRecord[m_regnum].registered = true;
        for(uint i = 0; i < vehicleCount; i++){
            if(keccak256(abi.encodePacked((vehicleArray[i].registrationNumber))) == keccak256(abi.encodePacked((m_regnum)))){
                vehicleArray[i].registered = true;
            }
        }
    }

    function InsuranceDeactive(string memory m_regnum) public {
        VehicleRecord[m_regnum].insuranceDetails = "";
        VehicleRecord[m_regnum].insuranceActive = false;
        for(uint i = 0; i < vehicleCount; i++){
            if(keccak256(abi.encodePacked((vehicleArray[i].registrationNumber))) == keccak256(abi.encodePacked((m_regnum)))){
                vehicleArray[i].insuranceActive = false;
                vehicleArray[i].insuranceDetails = "";
            }
        }
    }

    // function ProcessRegistration(string memory m_regnum) public {
    //     VehicleRecord[m_regnum].registered = true;
    //     for(uint i = 0; i < vehicleCount; i++){
    //         if(keccak256(abi.encodePacked((vehicleArray[i].registrationNumber))) == keccak256(abi.encodePacked((m_regnum)))){
    //             vehicleArray[i].registered = true;
    //         }
    //     }
    // }



}
