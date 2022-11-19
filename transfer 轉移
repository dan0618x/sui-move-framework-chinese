// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::transfer {

    /// 共享之前創建的對象。共享對象必須在合約創造時已經被構建。
    const ESharedNonNewObject: u64 = 0;

    /// 將`obj`的所有權轉移給`接收者`。 `obj` 必須具有 `key` 屬性，這（反過來）確保 `obj` 具有全局唯一ID。
    public fun transfer<T: key>(obj: T, recipient: address) {
        // TODO: 發出事件
        transfer_internal(obj, recipient)
    }

    /// 凍結`obj`。 凍結後 `obj` 變得不可變，不能再轉移或變異。
    public native fun freeze_object<T: key>(obj: T);

    /// 將給定對像變成每個人都可以訪問和改變的可變共享對象。 這是不可逆的，即一旦一個對像被共享，它將永遠保持共享。
    /// Sui 中還沒有完全支持共享可變對象，它正在積極開發中，應該很快就會得到支持。
    /// https://github.com/MystenLabs/sui/issues/633
    /// https://github.com/MystenLabs/sui/issues/681
    /// 公開這個 API 是為了演示我們如何能夠使用它來編寫使用共享對象的 Move 合約。
    /// 在此事務中未創建共享對象的“ESharedNonNewObject”中止。 未來可能會放寬這一限制。
    public native fun share_object<T: key>(obj: T);

    native fun transfer_internal<T: key>(obj: T, recipient: address);

    // 費用校準功能
    #[test_only]
    public fun calibrate_freeze_object<T: key>(obj: T) {
        freeze_object(obj);
    }
    #[test_only]
    public fun calibrate_freeze_object_nop<T: key + drop>(obj: T) {
        let _ = obj;
    }

    #[test_only]
    public fun calibrate_share_object<T: key>(obj: T) {
        share_object(obj);
    }
    #[test_only]
    public fun calibrate_share_object_nop<T: key + drop>(obj: T) {
        let _ = obj;
    }

    #[test_only]
    public fun calibrate_transfer_internal<T: key>(obj: T, recipient: address) {
        transfer_internal(obj, recipient);
    }
    #[test_only]
    public fun calibrate_transfer_internal_nop<T: key + drop>(obj: T, recipient: address) {
        let _ = obj;
        let _ = recipient;
    }

}
