// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LTrip.sol";
import "./Ownable.sol";

contract Trip is Ownable{

    Ltrip.Journey[190] public journey;

    // add : id : ticket
    mapping (address =>mapping(uint8 => Ltrip.MyTicket))internal MyT;

    // add :  id : balance
    mapping(address => mapping(uint8 =>uint256)) internal Spbalance;
    mapping(address => mapping(uint8 =>uint256)) internal Usbalance ;

    // FIND AVAILABLE ID 
    function findID() external view returns(uint8){
        return Ltrip.find_id(journey);
    }
     
    //CREATE  
    function addTrip(bytes32 name,bytes32 location,uint256 _EndDate,uint256 price ,uint8 totammount,uint8 id) external{
        Ltrip.create(journey,name,location,price,_EndDate,totammount,id);
    }
 
    // UPDATE          
    function update(bytes32 name,bytes32 location,uint256 _EndDate,uint256 price ,uint8 totammount,uint8 ID) external{
        Ltrip.update(journey,name,location,price,_EndDate,totammount,ID);
    }

    // BOOKING     
    function boking(uint256 StartDate,uint256 EndDate,uint8 AmmTick,uint8 ID)external payable {
        Ltrip.boking(MyT,journey,StartDate,EndDate,AmmTick,ID);

        uint256 price = journey[ID].price;
        uint256 total = price * AmmTick;
        Usbalance[msg.sender][ID] +=  total;
    }

    // ADD QT TO TICKET                              
    function addQt(uint8 AmmTick,uint8 ID)external payable{
        Ltrip.add(MyT,journey,AmmTick,ID);

        uint256 price = journey[ID].price;
        uint256 total = price * AmmTick;
        Usbalance[msg.sender][ID] +=  total;
    }

    //CANC ORDER       
    function cancel(uint8 ID) external  {
        Ltrip.canc(MyT,journey,ID);

        uint256 TOTAL = Usbalance[msg.sender][ID];
        Usbalance[msg.sender][ID] = 0;
        payable(msg.sender).transfer(TOTAL);
    }

    //CANC SINGLE QT OF  ORDER   
    function cancel_Qt(uint8 ID,uint8 AmmTick) external {
        uint256 TOTAL = Ltrip.cancSingle(MyT,Usbalance,ID,AmmTick);

        journey[ID].avaiable += AmmTick;
        Usbalance[msg.sender][ID] -= TOTAL;
        payable(msg.sender).transfer(TOTAL);
    }

    // PAY SP
    function checkout(uint8 ID) external {
        require (MyT[msg.sender][ID].QtOwned >= 1,"CheckId_Qt");
        require (block.timestamp > MyT[msg.sender][ID].StartDate, "wait the Start of trip");

        uint256 TOTAL = Usbalance[msg.sender][ID];
        address SP = journey[ID].serviceProvider;
        MyT[msg.sender][ID].QtOwned = 0;
        Usbalance[msg.sender][ID] = 0;
        
        Spbalance[SP][ID] += TOTAL;
    }
    
    // SP WITHDRAW
    function spwithdraw(uint8 ID)external {
        require (msg.sender == journey[ID].serviceProvider,"NotOwner");

        uint256 TOTAL = Spbalance[msg.sender][ID];
        Spbalance[msg.sender][ID] = 0;

        uint256 FEE = TOTAL/100 ; //  1%
        uint256 DIFF = TOTAL - FEE;

        owner.transfer(FEE);
        payable(msg.sender).transfer(DIFF);
    }

    function trips() external view returns(Ltrip.Journey[190] memory){
        return journey; 
    }

    function trip_by_index(uint8 index) external view returns(Ltrip.Journey memory){
        return journey[index];       
    }

    function mytickets(uint8 ID ) public view returns(Ltrip.MyTicket memory){
        return MyT[msg.sender][ID];
    }

    function rUsbalance(uint8 ID)public view returns (uint256){
        return Usbalance[msg.sender][ID];
    }

    function rSpbalance(uint8 ID)public view returns (uint256){
        return Spbalance[msg.sender][ID];
    }

    //CHECK INACTIVITY ID onlyOwner
    function checkInactivity() external onlyOwner view returns(uint8 id){
        return Ltrip.checkInactivity(journey);
    }

    // DELETE TRIP   onlyOwner
    function del(uint8 Id)external onlyOwner {
        require (block.timestamp > journey[Id].EndDate + 90 days," < EndDate + 90d");
        delete journey[Id];
    }
    
}
