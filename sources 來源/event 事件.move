// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::event {

    /// 在此事務的事件日誌中添加 `t`。 TODO(https://github.com/MystenLabs/sui/issues/19)：一旦我們可以在能力系統中表達這一點，就限制為內部類型
    public native fun emit<T: copy + drop>(event: T);
}
