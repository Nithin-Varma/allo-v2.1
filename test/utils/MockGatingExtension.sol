// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {CoreBaseStrategy} from "../../contracts/strategies/CoreBaseStrategy.sol";
import {EASGatingExtension} from "../../contracts/extensions/EASGatingExtension.sol";
import {NFTGatingExtension} from "../../contracts/extensions/NFTGatingExtension.sol";
import {TokenGatingExtension} from "../../contracts/extensions/TokenGatingExtension.sol";
import {MockBaseStrategy} from "./MockBaseStrategy.sol";

contract MockGatingExtension is EASGatingExtension, NFTGatingExtension, TokenGatingExtension {
    constructor(address _allo) CoreBaseStrategy(_allo) {}

    function initialize(uint256 _poolId, bytes memory _data) public {
        __BaseStrategy_init(_poolId);

        address _eas = abi.decode(_data, (address));

        __EASGatingExtension_init(_eas);
        emit Initialized(_poolId, _data);
    }

    // this is called via allo.sol to register recipients
    function _register(address[] memory _recipients, bytes memory _data, address _sender)
        internal
        override
        returns (address[] memory _recipientIds)
    {
        _data;
        _sender;
        return _recipients;
    }

    // only called via allo.sol by users to allocate to a recipient
    function _allocate(address[] memory _recipients, uint256[] memory _amounts, bytes memory _data, address _sender)
        internal
        override
    {
        _recipients;
        _amounts;
        _data;
        _sender;
    }

    // this will distribute tokens to recipients
    function _distribute(address[] memory _recipientIds, bytes memory _data, address _sender) internal override {
        _recipientIds;
        _data;
        _sender;
    }

    function onlyErc20Helper(address _token, uint256 _amount) public onlyWithToken(_token, _amount, msg.sender) {}

    function onlyWithNFTHelper(address _nft) public onlyWithNFT(_nft, msg.sender) {}

    function onlyWithAttestationHelper(bytes32 _schema, address _attester, bytes32 _uid)
        public
        onlyWithAttestation(_schema, _attester, _uid)
    {}
}