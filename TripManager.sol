// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ltrip.sol";
import "./Ownable.sol";

contract TripManager is Ownable {
    Ltrip.Journey[190] public journey;

    // add : iD : ticket
    mapping(address => mapping(uint8 => Ltrip.myTicket)) internal myTicket;

    // service provider balance    add :  iD : balance
    mapping(address => mapping(uint8 => uint256)) internal spBalance;

    // user balance   add :  iD : balance
    mapping(address => mapping(uint8 => uint256)) internal usBalance;


    constructor(address owner) Ownable(owner) {
        Ltrip.create(
            journey,
            0x53706c656e646f7220486f74656c202d20303031363420526f6d6120524d0000,    //32 chars
            0x5669612047696f7267696f205a6f6567612c2032303200000000000000000000,
            1791613788,
            150000000000000000,
            "room for 2 people (double bed) + breakfast buffet",  // to add more detailed information store the data off-chain
            20,
            0
        );
    }

    // FIND AVAILABLE iD
    function findId() external view returns (int256) {
        return Ltrip.findId(journey);
    }

    //CREATE
    function createTrip(
        bytes32 name,
        bytes32 location,
        uint256 endDate,
        uint256 price,
        string memory description,
        uint8 available,
        uint8 iD
    ) external {
        Ltrip.create(journey, name, location,endDate, price, description, available, iD);
    }

    // UPDATE  if service provider wants to block the sale of the ticket he must set the available quantity to 0
    //**if s.p. wants to cancel the creation of the trip, he could update with the default values ​​of the variables
    function update(
        bytes32 name,
        bytes32 location,
        uint256 endDate,
        uint256 price,
        string memory description,
        uint8 available,
        uint8 iD
        // address serviceProvider **
    ) external {
        Ltrip.update(journey, name, location, endDate,price, description, available, iD);  
    }

    // BOOKING
    function boking(
        uint256 startDate,
        uint256 endDate,
        uint8 amount,
        uint8 iD
    ) external payable {
        Ltrip.boking(myTicket, journey, startDate, endDate, amount, iD);

        uint256 price = journey[iD].price;
        uint256 total = price * amount;
        usBalance[msg.sender][iD] += total;
    }

    // ADD AMOUNT TO TICKET
    function addAmount(uint8 amount, uint8 iD) external payable {
        Ltrip.add(myTicket, journey, amount, iD);

        uint256 price = journey[iD].price;
        uint256 total = price * amount;
        usBalance[msg.sender][iD] += total;
    }

    //CANC ORDER
    function cancel(uint8 iD) external {
        Ltrip.canc(myTicket, journey, iD);

        uint256 TOTAL = usBalance[msg.sender][iD];
        usBalance[msg.sender][iD] = 0;
        payable(msg.sender).transfer(TOTAL);
    }

    //CANC AMOUNT OF ORDER
    function cancelAmount(uint8 iD, uint8 amount) external {
        uint256 TOTAL = Ltrip.cancSingle(myTicket, usBalance, iD, amount);

        journey[iD].available += amount;
        usBalance[msg.sender][iD] -= TOTAL;
        payable(msg.sender).transfer(TOTAL);
    }

    // PAY SERVICE PROVIDER
    function checkout(uint8 iD) external {
        require(myTicket[msg.sender][iD].amountOwned >= 1, "Check_iD_Qt");
        require(
            block.timestamp > myTicket[msg.sender][iD].startDate,
            "Wait the start of trip"
        );

        uint256 TOTAL = usBalance[msg.sender][iD];
        address SP = journey[iD].serviceProvider;
        myTicket[msg.sender][iD].amountOwned = 0;
        usBalance[msg.sender][iD] = 0;

        spBalance[SP][iD] += TOTAL;
    }

    // SERVICE PROVIDER WITHDRAW
    function SpWithdraw(uint8 iD) external {
        require(msg.sender == journey[iD].serviceProvider, "NotOwner");

        uint256 TOTAL = spBalance[msg.sender][iD];
        spBalance[msg.sender][iD] = 0;

        uint256 FEE = TOTAL / 100; //  1%
        uint256 NET = TOTAL - FEE;

        owner.transfer(FEE);
        payable(msg.sender).transfer(NET);
    }

    function trips() public view returns (Ltrip.Journey[190] memory) {
        return journey;
    }

    function tripByIndex(uint8 iD)
        external
        view
        returns (Ltrip.Journey memory)
    {
        return journey[iD];
    }


    function myTickets(uint8 iD) public view returns (Ltrip.myTicket memory) {
        return myTicket[msg.sender][iD];
    }

    function UsBalance(uint8 iD) public view returns (uint256) {
        return usBalance[msg.sender][iD];
    }

    function SpBalance(uint8 iD) public view returns (uint256) {
        return spBalance[msg.sender][iD];
    }

    //CHECK INACTIVITY iD onlyOwner
    function checkInactivity() external view onlyOwner returns (int iD) {
        return Ltrip.checkInactivity(journey);
    }

    // DELETE TRIP   onlyOwner
    function del(uint8 iD) external onlyOwner {
        require(
            block.timestamp > journey[iD].endDate + 90 days, 
            "< endDate + 90d"
        );
        delete journey[iD];
    }




    
}
