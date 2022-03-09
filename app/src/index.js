import Web3 from "web3";
import auctionArtifact from "../../build/contracts/Auction.json";

const App = {
  web3: null,
  account: null,
  auction: null,

  start: async function() {
    const {web3} = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = auctionArtifact.networks[networkId];
      this.auction = new web3.eth.Contract(        //建立智能合约实例this.auction;
        auctionArtifact.abi,
        deployedNetwork.address,
      );
      //console.log(this.auction);
      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];
      console.log(accounts);
      

    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },


  //增加商品
  addProductToStore: async function(){
    try {
      const {addProductToStore} = this.auction.methods;
      const name = document.getElementById("name").value;
      const category = document.getElementById("category").value;
      const start_price = document.getElementById("start_price").value;
      const auction_time = parseInt(document.getElementById("auction_time").value);
      const start_time = Math.round(new Date() / 1000);;
      const end_time = start_time + auction_time
      //console.log(start_time);
      //console.log(end_time);
      await addProductToStore(name, category, start_time, end_time, start_price,0).send({from: this.account,gas:1000000});
      swal("已添加");


    } catch (error) {
      console.log(error);
    }
  },


  //出价
  bid: async function(){
      const EjsUtil = require('ethereumjs-util');
    try {
      const {bid} = this.auction.methods;
      const bid_index = document.getElementById("bid_index").value;
      const bid_address = document.getElementById("bid_address").value;
      const bid_price = document.getElementById("bid_price").value;
      //const  sealedBid ='0x'+ EjsUtil.keccak256(2*bid_price+'firstsecrt').toString('hex');  这里还有问题没解决，先用现成的bytes32代替
      const sealedBid = '0x9566873896902aca059cbe402b2aa82638fe6e57980c97ac25c576cc6496a233';
      bid(bid_index,sealedBid).send({value:bid_price,from: bid_address, gas: 1000000});
    } catch (error) {
      console.log(error);
    }
  },



  //查询账户资金
   search: async function(){
    const {web3} = this;
    try {
      const search_address = document.getElementById("search_address").value;
      web3.eth.getBalance(search_address).then(function(result){swal("剩余资金：",result);});
    } catch (error) {
      console.log(error);
    }
  },


  //揭标
  revealBid: async function(){
    try {
      const {revealBid} = this.auction.methods;
      const reveal_index = document.getElementById("reveal_index").value;
      const reveal_address = document.getElementById("reveal_address").value;
      const reveal_price = document.getElementById("reveal_price").value;
      //const  sealedBid ='0x'+ EjsUtil.keccak256(2*bid_price+'firstsecrt').toString('hex');  这里还有问题没解决，先用现成的bytes32代替
      const sealedBid = '0x9566873896902aca059cbe402b2aa82638fe6e57980c97ac25c576cc6496a233';
      revealBid(reveal_index,reveal_price.toString,sealedBid).send({from: reveal_address,gas: 1000000});
      swal('已揭标，请检查钱包已确认是否竞拍成功');
    } catch (error) {
      console.log(error);
    }
  },



  //获取商品信息
  getProduct: async function(){
    try {
      const {getProduct} = this.auction.methods;
      const search_index = document.getElementById("search_index").value;
      await  getProduct(search_index).call(function(error,result){
        var sr_index = document.getElementById("sr_index");
        var sr_name = document.getElementById("sr_name");
        var sr_category = document.getElementById("sr_category");
        var sr_startTime = document.getElementById("sr_startTime");
        var sr_endTime = document.getElementById("sr_endTime");
        var sr_status = document.getElementById("sr_status");
        var sr_startPrice = document.getElementById("sr_startPrice");
        sr_index.innerHTML="  序号："+result[0];
        sr_name.innerHTML="商品名称："+result[1];
        sr_category.innerHTML="  分类："+result[2];
        sr_startTime.innerHTML="  起拍时间："+result[3];
        sr_endTime.innerHTML="  结束时间："+result[4];
        sr_status.innerHTML="  状态:"+result[6];
        sr_startPrice.innerHTML="  当前价格："+result[5];
        console.log(result);
      });
      //console.log(product);
    } catch (error) {
      console.log(error);
    }
  },
  

 //查询赢家地址
  highestBidderInfo: async function(){
    try {
      const {highestBidderInfo} = this.auction.methods;
      const show_index = document.getElementById("show_index").value;
      await  highestBidderInfo(show_index).call(function(error,result){
        swal("地址：",result[0]);
      });
      //console.log(product);
    } catch (error) {
      console.log(error);
    }
  },


  
};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
