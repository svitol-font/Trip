// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Ltrip {
    struct Journey {
        bytes32 name; 
        bytes32 location; 
        uint256 StartDate; 
        uint256 EndDate; 
        uint256 price; 
        uint8 avaiable; 
        uint8 id; 
        address serviceProvider; 
    }

    struct MyTicket {
        uint256 StartDate; 
        uint256 EndDate; 
        uint8 QtOwned; 
        address owner;
    }

    event Booking(uint8 indexed ID, uint8 indexed Qt);   
    event AddQt(uint8 indexed ID, uint8 indexed Qt);  
    event Cancelled(uint8 indexed ID, uint8 indexed Qt); 

    // FIND YOUR AVAILABLE ID
    function find_id(Journey[190] storage journey)
        public
        view
        returns (uint8 index)
    {
        for (uint8 x = 1; x < 191; x++) {
            if (journey[0].price == 0) {
                return 0;
            } else {
                if (journey[x].price == 0) {
                    index = journey[x - 1].id + 1;
                    return index;
                }
            }
        }
    }

    // CREATE
    function create(
        Journey[190] storage journey,
        bytes32 name,
        bytes32 location,
        uint256 price,
        uint256 EndDate,
        uint8 avaiable,
        uint8 ID
    ) internal {

        require(EndDate > block.timestamp,"Checkdate"); 
        require(journey[ID].price == 0,"IDused");   
        Ltrip.Journey storage j = journey[ID];

        j.name = name;
        j.location = location;
        j.StartDate = block.timestamp;
        j.EndDate = EndDate;
        j.price = price;
        j.avaiable = avaiable;
        j.id = ID;
        j.serviceProvider = msg.sender;
    }

    // UPDATE
    function update(
        Journey[190] storage journey,
        bytes32 name,
        bytes32 location,
        uint256 price,
        uint256 EndDate,
        uint8 avaiable,
        uint8 ID
    ) internal {
        require (journey[ID].serviceProvider == msg.sender,"NotOwner"); 
        require (EndDate > block.timestamp,"Checkdate") ;

        Ltrip.Journey storage j = journey[ID];

        j.name = name;
        j.location = location;
        j.price = price;
        j.avaiable = avaiable;
        j.id = ID;
        j.StartDate = block.timestamp;
        j.EndDate = EndDate;
    }

    // BOOKING
    function boking(
        mapping(address => mapping(uint8 => MyTicket)) storage myT,
        Journey[190] storage journey,
        uint256 StartDate,
        uint256 EndDate,
        uint8 qt,         
        uint8 ID
    ) internal {
        require (journey[ID].price != 0,"ID_NotExist");
        require(StartDate < journey[ID].EndDate,"TimeExpired") ;
        require (qt < journey[ID].avaiable,"exceed_qt");
        require (msg.value == journey[ID].price * qt,"Checkvalue");
        require(myT[msg.sender][ID].QtOwned < 1, "canc for nw_date or addQt");

        MyTicket storage m = myT[msg.sender][ID];

        m.StartDate = StartDate;
        m.EndDate = EndDate;
        m.QtOwned += qt;
        m.owner = msg.sender;

        journey[ID].avaiable -= qt;
        emit Booking(ID, qt);
    }

    // ADD QT TO TICKET
    function add(
        mapping(address => mapping(uint8 => MyTicket)) storage myT,
        Journey[190] storage journey,
        uint8 qt, 
        uint8 ID
    ) internal {
        require (msg.sender == myT[msg.sender][ID].owner,"NotOwner");
        require(block.timestamp < myT[msg.sender][ID].StartDate,"TimeExpired");
        require (msg.value == journey[ID].price * qt ,"Checkvalue");
        require (myT[msg.sender][ID].QtOwned >= 1,"CheckId_Qt") ;

        journey[ID].avaiable -= qt;
        myT[msg.sender][ID].QtOwned += qt;
        emit AddQt(ID, qt);
    }

    // CANC ORDER
    function canc(
        mapping(address => mapping(uint8 => MyTicket)) storage myT,
        Journey[190] storage journey,
        uint8 ID
    ) internal {
        require (msg.sender == myT[msg.sender][ID].owner,"NotOwner");
        require(block.timestamp < myT[msg.sender][ID].StartDate,"TimeExpired");
        require (myT[msg.sender][ID].QtOwned >= 1,"CheckId_Qt") ;

        uint8 qt = myT[msg.sender][ID].QtOwned;  
        journey[ID].avaiable += qt;
        myT[msg.sender][ID].QtOwned = 0;
        emit Cancelled(ID, qt);
    }

    //  CANC SINGLE QT
    function cancSingle(
        mapping(address => mapping(uint8 => MyTicket)) storage myT,
        mapping(address => mapping(uint8 => uint256)) storage pr,
        uint8 ID,
        uint8 qt  
    ) internal returns (uint256) {

        require (msg.sender == myT[msg.sender][ID].owner,"NotOwner");
        require(block.timestamp < myT[msg.sender][ID].StartDate,"TimeExpired");
        require (myT[msg.sender][ID].QtOwned > 1,"CheckId_Qt") ;

        uint256 TOTALPRICE = pr[msg.sender][ID];
        uint8 MyQt = myT[msg.sender][ID].QtOwned;
        uint256 SINGLE_PRICE = TOTALPRICE / MyQt;
        uint256 TOTAL = SINGLE_PRICE * qt;

        myT[msg.sender][ID].QtOwned -= qt;
        emit Cancelled(ID, qt);

        return TOTAL;
    }

    //CHECK INACTIVITY ID
    function checkInactivity(Journey[190] storage journey)
        internal
        view
        returns (uint8 ID)
    {
        for (uint8 x = 0; x < 181; x++) {
            if (block.timestamp > journey[x].EndDate + 90 days) {
                if (journey[x].EndDate == 0) {
                    continue;
                } else {
                    return journey[x].id;
                }
            }
        }
    }
}
