// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ISanctionEvents } from "./ISanction.sol";

import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import { AccessControl } from "openzeppelin/access/AccessControl.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";

contract Sanction is ISanctionEvents, ERC20, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bool) private _sanctionList;

    modifier checkSanctions() {
        require(
            !_sanctionList[msg.sender],
            string(
                abi.encodePacked(
                    "Unauthorized: account ",
                    Strings.toHexString(msg.sender),
                    " is on the sanction list"
                )
            )
        );
        _;
    }

    constructor(address admin) ERC20("Sanction", "SAN") {
        _grantRole(ADMIN_ROLE, admin);
    }

    function checkSanctionList(address user)
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (bool)
    {
        return _sanctionList[user];
    }

    function addToSanctionList(address user) external onlyRole(ADMIN_ROLE) {
        _sanctionList[user] = true;

        emit SanctionListUpdate(msg.sender, user, "ADD");
    }

    function removeFromSanctionList(address user)
        external
        onlyRole(ADMIN_ROLE)
    {
        delete _sanctionList[user];

        emit SanctionListUpdate(msg.sender, user, "REMOVE");
    }

    function mint(uint256 amount) external payable checkSanctions {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external checkSanctions {
        _burn(msg.sender, amount);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        checkSanctions
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        checkSanctions
        returns (bool)
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}
