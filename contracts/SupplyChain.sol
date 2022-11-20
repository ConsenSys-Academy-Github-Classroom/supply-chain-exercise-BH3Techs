// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner;

  // <skuCount>
  uint public skuCount;

  // <items mapping>
  mapping(uint=>Item) items;

  // <enum State: ForSale, Sold, Shipped, Received>
  enum State {ForSale, Sold, Shipped, Received}

  // <struct Item: name, sku, price, state, seller, and buyer>

  struct Item{
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);
  // <LogSold event: sku arg>
  event LogSold(uint sku);
  // <LogShipped event: sku arg>
  event LogShipped(uint sku);
  // <LogReceived event: sku arg>
  event LogReceived(uint sku);


  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  // <modifier: isOwner
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier verifyCaller (uint _sku) { 
    require (msg.sender ==items[_sku].seller || msg.sender == items[_sku].buyer); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >=_price);
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    uint _price = items[_sku].price;
    require(msg.value>=_price);
    uint amountToRefund = msg.value - _price;
    payable(items[_sku].buyer).transfer(amountToRefund);
    _;
  }
  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  // modifier forSale
  modifier forSale(uint _sku){
    require(items[_sku].state==State.ForSale);
    _;
  }
  // modifier sold(uint _sku) 
  modifier sold(uint _sku){
    require(items[_sku].state == State.Sold);
    _;
  }
  // modifier shipped(uint _sku) 
  modifier shipped(uint _sku){
    require(items[_sku].state == State.Shipped);
    _;
  }
  // modifier received(uint _sku) 
  modifier received(uint _sku){
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() {
    // 1. Set the owner to the transaction sender
    owner =msg.sender;
    // 2. Initialize the sku count to 0. Question, is this necessary?
    skuCount =0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    // 2. Increment the skuCount by one
    // 3. Emit the appropriate event
    // 4. return true

    // hint:
    items[skuCount] = Item({
      name: _name, 
      sku: skuCount, 
      price: _price, 
      state: State.ForSale, 
      seller: payable(msg.sender), 
      buyer: payable(address(0))
    });
    
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!
  function buyItem(uint _sku) public payable forSale(_sku) paidEnough(_sku) checkValue(_sku){
    items[_sku].seller.transfer(items[_sku].price);
    items[_sku].buyer = payable(msg.sender);
    items[_sku].state = State.Sold;

    emit LogSold(_sku);

  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller.
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint _sku) public sold(_sku) verifyCaller(_sku) {
    require(msg.sender == items[_sku].seller);
    items[_sku].state = State.Shipped;

    emit LogShipped(_sku);

  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint _sku) public shipped(_sku) verifyCaller(_sku){
    require(items[_sku].buyer == msg.sender);
    items[_sku].state = State.Received;

    emit LogReceived(_sku);

  }

  // Uncomment the following code block. it is needed to run tests
   function fetchItem(uint _sku) public view 
returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)   { 
     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
   }
}
