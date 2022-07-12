// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

library LibOrder {

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(bytes4 tokenType,bytes4 saleType,address seller,address tokenAddress,uint256 tokenId,uint256 tokenAmount,uint256 price,uint256 startTime,uint256 endTime,uint256 nonce)"
    );

    struct Order {
        bytes4 tokenType;
        bytes4 saleType;
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 nonce;
    }

    /**
     * @dev Internal function to get order hash.
     *
     * Requirements:
     * - @param order - object of an order.
     * 
     * @return bytes32 - hash value.
     */
    function genHashKey(Order memory order) internal pure returns(bytes32) {
        bytes32 hashKey = keccak256(
            abi.encode(order.tokenType, order.saleType, order.seller, order.tokenAddress, order.tokenId, order.tokenAmount, order.price, order.startTime, order.endTime, order.nonce)
        );
        return hashKey;
    }

    /**
     * @dev Internal function to get order type hash.
     *
     * Requirements:
     * - @param order - object of an order.
     * 
     * @return bytes32 - hash value.
     */
    function genOrderHash(Order memory order) internal pure returns(bytes32) {
        return keccak256(
            abi.encode(ORDER_TYPEHASH, order.tokenType, order.saleType, order.seller, order.tokenAddress, order.tokenId, order.tokenAmount, order.price, order.startTime, order.endTime, order.nonce)
        );
    }
}