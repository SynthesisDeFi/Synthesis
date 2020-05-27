pragma solidity 0.4.25;

import "./SmartLoan.sol";

/**
 * @title IBorrowersRegistry
 * Keeps a registry of created trading accounts to verify their borrowing rights
 */
contract IBorrowersRegistry {

  function canBorrow(address _account) external view returns(bool);

  function getAccountForUser(address _user) external view returns(SmartLoan);

  function getOwnerOfAccount(SmartLoan _account) external view returns(address);

}
