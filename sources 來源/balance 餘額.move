// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// 一般用於餘額的可存儲處理程序。
/// 在 `Coin` 模塊中使用以允許餘額操作，並可用於使用 `Supply` 和 `Balance`s 實現自定義硬幣。

module sui::balance {
    /// 當試圖銷毀非零餘額時。
    const ENonZero: u64 = 0;

    /// 當供給操作發生溢出時。
    const EOverflow: u64 = 1;

    /// 當試圖撤回更多時。
    const ENotEnough: u64 = 2;

    /// T 的供應用於鑄造和燃燒。
    /// 包裝在“Coin”模塊中的“TreasuryCap”中。
    struct Supply<phantom T> has store {
        value: u64
    }

    /// 可存儲餘額 - Coin 類型的內部結構。
    /// 可用於存放不需要 key 能力的 Coin。
    struct Balance<phantom T> has store {
        value: u64
    }

    /// 獲取存儲在“餘額”中的金額。
    public fun value<T>(self: &Balance<T>): u64 {
        self.value
    }

    /// 獲取“供應”值。
    public fun supply_value<T>(supply: &Supply<T>): u64 {
        supply.value
    }

    /// 為類型 T 創建一個新供應。
    public fun create_supply<T: drop>(_: T): Supply<T> {
        Supply { value: 0 }
    }

    /// 通過 `value` 增加供應並使用該值創建一個新的 `Balance<T>`。
    public fun increase_supply<T>(self: &mut Supply<T>, value: u64): Balance<T> {
        assert!(value < (18446744073709551615u64 - self.value), EOverflow);
        self.value = self.value + value;
        Balance { value }
    }

    /// 燒掉一個餘額<T>並減少供應量<T>。
    public fun decrease_supply<T>(self: &mut Supply<T>, balance: Balance<T>): u64 {
        let Balance { value } = balance;
        assert!(self.value >= value, EOverflow);
        self.value = self.value - value;
        value
    }

    /// 為類型“T”創建一個零“balance”。
    public fun zero<T>(): Balance<T> {
        Balance { value: 0 }
    }

    spec zero {
        aborts_if false;
        ensures result.value == 0;
    }

    /// 將兩個餘額連接在一起。
    public fun join<T>(self: &mut Balance<T>, balance: Balance<T>): u64 {
        let Balance { value } = balance;
        self.value = self.value + value;
        self.value
    }

    spec join {
        ensures self.value == old(self.value) + balance.value;
        ensures result == self.value;
    }

    /// 拆分“balance”並從中獲取子餘額。
    public fun split<T>(self: &mut Balance<T>, value: u64): Balance<T> {
        assert!(self.value >= value, ENotEnough);
        self.value = self.value - value;
        Balance { value }
    }

    spec split {
        aborts_if self.value < value with ENotEnough;
        ensures self.value == old(self.value) - value;
        ensures result.value == value;
    }

    /// 銷毀零“balance”。
    public fun destroy_zero<T>(balance: Balance<T>) {
        assert!(balance.value == 0, ENonZero);
        let Balance { value: _ } = balance;
    }

    spec destroy_zero {
        aborts_if balance.value != 0 with ENonZero;
    }

    #[test_only]
    /// 為測試目的，創建任何coin的“Balance”。
    public fun create_for_testing<T>(value: u64): Balance<T> {
        Balance { value }
    }

    #[test_only]
    /// 為測試目的，銷毀其中包含任何值的“Balance”。
    public fun destroy_for_testing<T>(self: Balance<T>): u64 {
        let Balance { value } = self;
        value
    }

    #[test_only]
    /// 為測試目的，銷毀其中包含任何值的 `Supply`。
    public fun destroy_supply_for_testing<T>(self: Supply<T>): u64 {
        let Supply { value } = self;
        value
    }

    #[test_only]
    /// 為測試目的，創建任何coin的“Supply”。
    public fun create_supply_for_testing<T>(value: u64): Supply<T> {
        Supply { value }
    }
}

#[test_only]
module sui::balance_tests {
    use sui::balance;
    use sui::sui::SUI;

    #[test]
    fun test_balance() {
        let balance = balance::zero<SUI>();
        let another = balance::create_for_testing(1000);

        balance::join(&mut balance, another);

        assert!(balance::value(&balance) == 1000, 0);

        let balance1 = balance::split(&mut balance, 333);
        let balance2 = balance::split(&mut balance, 333);
        let balance3 = balance::split(&mut balance, 334);

        balance::destroy_zero(balance);

        assert!(balance::value(&balance1) == 333, 1);
        assert!(balance::value(&balance2) == 333, 2);
        assert!(balance::value(&balance3) == 334, 3);

        balance::destroy_for_testing(balance1);
        balance::destroy_for_testing(balance2);
        balance::destroy_for_testing(balance3);
    }
}
