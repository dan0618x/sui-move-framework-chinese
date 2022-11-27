// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// 該模塊定義了 Option 類型及其表示和處理可選值的方法。
module std::option {
    use std::vector;

    /// 可能存在或不存在的抽象值。 使用大小為 0 或 1 的向量實現，因為 Move 字節碼沒有 ADT。
    struct Option<Element> has copy, drop, store {
        vec: vector<Element>
    }
    spec Option {
        /// 向量的大小總是小於等於 1，因為它是 0 表示“無”或 1 表示“一些”。
        invariant len(vec) <= 1;
    }

    /// 對於嘗試的操作，“Option”處於無效狀態。
    /// `Option` 是 `Some` 而它應該是 `None`。
    const EOPTION_IS_SET: u64 = 0x40000;
    /// `Option` 對於嘗試的操作處於無效狀態。
    /// `Option` 是 `Some` 而它應該是 `None`。
    const EOPTION_NOT_SET: u64 = 0x40001;

    /// 返回一個空的“選項”
    public fun none<Element>(): Option<Element> {
        Option { vec: vector::empty() }
    }
    spec none {
        pragma opaque;
        aborts_if false;
        ensures result == spec_none<Element>();
    }
    spec fun spec_none<Element>(): Option<Element> {
        Option{ vec: vec() }
    }

    /// 返回一個包含 `e` 的 `Option`
    public fun some<Element>(e: Element): Option<Element> {
        Option { vec: vector::singleton(e) }
    }
    spec some {
        pragma opaque;
        aborts_if false;
        ensures result == spec_some(e);
    }
    spec fun spec_some<Element>(e: Element): Option<Element> {
        Option{ vec: vec(e) }
    }

    /// 如果 `t` 不包含值，則返回 true
    public fun is_none<Element>(t: &Option<Element>): bool {
        vector::is_empty(&t.vec)
    }
    spec is_none {
        pragma opaque;
        aborts_if false;
        ensures result == is_none(t);
    }

    /// 如果 `t` 持有一個值，則返回 true
    public fun is_some<Element>(t: &Option<Element>): bool {
        !vector::is_empty(&t.vec)
    }
    spec is_some {
        pragma opaque;
        aborts_if false;
        ensures result == is_some(t);
    }

    /// 如果 `t` 中的值等於 `e_ref`，則返回 true
    /// 如果 `t` 不包含值，則始終返回 `false`
    public fun contains<Element>(t: &Option<Element>, e_ref: &Element): bool {
        vector::contains(&t.vec, e_ref)
    }
    spec contains {
        pragma opaque;
        aborts_if false;
        ensures result == spec_contains(t, e_ref);
    }
    spec fun spec_contains<Element>(t: Option<Element>, e: Element): bool {
        is_some(t) && borrow(t) == e
    }

    /// 返回對 `t` 中值的不可變引用
    /// 如果 `t` 沒有值則中止
    public fun borrow<Element>(t: &Option<Element>): &Element {
        assert!(is_some(t), EOPTION_NOT_SET);
        vector::borrow(&t.vec, 0)
    }
    spec borrow {
        pragma opaque;
        include AbortsIfNone<Element>;
        ensures result == borrow(t);
    }

    /// 返回對 `t` 中的值的引用，如果它包含一個
    /// 如果 `t` 不包含值，則返回 `default_ref`
    public fun borrow_with_default<Element>(t: &Option<Element>, default_ref: &Element): &Element {
        let vec_ref = &t.vec;
        if (vector::is_empty(vec_ref)) default_ref
        else vector::borrow(vec_ref, 0)
    }
    spec borrow_with_default {
        pragma opaque;
        aborts_if false;
        ensures result == (if (is_some(t)) borrow(t) else default_ref);
    }

    /// 返回 `t` 中的值，如果它包含一個
    /// 如果 `t` 不包含值，則返回 `default`
    public fun get_with_default<Element: copy + drop>(
        t: &Option<Element>,
        default: Element,
    ): Element {
        let vec_ref = &t.vec;
        if (vector::is_empty(vec_ref)) default
        else *vector::borrow(vec_ref, 0)
    }
    spec get_with_default {
        pragma opaque;
        aborts_if false;
        ensures result == (if (is_some(t)) borrow(t) else default);
    }

    /// 通過添加 `e` 將 none 選項 `t` 轉換為 some 選項。
    /// 如果 `t` 已經持有一個值，則中止
    public fun fill<Element>(t: &mut Option<Element>, e: Element) {
        let vec_ref = &mut t.vec;
        if (vector::is_empty(vec_ref)) vector::push_back(vec_ref, e)
        else abort EOPTION_IS_SET
    }
    spec fill {
        pragma opaque;
        aborts_if is_some(t) with EOPTION_IS_SET;
        ensures is_some(t);
        ensures borrow(t) == e;
    }

    /// 通過刪除並返回存儲在 `t` 中的值，將 `some` 選項轉換為 `none`
    /// 如果 `t` 沒有值則中止
    public fun extract<Element>(t: &mut Option<Element>): Element {
        assert!(is_some(t), EOPTION_NOT_SET);
        vector::pop_back(&mut t.vec)
    }
    spec extract {
        pragma opaque;
        include AbortsIfNone<Element>;
        ensures result == borrow(old(t));
        ensures is_none(t);
    }

    /// 返回對 `t` 中值的可變引用
    /// 如果 `t` 沒有值則中止
    public fun borrow_mut<Element>(t: &mut Option<Element>): &mut Element {
        assert!(is_some(t), EOPTION_NOT_SET);
        vector::borrow_mut(&mut t.vec, 0)
    }
    spec borrow_mut {
        pragma opaque;
        include AbortsIfNone<Element>;
        ensures result == borrow(t);
    }

    /// 用 `e` 交換 `t` 中的舊值並返回舊值
    /// 如果 `t` 沒有值則中止
    public fun swap<Element>(t: &mut Option<Element>, e: Element): Element {
        assert!(is_some(t), EOPTION_NOT_SET);
        let vec_ref = &mut t.vec;
        let old_value = vector::pop_back(vec_ref);
        vector::push_back(vec_ref, e);
        old_value
    }
    spec swap {
        pragma opaque;
        include AbortsIfNone<Element>;
        ensures result == borrow(old(t));
        ensures is_some(t);
        ensures borrow(t) == e;
    }

    /// 將 `t` 中的舊值與 `e` 交換並返回舊值；
    /// 或者如果沒有舊值，則用 `e` 填充它。
    /// 與 swap() 不同，swap_or_fill() 允許 `t` 不保存值。
    public fun swap_or_fill<Element>(t: &mut Option<Element>, e: Element): Option<Element> {
        let vec_ref = &mut t.vec;
        let old_value = if (vector::is_empty(vec_ref)) none()
            else some(vector::pop_back(vec_ref));
        vector::push_back(vec_ref, e);
        old_value
    }
    spec swap_or_fill {
        pragma opaque;
        ensures result == old(t);
        ensures borrow(t) == e;
    }

    /// 銷毀 `t`。如果 `t` 持有一個值，則返回它。 否則返回 `default`
    public fun destroy_with_default<Element: drop>(t: Option<Element>, default: Element): Element {
        let Option { vec } = t;
        if (vector::is_empty(&mut vec)) default
        else vector::pop_back(&mut vec)
    }
    spec destroy_with_default {
        pragma opaque;
        aborts_if false;
        ensures result == (if (is_some(t)) borrow(t) else default);
    }

    /// 解壓 `t` 並返回其內容
    /// 如果 `t` 沒有值則中止
    public fun destroy_some<Element>(t: Option<Element>): Element {
        assert!(is_some(&t), EOPTION_NOT_SET);
        let Option { vec } = t;
        let elem = vector::pop_back(&mut vec);
        vector::destroy_empty(vec);
        elem
    }
    spec destroy_some {
        pragma opaque;
        include AbortsIfNone<Element>;
        ensures result == borrow(t);
    }

    /// 解壓`t`
    /// 如果 `t` 持有一個值，則中止
    public fun destroy_none<Element>(t: Option<Element>) {
        assert!(is_none(&t), EOPTION_IS_SET);
        let Option { vec } = t;
        vector::destroy_empty(vec)
    }
    spec destroy_none {
        pragma opaque;
        aborts_if is_some(t) with EOPTION_IS_SET;
    }

    /// 將 `t` 轉換為長度為 1 的向量，如果它是 `Some`，
    /// 否則為空向量
    public fun to_vec<Element>(t: Option<Element>): vector<Element> {
        let Option { vec } = t;
        vec
    }
    spec to_vec {
        pragma opaque;
        aborts_if false;
        ensures result == t.vec;
    }

    spec module {} // 將文檔上下文切換回模塊級別

    spec module {
        pragma aborts_if_is_strict;
    }

    /// # 輔助模式

    spec schema AbortsIfNone<Element> {
        t: Option<Element>;
        aborts_if is_none(t) with EOPTION_NOT_SET;
    }
}
