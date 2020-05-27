pragma solidity 0.4.25;

import "../synthetix/Owned.sol";

import "../synthetix/interfaces/ISynthetix.sol";
import "../synthetix/interfaces/IExchangeRates.sol";
import "../synthetix/Depot.sol";
import "../synthetix/Synth.sol";
import "../synthetix/SafeDecimalMath.sol";
import "./ILoanProvider.sol";
import "./IBorrowersRegistry.sol";

/**
 * @title LendingPool
 *
 */
contract LendingPool is MixinResolver, ILoanProvider {
  using SafeMath for uint;
  using SafeDecimalMath for uint;


  bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
  bytes32 private constant CONTRACT_DEPOT = "Depot";
  bytes32[24] public CONTRACTS = [CONTRACT_EXRATES, CONTRACT_DEPOT];

  ISynthetix private synthetix;
  Synth public asset;
  IBorrowersRegistry borrowersRegistry;


  uint256 public borrowingRate;

  uint256 public totalDeposited;
  uint256 public totalBorrowed;


  uint256 private constant RATE_PRECISION = 10000;
  mapping(address => uint256) public deposits;
  mapping(address => uint256) public loans;

  constructor(bytes32 _assetKey, ISynthetix _synthetix, address _synthethixResolver) public
  MixinResolver(msg.sender, _synthethixResolver, CONTRACTS)
  {
    synthetix = _synthetix;
    asset = synthetix.synths(_assetKey);
    borrowingRate = 500; // Default 5% rate
  }

  function deposit() external payable {
    uint256 balanceBefore = asset.balanceOf(address(this));
    depot().exchangeEtherForSynths.value(msg.value)();
    uint256 balanceAfter = asset.balanceOf(address(this));
    uint256 deposited = balanceAfter.sub(balanceBefore);

    //Update internal state
    deposits[msg.sender] = deposits[msg.sender].add(deposited);
    totalDeposited = totalDeposited.add(deposited);

    emit Deposited(msg.sender, deposited, now);
  }

  function withdraw(uint256 _amount) external  {
    require(deposits[msg.sender] >= _amount, "Not enough money to be withdrawn");
    uint256 availableInPool = asset.balanceOf(address(this));
    uint256 withdrawn = availableInPool >= _amount ? _amount : availableInPool;

    //Update internal state
    deposits[msg.sender] = deposits[msg.sender].sub(withdrawn);
    totalDeposited = totalDeposited.sub(withdrawn);

    asset.transfer(msg.sender, withdrawn);

    emit Withdrawn(msg.sender, withdrawn, now);
  }

  function borrow(uint256 _amount) external {
    require(getAvailableToBorrow() >= _amount, "Not enough funds available in the pool.");

    //Update internal state
    loans[msg.sender] = loans[msg.sender].add(_amount);
    totalBorrowed = totalBorrowed.add(_amount);

    require(asset.transfer(msg.sender, _amount));

    emit Borrowed(msg.sender, _amount, now);
  }

  function repay(uint256 _amount) isAccreditedBorrower external  {

    //Update internal state
    loans[msg.sender] = loans[msg.sender].sub(_amount);
    totalBorrowed = totalBorrowed.sub(_amount);

    emit Repaid(msg.sender, _amount, now);
  }


  function setborrowersRegistry(IBorrowersRegistry _registry) onlyOwner {
    borrowersRegistry = _registry;
  }

  function setBorrowingRate(uint256 _newRate) onlyOwner {
    borrowingRate = _newRate;
  }

  function getDepositedBy(address _depositor) public view returns(uint256) {
    return deposits[_depositor];
  }

  function getBorrowedBy(address _borrower) public view returns(uint256) {
    return loans[_borrower];
  }

  function getMyDebt() external view returns(uint256) {
    return loans[msg.sender];
  }

  function getAvailableToBorrow() public view returns(uint256) {
    return totalDeposited.sub(totalBorrowed);
  }

  function asset() external view returns(Synth) {
    return asset;
  }

  function getSynthForEth() public view returns(uint256) {
    return depot().synthsReceivedForEther(1 ether);
  }

  function exchangeRates() internal view returns (IExchangeRates) {
    return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
  }

  function depot() internal view returns (Depot) {
    return Depot(requireAndGetAddress(CONTRACT_DEPOT, "Missing Depot address"));
  }


  /* ========== Events ========== */
  event Borrowed(address indexed borrower, uint amount, uint time);

  event Repaid(address indexed borrower, uint amount, uint time);

  event Deposited(address indexed depositor, uint amount, uint time);

  event Withdrawn(address indexed depositor, uint amount, uint time);


  // ========== MODIFIERS ==========

  modifier isAccreditedBorrower() {
    require(borrowersRegistry.canBorrow(msg.sender), "Given account is not allowed to borrow from the pool.");
    _;
  }


}
