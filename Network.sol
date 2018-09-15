pragma solidity ^0.4.24;

contract Network {

  enum Status{FUNDED, RELEASED}

  struct Transaction {
    address seller;
    address buyer;
    uint value;
    bytes32 uid;
    address[] signatures;
    Status status;
    mapping(address => bool) isOwner;
    mapping(address => bool) voted;
  }

  mapping(bytes32 => Transaction) public transactions;
  bytes32[] public id;

  function createTransaction(address _buyer, address _seller, bytes32 _uid, address[] _signatures, uint _value) public {

    Transaction memory newTransaction = Transaction({
        buyer: _buyer,
        seller: _seller,
        value: _value,
        uid: _uid,
        signatures: _signatures,
        status: Status.FUNDED
      });

      transactions[_uid] = newTransaction;
      transactions[_uid].isOwner[_seller] = true;
      transactions[_uid].isOwner[_buyer] = true;
      id.push(_uid);

      for(uint i = 0; i < _signatures.length; i++) {
        require(_signatures[i] != 0);
        //require(!transactions[_uid].isOwner[_signatures[i]]);

        transactions[_uid].isOwner[_signatures[i]] = true;
      }
  }

  function addFunds(bytes32 _uid) public payable {
    uint _value = msg.value;
    require(_value > 0);

    transactions[_uid].value += _value;
  }

  function transferFunds(bytes32 _uid, uint _amount, address _destination) private returns(uint _valueTransferred) {
    Transaction storage trans = transactions[_uid];

    require(_amount > 0);
    require(_destination != address(0) && trans.isOwner[_destination]);

    _valueTransferred = _amount;
    _destination.transfer(_amount);
  }

}
