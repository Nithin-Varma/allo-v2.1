// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;


/**
 * @title IGitcoinPassportDecoder
 * @notice Minimal interface for consuming GitcoinPassportDecoder data
 */
interface IGitcoinPassportDecoder {
  function getScore(address user) external view returns (uint256);

  function getScore(uint32 communityId, address user) external view returns (uint256);

  function isHuman(address user) external view returns (bool);
}