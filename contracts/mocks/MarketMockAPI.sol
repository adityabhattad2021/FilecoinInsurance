/*******************************************************************************
 *   (c) 2022 Zondax AG
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ********************************************************************************/
//
// DRAFT!! THIS CODE HAS NOT BEEN AUDITED - USE ONLY FOR PROTOTYPING

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library MockTypes {
    struct Deal {
        uint64 id;
        bytes cid;
        uint64 size;
        bool verified;
        uint64 client;
        uint64 provider;
        string label;
        int64 start;
        int64 end;
        uint256 price_per_epoch;
        uint256 provider_collateral;
        uint256 client_collateral;
        int64 activated;
        int64 terminated;
    }
}




/// @title This contract is a proxy to the singleton Storage Market actor (address: f05). Calling one of its methods will result in a cross-actor call being performed. However, in this mock library, no actual call is performed.
/// @author Zondax AG
/// @dev Methods prefixed with mock_ will not be available in the real library. These methods are merely used to set mock state. Note that this interface will likely break in the future as we align it
//       with that of the real library!
contract MarketMockAPI {
    // mapping(string => BigNumber) balances;
    mapping(uint64 => MockTypes.Deal) deals;

    constructor() {
        mockGenerateDeals();
    }

    /// @notice Deposits the received value into the balance held in escrow.
    /// @dev Because this is a mock method, no real balance is being deducted from the caller, nor incremented in the Storage Market actor (f05).
    // function addBalance(address memory provider_or_client) public payable {
    //     BigNumber memory newValue = BigNumbers.init(msg.value, false);
    //     balances[string(provider_or_client)] = BigNumbers.add(balances[string(provider_or_client)], newValue);
    // }

    /// @notice Attempt to withdraw the specified amount from the balance held in escrow.
    /// @notice If less than the specified amount is available, yields the entire available balance.
    /// @dev This method should be called by an approved address, but the mock does not check that the caller is an approved party.
    /// @dev Because this is a mock method, no real balance is deposited in the designated address, nor decremented from the Storage Market actor (f05).
    // function withdrawBalance(MarketTypes.WithdrawBalanceParams memory params) public returns (MarketTypes.WithdrawBalanceReturn memory) {
    //     BigNumber memory balance = balances[string(params.provider_or_client)];
    //     BigNumber memory tokenAmount = BigNumbers.init(params.tokenAmount.val, params.tokenAmount.neg);

    //     if (BigNumbers.gte(balance, tokenAmount)) {
    //         balances[string(params.provider_or_client)] = BigNumbers.sub(balance, tokenAmount);
    //         balance = tokenAmount;
    //     } else {
    //         balances[string(params.provider_or_client)] = BigNumbers.zero();
    //     }

    //     return MarketTypes.WithdrawBalanceReturn(BigInt(balance.val, balance.neg));
    // }

    /// @return the escrow balance and locked amount for an address.
    // function getBalance(bytes memory addr) public view returns (MarketTypes.GetBalanceReturn memory) {
    //     BigNumber memory actualBalance = balances[string(addr)];
    //     BigNumber memory zero = BigNumbers.zero();

    //     return MarketTypes.GetBalanceReturn(BigInt(actualBalance.val, actualBalance.neg), BigInt(zero.val, zero.neg));
    // }

    /// @return the data commitment and size of a deal proposal.
    /// @notice This will be available after the deal is published (whether or not is is activated) and up until some undefined period after it is terminated.
    /// @dev set data values correctly, currently returning fixed data, feel free to adjust in your local mock.
    function getDealDataCommitment(uint64 dealID) public view returns (uint64) {
        require(deals[dealID].id > 0);

        return deals[dealID].size;
    }

    /// @return the client of a deal proposal.
    function getDealClient(uint64 dealID) public view returns (uint64) {
        require(deals[dealID].id > 0);

        return deals[dealID].client;
    }

    /// @return the provider of a deal proposal.
    function getDealProvider(uint64 dealID) public view returns (uint64) {
        require(deals[dealID].id > 0);

        return deals[dealID].provider;
    }

    /// @return the label of a deal proposal.
    function getDealLabel(uint64 dealID) public view returns (string memory) {
        require(deals[dealID].id > 0);

        return deals[dealID].label;
    }

    /// @return the start epoch and duration (in epochs) of a deal proposal.
    function getDealTerm(uint64 dealID) public view returns (int64,int64) {
        require(deals[dealID].id > 0);

        return (deals[dealID].start, deals[dealID].end);
    }

    /// @return the per-epoch price of a deal proposal.
    function getDealTotalPrice(uint64 dealID) public view returns (uint256) {
        require(deals[dealID].id > 0);

        return deals[dealID].price_per_epoch;
    }

    /// @return the client collateral requirement for a deal proposal.
    function getDealClientCollateral(uint64 dealID) public view returns (uint256) {
        require(deals[dealID].id > 0);

        return deals[dealID].client_collateral;
    }

    /// @return the provider collateral requirement for a deal proposal.
    function getDealProviderCollateral(uint64 dealID) public view returns (uint256) {
        require(deals[dealID].id > 0);

        return deals[dealID].provider_collateral;
    }

    /// @return the verified flag for a deal proposal.
    /// @notice Note that the source of truth for verified allocations and claims is the verified registry actor.
    function getDealVerified(uint64 dealID) public view returns (bool) {
        require(deals[dealID].id > 0);

        return deals[dealID].verified;
    }

    /// @notice Fetches activation state for a deal.
    /// @notice This will be available from when the proposal is published until an undefined period after the deal finishes (either normally or by termination).
    /// @return USR_NOT_FOUND if the deal doesn't exist (yet), or EX_DEAL_EXPIRED if the deal has been removed from state.
    function getDealActivation(uint64 dealID) public view returns (int64) {
        require(deals[dealID].id > 0);

        return deals[dealID].activated;
    }

    /// @notice Publish a new set of storage deals (not yet included in a sector).
    // function publishStorageDeals(bytes memory raw_auth_params, address callee) public {
    //     // calls standard filecoin receiver on message authentication api method number
    //     (bool success, ) = callee.call(
    //         abi.encodeWithSignature("handle_filecoin_method(uint64,uint64,bytes)", 0, 2643134072, raw_auth_params)
    //     );
    //     require(success, "client contract failed to authorize deal publish");
    // }

    /// @notice Adds mock deal data to the internal state of this mock.
    /// @dev Feel free to adjust the data here to make it align with deals in your network.
    function mockGenerateDeals() internal {
        MockTypes.Deal memory deal_67;
        deal_67.id = 67;
        deal_67.cid = "baga6ea4seaqlkg6mss5qs56jqtajg5ycrhpkj2b66cgdkukf2qjmmzz6ayksuci";
        deal_67.size = 8388608;
        deal_67.verified = false;
        deal_67.client = 101;
        deal_67.provider = 103;
        deal_67.label = "mAXCg5AIg8YBXbFjtdBy1iZjpDYAwRSt0elGLF5GvTqulEii1VcM";
        deal_67.start = 25245;
        deal_67.end = 545150;
        deal_67.price_per_epoch = 1100000000000;
        deal_67.provider_collateral = 1000000000000000;
        deal_67.client_collateral = 0;
        deal_67.activated = 1;
        deal_67.terminated = 0;

        deals[deal_67.id] = deal_67;

        // As EVM smart contract has a limited capacity for size (24KiB), we cannot set all deals directly here.
        // Please, take them from docs.

        // Add or replace more deals here.
    }
}