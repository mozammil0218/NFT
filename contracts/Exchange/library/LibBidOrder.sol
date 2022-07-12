// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <=0.8.13;

library LibBidOrder {

    bytes32 constant BID_ORDER_TYPEHASH = keccak256(
        "BidOrder(bytes4 tokenType,bytes4 saleType,address seller,address tokenAddress,uint256 tokenId,uint256 tokenAmount,uint256 price,uint256 startTime,uint256 endTime,uint256 nonce,address buyer,uint256 bidAmount)"
    );

    struct BidOrder {
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
        address buyer;
        uint256 bidAmount;
    }

    /**
     * @dev Internal function to get bid order type hash.
     *
     * Requirements:
     * - @param order - object of a bid order.
     * 
     * @return bytes32 - hash value.
     */
    function genBidOrderHash(BidOrder memory order) internal pure returns(bytes32) {
        return keccak256(
            abi.encode(BID_ORDER_TYPEHASH, order.tokenType, order.saleType, order.seller, order.tokenAddress, order.tokenId, order.tokenAmount, order.price, order.startTime, order.endTime, order.nonce, order.buyer, order.bidAmount)
        );
    }
}