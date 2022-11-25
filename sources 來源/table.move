// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// table是類似地圖的集合。 但與傳統集合不同的是，它的鍵和值不存儲在 `Table` 值中，而是使用 Sui 的對象系統存儲。 
/// `Table` 結構僅充當對象系統的句柄以檢索這些鍵和值。
/// 請注意，這意味著具有完全相同鍵值映射的 `Table` 值在運行時將不等於`==`。 
/// 例如 ```
/// let table1 = table::new<u64, bool>();
/// let table2 = table::new<u64, bool>();
/// table::add(&mut table1, 0, false);
/// table::add(&mut table1, 1, true);
/// table::add(&mut table2, 0, false);
/// table::add(&mut table2, 1, true);
///   // table1 不等於 table2，儘管有相同的條目
/// assert!(&table1 != &table2, 0);
/// ```

module sui::table {

use sui::object::{Self, UID};
use sui::dynamic_field as field;
use sui::tx_context::TxContext;

// 試圖銷毀非空table
const ETableNotEmpty: u64 = 0;

struct Table<phantom K: copy + drop + store, phantom V: store> has key, store {
    /// 此table的 ID
    id: UID,
    /// table中鍵值對的數量
    size: u64,
}

/// 創建一個新的空table
public fun new<K: copy + drop + store, V: store>(ctx: &mut TxContext): Table<K, V> {
    Table {
        id: object::new(ctx),
        size: 0,
    }
}

/// 向table 添加一個key-value pair。    `table: &mut Table<K, V>` 
/// 如果表已經有一個具有entry key `k: K` 的條目，則使用 `sui::dynamic_field::EFieldAlreadyExists` 中止。

public fun add<K: copy + drop + store, V: store>(table: &mut Table<K, V>, k: K, v: V) {
    field::add(&mut table.id, k, v);
    table.size = table.size + 1;
}

/// 不可變的借用了table 中的key關聯的value。  `table: &Table<K, V>`
/// 如果表沒有entry key `k:K` 的條目，則使用 `sui::dynamic_field::EFieldDoesNotExist` 中止。

public fun borrow<K: copy + drop + store, V: store>(table: &Table<K, V>, k: K): &V {
    field::borrow(&table.id, k)
}

/// 可變的借用與table 中的key關聯的value。   `table: &mut Table<K, V>`
/// 如果表沒有entry key `k: K` 的條目，則使用 `sui::dynamic_field::EFieldDoesNotExist` 中止。

public fun borrow_mut<K: copy + drop + store, V: store>(table: &mut Table<K, V>, k: K): &mut V {
    field::borrow_mut(&mut table.id, k)
}

/// 可變的借用table 中的鍵值對並返回值。   `table: &mut Table<K, V>`
/// 如果表沒有entry key `k: K` 的條目，則使用 `sui::dynamic_field::EFieldDoesNotExist` 中止。

public fun remove<K: copy + drop + store, V: store>(table: &mut Table<K, V>, k: K): V {
    let v = field::remove(&mut table.id, k);
    table.size = table.size - 1;
    v
}

/// 如果table中 `table: &Table<K, V>` 存在與key `k: K` 關聯的值，則返回 true
public fun contains<K: copy + drop + store, V: store>(table: &Table<K, V>, k: K): bool {
    field::exists_with_type<K, V>(&table.id, k)
}

/// 返回table的大小，key-value pairs的數值
public fun length<K: copy + drop + store, V: store>(table: &Table<K, V>): u64 {
    table.size
}

/// 如果table為空，則返回 true（如果 `length` 返回 `0`）
public fun is_empty<K: copy + drop + store, V: store>(table: &Table<K, V>): bool {
    table.size == 0
}

/// 銷毀一個空table
/// 如果表仍然包含值，則使用 `ETableNotEmpty` 中止

public fun destroy_empty<K: copy + drop + store, V: store>(table: Table<K, V>) {
    let Table { id, size } = table;
    assert!(size == 0, ETableNotEmpty);
    object::delete(id)
}

/// 刪除一個可能非空的table。
/// 僅當值類型 `V` 具有 `drop` 能力時才可用
public fun drop<K: copy + drop + store, V: drop + store>(table: Table<K, V>) {
    let Table { id, size: _ } = table;
    object::delete(id)
}

}
