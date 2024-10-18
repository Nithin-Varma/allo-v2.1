// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Setup} from "../Setup.t.sol";
import {IRegistry} from "contracts/core/Registry.sol";
import {Allo, Metadata} from "contracts/core/Allo.sol";
import {FuzzERC20} from "../helpers/FuzzERC20.sol";

contract HandlerAllo is Setup {
    uint256[] ghost_poolIds;
    mapping(uint256 _poolId => address[] _managers) ghost_poolManagers;
    mapping(uint256 _poolId => address _poolAdmin) ghost_poolAdmins;

    function handler_createPool(uint256 _msgValue) public {
        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(
            _ghost_anchorOf[msg.sender]
        );

        // Avoid EOA
        if (profile.anchor == address(0)) return;

        // Create a pool
        (bool succ, bytes memory ret) = targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.createPool,
                (
                    profile.id,
                    address(strategy_directAllocation),
                    bytes(""),
                    address(token),
                    0,
                    profile.metadata,
                    new address[](0)
                )
            )
        );

        if (succ) {
            uint256 _poolId = abi.decode(ret, (uint256));
            ghost_poolIds.push(_poolId);
            ghost_poolAdmins[_poolId] = msg.sender;
        }
    }

    function handler_updatePoolMetadata(
        uint256 _idSeed,
        uint256 _metadataProtocol,
        string calldata _data
    ) public {
        // Needs at least one pool
        if (ghost_poolIds.length == 0) return;

        _idSeed = _idSeed % ghost_poolIds.length;
        uint256 poolId = ghost_poolIds[_idSeed];

        // Get the profile ID
        IRegistry.Profile memory profile = registry.getProfileByAnchor(
            _ghost_anchorOf[msg.sender]
        );

        // Avoid EOA
        if (profile.anchor == address(0)) return;

        Metadata memory metadata = Metadata({
            protocol: _metadataProtocol,
            pointer: _data
        });

        // Update the pool metadata - will revert on wrong anchor
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.updatePoolMetadata, (poolId, metadata))
        );
    }

    function handler_updatePercentFee(uint256 _newPercentFee) public {
        _newPercentFee = bound(_newPercentFee, 0, 1e18);

        // Update the percent fee - will revert if caller is not the owner
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.updatePercentFee, (_newPercentFee))
        );
    }

    function handler_updateBaseFee(uint256 _newBaseFee) public {
        // Update the base fee - will revert if caller is not the owner
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.updateBaseFee, (_newBaseFee))
        );
    }

    function handler_updateRegistry(address _newRegistry) public {
        // Update the registry - will revert if caller is not the owner or if the new registry is zero
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.updateRegistry, (_newRegistry))
        );
    }

    function handler_updateTreasury(address _newTreasury) public {
        // Update the treasury - will revert if caller is not the owner or if the new treasury is zero
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.updateTreasury, (payable(_newTreasury)))
        );
    }

    function handler_updateTrustedForwarder(address _newForwarder) public {
        // Update the trusted forwarder - will revert if caller is not the owner or if the new forwarder is zero
        targetCall(
            address(allo),
            0,
            abi.encodeCall(Allo.updateTrustedForwarder, (_newForwarder))
        );
    }

    function handler_addPoolManagers(
        uint256 _idSeed,
        address[] calldata _managers
    ) public {
        uint256 _poolId = _pickPoolId(_idSeed);

        // Add pool managers - will revert if caller is not the pool admin of the pool id
        (bool _succ, ) = targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.addPoolManagers, (_poolId, _managers))
        );

        if (_succ) {
            for (uint256 _i; _i < _managers.length; ++_i) {
                ghost_poolManagers[_poolId].push(_managers[_i]);
            }
        }
    }

    function handler_removePoolManagers(uint256 _idSeed) public {
        uint256 _poolId = _pickPoolId(_idSeed);
        address[] memory _managers = ghost_poolManagers[_poolId];

        // Remove pool managers - will revert if caller is not a pool admin of the pool id
        (bool _succ, ) = targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.removePoolManagers, (_poolId, _managers))
        );

        if (_succ) {
            delete ghost_poolManagers[_poolId];
        }
    }

    function handler_addPoolManagersInMultiplePools(
        uint256[] calldata _seeds
    ) public {
        uint256[] memory _poolIds = _pickPoolId(_seeds);

        address[] memory _managers = ghost_poolManagers[_poolIds[0]];

        // Add pool managers in multiple pools - will revert if caller is not a pool admin of any pool id
        (bool _succ, ) = targetCall(
            address(allo),
            0,
            abi.encodeCall(
                allo.addPoolManagersInMultiplePools,
                (_poolIds, _managers)
            )
        );

        if (_succ) {
            for (uint256 _i; _i < _poolIds.length; ++_i) {
                uint256 _poolId = _poolIds[_i];
                for (uint256 _j; _j < _managers.length; ++_j) {
                    ghost_poolManagers[_poolId].push(_managers[_j]);
                }
            }
        }
    }

    function handler_removePoolManagersInMultiplePools(
        uint256[] calldata _seeds,
        address[] calldata _managers
    ) public {
        uint256[] memory _poolIds = _pickPoolId(_seeds);

        // Remove pool managers in multiple pools - will revert if caller is not a pool admin of any pool id
        (bool _succ, ) = targetCall(
            address(allo),
            0,
            abi.encodeCall(
                allo.removePoolManagersInMultiplePools,
                (_poolIds, _managers)
            )
        );

        if (_succ) {
            for (uint256 _i; _i < _poolIds.length; ++_i) {
                uint256 _poolId = _poolIds[_i];
                delete ghost_poolManagers[_poolId];
            }
        }
    }

    function handler_recoverFunds(address _token, address _recipient) public {
        // Recover funds - will revert if caller is not the owner
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.recoverFunds, (_token, _recipient))
        );
    }

    function handler_registerRecipient(
        uint256 _seed,
        address[] memory _recipientAddresses,
        bytes memory _data,
        uint256 _msgValue
    ) public {
        uint256 _poolId = _pickPoolId(_seed);
        // Register recipient
        targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.registerRecipient,
                (_poolId, _recipientAddresses, _data)
            )
        );
    }

    function handler_batchRegisterRecipient(
        uint256[] memory _seeds,
        address[][] memory _recipientAddresses,
        bytes[] memory _data
    ) public {
        uint256[] memory _poolIds = _pickPoolId(_seeds);
        // Batch register recipient - will revert if arrays are not of same length
        targetCall(
            address(allo),
            0,
            abi.encodeCall(
                allo.batchRegisterRecipient,
                (_poolIds, _recipientAddresses, _data)
            )
        );
    }

    function handler_fundPool(
        uint256 _seed,
        uint256 _amount,
        uint256 _msgValue
    ) public {
        uint256 _poolId = _pickPoolId(_seed);
        uint256 _previousBalance = token.balanceOf(address(msg.sender));
        if (_previousBalance > 0) {
            _amount = bound(_amount, 0, type(uint256).max - _previousBalance);
        }

        if (_amount > 0) {
            FuzzERC20(address(token)).mint(address(msg.sender), _amount);
        }

        // Fund pool - will revert if the amount is zero or if pool token is native and message value is != amount
        targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(allo.fundPool, (_poolId, _amount))
        );
    }

    function handler_allocate(
        uint256 _seed,
        address[] memory _recipients,
        uint256[] memory _amounts,
        bytes memory _data,
        uint256 _msgValue
    ) public {
        uint256 _poolId = _pickPoolId(_seed);
        // Allocate - allocate to a recipient or multiple recipients
        targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.allocate,
                (_poolId, _recipients, _amounts, _data)
            )
        );
    }

    function handler_batchAllocate(
        uint256[] calldata _seeds,
        address[][] calldata _recipients,
        uint256[][] calldata _amounts,
        uint256[] calldata _values,
        bytes[] memory _datas,
        uint256 _msgValue
    ) public {
        uint256[] memory _poolIds = _pickPoolId(_seeds);
        // Batch allocate - allocate to multiple pools and recipients, will revert if arrays are not of same length
        targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.batchAllocate,
                (_poolIds, _recipients, _amounts, _values, _datas)
            )
        );
    }

    function handler_distribute(
        uint256 _seed,
        address[] memory _recipientIds,
        bytes memory _data
    ) public {
        uint256 _poolId = _pickPoolId(_seed);
        // Distribute - distribute to a recipient or multiple recipients
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.distribute, (_poolId, _recipientIds, _data))
        );
    }

    function handler_changeAdmin(uint256 _seed, address _newAdmin) public {
        uint256 _poolId = _pickPoolId(_seed);
        // Change admin - will revert if caller is not the pool admin
        targetCall(
            address(allo),
            0,
            abi.encodeCall(allo.changeAdmin, (_poolId, _newAdmin))
        );
    }

    function handler_createPoolWithCustomStrategy(uint256 _msgValue) public {
        // Get the profile ID
        IRegistry.Profile memory _profile = registry.getProfileByAnchor(
            _ghost_anchorOf[msg.sender]
        );

        // Avoid EOA
        if (_profile.anchor == address(0)) revert("EOA");

        targetCall(
            address(allo),
            _msgValue,
            abi.encodeCall(
                allo.createPoolWithCustomStrategy,
                (
                    _profile.id,
                    address(strategy_directAllocation),
                    bytes(""),
                    address(token),
                    0,
                    _profile.metadata,
                    new address[](0)
                )
            )
        );
    }

    function _pickPoolId(uint256 _idSeed) internal view returns (uint256) {
        if (ghost_poolIds.length == 0) return 0;

        return ghost_poolIds[_idSeed % ghost_poolIds.length];
    }

    function _pickPoolId(
        uint256[] memory _seeds
    ) internal view returns (uint256[] memory) {
        uint256[] memory _poolIds = new uint256[](_seeds.length);

        for (uint256 _i; _i < _seeds.length; ++_i) {
            _poolIds[_i] = _pickPoolId(_seeds[_i]);
        }

        return _poolIds;
    }
}
