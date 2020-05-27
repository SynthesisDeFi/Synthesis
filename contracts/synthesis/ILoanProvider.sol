pragma solidity 0.4.25;

import "../synthetix/Synth.sol";


/**
 * @title ILoanProvider
 *
 */
contract ILoanProvider {

  function asset() external view returns(Synth);

  function borrow(uint256 _amount) external;

  function repay(uint256 _amount) external;

  function getMyDebt() external view returns(uint256);

}
