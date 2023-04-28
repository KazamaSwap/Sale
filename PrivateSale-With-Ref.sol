// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.3/utils/Counters.sol";

contract SenshiDummies is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Senshi Dummy", "SENSHI-DUMMY") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}

interface IBEP20 {
     // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    // Moves `amount` tokens from the caller's account to `recipient`.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Moves `amount` tokens from `sender` to `recipient`
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract KazamaPrivateSale {

    // SM Modifier
    mapping(address => bool) internal senshiMaster;

    // P-KAZAMA address
    IBEP20 presaleToken = IBEP20(0x52230fF598b8Ad36aFa00D2948122Eca98151b02);

    // USDT address
    IBEP20 usdToken = IBEP20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);

    // Public info
    uint256 public biggestRefAmount;
    uint256 public biggestRefReceived;
    address public biggestReferrer;
    uint256 public totalReferred;
    uint256 public totalRewarded;
    uint256 public totalDummiesRewarded;

    // Settings
    address internal usdReceiver;
    address public dummyAddress;
    bool public saleActive;
    uint256 public kazamaPerUsd = 1000;
    uint256 public minimumBuy = 1;
    uint256 public refPercentage = 5;
    SenshiDummies senshidummies;

    // Bonus settings
    uint256 public maxWallets = 4;
    uint256 public currentWallets;
    bool public bonusActive;

    // User stats
    mapping (address => bool) public bonusBuyer;
    mapping (address => bool) public refLinkActive;
    mapping (address => uint256) public totalUsdReferred;
    mapping (address => uint256) public totalUsdRewarded;

    constructor () payable {
        senshidummies = new SenshiDummies();
        dummyAddress = address(senshidummies);
        senshiMaster[0x4162fBe60B7dDb0EaAbC0b13C6e68cC836Fe3a8f] = true;
    }

     function isSenshiMaster(address account) public view returns (bool) {
        return senshiMaster[account];
    }

     modifier onlySenshiMaster() {
        require(isSenshiMaster (msg.sender),
        "Only Senshi Master ..");
        _;
    }

    function mintTwoDummies(address receiver) internal {
        senshidummies.safeMint(receiver);
        senshidummies.safeMint(receiver);
    }

    function mintThreeDummies(address receiver) internal {
        senshidummies.safeMint(receiver);
        senshidummies.safeMint(receiver);
        senshidummies.safeMint(receiver);
    }

    function mintFourDummies(address receiver) internal {
        senshidummies.safeMint(receiver);
        senshidummies.safeMint(receiver);
        senshidummies.safeMint(receiver);
        senshidummies.safeMint(receiver);
    }
    
    function purchaseTokens (uint256 amount, address referredBy) external {
        uint256 kazamaToReceive = amount * kazamaPerUsd;
        require (saleActive == true, "Sale not active");
        require (IBEP20(usdToken).balanceOf(msg.sender) >= amount, "Not enough USDT");
        require (IBEP20(presaleToken).balanceOf(address(this)) >= kazamaToReceive, "Not enough presale tokens");
        require (amount >= minimumBuy, "Need to buy the minimum");
        address senshiReceiver = msg.sender;

        // If bonus is activated
        if (bonusActive == true) {
            // If amount below 500
            if (amount < 5e18) {
                uint256 bonusPercentage = 2;
                uint256 bonusTokens = kazamaToReceive / 100 * bonusPercentage;
                uint256 toReceive = kazamaToReceive + bonusTokens;
                if (bonusBuyer[msg.sender] == true) {
                    IBEP20(presaleToken).transfer(msg.sender, toReceive);                   
                }
                if (bonusBuyer[msg.sender] == false) {
                    bonusBuyer[msg.sender] = true;
                    currentWallets += 1;
                    IBEP20(presaleToken).transfer(msg.sender, toReceive);
                    totalDummiesRewarded = totalDummiesRewarded + 2;
                    mintTwoDummies(senshiReceiver);
                }
                if (currentWallets >= maxWallets) {
                    bonusActive = false;
                }
                if (refLinkActive[msg.sender] == false) {
                    refLinkActive[msg.sender] = true;
                }
                if (referredBy != 0x0000000000000000000000000000000000000000 &&
                    referredBy != msg.sender && refLinkActive[referredBy] == true) {
                    uint256 referrerUsd = amount / 100 * refPercentage;
                    uint256 correctedUsd = amount - referrerUsd;
                    totalUsdReferred[referredBy] = totalUsdReferred[referredBy] + amount;
                    totalUsdRewarded[referredBy] = totalUsdRewarded[referredBy] + amount;
                    if (amount > biggestRefAmount) {
                        biggestRefAmount = amount;
                        biggestReferrer = referredBy;
                        biggestRefReceived = referrerUsd;
                    }
                    totalReferred = totalReferred + amount;
                    totalRewarded = totalRewarded + referrerUsd;
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, correctedUsd);
                    IBEP20(usdToken).transferFrom(msg.sender, referredBy, referrerUsd);
                } else {
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, amount);                    
                }
            }
            // If amount between 500 and 1000
            if (amount >= 5e18 && amount < 10e18) {
                uint256 bonusPercentage = 3;
                uint256 bonusTokens = kazamaToReceive / 100 * bonusPercentage;
                uint256 toReceive = kazamaToReceive + bonusTokens;
                if (bonusBuyer[msg.sender] == true) {
                    IBEP20(presaleToken).transfer(msg.sender, toReceive);                   
                }
                if (bonusBuyer[msg.sender] == false) {
                    bonusBuyer[msg.sender] = true;
                    currentWallets += 1;
                    IBEP20(presaleToken).transfer(msg.sender, toReceive);
                    totalDummiesRewarded = totalDummiesRewarded + 3;
                    mintThreeDummies(senshiReceiver);
                }
                if (currentWallets >= maxWallets) {
                    bonusActive = false;
                }
                if (refLinkActive[msg.sender] == false) {
                    refLinkActive[msg.sender] = true;
                }
                if (referredBy != 0x0000000000000000000000000000000000000000 &&
                    referredBy != msg.sender && refLinkActive[referredBy] == true) {
                    uint256 referrerUsd = amount / 100 * refPercentage;
                    uint256 correctedUsd = amount - referrerUsd;
                    totalUsdReferred[referredBy] = totalUsdReferred[referredBy] + amount;
                    totalUsdRewarded[referredBy] = totalUsdRewarded[referredBy] + amount;
                    if (amount > biggestRefAmount) {
                        biggestRefAmount = amount;
                        biggestReferrer = referredBy;
                        biggestRefReceived = referrerUsd;
                    }
                    totalReferred = totalReferred + amount;
                    totalRewarded = totalRewarded + referrerUsd;
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, correctedUsd);
                    IBEP20(usdToken).transferFrom(msg.sender, referredBy, referrerUsd);
                } else {
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, amount);                    
                }
            }
            // If amount above 1000
            if (amount >= 10e18) {
                uint256 bonusPercentage = 4;
                uint256 bonusTokens = kazamaToReceive / 100 * bonusPercentage;
                uint256 toReceive = kazamaToReceive + bonusTokens;
                if (bonusBuyer[msg.sender] == true) {
                    IBEP20(presaleToken).transfer(msg.sender, toReceive);                   
                }
                if (bonusBuyer[msg.sender] == false) {
                    bonusBuyer[msg.sender] = true;
                    currentWallets += 1;
                    IBEP20(presaleToken).transfer(msg.sender, toReceive);
                    totalDummiesRewarded = totalDummiesRewarded + 4;
                    mintFourDummies(senshiReceiver);
                }
                if (currentWallets >= maxWallets) {
                    bonusActive = false;
                }
                if (refLinkActive[msg.sender] == false) {
                    refLinkActive[msg.sender] = true;
                }
                if (referredBy != 0x0000000000000000000000000000000000000000 &&
                    referredBy != msg.sender && refLinkActive[referredBy] == true) {
                    uint256 referrerUsd = amount / 100 * refPercentage;
                    uint256 correctedUsd = amount - referrerUsd;
                    totalUsdReferred[referredBy] = totalUsdReferred[referredBy] + amount;
                    totalUsdRewarded[referredBy] = totalUsdRewarded[referredBy] + amount;
                    if (amount > biggestRefAmount) {
                        biggestRefAmount = amount;
                        biggestReferrer = referredBy;
                        biggestRefReceived = referrerUsd;
                    }
                    totalReferred = totalReferred + amount;
                    totalRewarded = totalRewarded + referrerUsd;
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, correctedUsd);
                    IBEP20(usdToken).transferFrom(msg.sender, referredBy, referrerUsd);
                } else {
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, amount);                    
                }
            }
        }

        // If bonus is deactivated
        if (bonusActive == false) {
                if (refLinkActive[msg.sender] == false) {
                    refLinkActive[msg.sender] = true;
                }
                if (referredBy != 0x0000000000000000000000000000000000000000 &&
                    referredBy != msg.sender && refLinkActive[referredBy] == true) {
                    uint256 referrerUsd = amount / 100 * refPercentage;
                    uint256 correctedUsd = amount - referrerUsd;
                    totalUsdReferred[referredBy] = totalUsdReferred[referredBy] + amount;
                    totalUsdRewarded[referredBy] = totalUsdRewarded[referredBy] + amount;
                    if (amount > biggestRefAmount) {
                        biggestRefAmount = amount;
                        biggestReferrer = referredBy;
                        biggestRefReceived = referrerUsd;
                    }
                    totalReferred = totalReferred + amount;
                    totalRewarded = totalRewarded + referrerUsd;
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, correctedUsd);
                    IBEP20(usdToken).transferFrom(msg.sender, referredBy, referrerUsd);
                    IBEP20(presaleToken).transfer(msg.sender, kazamaToReceive);   
                } else {
                    IBEP20(usdToken).transferFrom(msg.sender, usdReceiver, amount);
                    IBEP20(presaleToken).transfer(msg.sender, kazamaToReceive);                   
            }
        }
    }

    // Enable or disable sale
    function setSaleActive (bool _saleActive) external onlySenshiMaster {
        saleActive = _saleActive;
    }

    // Change max wallets
    function setMaxWallets (uint256 _maxWallets) external onlySenshiMaster {
        maxWallets = _maxWallets;
    }

    // Clear current bonus wallets
    function clearCurrentWallets () external onlySenshiMaster {
        currentWallets = 0;
    }

    // Set funds receiver
    function setFundsReceiver (address _usdReceiver) external onlySenshiMaster {
        usdReceiver = _usdReceiver;
    }

    // Enable or disable bonus phase
    function setBonusActive (bool _bonusActive) external onlySenshiMaster {
        bonusActive = _bonusActive;
    }

    // Change ref %
    function setRefPercentage (uint256 _refPercentage) external onlySenshiMaster {
        require (_refPercentage > 0, "Must be above zero");
        require (_refPercentage < 11, "Max is ten");        
        refPercentage = _refPercentage;
    }

    // Extract presale tokens
    function recoverPresaleTokens () external onlySenshiMaster {
        uint256 tokenAmount = IBEP20(presaleToken).balanceOf(address(this));
        IBEP20(presaleToken).transfer(msg.sender, tokenAmount);
    }

    // Change minimum buy
    function setMinimumBuy (uint256 _minimumBuy) external onlySenshiMaster {
        minimumBuy = _minimumBuy;
    }

    // Set active ref manually
    function setRefActive (address account) external onlySenshiMaster {
        refLinkActive[account] = true;
    }
}
