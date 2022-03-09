pragma solidity ^0.4.24;
//定义合约AuctionStore
contract Auction {
    //定义枚举ProductStatus
    enum ProductStatus {
        Open, //拍卖开始
        Sold, //已售出,交易成功
        Unsold //为售出，交易未成功
    }
    enum ProductCondition {
        New, //拍卖商品是否为新品
        Used //拍卖商品是否已经使用过
    }
    // 用于统计商品数量，作为ID
    uint public productIndex; 
    //商品Id与钱包地址的对应关系
    mapping(uint => address) productIdInStore;
    // 通过地址查找到对应的商品集合
    mapping(address => mapping(uint => Product)) stores;
 
    //增加投标人信息
    struct Bid {
        address bidder;
        uint productId;
        uint value;
        bool revealed; //是否已经揭标
    }
 
    //定义商品结构体
    struct Product {
        uint id;                 //商品id
        string name;             //商品名称
        string category ;       //商品分类
        uint auctionStartTime; //开始竞标时间
        uint auctionEndTime;    //竞标结束时间
        uint startPrice;       //拍卖价格   
        address highestBidder ; //出价最高，赢家的钱包地址
        uint highestBid ;       //赢家得标的价格
        uint secondHighestBid ; //竞标价格第二名
        uint totalBids ;        //共计竞标的人数
        string status;    //状态
        ProductCondition condition ;  //商品新旧标识
        mapping(address => mapping(bytes32 => Bid)) bids;// 存储所有投标人信息
 
    }
    constructor ()public{
        productIndex = 0;
    }
    //添加商品到区块链中
    function addProductToStore(string _name, string _category, uint _auctionStartTime, uint _auctionEndTime ,uint _startPrice, uint  _productCondition) public  {
        //开始时间需要小于结束时间
        require(_auctionStartTime < _auctionEndTime,"开始时间不能晚于结束时间");
        //商品ID自增
        productIndex += 1;
        //product对象稍后直接销毁即可
        //product.highestBid = _startPrice;
        Product memory product = Product(productIndex,_name,_category,_auctionStartTime,_auctionEndTime,_startPrice,0,_startPrice,0,0,'Open',ProductCondition(_productCondition));
        stores[msg.sender][productIndex] = product;
        productIdInStore[productIndex] = msg.sender;   
    }
    //通过商品ID读取商品信息
    function getProduct(uint _productId)  public view returns (uint,string, string,uint ,uint,uint, string, ProductCondition)  {
        Product memory product = stores[productIdInStore[_productId]][_productId];
        if (now > product.auctionEndTime){ product.status='Sold';}
        return (product.id, product.name,product.category,product.auctionStartTime,product.auctionEndTime,product.highestBid,product.status,product.condition);
    }
    //投标,传入参数为商品Id以及Hash值(实际竞标价与秘钥词语的组合Hash),需要添加Payable
    function bid(uint _productId, bytes32 _bid) payable public returns (bool) {
        Product storage product = stores[productIdInStore[_productId]][_productId];
        require(now >= product.auctionStartTime, "商品竞拍时间未到，暂未开始，请等待...");
        require(now <= product.auctionEndTime,"商品竞拍已经结束");
        require(msg.value >= product.highestBid,"设置的虚拟价格不能低于开标价格");
        require(product.bids[msg.sender][_bid].bidder == 0); //在提交竞标之前，必须保证bid的值为空
        //将投标人信息进行保存
        product.bids[msg.sender][_bid] = Bid(msg.sender, _productId, msg.value,false);
        //商品投标人数递增
        product.totalBids += 1;
        product.highestBid=msg.value;
        product.highestBidder=msg.sender;
        //返回投标成功
        return true;
    }
 
    //公告，揭标方法
    function revealBid(uint _productId, string _amount, bytes32 _sealedbid) public returns (bool) {
            //通过商品ID获取商品信息
            Product storage product = stores[productIdInStore[_productId]][_productId];
            //确保当前时间大于投标结束时间
            require(now > product.auctionEndTime,"竞标尚未结束，未到公告价格时间");
            // 对竞标价格与关键字密钥进行加密
            bytes32 sealedBid = _sealedbid;
            //获取投标人信息
            Bid memory bidInfo = product.bids[msg.sender][sealedBid];
            //判断是否存在钱包地址，钱包地址0x4333  uint160的钱包类型
            require(bidInfo.bidder > 0,"钱包地址不存在"); 
            //判断是否已经公告揭标过
            require(bidInfo.revealed == false,"已经揭标");
            // 定义系统的退款
            uint refund;
            uint amount = stringToUint(_amount);        // bidInfo.value 其实就是 mask bid，用于迷惑竞争对手的价格
            if (msg.sender!=product.highestBidder) {               //如果bidInfo.value的值< 实际竞标价，则返回全部退款，属于无效投标
                refund = amount;
                return false;
            }else { //如果属于有效投标，参照如下分类
                return true;
            }
            if (refund > 0){ //退款
                msg.sender.transfer(refund);
                
            }
    
        }
    
        //帮助方法
        //1. 获取竞标赢家信息
        function highestBidderInfo (uint _productId)public view returns (address, uint ,uint) {
            Product memory product = stores[productIdInStore[_productId]][_productId];
            if (now > product.auctionEndTime){
            return (product.highestBidder,product.highestBid,product.secondHighestBid);
            }
            else{
            return (0,0,0);
            }
        }    
        //2. 获取参与竞标的人数
        function  totalBids(uint _productId) view public returns (uint) {
            Product memory product = stores[productIdInStore[_productId]][_productId];
            return  product.totalBids;
        }
        //3. 将字符串string到uint类型
        function stringToUint(string s) pure private returns (uint) {
            bytes memory b = bytes(s);
            uint result = 0 ;
            for (uint i = 0; i < b.length; i++ ){
                if (b[i] >=48 && b[i] <=57){
                    result = result * 10  + (uint(b[i]) - 48);
                }
            }
            return result;
        }
    }
