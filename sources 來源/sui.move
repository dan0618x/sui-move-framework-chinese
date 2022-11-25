// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Coin<SUI> 是 Sui 中用於支付 gas 的代幣。
/// 它有9位小數，最小的單位（10^-9）叫做“霧”。
module sui::sui {
    use std::option;
    use sui::tx_context::TxContext;
    use sui::balance::Supply;
    use sui::transfer;
    use sui::coin;

    friend sui::genesis;

    /// 幣名
    struct SUI has drop {}

    /// 註冊 `SUI` 硬幣以獲取其 `Supply`。
    /// 這應該在創世紀創建期間只調用一次。
    public(friend) fun new(ctx: &mut TxContext): Supply<SUI> {
        let (treasury, metadata) = coin::create_currency(
            SUI {}, 
            9,
            b"SUI",
            b"Sui",
            // TODO: 添加適當的描述和標誌 url
            b"",
            option::none(),
            ctx
        );
        transfer::freeze_object(metadata);
        coin::treasury_into_supply(treasury)
    }

    public entry fun transfer(c: coin::Coin<SUI>, recipient: address) {
        transfer::transfer(c, recipient)
    }
}
