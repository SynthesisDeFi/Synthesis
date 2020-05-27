pragma solidity 0.4.25;

import "../synthetix/Owned.sol";

import "../synthetix/interfaces/ISynthetix.sol";
import "../synthetix/interfaces/IExchangeRates.sol";
import "../synthetix/interfaces/IDepot.sol";
import "../synthetix/Synth.sol";
import "./SmartLoan.sol";
import "./LendingPool.sol";
import "./IBorrowersRegistry.sol";

/**
 * @title SmartLoansFactory
 *
 */
contract SmartLoansFactory is IBorrowersRegistry {

  event SmartLoanCreated(address indexed accountAddress, address indexed creator);

  ISynthetix private synthetix;
  address private synthetixResolver;
  LendingPool private lendingPool;

  uint256 public minSolvencyRatio;

  uint256 private constant MAX_VAL = 2**256-1 ether;

  mapping(address => SmartLoan) public creatorsToAccounts;
  mapping(address => address) public accountsToCreators;

  constructor(
    ISynthetix _synthetix,
    address _synthethixResolver,
    LendingPool _lendingPool,
    uint256 _minSolvencyRatio) public {
    synthetix = _synthetix;
    synthetixResolver = _synthethixResolver;
    lendingPool = _lendingPool;
    minSolvencyRatio = _minSolvencyRatio;
  }

  function createLoan() public returns(SmartLoan) {
    SmartLoan newAccount = new SmartLoan(synthetix, synthetixResolver, lendingPool, minSolvencyRatio, msg.sender);

    //Update registry and emit event
    updateRegistry(newAccount);

    return newAccount;
  }

  function createAndFundLoan(uint256 _initialDebt) external payable returns(SmartLoan) {
    SmartLoan newAccount = new SmartLoan(synthetix, synthetixResolver, lendingPool, minSolvencyRatio, this);

    //Fund account with own funds and credit
    newAccount.fund.value(msg.value)();
    newAccount.borrow(_initialDebt);
    require(newAccount.isSolvent());

    newAccount.transferOwnership(msg.sender);

    //Update registry and emit event
    updateRegistry(newAccount);


    return newAccount;
  }

  function updateRegistry(SmartLoan _newAccount) internal {
    creatorsToAccounts[msg.sender] = _newAccount;
    accountsToCreators[address(_newAccount)] = msg.sender;

    emit SmartLoanCreated(address(_newAccount), msg.sender);
  }

  function canBorrow(address _account) external view returns(bool) {
    return accountsToCreators[_account] != 0x0;
  }

  function getAccountForUser(address _user) external view returns(SmartLoan) {
    return creatorsToAccounts[_user];
  }

  function getOwnerOfAccount(SmartLoan _account) external view returns(address) {
    return SmartLoan(accountsToCreators[_account]);
  }

}
