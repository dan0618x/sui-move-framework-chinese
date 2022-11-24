/// 具有基本屬性、庫存和相關邏輯的遊戲角色示例。
module games::hero {
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::math;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};

    /// 我們的英雄
    struct Hero has key, store {
        id: UID,
        /// 生命值，如果他們歸零，角色將無法使用
        hp: u64,
        /// 英雄的經驗，從0開始
        experience: u64,
        /// 英雄基本裝備
        sword: Option<Sword>,
        /// 遊戲玩家 ID
        game_id: ID,
    }

    /// 英雄的信仰之劍
    struct Sword has key, store {
        id: UID,
        /// 創建時設定的數值(常數),作為力量加成
        /// 具有高魔法值的劍更加稀有(因為他們成本更高）
        magic: u64,
        /// 當我們使用劍時，他會更加強大
        strength: u64,
        /// 遊戲ID
        game_id: ID,
    }

    /// 藥水，用於治療受傷英雄
    struct Potion has key, store {
        id: UID,
        /// 藥水功效
        potency: u64,
        /// 遊戲 ID
        game_id: ID,
    }

    /// 野豬，英雄練等用
    struct Boar has key {
        id: UID,
        /// 生命值
        hp: u64,
        /// 攻擊力
        strength: u64,
        /// 遊戲ID
        game_id: ID,
    }

    /// 包含遊戲管理員信息，初始設定後不可再變更
    struct GameInfo has key {
        id: UID,
        admin: address
    }

    /// 給予製造野豬及藥水的能力
    struct GameAdmin has key {
        id: UID,
        /// 管理員創造野豬的總數
        boars_created: u64,
        /// 管理員創造藥水總量
        potions_created: u64,
        /// 當前管理員 ID
        game_id: ID,
    }

    /// 每次英雄殺死野豬時發出的事件
    struct BoarSlainEvent has copy, drop {
        /// 殺死野豬的用戶的地址
        slayer_address: address,
        /// 殺死野豬的英雄的ID
        hero: ID,
        /// 已故野豬的ID
        boar: ID,
        /// 遊戲事件ID
        game_id: ID,
    }

    /// 玩家HP上限
    const MAX_HP: u64 = 1000;
    /// 劍的稀有度上限
    const MAX_MAGIC: u64 = 10;
    /// 劍的最低金額
    const MIN_SWORD_COST: u64 = 100;

    // TODO: 顯示的錯誤代碼
    /// 野豬贏得了戰鬥
    const EBOAR_WON: u64 = 0;
    /// 英雄過度疲勞
    const EHERO_TIRED: u64 = 1;
    /// 嘗試從非管理員帳戶初始化
    const ENOT_ADMIN: u64 = 2;
    /// 沒有足夠的錢購買給定的物品
    const EINSUFFICIENT_FUNDS: u64 = 3;
    /// 英雄沒有劍，無法移除劍
    const ENO_SWORD: u64 = 4;
    /// 測試錯誤的斷言
    const ASSERT_ERR: u64 = 5;

    // --- 初始化

    /// 在模塊發佈時，發送者創建一個新遊戲。
    /// 一旦發布，任何人都可以使用`new_game`函數創建一個新遊戲。
    fun init(ctx: &mut TxContext) {
        create(ctx);
    }

    /// 任何人都可以創建運行自己的遊戲，所有遊戲對像都將鏈接到這個遊戲。
    public entry fun new_game(ctx: &mut TxContext) {
        create(ctx);
    }

    /// 創建一個新遊戲。分流以繞過公開入口與初始化要求。
    fun create(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);

        transfer::freeze_object(GameInfo {
            id,
            admin: sender,
        });

        transfer::transfer(
            GameAdmin {
                game_id,
                id: object::new(ctx),
                boars_created: 0,
                potions_created: 0,
            },
            sender
        )
    }

    // --- 遊戲玩法 ---

    /// 用“英雄”的劍殺死“野豬”，獲得經驗。
    /// 如果英雄的 HP 為 0 或力量不足以殺死野豬，則中止
    public entry fun slay(
        game: &GameInfo, hero: &mut Hero, boar: Boar, ctx: &mut TxContext
    ) {
        check_id(game, hero.game_id);
        check_id(game, boar.game_id);
        let Boar { id: boar_id, strength: boar_strength, hp, game_id: _ } = boar;
        let hero_strength = hero_strength(hero);
        let boar_hp = hp;
        let hero_hp = hero.hp;
        // 用劍攻擊野豬，直到它的HP歸零
        while (boar_hp > hero_strength) {
            // 英雄先攻擊
            boar_hp = boar_hp - hero_strength;
            // 接著輪到野豬攻擊。 如果野豬會殺了英雄，我們就放棄吧，我們不能讓野豬贏
            assert!(hero_hp >= boar_strength , EBOAR_WON);
            hero_hp = hero_hp - boar_strength;

        };
        // 英雄舔了舔
        hero.hp = hero_hp;
        // 英雄獲得與野豬成正比的經驗，劍的力量增加一倍（如果英雄使用劍）
        hero.experience = hero.experience + hp;
        if (option::is_some(&hero.sword)) {
            level_up_sword(option::borrow_mut(&mut hero.sword), 1)
        };
        // 通過發出事件讓世界知道英雄的勝利！
        event::emit(BoarSlainEvent {
            slayer_address: tx_context::sender(ctx),
            hero: object::uid_to_inner(&hero.id),
            boar: object::uid_to_inner(&boar_id),
            game_id: id(game)
        });
        object::delete(boar_id);
    }

    /// 英雄攻擊時的力量
    public fun hero_strength(hero: &Hero): u64 {
        // 一個HP為零的英雄太累了無法戰鬥
        if (hero.hp == 0) {
            return 0
        };

        let sword_strength = if (option::is_some(&hero.sword)) {
            sword_strength(option::borrow(&hero.sword))
        } else {
            // 英雄無劍也能戰鬥，但不會很強
            0
        };
        // 英雄HP越低越弱
        (hero.experience * hero.hp) + sword_strength
    }

    fun level_up_sword(sword: &mut Sword, amount: u64) {
        sword.strength = sword.strength + amount
    }

    /// 攻擊時劍的力量
    public fun sword_strength(sword: &Sword): u64 {
        sword.magic + sword.strength
    }

    // --- 存貨 ---

    /// 用藥水治愈疲憊的英雄
    public fun heal(hero: &mut Hero, potion: Potion) {
        assert!(hero.game_id == potion.game_id, 403);
        let Potion { id, potency, game_id: _ } = potion;
        object::delete(id);
        let new_hp = hero.hp + potency;
        // 將英雄的 HP 上限設置為 MAX HP 以避免 int 溢出
        hero.hp = math::min(new_hp, MAX_HP)
    }

    /// 將`new_sword`添加到英雄的物品欄並歸還舊劍
    /// 如果有
    public fun equip_sword(hero: &mut Hero, new_sword: Sword): Option<Sword> {
        option::swap_or_fill(&mut hero.sword, new_sword)
    }

    /// 通過歸還他們的劍來解除英雄的武裝。
    /// 如果英雄沒有劍則中止.
    public fun remove_sword(hero: &mut Hero): Sword {
        assert!(option::is_some(&hero.sword), ENO_SWORD);
        option::extract(&mut hero.sword)
    }

    // --- 對象創建 ---

    /// 一切從劍開始。 任何人都可以買一把劍，收益給管理員。 劍中的魔法量取決於你為它付出的代價。
    public fun create_sword(
        game: &GameInfo,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ): Sword {
        let value = coin::value(&payment);
        // 確保用戶為劍支付足夠的費用
        assert!(value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS);
        // 為這把劍付錢給管理員
        transfer::transfer(payment, game.admin);

        // 劍的魔法與您支付的金額成正比，最高可達最大值。只能給一把劍灌輸限定魔力
        let magic = (value - MIN_SWORD_COST) / MIN_SWORD_COST;
        Sword {
            id: object::new(ctx),
            magic: math::min(magic, MAX_MAGIC),
            strength: 1,
            game_id: id(game)
        }
    }

    public entry fun acquire_hero(
        game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext
    ) {
        let sword = create_sword(game, payment, ctx);
        let hero = create_hero(game, sword, ctx);
        transfer::transfer(hero, tx_context::sender(ctx))
    }

    /// 只要有劍，任何人都可以創造英雄。 所有英雄都以相同的屬性開始。
    public fun create_hero(
        game: &GameInfo, sword: Sword, ctx: &mut TxContext
    ): Hero {
        check_id(game, sword.game_id);
        Hero {
            id: object::new(ctx),
            hp: 100,
            experience: 0,
            sword: option::some(sword),
            game_id: id(game)
        }
    }

    /// 管理員可以為“收件人”創建具有特定效力的藥水
    public entry fun send_potion(
        game: &GameInfo,
        potency: u64,
        player: address,
        admin: &mut GameAdmin,
        ctx: &mut TxContext
    ) {
        check_id(game, admin.game_id);
        admin.potions_created = admin.potions_created + 1;
        // 向指定玩家發送藥水
        transfer::transfer(
            Potion { id: object::new(ctx), potency, game_id: id(game) },
            player
        )
    }

    /// 管理員可以為“收件人”創建具有特定屬性的公豬
    public entry fun send_boar(
        game: &GameInfo,
        admin: &mut GameAdmin,
        hp: u64,
        strength: u64,
        player: address,
        ctx: &mut TxContext
    ) {
        check_id(game, admin.game_id);
        admin.boars_created = admin.boars_created + 1;
        // 向指定玩家發送野豬
        transfer::transfer(
            Boar { id: object::new(ctx), hp, strength, game_id: id(game) },
            player
        )
    }

    // --- 遊戲完整性/鏈接檢查 ---

    public fun check_id(game_info: &GameInfo, id: ID) {
        assert!(id(game_info) == id, 403); // TODO: error code
    }

    public fun id(game_info: &GameInfo): ID {
        object::id(game_info)
    }

    // --- 測試功能 ---
    public fun assert_hero_strength(hero: &Hero, strength: u64, _: &mut TxContext) {
        assert!(hero_strength(hero) == strength, ASSERT_ERR);
    }

    #[test_only]
    public fun delete_hero_for_testing(hero: Hero) {
        let Hero { id, hp: _, experience: _, sword, game_id: _ } = hero;
        object::delete(id);
        let sword = option::destroy_some(sword);
        let Sword { id, magic: _, strength: _, game_id: _ } = sword;
        object::delete(id)
    }

    #[test_only]
    public fun delete_game_admin_for_testing(admin: GameAdmin) {
        let GameAdmin { id, boars_created: _, potions_created: _, game_id: _ } = admin;
        object::delete(id);
    }

    #[test]
    fun slay_boar_test() {
        use sui::coin;
        use sui::test_scenario;

        let admin = @0xAD014;
        let player = @0x0;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        // 運行模塊初始化程序
        test_scenario::next_tx(scenario, admin);
        {
            init(test_scenario::ctx(scenario));
        };
        // 玩家用硬幣購買英雄
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // 管理員向玩家發送一頭野豬
        test_scenario::next_tx(scenario, admin);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let admin_cap = test_scenario::take_from_sender<GameAdmin>(scenario);
            send_boar(game_ref, &mut admin_cap, 10, 10, player, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };
        // 玩家殺死了野豬！
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let hero = test_scenario::take_from_sender<Hero>(scenario);
            let boar = test_scenario::take_from_sender<Boar>(scenario);
            slay(game_ref, &mut hero, boar, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, hero);
            test_scenario::return_immutable(game);
        };
        test_scenario::end(scenario_val);
    }
}
