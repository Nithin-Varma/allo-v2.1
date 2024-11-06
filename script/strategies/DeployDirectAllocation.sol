// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployBase} from "script/DeployBase.sol";
import {DirectAllocation} from "contracts/strategies/examples/direct-allocation/DirectAllocation.sol";

contract DeployDirectAllocation is DeployBase {
    function _deploy() internal override returns (address _contract, string memory _contractName) {
        address _allo = vm.envAddress("ALLO_ADDRESS");

        _contract = address(new DirectAllocation(_allo));
        _contractName = "DirectAllocation";
    }
}
