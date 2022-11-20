// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::tx_context {
    use std::signer;

    friend sui::object;

    #[test_only]
    use std::vector;

    /// tx 哈希值中的字節數（將是交易摘要）
    const TX_HASH_LENGTH: u64 = 32;

    /// 預期長度為 32 的 tx 哈希值，但發現長度不同
    const EBadTxHashLength: u64 = 0;

    #[test_only]
    /// 在沒有創建對象 ID 時嘗試獲取最近創建的對象 ID。
    const ENoIDsCreated: u64 = 1;

    /// 有關當前正在執行事務的信息。
    /// 這不能由事務構造——它是由 VM 創建的特權對象，並作為 `&mut TxContext` 傳遞到事務的入口點。
    struct TxContext has drop {
        /// 一個 `signer` 包裝了簽署當前交易的用戶地址
        signer: signer,
        /// 當前交易的哈希值
        tx_hash: vector<u8>,
        /// 當前epoch數
        epoch: u64,
        /// 計數器,記錄執行此事務時創建的新 id 的數量。 事務初始為 0
        ids_created: u64
    }

    /// 返回簽署當前交易的用戶地址
    public fun sender(self: &TxContext): address {
        signer::address_of(&self.signer)
    }

    /// 為簽署當前交易的用戶返回一個`signer`
    public fun signer_(self: &TxContext): &signer {
        &self.signer
    }

    public fun epoch(self: &TxContext): u64 {
        self.epoch
    }

    /// 使用版本 0 生成新的全局唯一對象 ID
    public(friend) fun new_object(ctx: &mut TxContext): address {
        let ids_created = ctx.ids_created;
        let id = derive_id(*&ctx.tx_hash, ids_created);
        ctx.ids_created = ids_created + 1;
        id
    }

    /// 返回當前事務創建的 id 數量。
    /// 暫時隱藏，以後可能會再顯現
    fun ids_created(self: &TxContext): u64 {
        self.ids_created
    }

    /// 通過 hash(tx_hash || ids_created) 獲取 ID 的本地函數
    native fun derive_id(tx_hash: vector<u8>, ids_created: u64): address;

    // ==== 測試用函數 ====

    #[test_only]
    /// 創建一個 `TxContext` 用於測試
    public fun new(addr: address, tx_hash: vector<u8>, epoch: u64, ids_created: u64): TxContext {
        assert!(vector::length(&tx_hash) == TX_HASH_LENGTH, EBadTxHashLength);
        TxContext { signer: new_signer_from_address(addr), tx_hash, epoch, ids_created }
    }

    #[test_only]
    /// 創建一個用於測試的 `TxContext`，其epoch數可能非零。
    public fun new_from_hint(addr: address, hint: u64, epoch: u64, ids_created: u64): TxContext {
        new(addr, dummy_tx_hash_with_hint(hint), epoch, ids_created)
    }

    #[test_only]
    /// 創建一個虛擬的 `TxContext` 用於測試
    public fun dummy(): TxContext {
        let tx_hash = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";
        new(@0x0, tx_hash, 0, 0)
    }

    #[test_only]
    /// 用於創建 256 個僅輸入哈希值的實用程序
    fun dummy_tx_hash_with_hint(hint: u64): vector<u8> {
        let tx_hash = vector[];
        let i = 1;
        let hash_length = (TX_HASH_LENGTH as u8);
        while (i <= hash_length) {
            let value = if (i <= 8) ((hint >> (64 - (8 * i))) as u8) else 0;
            vector::push_back(&mut tx_hash, value);
            i = i + 1;
        };
        tx_hash
    }

    #[test_only]
    public fun get_ids_created(self: &TxContext): u64 {
        ids_created(self)
    }

    #[test_only]
    /// 返回最近創建的對象 ID。
    public fun last_created_object_id(self: &TxContext): address {
        let ids_created = self.ids_created;
        assert!(ids_created > 0, ENoIDsCreated);
        derive_id(*&self.tx_hash, ids_created - 1)
    }

    #[test_only]
    public fun increment_epoch_number(self: &mut TxContext) {
        self.epoch = self.epoch + 1
    }

    #[test_only]
    /// 僅用於從“簽名者地址”創建新簽名者的測試函數。
    native fun new_signer_from_address(signer_address: address): signer;

    // 費用校準功能
    #[test_only]
    public fun calibrate_derive_id(tx_hash: vector<u8>, ids_created: u64) {
        derive_id(tx_hash, ids_created);
    }
    #[test_only]
    public fun calibrate_derive_id_nop(tx_hash: vector<u8>, ids_created: u64) {
        let _ = tx_hash;
        let _ = ids_created;
    }}
