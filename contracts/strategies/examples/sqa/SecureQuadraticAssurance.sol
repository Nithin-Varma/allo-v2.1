// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";

contract SecureQuadraticAssurance is BaseStrategy {
    using Transfer for address;

    mapping(address => uint256) public recipientAmount;
    mapping(address => bool) public registeredRecipients;
    mapping(address => bool) public paidOut;
    mapping(address => uint246[]) public individualAllocations;
    address[] public allocators;
    uint256 public totalFunds;

    struct SQAInitializeData {
        uint256 totalFunds;
        uint64 donationStartTime;
        uint64 donationEndTime;
        uint256 goalAmount;
        bool goalMet;
    }

    SQAInitializeData public initializeData;

    //errors
    error DonationsNotStarted();
    error GoalAlreadyMet();
    error ARRAY_MISMATCH();
    error INVALID_RECIPIENT();
    error NoFundsOrGoalNotMet();

    // modifiers
    function _donationPeriod() private view {
        if(initializeData.donationStartTime == 0) revert DonationsNotStarted();
    }

    modifier onlyDonationPeriod() {
        _donationPeriod();
        _;
    }
    
    function _goalMet() private view {
        if(initializeData.goalMet == true) revert GoalAlreadyMet();
    }

    modifier goalNotMet() {
        _goalMet();
        _;
    }

    constructor(address _allo, string memory _strategyName) {
        BaseStrategy(_allo, _strategyName);
    }

    function _initializeStrategy(uint256 _poolId, SQAInitializeData memory _initializeData) internal virtual override {
        initializeData = _initializeData;
    }

    //function to register the projects into the round
    function _register() internal virtual override {
        if (_recipient == address(0)) {
            revert INVALID_RECIPIENT();
        }
        registeredRecipients[_recipient] = true;
    }

    //function to allocate the funds to the projects
    function _allocate(address[] memory _recipient, uint256[] memory _amounts, bytes memory _data, address _sender) internal override goalNotMet onlyDonationPeriod {  
        uint24 length = _recipient.length;
        if(length != _amount.length) revert ARRAY_MISMATCH();

        for (uint256 i=0; i < length; i++) {
            recipientAmount[_recipients[i]] += _amounts[i];
            individualAllocations[_recipients[i]].push(_amounts[i]);
            totalFunds += _amounts[i];
        }
        allocators.push(_sender);
    }

    function _matchingAmount(address _recipient) private {
        uint256 impact = //calculate the summation of root of individual donated amount to the recipient
        uint256 transferable_amount = //calculate the transferable amount as per the impact
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual override {
        if(totalFunds == 0 || initializeData.goalMet == false ) revert NoFundsOrGoalNotMet();
        // totalFunds = _poolAmount;

        address _token = _ALLO.getPool(_poolId).token;
        for(uint256 i; i < _recipientIds.length; i++) {
            address _recipient = _recipientIds[i];
            
        }
        
    }

    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal virtual override onlyAfterAllocation onlyPoolManager(_sender) {
        if (totalPayoutAmount == 0) {
            totalPayoutAmount = _poolAmount;
        }  

        uint256[] memory _payouts = _votingState.getPayout(_recipientIds, totalPayoutAmount);

        address _token = _ALLO.getPool(_poolId).token;
        for(uint256 i; i < _recipientIds.length; i++) {
            address _recipient = _recipientIds[i];

            paidOut[_recipient] = true;
            _poolAmount -= _payouts[i];
            _token.transferAmount(_recipient, _payouts[i]);
        }
    } 


    function _refunds() {
        //refund the funds back to the allocators...
    }

}