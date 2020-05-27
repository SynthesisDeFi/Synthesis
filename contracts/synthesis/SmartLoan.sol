pragma solidity 0.4.25;

import "../synthetix/Owned.sol";

import "../synthetix/interfaces/ISynthetix.sol";
import "../synthetix/interfaces/IExchangeRates.sol";
import "../synthetix/interfaces/IDepot.sol";
import "../synthetix/Synth.sol";
import "../synthetix/SafeDecimalMath.sol";
import "./ILoanProvider.sol";

/**
 * @title SmartLoan
 *
 */
contract SmartLoan is MixinResolver {
  using SafeMath for uint;
  using SafeDecimalMath for uint;

  bytes32 public S_USD = 'sUSD';
  bytes32 public S_GBP = 'sGBP';
  bytes32 public S_EUR = 'sEUR';
  bytes32 public S_BTC = 'sBTC';
  bytes32 public S_ETH = 'sETH';
  bytes32 public S_EOS = 'sEOS';
  bytes32 public S_XAU = 'sXAU';
  bytes32 public S_XAG = 'sXAG';
  bytes32 public EMPTY = '';
  bytes32[8] public ASSETS = [S_USD, S_GBP, S_EUR, S_BTC, S_ETH, S_EOS, S_XAU, S_XAG];


  uint256 private constant SOLVENCY_PRECISION = 1000;
  uint256 private constant MAX_SOLVENCY_RATIO = 10000;

  uint256 private constant LIQUIDATION_BONUS = 10;
  uint256 private constant LIQUIDATION_CAP = 1300;


  bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
  bytes32 private constant CONTRACT_DEPOT = "Depot";
  bytes32[24] public CONTRACTS = [CONTRACT_EXRATES, CONTRACT_DEPOT];

  ISynthetix private synthetix;
  ILoanProvider private loanProvider;

  uint256 public minSolvencyRatio;

  constructor(
    ISynthetix _synthetix,
    address _synthethixResolver,
    ILoanProvider _loanProvider,
    uint256 _minSolvencyRatio,
    address _owner) public
    MixinResolver(_owner, _synthethixResolver, CONTRACTS)
  {
    synthetix = _synthetix;
    loanProvider = _loanProvider;
    minSolvencyRatio = _minSolvencyRatio;
  }

  function fund() external payable remainsSolvent onlyOwner {
    depot().exchangeEtherForSynths.value(msg.value)();

    emit Funded(msg.sender, msg.value, now);
  }

  function withdraw(uint256 _amount) external remainsSolvent payable onlyOwner {
    require(loanProvider.asset().transfer(msg.sender, _amount));

    emit Withdrawn(msg.sender, _amount, now);
  }

  //FIXME: Should be modified by remainsSolvent but left open for demo purpose
  function borrow(uint256 _amount) external onlyOwner {
    loanProvider.borrow(_amount);

    emit Borrowed(msg.sender, _amount, now);
  }

  function repay(uint256 _amount) public remainsSolvent {
    if (isSolvent()) {
      require(msg.sender == owner);
    }

    require(loanProvider.asset().transfer(address(loanProvider), _amount));
    loanProvider.repay(_amount);

    emit Repaid(msg.sender, _amount, now);
  }

  function trade(bytes32 _assetToSell, uint256 _amountToSell, bytes32 _assetToBuy) external {
    //If the account is insolvent we allow liquidators to swap assets so they can be returned
    //Otherwise only the owner may trade
    if (isSolvent()) {
      require(msg.sender == owner);
    }

    synthetix.exchange(_assetToSell, _amountToSell, _assetToBuy);

    emit Traded(msg.sender, _assetToSell, _amountToSell, _assetToBuy, now);
  }


  function liquidate(uint256 _amount) remainsSolvent {
    require(!isSolvent(), "Cannot liquidate a solvent account");
    repay(_amount);
    uint256 bonus = _amount.mul(LIQUIDATION_BONUS).div(100);
    require(loanProvider.asset().transfer(msg.sender, bonus));
    require(getSolvencyRatio() <= LIQUIDATION_CAP);
  }


  function getSolvencyRatio() public view returns(uint256) {
    uint256 debt = getMyDebt();
    if (debt == 0) {
      return MAX_SOLVENCY_RATIO;
    } else {
      return getAccountValue().mul(SOLVENCY_PRECISION).div(debt);
    }
  }


  function isSolvent() public view returns(bool) {
    return getSolvencyRatio() >= minSolvencyRatio;
  }


  function getMyDebt() public view returns(uint256) {
    return loanProvider.getMyDebt();
  }


  function getAccountValue() public view returns(uint256) {
    uint256 total = 0;
    for(uint i = 0; i< ASSETS.length; i++) {
        total = total.add(getAssetValue(ASSETS[i]));
    }
    return total;
  }


  function getAssetBalance(bytes32 _assetKey) public view returns(uint256) {
    Synth s = synthetix.synths(_assetKey);
    return s.balanceOf(address(this));
  }


  function getAllAssetsBalances() public view returns(uint256[]) {
    uint256[] memory results = new uint256[] (ASSETS.length);
    for(uint i = 0; i< ASSETS.length; i++) {
      Synth s = synthetix.synths(ASSETS[i]);
      results[i] = s.balanceOf(address(this));
    }
    return results;
  }


  function getAssetPrice(bytes32 _assetKey) public view returns(uint256) {
    IExchangeRates exRates = exchangeRates();
    return exRates.rateForCurrency(_assetKey);
  }


  function getAllAssetsPrices() public view returns(uint256[]) {
    uint256[] memory results = new uint256[] (ASSETS.length);
    IExchangeRates exRates = exchangeRates();
    for(uint i = 0; i< ASSETS.length; i++) {
      results[i] = exRates.rateForCurrency(ASSETS[i]);
    }
    return results;
  }


  function getAssetValue(bytes32 _assetKey) public view returns(uint256) {
    return getAssetBalance(_assetKey).multiplyDecimalRound(getAssetPrice(_assetKey));
  }


  function exchangeRates() internal view returns (IExchangeRates) {
    return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
  }


  function depot() internal view returns (IDepot) {
    return IDepot(requireAndGetAddress(CONTRACT_DEPOT, "Missing Depot address"));
  }

  /* ========== Events ========== */
  event Borrowed(address indexed borrower, uint amount, uint time);

  event Repaid(address indexed borrower, uint amount, uint time);

  event Funded(address indexed funder, uint amount, uint time);

  event Withdrawn(address indexed funder, uint amount, uint time);

  event Traded(address indexed trader, bytes32 assetToSell, uint amount, bytes32 assetToBuy, uint time);


  // ========== MODIFIERS ==========

  modifier remainsSolvent() {
    _;
    require(isSolvent(), "The action may cause an account to become insolvent.");
  }


}
