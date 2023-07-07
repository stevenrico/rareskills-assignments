// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ISanctionEvents {
    event SanctionListUpdate(
        address indexed admin, address indexed user, string action
    );
}
