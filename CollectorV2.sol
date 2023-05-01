// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CollectorV2 is Ownable, ReentrancyGuard {
    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => bool) public supportedTokens;
    address[] public tokenAddresses;
    
    event TokenTransfer(
        address indexed sender,
        address indexed recipient,
        address indexed tokenAddress,
        uint256 amount
    );

    constructor(address[] memory _tokens) {
        for (uint i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = true;
            tokenAddresses.push(_tokens[i]);
        }
    }

    function CollectV2(
        address _tokenAddress,
        uint256 _amount
    ) external payable nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "Incorrect amount of BNB sent");
            payable(owner()).transfer(msg.value);
            balances[msg.sender][_tokenAddress] += msg.value;
        } 
        else {
            require(supportedTokens[_tokenAddress], "Token not supported");
            IERC20 token = IERC20(_tokenAddress);
            address sender = msg.sender;

            require(
                token.transferFrom(sender, owner(), _amount),
                "Transfer failed"
            );
            balances[sender][_tokenAddress] += _amount;
        }
        emit TokenTransfer(msg.sender, owner(), _tokenAddress, _amount);
    }

    function getBalance(
        address _user,
        address _tokenAddress
    ) public view returns (uint256) {
        return balances[_user][_tokenAddress];
    }
    
    function getSupportedTokenCount() public view returns (uint256) {
        return tokenAddresses.length;
    }

    function addSupportedToken(address _tokenAddress) external onlyOwner {
        require(!supportedTokens[_tokenAddress], "Token already added");
        supportedTokens[_tokenAddress] = true;
        tokenAddresses.push(_tokenAddress);
    }

    function removeSupportedToken(address _tokenAddress) external onlyOwner {
        require(supportedTokens[_tokenAddress], "Token already removed");
        supportedTokens[_tokenAddress] = false;
        uint256 length = tokenAddresses.length;
        uint256 i = 0;
        for (i = 0; i < length; ++i) {
            if (tokenAddresses[i] == _tokenAddress) {
                break;
            }
        }
        tokenAddresses[i] = tokenAddresses[length - 1];
        tokenAddresses.pop();
    }
} 