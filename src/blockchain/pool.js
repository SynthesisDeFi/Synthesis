import LENDING_POOL from '@contracts/LendingPool.json'
import SYNTH from '@contracts/Synth.json'

import { getProvider, getMainAccount } from "./network.js"
import state from "@/state";

const ethers = require('ethers');
const utils = ethers.utils;

const SUSD_ADDRESS = "0x57Ab1ec28D129707052df4dF418D58a2D46d5f51";
const S_USD = utils.formatBytes32String('sUSD');
const S_BTC = utils.formatBytes32String('sBTC');

var cachedPool;

async function getPool() {
  if (!cachedPool) {
    let provider = await getProvider();
    cachedPool = new ethers.Contract(LENDING_POOL.networks["42"].address, LENDING_POOL.abi, provider.getSigner());
  }
  return cachedPool;
}

async function getStats() {
  // let pool = getPool();
  //
  //
  //
  // let available = await pool.getAvailableToBorrow();
  // console.log("Available to borrow: " + ethers.utils.formatEther(available));
  //
  // let poolBorrowerBalance = await pool.getBorrowedBy(wallet.address);
  // console.log("Pool borrower balance: " + ethers.utils.formatEther(poolBorrowerBalance));
  //
  // let sBTCPrice = await sta.getAssetPrice(S_BTC);
  // console.log("sBTC price: " + ethers.utils.formatEther(sBTCPrice));
  //
  // let sBTCValue = await sta.getAssetValue(S_BTC);
  // console.log("sBTC value: " + ethers.utils.formatEther(sBTCValue));
}

export async function getSynthRate() {
  let pool = await getPool();
  let rate = await pool.getSynthForEth();
  state.pool.ethRate = parseFloat(ethers.utils.formatEther(rate));
  console.log("Rate: " + state.pool.ethRate);
}

export async function getMyDeposits() {
  let pool = await getPool();
  let main = await getMainAccount();

  let poolDepositorBalance = await pool.getDepositedBy(main);
  state.pool.myDeposits = parseFloat(ethers.utils.formatEther(poolDepositorBalance));

  //Pool stats
  state.pool.myDeposits = parseFloat(ethers.utils.formatEther(poolDepositorBalance));
  state.pool.totalDeposited = parseFloat(ethers.utils.formatEther(await pool.totalDeposited()));
  state.pool.totalBorrowed = parseFloat(ethers.utils.formatEther(await pool.totalBorrowed()));
  state.pool.effectiveRate = state.pool.totalBorrowed / state.pool.totalDeposited * 0.05;

  console.log("Pool depositor balance: " + state.pool.myDeposits);
}

export async function sendDeposit(amount) {
  console.log("Depositing: " + amount);
  let provider = await getProvider();
  let pool = await getPool();
  let tx = await pool.deposit({gasLimit: 1000000, value: utils.parseEther(amount)});
  console.log("Deposited: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  await getMyDeposits();
}

export async function withdraw(amount) {
  console.log("Withdrawing: " + amount);

  let provider = await getProvider();
  let pool = await getPool();
  let tx = await pool.withdraw(utils.parseEther(amount));
  console.log("Withdrawn: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  await getMyDeposits();
}

