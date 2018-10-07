pragma solidity ^0.4.19;

contract MarketPlace {

  Escrow escrow;

//Has all the information of a particular product
  struct Product {
    string itemName;
    string color;
    string description;
    string manufacturer;
    uint warranty;
    uint quantity;
    uint price;
    uint productID;
    bool inStock;
    address oneSeller;
  }

//Has all the information of the seller and the number of products this seller has.
  struct Seller {
    string sellerName;
    address sellerAddress;
    string sellerPhoneNumber;
    string sellerEmail;
    uint noOfProducts;
    mapping(uint => Product) sellerProducts;
  }

  event AddedSeller(address seller, string sellerName, string sellerPhoneNumber, string sellerEmail);
  event AddedItem(address seller, string itemName, string color, string description, string manufacturer, uint warranty, uint price, uint quantity);

//This is an array of Seller struct. Can iterate through the number of sellers that have registered and get their information.
//This is an array of Product struct. Can iterate through the number of products that are there in the marketplace. Used an array here to retrieve the products to the marketplace to display them to users.
//Address of the owner of the marketplace contract. Used to deploy it the first time.
//Addresses of all the sellers.
//To hold all the paymentIDs
//msg.sender is associated with the seller information when he/she is asked to fill in the details before adding products to the page.
//To make sure that the seller is already in the system to avoid duplications.
//Payment Details are all held here associated with their UIDs as keys
  Seller[] public sellerList;
  Product[] public productsArray;

  address public owner;
  address[] public sellersAdd;

  bytes32[] public txHash;

  mapping(address => Seller) public sellers;
  mapping(address => mapping(uint => Product)) public products;
  mapping(address => bool) public isSeller;


//Constructor function.
  constructor(address _escrowAdd) public {
    owner = msg.sender;
    escrow = Escrow(_escrowAdd);
  }

//Function to add a seller.
//Must be a new seller. Hence, seller address should not exist in the isSeller Mapping.
//a new Seller struct variable is created to push to "Seller[] public sellerList"
//Adding the struct to the mapping of address to struct.
//Added seller struct to the array of struct.
//Marked seller address as true to check later to avoid duplications.
//Added the seller address to the array of addresses that hold all the sellers.
  function addSeller(string _sellerName, string _sellerPhoneNumber, string _sellerEmail) public {
    require(!isSeller[msg.sender]);

    Seller memory newSeller = Seller({
      sellerName: _sellerName,
      sellerAddress: msg.sender,
      sellerPhoneNumber: _sellerPhoneNumber,
      sellerEmail: _sellerEmail,
      noOfProducts: 0
    });

    sellers[msg.sender] = newSeller;
    sellerList.push(newSeller);
    isSeller[msg.sender] = true;
    sellersAdd.push(msg.sender);

    emit AddedSeller(msg.sender, _sellerName, _sellerPhoneNumber, _sellerEmail);
  }

//Function to add an Item.
//Must be an existing seller. Therefore we check to see if the address exists as a registered seller.
//A new product struct is created to be pushed with the product details to "Product[] public productsArray"
//noOfProducts holds the amount of products each seller has under his/her account. This value increases as more products are added.
//The new product is added to the mapping using itemNo as mapping key(uint) which is later incremented to make room for next product
//noOfProducts is now incremented for when the next product is to be entered
/*Thew new product is also pushed to an array of products call productsArray. Please see that I used arrays here as well on top of mappings just so that I could iterate through the values without having to have any knowledge of mapping keys.*/
  function addItem(string _itemName, string _color, string _description, string _manufacturer, uint _warranty, uint _price, uint _productID, uint _quantity) public {
    require(isSeller[msg.sender]);

    Product memory newProduct = Product({
      itemName: _itemName,
      color: _color,
      description: _description,
      warranty: _warranty,
      manufacturer: _manufacturer,
      price: _price,
      productID: _productID,
      quantity: _quantity,
      inStock: true,
      oneSeller: msg.sender
    });

    uint itemNo = sellers[msg.sender].noOfProducts;
    sellers[msg.sender].sellerProducts[itemNo] = newProduct;
    sellers[msg.sender].noOfProducts++;
    productsArray.push(newProduct);
    products[msg.sender][newProduct.productID] = newProduct;
    emit AddedItem(msg.sender, _itemName, _color, _description, _manufacturer, _warranty, _price, _quantity);
  }

//Function to get sellers count.
  function getSellerCount() public view returns(uint) {
    return sellerList.length;
  }

//Function to get the products count so we can iterate through all products and display them.
  function getProductCount() public view returns(uint) {
    return productsArray.length;
  }

//Function for buying an item.
//Getting the specific product information. This can be done through react.js
//Pulling up seller details also. Seller struct is not used much over here but I believe we may need it when doing some error checking and things like that.
//Used to create a Unique ID for the paymentdetails mapping.
//This is where all the payment details are created. Note I did not add all the required values here. All required fields can be added later.
//New payment info is added to the mapping. With unique ID as mapping key(like you mentioned)
//Unique ID is then pushed to productID array (like you mentioned)
//Unique ID is then incremented. We can figure out a way to generate proper Unique IDs for this case. This was just a mockup.
//Amount is transferred to selleraddress. If fails, function throws. This can be redone to do better error handling. If it goes throgh, we then decrease the quantity.
//Check to see if there is enough quantity of other buyers.
  function buyItem(address _seller, uint _no, address[] _sigs) public payable {
    Product storage productIndex = products[_seller][_no];
    require(msg.sender != 0);
    require(msg.sender != productIndex.oneSeller, "Buyer address is same as Seller Address");
    require(msg.value >= productIndex.price);
    require(productIndex.inStock);
    bytes32 transactionHash = keccak256(abi.encodePacked(msg.sender, productIndex.oneSeller, _sigs, msg.value));
    txHash.push(transactionHash);

    escrow.createTransaction.value(msg.value)(msg.sender, productIndex.oneSeller, transactionHash, _sigs, productIndex.productID, msg.value);
    productIndex.quantity--;
  }

  function getMarketAccountBal() public view returns(uint) {
    return address(this).balance;
  }
}
