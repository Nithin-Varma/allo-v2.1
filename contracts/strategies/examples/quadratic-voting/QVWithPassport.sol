// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {PassportGatingExtension} from "contracts/strategies/extensions/gating/PassportGatingExtension.sol";
import {AllocationExtension} from "contracts/strategies/extensions/allocate/AllocationExtension.sol";
import {QVHelper} from "strategies/libraries/QVHelper.sol";
import {Transfer} from "contracts/core/libraries/Transfer.sol";

contract QVWithPassportStrategy is BaseStrategy, PassportGatingExtension, AllocationExtension {
    using QVHelper for QVHelper.VotingState;
    using Transfer for address;

    QVHelper.VotingState internal _votingState;
    uint256 public maxAllocation;
    uint256 public totalPayoutAmount;
    mapping(address => uint256) public voiceCreditsAllocated;
    mapping(address => bool) public registeredRecipients;
    mapping(address => bool) public paidOut;

    error INVALID_RECIPIENT();
    error INVALID_ALLOCATOR();
    error INVALID_CREDITS();

    constructor(address _allo, string memory _name) BaseStrategy(_allo, _name) {}

    function _initializeStrategy(uint256 _poolId, bytes memory _data) internal override {
        (uint64 _allocationStart, uint64 _allocationEnd, address _decoder, uint256 _minScore) = abi.decode(
            _data,
            (uint64, uint64, address, uint256)
        );

        __AllocationExtension_init(new address[](0), _allocationStart, _allocationEnd, false);
        __PassportGatingExtension_init(_decoder, _minScore);
    }

    function _register(address[] memory _recipients, bytes memory _data, address _sender) internal virtual override returns (address[] memory _recipientIds) {
        uint256 _length = _recipients.length;
        for (uint256 i; i < _length; i++) {
            address _recipient = _recipients[i];
            if (_recipient == address(0)) {
                revert INVALID_RECIPIENT();
            }
            registeredRecipients[_recipient] = true;
        }
    }

    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender) internal virtual override onlyActiveAllocation {
        if (!_isValidAllocator(_sender)) revert INVALID_ALLOCATOR();

        uint256 _totalAllocatedAmount = 0;
        for (uint256 i; i < _recipients.length; i++) {
            address _recipient = _recipients[i];
            if (!registeredRecipients[_recipient]) revert INVALID_RECIPIENT();

            _totalAllocatedAmount += _amounts[i];
        }  

        if(!_hasVoiceCreditsLefts(_totalAllocatedAmount, voiceCreditsAllocated[_sender])) revert INVALID_CREDITS();

        _votingState.voteWithVoiceCredits(_recipients, _amounts);
        voiceCreditsAllocated[_sender] += _totalAllocatedAmount;
    }

    /// @notice This will distribute funds (tokens) to recipients.
    /// @dev most strategies will track a TOTAL amount per recipient, and a PAID amount, and pay the difference
    /// this contract will need to track the amount paid already, so that it doesn't double pay.
    /// @param _recipientIds The ids of the recipients to distribute to
    /// @param _data Data required will depend on the strategy implementation
    /// @param _sender The address of the sender
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


    function _hasVoiceCreditsLefts(uint256 _creditsToCast, uint256 _creditsAlreadyCasted) internal view returns (bool) {
        return maxAllocation >= _creditsToCast + _creditsAlreadyCasted;
    }

    function _isValidAllocator(address _allocator) internal view virtual override returns (bool) {
        return _checkPassportScore(_allocator);
    }
}