/* eslint-disable */
<template>
  <div class="page">

    <md-dialog :md-active.sync="processing" :md-click-outside-to-close="false">
      <md-dialog-title>Processing transaction</md-dialog-title>

      <md-dialog-content style="text-align: center">


        <md-progress-spinner md-mode="indeterminate"></md-progress-spinner>

        <div>
          Please wait....
        </div>

      </md-dialog-content>
    </md-dialog>


    <div class="md-layout md-gutter" v-show="!account.isCreated">

      <div class="md-layout-item md-size-25"></div>

      <div class="md-layout-item md-size-50">

        <md-card>
          <md-card-header>
            <md-card-header-text>
              <div class="md-title">Take a new smart loan </div>
              <div class="md-subhead">Decide how much you want to borrow and provide the collateral</div>

            </md-card-header-text>

          </md-card-header>

          <md-card-content>

            <form novalidate>
              <div class="form-container">
                <md-field>
                  <label for="borrowAmount">Initial balance (amount to borrow) in USD</label>
                  <md-input name="borrowAmount" id="borrowAmount" v-model="borrowAmount"
                            :disabled="processing"/>
                </md-field>
                <div class="collateral-info">
                  You will need to provide <b>{{collateral | eth}}</b> as an initial buffer.
                </div>
              </div>

            </form>



            <div style="text-align: center">
              <md-button class="md-raised md-primary pool-button" @click="createAccount">Create</md-button>
            </div>
          </md-card-content>

        </md-card>


      </div>

    </div>

    <div class="md-layout md-gutter" v-show="account.isCreated" style="margin-top:-30px;">

      <div class="md-layout-item md-size-10"></div>

      <div class="md-layout-item md-size-80">

        <div class="md-layout md-gutter">

        <div class="md-layout-item md-medium-size-50 md-size-33 widget">
          <div class="md-card md-card-stats md-theme-default">
            <div class="md-card-header md-card-header-icon md-card-header-blue" style="height: 100px;">
              <div class="card-icon">
                <i class="md-icon md-icon-font md-theme-default md-size-3x" style="color:#8A48DB">
                  account_balance_wallet
                </i>
              </div>
              <div class="category">
                Borrowed
                <div class="cat-value">{{ account.debt | usd }}</div>
              </div>
            </div>

            <md-card-content>
              <div class="actions-card">
                <md-button class="md-primary" @click="showRepayPanel = true">Repay</md-button>
                <md-button class="md-accent" @click="showBorrowMorePanel = true">Borrow more</md-button>
              </div>
            </md-card-content>

          </div>
        </div>

        <div class="md-layout-item md-medium-size-50 md-size-33 widget">
          <div class="md-card md-card-stats md-theme-default">
            <div class="md-card-header md-card-header-icon md-card-header-blue" style="height: 100px;">
              <div class="card-icon">
                <i class="md-icon md-icon-font md-theme-default md-size-3x" style="color:red">
                  local_hospital
                </i>
              </div>
              <div class="category">
                Solvency ratio
                <div class="cat-value">{{ account.solvencyRatio }}</div>
              </div>
            </div>

            <md-card-content>
              <div class="actions-card solvency-warning" style="padding-top:10px;">
                Remember to keep it above 120
              </div>
            </md-card-content>

          </div>
        </div>

        <div class="md-layout-item md-medium-size-50 md-size-33 widget">
          <div class="md-card md-card-stats md-theme-default">
            <div class="md-card-header md-card-header-icon md-card-header-blue" style="height: 100px;">
              <div class="card-icon">
                <i class="md-icon md-icon-font md-theme-default md-size-3x" style="color:green">
                  account_box
                </i>
              </div>
              <div class="category">
                Your contibution
                <div class="cat-value">{{ account.collateral | usd }}</div>
              </div>
            </div>

            <md-card-content>
              <div class="actions-card">
                <md-button class="md-primary" @click="showDepositMorePanel = true">Deposit more</md-button>
                <md-button class="md-accent" @click="showWithdrawPanel = true">Withdraw</md-button>
              </div>
            </md-card-content>

          </div>
        </div>

        </div>

        <md-card>
          <md-card-header>
            <md-card-header-text>
              <div class="md-title" style="float: left">Your assets </div>

              <div style="text-align: center; ">
                <md-button class="md-raised md-primary pool-button" @click="showTradePanel = true">Trade</md-button>
                <div class="category">
                  Total value
                  <div class="cat-value">{{ account.balance | usd }}</div>
                </div>
              </div>


            </md-card-header-text>

          </md-card-header>

          <md-card-content>

            <md-table class="assets">
              <md-table-row>
                <md-table-head>Asset</md-table-head>
                <md-table-head>Symbol</md-table-head>
                <md-table-head>Price</md-table-head>
                <md-table-head>Holdings</md-table-head>
                <md-table-head>Value</md-table-head>
                <md-table-head>Share</md-table-head>
              </md-table-row>

              <md-table-row v-for="a in account.assets" v-bind:key="a.symbol">
                <md-table-cell>{{a.name}}</md-table-cell>
                <md-table-cell>{{a.symbol}}</md-table-cell>
                <md-table-cell>{{a.price | usd}}</md-table-cell>
                <md-table-cell>{{a.balance | units}}</md-table-cell>
                <md-table-cell>{{a.value | usd}}</md-table-cell>
                <md-table-cell>{{a.share | percent}}</md-table-cell>
              </md-table-row>
            </md-table>
          </md-card-content>

        </md-card>


      </div>

    </div>

    <md-drawer class="md-drawer md-right" :md-active.sync="showTradePanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Trade</span>
      </md-toolbar>

      <div class="text">
        Trade between your assets.
      </div>

      <form novalidate>
        <div class="form-container">

          <md-field>
            <label for="tradeAmount">Asset to sell</label>
            <md-select v-model="assetToSell" name="assetToSell" id="assetToSell">
              <md-option v-for="(a, index) in account.assets" :value="a.symbol" :key="a.symbol">{{a.name}}
              </md-option>
            </md-select>
          </md-field>

          <md-field>
            <label for="tradeAmount">Amount to sell</label>
            <md-input name="tradeAmount" id="tradeAmount" v-model="tradeAmount"
                      :disabled="processing"/>
          </md-field>

          <md-field>
            <label for="assetToBuy">Asset to buy</label>
            <md-select v-model="assetToBuy" name="assetToBuy" id="assetToBuy">
              <md-option v-for="(a, index) in account.assets" :value="a.symbol" :key="a.symbol">{{a.name}}
              </md-option>
            </md-select>
          </md-field>

        </div>

        <md-button class="md-primary md-raised pool-button" @click="trade()">Trade</md-button>

      </form>
    </md-drawer>

    <md-drawer class="md-drawer md-right" :md-active.sync="showRepayPanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Repay</span>
      </md-toolbar>

      <div class="text">
        Pay back your loan to improve the solvency ratio.
      </div>

      <form novalidate>
        <div class="form-container">
          <md-field>
            <label for="repayAmount">Amount in Usd</label>
            <md-input name="repayAmount" id="repayAmount" v-model="repayAmount"
                      :disabled="processing"/>
          </md-field>
        </div>

        <md-button class="md-primary md-raised pool-button" @click="repay()">Repay</md-button>

      </form>
    </md-drawer>

    <md-drawer class="md-drawer md-right" :md-active.sync="showBorrowMorePanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Borrow more</span>
      </md-toolbar>

      <div class="text">
        Borrow more funds to expand your portfolio.
      </div>

      <form novalidate>
        <div class="form-container">
          <md-field>
            <label for="borrowMoreAmount">Amount in Usd</label>
            <md-input name="borrowMoreAmount" id="borrowMoreAmount" v-model="borrowMoreAmount"
                      :disabled="processing"/>
          </md-field>
        </div>

        <md-button class="md-primary md-raised pool-button" @click="borrowMore()">Borrow</md-button>

      </form>
    </md-drawer>

    <md-drawer class="md-drawer md-right" :md-active.sync="showDepositMorePanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Deposit more</span>
      </md-toolbar>

      <div class="text">
        Deposit more funds to expand your portfolio.
      </div>

      <form novalidate>
        <div class="form-container">
          <md-field>
            <label for="borrowMoreAmount">Amount in Usd</label>
            <md-input name="depositMoreAmount" id="depositMoreAmount" v-model="depositMoreAmount"
                      :disabled="processing"/>
          </md-field>
        </div>

        <md-button class="md-primary md-raised pool-button" @click="depositMore()">Deposit</md-button>

      </form>
    </md-drawer>

    <md-drawer class="md-drawer md-right" :md-active.sync="showWithdrawPanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Withdraw funds</span>
      </md-toolbar>

      <div class="text">
        Withdraw funds to cash out your earnings.
      </div>

      <form novalidate>
        <div class="form-container">
          <md-field>
            <label for="withdrawAmount">Amount in Usd</label>
            <md-input name="withdrawAmount" id="withdrawAmount" v-model="withdrawAmount"
                      :disabled="processing"/>
          </md-field>
        </div>

        <md-button class="md-primary md-raised pool-button" @click="makeWithdraw()">Withdraw</md-button>

      </form>
    </md-drawer>







  </div>
</template>

<script>
  import {getMyDeposits, sendDeposit} from '@/blockchain/pool'
  import {createAccount, calculateCollateral, getTradingAccount, trade, repay, borrow, fund, withdraw} from '@/blockchain/trade'
  import State from '@/state'
  import RangeSlider from 'vue-range-slider'
  import 'vue-range-slider/dist/vue-range-slider.css'
  import 'vue-select/dist/vue-select.css';
  import vSelect from 'vue-select'

  export default {
    name: 'Pool',
    components: {
      RangeSlider, vSelect
    },
    data() {
      return {
        account: State.account,
        borrowAmount: 0,
        showTradePanel: false,
        showBorrowMorePanel: false,
        showRepayPanel: false,
        showDepositMorePanel:false,
        showWithdrawPanel:false,
        currencies: State.currencies,
        assetToSell: null,
        tradeAmount: 0,
        assetToBuy: null,
        processing: false,

        repayAmount: 0,
        borrowMoreAmount:0,
        depositMoreAmount: 0,
        withdrawAmount: 0
      }
    },
    asyncComputed: {
      async collateral() {
        return await calculateCollateral(this.borrowAmount);
      }
    },
    beforeCreate: async function () {
      await getTradingAccount();
    },
    methods: {
      onCurrencyChange: function () {
        console.log("Currency changed: " + this.selectedCurrency.title);
        this.deposit = this.selectedCurrency.balance / 2;
        this.maxDeposit = this.selectedCurrency.balance;
        this.step = this.selectedCurrency.step;
        this.precision = this.selectedCurrency.precision;
      },
      createAccount: async function () {
        this.processing = true;
        try {
          await createAccount(this.borrowAmount);

          let toast = this.$toasted.show("A new account has been created!", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } finally {
          this.processing = false;
        }
      },
      trade: async function () {
        this.processing = true;
        try {
          await trade(this.assetToSell, this.tradeAmount, this.assetToBuy);

          let toast = this.$toasted.show("The trade was processed successfully!", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } finally {
          this.processing = false;
          this.showTradePanel = false;
        }
      },
      repay: async function () {
        this.processing = true;
        try {
          await repay(this.repayAmount);

          let toast = this.$toasted.show("You've repaid part of the loan", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } catch (error) {
          console.log("ERROR: " + error);
          let toast = this.$toasted.show("Error processing transaction.", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } finally {
          this.processing = false;
          this.showRepayPanel = false;
        }
      },
      borrowMore: async function () {
        this.processing = true;
        try {
          await borrow(this.borrowMoreAmount);

          let toast = this.$toasted.show("You've borrowed more funds.", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } finally {
          this.processing = false;
          this.showBorrowMorePanel = false;
        }
      },
      depositMore: async function () {
        this.processing = true;
        try {
          await fund(this.depositMoreAmount);

          let toast = this.$toasted.show("You've added more funds to the account.", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } finally {
          this.processing = false;
          this.showDepositMorePanel = false;
        }
      },
      makeWithdraw: async function() {
        this.processing = true;
        try {
          await withdraw(this.withdrawAmount);

          let toast = this.$toasted.show("You've withdrawn the funds.", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } catch (error) {
          console.log("ERROR: " + error);
          let toast = this.$toasted.show("Error: Are you sure the loan will remain solvent?", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'error'
          });
        } finally {
          this.processing = false;
          this.showWithdrawPanel = false;
        }
      }
    }
  }
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">

  div.page {
    padding: 60px 20px 0 20px;
    width: 100%;
    height: 800px;
    text-align: center;
    background-color: #F5F5F5;
  }


  .text {
    font-size: 36px;
    padding: 30px 0 30px 0;
  }

  .dinput {
    width: 50px;
    border-bottom: 1px solid gray;
  }

  .slider {
    /* overwrite slider styles */
    width: 500px;
  }

  .v-select {
    min-width: 150px;
    display: inline-block;
  }

  .pool-button {
    border-radius: 30px;
    height: 50px;
    font-size: 14px;
    width: 120px;
    margin-left:20px;
    margin-right:20px;
  }

  .md-dialog {
    max-height: none;
    width: 550px;
    height: 550px;
  }

  .container {
    position: relative;
    text-align: center;
    color: white;
  }

  .image-overlay {
    position: absolute;
    top: 30px;
    left: 40px;
    font-size: 24px;
  }

  .range-slider-fill {
    background-color: #E84F89;
  }

  .vs__clear {
    display: none !important;
  }

  .v-select {
    min-width: 110px;
  }

  .text {
    font-size: 14px;
    height: auto;
    font-style: italic;
    color: gray;
    padding: 16px 16px 16px 16px;
  }

  .md-drawer form {
    padding: 20px;
  }

  .md-dialog.md-theme-default {
    max-width: 768px;
    height: 250px;
    background-color: #f5f5f5;
  }
  .md-dialog-content {
    padding: 20px;
  }

  .collateral-info {
    font-size: 14px;
    color: gray;
    text-align: left;
    margin-top:-20px;
    margin-bottom:20px;
  }

  div.widget {
    margin-bottom: 20px;
    border-radius: 20px;
  }

  .md-card {
    border-radius: 5px;
  }

  div.card-icon {
    float: left;
  }

  .category {
    float:right;
    font-size: 14px;
    color: #999;
    text-align: right;
  }

  .cat-value {
    font-size:28px;
    color: black;
    margin-top: 10px;
    text-align: right;
  }

  .actions-card {
    border-top: 1px solid lightgray;
    height: 25px;
  }

  .solvency-warning {
    color: #999;
    font-style: italic;
  }

  .assets .md-table-cell {
    text-align: left;
  }




</style>
