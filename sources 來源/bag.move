// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// 一個包是一個異構的類似地圖的集合。該集合類似於 `sui::table`它的鍵和值不存儲在 `Bag` 值中，而是使用 Sui 的存儲對象系統。
/// `Bag` 結構僅充當對象系統的句柄以檢索那些鍵和值。
/// 請注意，這意味著具有完全相同的鍵值映射的 `Bag` 值將不會被在運行時使用 `==` 相等。
/// 例如```
/// 讓 bag1 = bag::new();
/// 讓 bag2 = bag::new();
/// bag::add(&mut bag1, 0, false);
/// bag::add(&mut bag1, 1, true);
/// bag::add(&mut bag2, 0, false);
/// bag::add(&mut bag2, 1, true);
/// // bag1 不等於 bag2，儘管有相同的條目
/// assert!(&bag1 != &bag2, 0);
/// ```
/// 在它的核心，`sui::bag` 是 `UID` 的包裝器，允許訪問 `sui::dynamic_field` 同時防止意外擱淺字段值。
/// `UID` 可以是刪除，即使它有關聯的動態字段，但另一方面，包必須是空的被銷毀。

module sui::bag {

use sui::object::{Self, UID};
use sui::dynamic_field as field;
use sui::tx_context::TxContext;

// 試圖銷毀一個非空包
const EBagNotEmpty: u64 = 0;

struct Bag has key, store {
    /// 這個包的ID
    id: UID,
    /// 包中鍵值對的個數
    size: u64,
}

/// 創建一個新的空包
public fun new(ctx: &mut TxContext): Bag {
    Bag {
        id: object::new(ctx),
        size: 0,
    }
}

/// 添加一個鍵值對到 bag `bag: &mut Bag` 如果包已經有entry key `k: K` 的條目，則使用 `sui::dynamic_field::EFieldAlreadyExists` 中止。

public fun add<K: copy + drop + store, V: store>(bag: &mut Bag, k: K, v: V) {
    field::add(&mut bag.id, k, v);
    bag.size = bag.size + 1;
}

/// 不可變的借用包中的鍵關聯的值 `bag: &Bag`。
/// 如果包沒有entry key `k:K` 的條目，則使用 `sui::dynamic_field::EFieldDoesNotExist` 中止。
/// 如果包有entry key，但值不具有指定的類型，則使用 `sui::dynamic_field::EFieldTypeMismatch` 中止。

public fun borrow<K: copy + drop + store, V: store>(bag: &Bag, k: K): &V {
    field::borrow(&bag.id, k)
}

/// 可變的借用包中的鍵關聯的值 `bag: &mut Bag` 。
/// 如果包沒有entry key `k:K` 的條目，則使用 `sui::dynamic_field::EFieldDoesNotExist` 中止。
/// 如果包有entry key，但值不具有指定的類型，則使用 `sui::dynamic_field::EFieldTypeMismatch` 中止。

public fun borrow_mut<K: copy + drop + store, V: store>(bag: &mut Bag, k: K): &mut V {
    field::borrow_mut(&mut bag.id, k)
}

/// 可變借用包中的鍵值對並返回值 `bag: &mut Bag`。
/// 如果包沒有entry key `k:K` 的條目，則使用 `sui::dynamic_field::EFieldDoesNotExist` 中止。
/// 如果包有entry key，但值不具有指定的類型，則使用 `sui::dynamic_field::EFieldTypeMismatch` 中止。

public fun remove<K: copy + drop + store, V: store>(bag: &mut Bag, k: K): V {
    let v = field::remove(&mut bag.id, k);
    bag.size = bag.size - 1;
    v
}

/// 一旦我們有了lamport timestamps，TODO 執行控制（沒有V類型）
/// 如果在bag `bag：&Bag`中有一個與key`k：K`關聯的值，則返回true。

public fun contains_with_type<K: copy + drop + store, V: store>(bag: &Bag, k: K): bool {
    field::exists_with_type<K, V>(&bag.id, k)
}

/// 返回包的大小，key-value pairs的數量
public fun length(bag: &Bag): u64 {
    bag.size
}

/// 如果包為空則返回真（如果 `length` 返回 `0`）
public fun is_empty(bag: &Bag): bool {
    bag.size == 0
}

/// 銷毀一個空包
/// 如果包仍然包含值，則使用 `EBagNotEmpty` 中止
public fun destroy_empty(bag: Bag) {
    let Bag { id, size } = bag;
    assert!(size == 0, EBagNotEmpty);
    object::delete(id)
}

}
