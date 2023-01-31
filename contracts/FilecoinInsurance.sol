// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/"
import {MarketMockAPI} from "./TestContrct.sol";

contract FilecoinInsurance {
    MarketMockAPI private MarketAPI;
    uint256 private immutable insuranceCoverageLimit;
    uint256 private immutable insuranceCoveragePercentage;
    uint256 private immutable insuranceCoveragePremium;

    using SafeMath for uint256;

    event NewInsuranceRegistered(
        address indexed insuranceHolder,
        uint256 indexed dealId,
        uint256 indexed FILPrice
    );

    event InsuranceClaimed(
        address indexed insuranceHolder,
        uint256 indexed dealId,
        uint256 indexed FILPrice,
        uint256 amountPaid
    );

    struct Deal {
        string dealLabel;
        uint64 dealClientActorId;
        uint64 dealProviderActorId;
        int64 isDealActive;
        uint256 dealStorageProviderCollateral;
    }
    mapping(uint256 => Deal) public dealIdToDeal;

    struct Insurance {
        address insuranceHolder;
        uint64 dealId;
        uint64 FILPrice; // This has to be in WEI i.e. 1 FIL = $5.73 1000000000000000000=5730000000000000000
        uint256 collateralLocked;
        uint256 coverageLimit;
        uint64 coveragePercentage;
        uint256 premium;
        uint256 totalAmountClaimed;
        uint256 InsuranceExpiry;
    }
    mapping(address => Insurance) public holderToInsurance;
    address[] public insuranceHolders;

    constructor(
        address marketAPI,
        uint256 coverageLimit,
        uint256 coveragePercentage,
        uint256 covergaePremium
    ) {
        MarketAPI = MarketMockAPI(marketAPI);
        insuranceCoveragePercentage = coveragePercentage;
        insuranceCoverageLimit = coverageLimit;
        insuranceCoveragePremium = covergaePremium;
    }

    function getDeal(uint64 dealId) public {
        string memory dealLabel = MarketAPI.getDealLabel(dealId);
        uint64 dealClientActorId = MarketAPI.getDealClient(dealId);
        uint64 dealProviderActorId = MarketAPI.getDealProvider(dealId);
        int64 isDealActive = MarketAPI.getDealActivation(dealId);
        uint256 dealStorageProviderCollateral = MarketAPI
            .getDealProviderCollateral(dealId);
        dealIdToDeal[dealId] = Deal({
            dealLabel: dealLabel,
            dealClientActorId: dealClientActorId,
            dealProviderActorId: dealProviderActorId,
            isDealActive: isDealActive,
            dealStorageProviderCollateral: dealStorageProviderCollateral
        });
    }

    // Current Sample Insurance Plan:
    // 1. coverageLimit=10FIL
    // 2. coveragePercentage=70%
    // 3. premium=1FIL
    function registerInsurance(uint64 dealId, uint64 FILToDollar)
        public
        payable
    {
        getDeal(dealId);
        Deal memory newDeal = dealIdToDeal[dealId];
        require(newDeal.isDealActive == 1, "Deal is not active");
        require(
            msg.value > insuranceCoveragePremium,
            "Need to send the required premium."
        );
        // TODO: Check if the msg.sender is the storage provider in the deal.
        holderToInsurance[msg.sender] = Insurance({
            insuranceHolder: msg.sender,
            dealId: dealId,
            FILPrice: FILToDollar,
            collateralLocked: newDeal.dealStorageProviderCollateral,
            coverageLimit: insuranceCoverageLimit,
            premium: insuranceCoveragePremium,
            coveragePercentage: 70,
            totalAmountClaimed: 0,
            InsuranceExpiry: block.timestamp + 5 minutes
        });
        insuranceHolders.push(msg.sender);

        emit NewInsuranceRegistered(msg.sender, dealId, FILToDollar);
    }

    function calculateLosses(
        uint64 currentFILPrice,
        uint256 collateralLocked,
        uint64 oldFILPrice
    ) public pure returns (uint256 totalPayableInFIL) {
        // e.g. $5.72=572000000000000000000
        uint256 oldAmountInDollar = collateralLocked.mul(oldFILPrice).div(
            1000000000000000000
        );
        uint256 newAmountInDollar = collateralLocked.mul(currentFILPrice).div(
            1000000000000000000
        );
        // Let loss be $2.13=2130000000000000000
        uint256 losses = oldAmountInDollar.sub(newAmountInDollar);
        require(losses > 0, "There were no losses");
        // Converting losses to FIL considering latest price.
        uint256 lossesInFIL = losses.mul(1000000000000000000).div(
            currentFILPrice
        );
        uint256 percentToBePaid = lossesInFIL.mul(insuranceCoveragePremium).div(
            100
        );
        totalPayableInFIL = percentToBePaid.div(currentFILPrice);
    }

    function claim(uint256 dealId, uint64 currentFILPrice) public {
        Deal memory newDeal = dealIdToDeal[dealId];
        require(newDeal.isDealActive == 1, "Deal is not active");
        Insurance storage insuranceData = holderToInsurance[msg.sender];
        uint64 oldFILPrice = insuranceData.FILPrice;
        require(
            currentFILPrice < oldFILPrice,
            "Current FIL Price > Old FIL Price"
        );
        uint256 collateralLocked = insuranceData.collateralLocked;
        uint256 totalPayable = calculateLosses(
            currentFILPrice,
            collateralLocked,
            oldFILPrice
        );
        insuranceData.totalAmountClaimed += totalPayable;
        (bool success, ) = payable(msg.sender).call{value: totalPayable}("");
        require(success, "Payment failed");

        emit InsuranceClaimed(
            msg.sender,
            dealId,
            currentFILPrice,
            totalPayable
        );
    }
}
