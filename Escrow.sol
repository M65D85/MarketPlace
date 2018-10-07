pragma solidity ^0.4.19;

contract Escrow {

  enum Status{FUNDED, RELEASED}

  struct Transaction {
    address seller;
    address buyer;
    uint value;
    uint lastFunded;
    uint productID;
    bytes32 transactionHash;
    address[] signatures;
    Status status;
    mapping(address => bool) isOwner;
    mapping(address => bool) voted;
  }

  mapping(bytes32 => Transaction) public transactions;
  mapping(address => bytes32[]) public userTransactions;
  bytes32[] public transactionID;
  uint transactionCount;

  modifier onlyOwner(bytes32 _transactionHash) {
    require(msg.sender == transactions[_transactionHash].buyer);
    _;
  }

  function createTransaction(address _buyer, address _seller, bytes32 _transactionHash, address[] _signatures, uint _productID, uint _value) public payable {
    Transaction memory newTransaction = Transaction({
        buyer: _buyer,
        seller: _seller,
        value: _value,
        lastFunded: block.timestamp,
        productID: _productID,
        transactionHash: _transactionHash,
        signatures: _signatures,
        status: Status.FUNDED
      });

    transactions[_transactionHash] = newTransaction;
    transactions[_transactionHash].isOwner[_seller] = true;
    transactions[_transactionHash].isOwner[_buyer] = true;
    transactionID.push(_transactionHash);
    addOwners(_transactionHash);

    userTransactions[_buyer].push(_transactionHash);
    userTransactions[_seller].push(_transactionHash);
    transactionCount++;
  }

  function addOwners(bytes32 _transactionHash) private {
    Transaction storage transaction = transactions[_transactionHash];
    for(uint i = 0; i < transaction.signatures.length; i++) {
      require(transaction.signatures[i] != 0);
      require(!transaction.isOwner[transaction.signatures[i]]);

      transaction.isOwner[transaction.signatures[i]] = true;
    }
  }

  function signTransaction(bytes32 _transactionHash) public {
    Transaction storage transaction = transactions[_transactionHash];

    require(transaction.isOwner[msg.sender]);
    require(!transaction.voted[msg.sender]);
    transaction.voted[msg.sender] = true;
  }

  function addFunds(bytes32 _transactionHash) public payable onlyOwner(_transactionHash) {
    uint _value = msg.value;
    require(_value > 0);

    transactions[_transactionHash].value += _value;
    transactions[_transactionHash].lastFunded = block.timestamp;
  }

  function finalizeTransaction(bytes32 _transactionHash) public onlyOwner(_transactionHash){
    if(confirmHash(_transactionHash)){
      transferFunds(_transactionHash);
    } else {
      revert();
    }
  }

  function transferFunds(bytes32 _transactionHash) private {
    Transaction storage transaction = transactions[_transactionHash];

    require(transaction.value > 0);
    require(transaction.seller != address(0) && transaction.isOwner[transaction.seller]);
    require(transaction.status != Status.RELEASED);

    //_valueTransferred = transaction.value;
    transaction.seller.transfer(transaction.value);
    transaction.status = Status.RELEASED;
  }

  function confirmHash(bytes32 _transactionHash) internal view returns(bool){
    require(_transactionHash != 0);
    bytes32 calculatedHash = getHash(_transactionHash);

    return _transactionHash == calculatedHash;
  }

  function getHash(bytes32 _transactionHash) internal view returns(bytes32 hash) {
    Transaction storage transaction = transactions[_transactionHash];
    hash = keccak256(abi.encodePacked(transaction.buyer, transaction.seller, transaction.signatures, transaction.value));
  }

  function getUserTransactions(address _userAddress) external view returns(bytes32[]) {
    return userTransactions[_userAddress];
  }

  function getEscrowAccountBal() public view returns(uint) {
      return address(this).balance;
  }
}
