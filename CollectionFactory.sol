// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC1155Collection.sol";

// Factory for ERC1155Collection
contract CollectionFactory is Ownable {

    using Counters for Counters.Counter;

    UpgradeableBeacon immutable beacon;
    address public current_implement;
    Counters.Counter internal id;

    constructor(address _upgrader, address _init_implement) {
        beacon = new UpgradeableBeacon(_init_implement);
        transferOwnership(_upgrader);
        current_implement = _init_implement;
    }

    address[] public Collections;

    struct Portfolio {
        address[] collections;
    }

    mapping(address => Portfolio) _collections;
    mapping(string => address) private _names;

    event createdCollection(address indexed creator, address collection);

    // Returns cloned collections address
    function createCollection(ERC1155Collection.Meta calldata _data)
    external returns(address){

        require(_names[_data.name] == address(0), "Collection with given name already exist");

        id.increment(); // id starts from 1

        BeaconProxy proxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(ERC1155Collection(address(0)).initialize.selector, _data, msg.sender)
        );

        Collections.push(address(proxy));

        _collections[msg.sender].collections.push(address(proxy));
        _names[_data.name] = address(proxy);

        emit createdCollection(msg.sender, address(proxy));

        return address(proxy);
    }

    function getByName(string memory name) external view returns (address) {
        require(_names[name] != address(0), "Collection doesn't exist");
        return _names[name];
    }

    function getCreatorCollections(address creator) external view returns(address[] memory){
        return _collections[creator].collections;
    }

    function total() external view returns (uint256) {
        return id.current();
    }


    // Init Beacon update
    function upgrade(address _implementation)
    external onlyOwner {
        beacon.upgradeTo(_implementation);
        current_implement = _implementation;
    }

    // Current Beacon
    function implementation()
    external view returns(address) {
        return beacon.implementation();
    }
}
