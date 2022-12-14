// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// 定義 `Coin` 類型 - 可替代代幣和硬幣的平台範圍表示。 
/// `Coin` 可以描述為 `Balance` 類型的安全包裝器。
module sui::coin {
    use sui::balance::{Self, Balance, Supply};
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;
    use std::vector;
    use sui::event;

    /// 當傳遞給 create_supply 的類型不是一次性見證時。
    const EBadWitness: u64 = 0;

    /// 當無效參數傳遞給函數時。
    const EInvalidArg: u64 = 1;

    /// 當嘗試拆分硬幣的次數超過其餘額允許的次數時。
    const ENotEnough: u64 = 2;

    /// `T` 代幣的價值。 可轉移和可存儲
    struct Coin<phantom T> has key, store {
        id: UID,
        balance: Balance<T>
    }

    /// 允許持有人鑄造和燃燒“T”代幣的能力。 可轉讓
    struct TreasuryCap<phantom T> has key, store {
        id: UID,
        total_supply: Supply<T>
    }

    // === 活動/事件 ===

    /// 當通過 `create_currency` 調用創建新貨幣時發出。
    /// 包含用於鏈下發現的貨幣元數據。
    ///  `T` 類型參數匹配 `Coin<T>` 中的 T
    struct CurrencyCreated<phantom T> has copy, drop {
        /// 硬幣使用的小數位數。
        /// 具有價值 N 和小數點 D 的硬幣應顯示為 N / 10^D 例如：具有`value` 7002 和小數點 3 的硬幣應顯示為 7.002
        /// 這是僅用於顯示用途的元數據。
        decimals: u8
    }

    // === Supply <-> TreasuryCap 變形和訪問器  ===

    /// 返回流通中的“T”總數。
    public fun total_supply<T>(cap: &TreasuryCap<T>): u64 {
        balance::supply_value(&cap.total_supply)
    }

    /// 打開 `TreasuryCap` 獲取 `Supply`。
    ///
    /// 此操作是不可逆的。由於不同的安全保證，Supply無法轉換為“TreasuryCap”（一種類型只能創建一次TreasuryCap）
    public fun treasury_into_supply<T>(treasury: TreasuryCap<T>): Supply<T> {
        let TreasuryCap { id, total_supply } = treasury;
        object::delete(id);
        total_supply
    }

    /// 獲取庫中“Supply”的不可變引用。
    public fun supply<T>(treasury: &mut TreasuryCap<T>): &Supply<T> {
        &treasury.total_supply
    }

    /// 獲取庫中“Supply”的可變引用。
    public fun supply_mut<T>(treasury: &mut TreasuryCap<T>): &mut Supply<T> {
        &mut treasury.total_supply
    }

    // === Balance <-> Coin 訪問器和類型變形 ===

    /// 公開獲取代幣價值
    public fun value<T>(self: &Coin<T>): u64 {
        balance::value(&self.balance)
    }

    /// 獲取coin餘額的不可變引用。
    public fun balance<T>(coin: &Coin<T>): &Balance<T> {
        &coin.balance
    }

    /// 獲取coin餘額的可變引用
    public fun balance_mut<T>(coin: &mut Coin<T>): &mut Balance<T> {
        &mut coin.balance
    }

    /// 將balance包裝為coin以使其可轉移。
    public fun from_balance<T>(balance: Balance<T>, ctx: &mut TxContext): Coin<T> {
        Coin { id: object::new(ctx), balance }
    }

    /// 拆開Coin包裝，將balance保存。
    public fun into_balance<T>(coin: Coin<T>): Balance<T> {
        let Coin { id, balance } = coin;
        object::delete(id);
        balance
    }

    /// 從 `Balance` 中獲取 `Coin` 的 `value`。
    /// 如果 `value > balance.value` 則中止
    public fun take<T>(
        balance: &mut Balance<T>, value: u64, ctx: &mut TxContext,
    ): Coin<T> {
        Coin {
            id: object::new(ctx),
            balance: balance::split(balance, value)
        }
    }

    /// 將 `Coin<T>` 放入 `Balance<T>`。
    public fun put<T>(balance: &mut Balance<T>, coin: Coin<T>) {
        balance::join(balance, into_balance(coin));
    }

    // === 基礎coin功能 ===

    /// 消耗硬幣`c`並將其值添加到`self`。
    /// 如果 `c.value + self.value > U64_MAX` 則中止
    public entry fun join<T>(self: &mut Coin<T>, c: Coin<T>) {
        let Coin { id, balance } = c;
        object::delete(id);
        balance::join(&mut self.balance, balance);
    }

    /// 將硬幣`self`拆分成兩個硬幣，一個有餘額split_amount，另一個餘額為`self`。
    public fun split<T>(
        self: &mut Coin<T>, split_amount: u64, ctx: &mut TxContext
    ): Coin<T> {
        take(&mut self.balance, split_amount, ctx)
    }

    /// 將硬幣“self”拆分為餘額相等的“n - 1”硬幣。 其餘的留在 `self` 中。 返回新創建的硬幣。
    public fun divide_into_n<T>(
        self: &mut Coin<T>, n: u64, ctx: &mut TxContext
    ): vector<Coin<T>> {
        assert!(n > 0, EInvalidArg);
        assert!(n <= value(self), ENotEnough);

        let vec = vector::empty<Coin<T>>();
        let i = 0;
        let split_amount = value(self) / n;
        while (i < n - 1) {
            vector::push_back(&mut vec, split(self, split_amount, ctx));
            i = i + 1;
        };
        vec
    }

    /// 製作任何零值的硬幣。 用於佔位投標/付款或搶先製作空餘額。
    public fun zero<T>(ctx: &mut TxContext): Coin<T> {
        Coin { id: object::new(ctx), balance: balance::zero() }
    }

    /// 銷毀價值為零的硬幣
    public fun destroy_zero<T>(c: Coin<T>) {
        let Coin { id, balance } = c;
        object::delete(id);
        balance::destroy_zero(balance)
    }

    // === 註冊新的硬幣類型和管理硬幣供應 ===

    /// 創建一個新的貨幣類型“T”，並將“T”的“TreasuryCap”返回給調用者。 只能使用 `one-time-witness` 類型調用，確保每個 `T` 只有一個 `TreasuryCap`。
    public fun create_currency<T: drop>(
        witness: T,
        decimals: u8,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        // 確保只有一個 T 類型的實例
        assert!(sui::types::is_one_time_witness(&witness), EBadWitness);

        // 將貨幣元數據作為事件發出。
        event::emit(CurrencyCreated<T> {
            decimals
        });

        TreasuryCap {
            id: object::new(ctx),
            total_supply: balance::create_supply(witness)
        }
    }

    /// 創造一個“value”價值的coin。 並相應地增加 `cap` 中的總供應量。
    public fun mint<T>(
        cap: &mut TreasuryCap<T>, value: u64, ctx: &mut TxContext,
    ): Coin<T> {
        Coin {
            id: object::new(ctx),
            balance: balance::increase_supply(&mut cap.total_supply, value)
        }
    }

    /// 鑄造一些 T 作為“balance”，並相應地增加 `cap`中的總供應量。
    /// 如果 `value` + `cap.total_supply` >= U64_MAX 則中止。
    public fun mint_balance<T>(
        cap: &mut TreasuryCap<T>, value: u64
    ): Balance<T> {
        balance::increase_supply(&mut cap.total_supply, value)
    }

    /// 銷毀硬幣“c”並相應地減少“cap”中的總供應量。
    public fun burn<T>(cap: &mut TreasuryCap<T>, c: Coin<T>): u64 {
        let Coin { id, balance } = c;
        object::delete(id);
        balance::decrease_supply(&mut cap.total_supply, balance)
    }

    // === 入口點 ===

    /// 鑄造`Coin`的`amount`並將其發送給`recipient`。 調用`mint()`。
    public entry fun mint_and_transfer<T>(
        c: &mut TreasuryCap<T>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        transfer::transfer(mint(c, amount, ctx), recipient)
    }

    /// 燒掉一枚硬幣並減少總供應量。 調用`burn()`。
    public entry fun burn_<T>(c: &mut TreasuryCap<T>, coin: Coin<T>) {
        burn(c, coin);
    }

    // === 測試用代碼 ===

    #[test_only]
    /// 僅用於（顯然！）測試目的的任何類型的鑄幣
    public fun mint_for_testing<T>(value: u64, ctx: &mut TxContext): Coin<T> {
        Coin { id: object::new(ctx), balance: balance::create_for_testing(value) }
    }

    #[test_only]
    /// 銷毀具有任何價值的“硬幣”以進行測試。
    public fun destroy_for_testing<T>(self: Coin<T>): u64 {
        let Coin { id, balance } = self;
        object::delete(id);
        balance::destroy_for_testing(balance)
    }
}
