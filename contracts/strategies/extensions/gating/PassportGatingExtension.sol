// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseStrategy} from "contracts/strategies/BaseStrategy.sol";
import {IGitcoinPassportDecoder} from "contracts/strategies/extensions/gating/IGitcoinPassportDecoder.sol";

abstract contract PassportGatingExtension is BaseStrategy {

    /// @notice The minimum passport score to be eligible
    uint256 public minScore;
    /// @notice The gitcoin decoder address
    address public decoder;

    error INVALID_DECODER();
    error INVALID_PASSPORT_SCORE();

    function __PassportGatingExtension_init(address _decoder, uint256 _minScore) internal {
        if (decoder == address(0)) revert INVALID_DECODER();
        decoder = _decoder;
        minScore = _minScore;
    }

    modifier onlyWithPassportScore(address _sender) {
        _checkPassportScore(_sender);
        _;
    }

    function _checkPassportScore(address _sender) internal view returns (bool) {
        uint256 _score = IGitcoinPassportDecoder(decoder).getScore(_sender);
        if (_score < minScore) revert INVALID_PASSPORT_SCORE();
    }
}