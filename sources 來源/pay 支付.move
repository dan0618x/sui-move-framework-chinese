// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// 這個模塊為錢包和 `sui::Coin` 管理提供方便的功能。
module sui::pay {
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use std::vector;

    /// 當空向量被提供給 join 函數時。
    const ENoCoins: u64 = 0;

    /// 將 `c` 傳遞給當前交易的發送方
    public fun keep<T>(c: Coin<T>, ctx: &TxContext) {
        transfer::transfer(c, tx_context::sender(ctx))
    }

    /// 將硬幣 `self` 拆分為兩個硬幣，一個帶有餘額 `split_amount`，剩下的餘額是 `self`。
    public entry fun split<T>(
        self: &mut Coin<T>, split_amount: u64, ctx: &mut TxContext
    ) {
        keep(coin::split(self, split_amount, ctx), ctx)
    }

    /// 將 coin `self` 拆分為多個 coin，每個都有指定的餘額在 `split_amounts` 中。剩餘餘額留在 `self` 中。
    public entry fun split_vec<T>(
        self: &mut Coin<T>, split_amounts: vector<u64>, ctx: &mut TxContext
    ) {
        let (i, len) = (0, vector::length(&split_amounts));
        while (i < len) {
            split(self, *vector::borrow(&split_amounts, i), ctx);
            i = i + 1;
        };
    }

    /// 將 `c` 的 `amount` 單位發送給 `recipient`如果 `amount` 大於或等於 `amount`，則使用 `EVALUE` 中止
    public entry fun split_and_transfer<T>(
        c: &mut Coin<T>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        transfer::transfer(coin::split(c, amount, ctx), recipient)
    }


    /// 將硬幣 `self` 分成餘額相等的 `n - 1` 硬幣。如果餘額是不能被 `n` 整除，餘數留在 `self` 中。
    public entry fun divide_and_keep<T>(
        self: &mut Coin<T>, n: u64, ctx: &mut TxContext
    ) {
        let vec: vector<Coin<T>> = coin::divide_into_n(self, n, ctx);
        let (i, len) = (0, vector::length(&vec));
        while (i < len) {
            transfer::transfer(vector::pop_back(&mut vec), tx_context::sender(ctx));
            i = i + 1;
        };
        vector::destroy_empty(vec);
    }

    /// 將 `coin` 加入 `self`。重新導出 coin::join 函數。
    public entry fun join<T>(self: &mut Coin<T>, coin: Coin<T>) {
        coin::join(self, coin)
    }

    /// 將 `coins` 中的所有內容與 `self` 連接起來
    public entry fun join_vec<T>(self: &mut Coin<T>, coins: vector<Coin<T>>) {
        let (i, len) = (0, vector::length(&coins));
        while (i < len) {
            let coin = vector::pop_back(&mut coins);
            coin::join(self, coin);
            i = i + 1
        };
        // 安全，因為我們已經耗盡了向量
        vector::destroy_empty(coins)
    }

    /// 將 `Coin` 的向量加入單個對象並將其傳輸到 `receiver`。
    public entry fun join_vec_and_transfer<T>(coins: vector<Coin<T>>, receiver: address) {
        assert!(vector::length(&coins) > 0, ENoCoins);

        let self = vector::pop_back(&mut coins);
        join_vec(&mut self, coins);
        transfer::transfer(self, receiver)
    }
}
