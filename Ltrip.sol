// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Ltrip {
    struct Journey {
        bytes32 name; 
        bytes32 location; 
        uint256 startDate; 
        uint256 endDate; 
        uint256 price; 
        string description;
        uint8 available; 
        uint8 id; 
        address serviceProvider; 
    }

    struct myTicket {
        uint256 startDate; 
        uint256 endDate; 
        uint8 amountOwned; 
        address owner;
    }

    event Booking(uint8 indexed id, uint8 indexed amount);   
    event AddAmount(uint8 indexed id, uint8 indexed amount);  
    event Cancelled(uint8 indexed id, uint8 indexed amount); 


    // FIND YOUR AVAILABLE id
    function find_id(Journey[190] storage journey)
            public
            view
            returns (int index)
        {
            for (uint x = 0; x < 190; x++) {
                if (journey[x].serviceProvider == 0x0000000000000000000000000000000000000000) {
                    return int(x) ;
                }
            }
            return -1;
        }

    // CREATE
    function create(
        Journey[190] storage journey,
        bytes32 name,
        bytes32 location,
        uint256 endDate,
        uint256 price,
        string memory description,
        uint8 available,
        uint8 id
    ) internal {

        require(endDate > block.timestamp,"Checkdate"); 
        require(id < 190,"id not valid")  ;
        require(journey[id].price == 0,"idUsed"); 
        Ltrip.Journey storage j = journey[id];

        j.name = name;
        j.location = location;
        j.startDate = block.timestamp;
        j.endDate = endDate;
        j.price = price;
        j.description = description;
        j.available = available;
        j.id = id;
        j.serviceProvider = msg.sender;
    }

    // UPDATE  if sp wants to block the sale of the ticket he must set the available quantity to 0
    //**  if sp wants to cancel the creation of the trip, he could update with the default values ​​of 0
    function update(
        Journey[190] storage journey,
        bytes32 name,
        bytes32 location,
        uint256 endDate,
        uint256 price,
        string memory description,
        uint8 available,
        uint8 id
        // address serviceProvider **
    ) internal {
        require (journey[id].serviceProvider == msg.sender,"Notowner"); 
        require (endDate > block.timestamp,"Checkdate") ;

        Ltrip.Journey storage j = journey[id];

        j.name = name;
        j.location = location;
        j.startDate = block.timestamp;
        j.endDate = endDate;
        j.price = price;
        j.description = description;
        j.available = available;
        j.id = id;
        // j.serviceProvider = serviceProvider;  **
        
    }

    // BOOKING
    function boking(
        mapping(address => mapping(uint8 => myTicket)) storage myT,
        Journey[190] storage journey,
        uint256 startDate,
        uint256 endDate,
        uint8 amount,         
        uint8 id
    ) internal {
        require (journey[id].price != 0,"Id NotExist");
        require(startDate < journey[id].endDate,"TimeExpired") ;
        require (amount < journey[id].available,"Exceed amount");
        require (msg.value == journey[id].price * amount,"Checkvalue");
        require(myT[msg.sender][id].amountOwned < 1, "Canc for newdate or addAmount");

        myTicket storage m = myT[msg.sender][id];

        m.startDate = startDate;
        m.endDate = endDate;
        m.amountOwned += amount;
        m.owner = msg.sender;

        journey[id].available -= amount;
        emit Booking(id, amount);
    }

    // ADD QUANTITY TO TICKET
    function add(
        mapping(address => mapping(uint8 => myTicket)) storage myT,
        Journey[190] storage journey,
        uint8 amount, 
        uint8 id
    ) internal {
        require (msg.sender == myT[msg.sender][id].owner,"Notowner");
        require(block.timestamp < myT[msg.sender][id].startDate,"TimeExpired");
        require (msg.value == journey[id].price * amount ,"Checkvalue");
        require (myT[msg.sender][id].amountOwned >= 1,"Check id-amount") ;

        journey[id].available -= amount;
        myT[msg.sender][id].amountOwned += amount;
        emit AddAmount(id, amount);
    }

    // CANC ORDER
    function canc(
        mapping(address => mapping(uint8 => myTicket)) storage myT,
        Journey[190] storage journey,
        uint8 id
    ) internal {
        require (msg.sender == myT[msg.sender][id].owner,"Notowner");
        require(block.timestamp < myT[msg.sender][id].startDate,"TimeExpired");
        require (myT[msg.sender][id].amountOwned >= 1,"Check id-amount") ;

        uint8 amount = myT[msg.sender][id].amountOwned;  
        journey[id].available += amount;
        myT[msg.sender][id].amountOwned = 0;
        emit Cancelled(id, amount);
    }

    //  CANC SINGLE AMOUNT
    function cancSingle(
        mapping(address => mapping(uint8 => myTicket)) storage myT,
        mapping(address => mapping(uint8 => uint256)) storage pr,
        uint8 id,
        uint8 amount  
    ) internal returns (uint256) {

        require (msg.sender == myT[msg.sender][id].owner,"Notowner");
        require(block.timestamp < myT[msg.sender][id].startDate,"TimeExpired");
        require (myT[msg.sender][id].amountOwned > 1,"Check id-amount") ;

        uint256 totalPrice = pr[msg.sender][id];
        uint8 myAmount = myT[msg.sender][id].amountOwned;
        uint256 singlePrice = totalPrice / myAmount;
        uint256 TOTAL = singlePrice * amount;

        myT[msg.sender][id].amountOwned -= amount;
        emit Cancelled(id, amount);

        return TOTAL;
    }

    // 

    //CHECK INACTIVITY id
    function checkInactivity(Journey[190] storage journey)
            internal
            view
            returns (int index)
        {
            for (uint x = 0; x < 190; x++){
                if (block.timestamp > journey[x].endDate + 90 days && journey[x].endDate != 0) {     
                    return int(x);
                }
            }
            return -1;
        }


}