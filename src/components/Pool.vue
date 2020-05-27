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

    <div style="height: 20px;"></div>

    <div class="md-layout md-gutter">

      <div class="md-layout-item md-size-25"></div>

      <div class="md-layout-item md-size-50">

        <div class="md-layout md-gutter">

          <div class="md-layout-item md-medium-size-50 md-size-50 widget">
            <div class="md-card md-card-stats md-theme-default">
              <div class="md-card-header md-card-header-icon md-card-header-blue" style="height: 100px;">
                <div class="card-icon">
                  <i class="md-icon md-icon-font md-theme-default md-size-3x" style="color: green">
                    cloud_download
                  </i>
                </div>
                <div class="category">
                  Total deposited
                  <div class="cat-value">{{ pool.totalDeposited | usd}}</div>
                </div>
              </div>

              <md-card-content>
                <div class="actions-card solvency-warning" style="padding-top:10px;">
                  Earning <b>{{pool.effectiveRate | percent}}</b> effective rate
                </div>
              </md-card-content>

            </div>
          </div>

          <div class="md-layout-item md-medium-size-50 md-size-50 widget">
            <div class="md-card md-card-stats md-theme-default">
              <div class="md-card-header md-card-header-icon md-card-header-blue" style="height: 100px;">
                <div class="card-icon">
                  <i class="md-icon md-icon-font md-theme-default md-size-3x" style="color:red">
                    cloud_upload
                  </i>
                </div>
                <div class="category">
                  Total borrowed
                  <div class="cat-value">{{ pool.totalBorrowed | usd }}</div>
                </div>
              </div>

              <md-card-content>
                <div class="actions-card solvency-warning" style="padding-top:10px;">
                  At fixed <b>5%</b> interest rate
                </div>
              </md-card-content>

            </div>
          </div>

        </div>

        <md-card>
          <md-card-header>
            <md-card-header-text>
              <div class="md-title">Your balance: <b>{{pool.myDeposits | usd}}</b> </div>
              <div class="md-subhead">Your have earned: <b>$0.00</b></div>

            </md-card-header-text>

          </md-card-header>

          <md-card-content>
            <div style="text-align: center">
              <md-button id="depositButton" class="md-raised md-primary pool-button" @click="showDepositPanel = true">Deposit</md-button>
              <md-button class="md-raised md-accent pool-button" @click="showWithdrawPanel = true">Withdraw</md-button>
            </div>
          </md-card-content>

        </md-card>


      </div>

    </div>

    <md-drawer class="md-drawer md-right" :md-active.sync="showDepositPanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Deposit funds</span>
      </md-toolbar>

      <div class="text">
        Supply funds to the pool to earn interest.
      </div>

      <form novalidate>
        <div class="form-container">
          <md-field>
            <label for="depositAmount">Amount in ETH</label>
            <md-input name="depositAmount" id="depositAmount" v-model="depositAmount"
                      :disabled="processing"/>
          </md-field>
        </div>

        <md-button class="md-primary md-raised pool-button" @click="makeDeposit()">Deposit</md-button>

      </form>
    </md-drawer>

    <md-drawer class="md-drawer md-right" :md-active.sync="showWithdrawPanel" md-swipeable>
      <md-toolbar class="md-primary">
        <span class="md-title">Withdraw funds</span>
      </md-toolbar>

      <div class="text">
        Withdraw funds to get cash out your earnings.
      </div>

      <form novalidate>
        <div class="form-container">
          <md-field>
            <label for="withdrawAmount">Amount in USD</label>
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
  import {getMyDeposits, sendDeposit, withdraw} from '@/blockchain/pool'
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
        pool: State.pool,
        showDepositPanel: false,
        showWithdrawPanel: false,
        currencies: State.currencies,
        depositAmount: 0,
        withdrawAmount: 0,
        processing: false,
      }
    },
    beforeCreate: async function () {
      await getMyDeposits();

    },
    methods: {
      onCurrencyChange: function () {
        console.log("Currency changed: " + this.selectedCurrency.title);
        this.deposit = this.selectedCurrency.balance / 2;
        this.maxDeposit = this.selectedCurrency.balance;
        this.step = this.selectedCurrency.step;
        this.precision = this.selectedCurrency.precision;
      },
      getData: async function () {
        await getReserveData();
      },
      makeDeposit: async function () {
        this.processing = true;
        try {
          await sendDeposit(this.depositAmount);

          let toast = this.$toasted.show("Your deposit has been registered!", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
          });
        } finally {
          this.processing = false;
          this.showDepositPanel = false;
        }
      },
      makeWithdraw: async function () {
        this.processing = true;
        try {
          await withdraw(this.withdrawAmount);

          let toast = this.$toasted.show("You have withdrawn the money!", {
            theme: "bubble",
            position: "top-center",
            duration: 5000,
            icon: 'sentiment_satisfied_alt'
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

  #depositButton .md-ripple {
    background-color: green;
  }


</style>
