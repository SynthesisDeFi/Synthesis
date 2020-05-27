import FACTORY from '@contracts/SmartLoansFactory.json'
import STA from '@contracts/SmartLoan.json'

import { getProvider, getMainAccount } from "./network.js"
import state from "@/state";

const ethers = require('ethers');
const utils = ethers.utils;

const SUSD_ADDRESS = "0x57Ab1ec28D129707052df4dF418D58a2D46d5f51";
const S_USD = utils.formatBytes32String('sUSD');
const S_BTC = utils.formatBytes32String('sBTC');

const DEFAULT_COLLATERAL_RATIO = 0.3;
const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

var cachedFactory, cachedSta;

async function getFactory() {
  if (!cachedFactory) {
    let provider = await getProvider();
    cachedFactory = new ethers.Contract(FACTORY.networks["42"].address, FACTORY.abi, provider.getSigner());
  }
  return cachedFactory;
}

async function getSta() {
  if (!cachedSta) {
    let provider = await getProvider();
    cachedSta = new ethers.Contract(state.account.address, STA.abi, provider.getSigner());
  }
  return cachedSta;
}


export async function calculateCollateral(amount) {
  if (amount) {
    let ethPrice = state.pool.ethRate;
    return amount * DEFAULT_COLLATERAL_RATIO / ethPrice;
  }
}

export async function getTradingAccount() {
  let factory = await getFactory();
  let myEthAddress = await getMainAccount();
  let account = await factory.creatorsToAccounts(myEthAddress);
  console.log("Linked trading account: " + account);
  if (account === NULL_ADDRESS) {
    state.account.isCreated = false;
  } else {
    state.account.isCreated = true;
    state.account.address = account;
    updateTradingAccount();
  }
}

export async function updateTradingAccount(trials) {
  let sta = await getSta();

  state.account.balance = parseFloat(ethers.utils.formatEther(await sta.getAccountValue()));
  state.account.debt = parseFloat(ethers.utils.formatEther(await sta.getMyDebt()));
  state.account.collateral = state.account.balance - state.account.debt;
  state.account.solvencyRatio = Math.round(parseFloat(await sta.getSolvencyRatio())/10);

  let prices = await sta.getAllAssetsPrices();
  let balances = await sta.getAllAssetsBalances();

  for(var i=0; i< state.account.assets.length; i++) {
    //console.log("Price " + state.account.assets[i].name + " : " + ethers.utils.formatEther(prices[i]));
    state.account.assets[i].price = parseFloat(ethers.utils.formatEther(prices[i]));
    state.account.assets[i].balance = parseFloat(ethers.utils.formatEther(balances[i]));
    state.account.assets[i].value = state.account.assets[i].price * state.account.assets[i].balance;
    state.account.assets[i].share = state.account.assets[i].value / state.account.balance;
  }
  //Infura, sometimes gives stale data, so we keep updating the data for a while
  if (trials>0) {
    console.log("Reading data again trial: " + trials);
    setTimeout(function() {
      updateTradingAccount(trials - 1);
    }, 3000);
  }
}

export async function createAccount(borrowingAmount) {
  console.log("Creating account with balance: " + borrowingAmount);
  let provider = await getProvider();
  let factory = await getFactory();

  let collateral = await calculateCollateral(borrowingAmount);
  let tx = await factory.createAndFundLoan(
    utils.parseEther(borrowingAmount),
    {gasLimit: 5000000, value: utils.parseEther(collateral.toString())});
  console.log("Creating account: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  await getTradingAccount();
}

export async function trade(assetToSell, tradeAmount, assetToBuy) {
  console.log("Selling " + tradeAmount + " of " + assetToSell + " to buy " + assetToBuy);

  let sta = await getSta();
  let provider = await getProvider();

  let tx = await sta.trade(
    utils.formatBytes32String(assetToSell),
    utils.parseEther(tradeAmount),
    utils.formatBytes32String(assetToBuy)
  );
  console.log("Trading tx: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  await updateTradingAccount(10);
}

export async function borrow(amount) {
  console.log("Borrowing: " + amount);

  let provider = await getProvider();
  let sta = await getSta();

  let tx = await sta.borrow(utils.parseEther(amount));
  console.log("Borrow: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  updateTradingAccount(10);
}

export async function fund(amount) {
  console.log("Funding: " + amount);

  let ethPrice = state.pool.ethRate;
  let amountInEth = amount / ethPrice;
  console.log("Sending eth: " + amountInEth);


  let provider = await getProvider();
  let sta = await getSta();

  let tx = await sta.fund(
    {gasLimit: 1000000, value: utils.parseEther(amountInEth.toFixed(10))}
  );
  console.log("Funding: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  updateTradingAccount(10);
}

export async function withdraw(amount) {
  console.log("Withdrawing: " + amount);

  let provider = await getProvider();
  let sta = await getSta();

  let tx = await sta.withdraw(utils.parseEther(amount));
  console.log("Withdrawal: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  updateTradingAccount(10);
}

export async function repay(amount) {
  console.log("Repaying: " + amount);

  let provider = await getProvider();
  let sta = await getSta();

  let tx = await sta.repay(utils.parseEther(amount));
  console.log("Repaid: " + tx.hash);
  let receipt = await provider.waitForTransaction(tx.hash);
  console.log(receipt);
  updateTradingAccount(10);
}

