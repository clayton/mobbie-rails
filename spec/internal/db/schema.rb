ActiveRecord::Schema[7.1].define do
  create_table "mobbie_users", force: :cascade do |t|
    t.string "device_id"
    t.string "email"
    t.string "username"
    t.boolean "is_anonymous", default: true
    t.string "oauth_provider"
    t.string "oauth_uid"
    t.string "name"
    t.integer "credit_balance", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_mobbie_users_on_device_id", unique: true
    t.index ["email"], name: "index_mobbie_users_on_email"
    t.index ["oauth_uid", "oauth_provider"], name: "index_mobbie_users_on_oauth"
  end

  create_table "mobbie_support_tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subject", null: false
    t.text "message", null: false
    t.string "category", default: "general"
    t.string "status", default: "open"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_mobbie_support_tickets_on_user_id"
    t.index ["status"], name: "index_mobbie_support_tickets_on_status"
  end

  create_table "mobbie_paywall_configs", force: :cascade do |t|
    t.string "title", null: false
    t.string "subtitle", null: false
    t.string "welcome_title", null: false
    t.string "welcome_subtitle", null: false
    t.boolean "show_skip_button", default: true
    t.string "skip_button_text", null: false, default: "Skip"
    t.boolean "active", default: false
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_mobbie_paywall_configs_on_active"
    t.index ["display_order"], name: "index_mobbie_paywall_configs_on_display_order"
  end

  create_table "mobbie_paywall_offerings", force: :cascade do |t|
    t.string "product_id", null: false
    t.string "display_name", null: false
    t.text "description"
    t.integer "cartoon_count"
    t.boolean "is_welcome_offer", default: false
    t.boolean "is_featured", default: false
    t.integer "display_order", default: 0
    t.string "badge_text"
    t.boolean "is_visible", default: true
    t.boolean "is_visible_for_onboarding", default: true
    t.bigint "paywall_config_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "paywall_config_id"], name: "index_mobbie_offerings_on_product_and_config", unique: true
    t.index ["display_order"], name: "index_mobbie_paywall_offerings_on_display_order"
  end

  create_table "mobbie_paywall_features", force: :cascade do |t|
    t.string "title", null: false
    t.string "icon", null: false
    t.text "description", null: false
    t.integer "display_order", default: 0
    t.boolean "is_visible", default: true
    t.bigint "paywall_config_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_mobbie_paywall_features_on_display_order"
  end

  create_table "mobbie_paywall_display_settings", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "welcome_title"
    t.string "welcome_subtitle"
    t.boolean "show_skip_button", default: true
    t.string "skip_button_text", default: "Skip"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mobbie_subscription_plans", force: :cascade do |t|
    t.string "product_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "tier", null: false
    t.string "billing_period", null: false
    t.integer "price_cents", default: 0
    t.string "currency", default: "USD"
    t.json "features", default: {}
    t.integer "display_order", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_mobbie_subscription_plans_on_product_id", unique: true
    t.index ["tier"], name: "index_mobbie_subscription_plans_on_tier"
    t.index ["billing_period"], name: "index_mobbie_subscription_plans_on_billing_period"
    t.index ["active"], name: "index_mobbie_subscription_plans_on_active"
  end

  create_table "mobbie_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subscription_plan_id"
    t.string "original_transaction_id", null: false
    t.string "transaction_id", null: false
    t.string "product_id", null: false
    t.datetime "purchase_date", null: false
    t.datetime "expires_at", null: false
    t.string "platform", null: false
    t.string "status", null: false
    t.string "tier", null: false
    t.string "webhook_notification_type"
    t.datetime "webhook_notification_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["original_transaction_id"], name: "index_mobbie_subscriptions_on_original_transaction_id", unique: true
    t.index ["product_id"], name: "index_mobbie_subscriptions_on_product_id"
    t.index ["expires_at"], name: "index_mobbie_subscriptions_on_expires_at"
    t.index ["status"], name: "index_mobbie_subscriptions_on_status"
    t.index ["tier"], name: "index_mobbie_subscriptions_on_tier"
    t.index ["user_id", "status"], name: "index_mobbie_subscriptions_on_user_id_and_status"
  end

  create_table "mobbie_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "original_transaction_id", null: false
    t.string "transaction_id", null: false
    t.string "product_id", null: false
    t.integer "credits_granted", null: false
    t.datetime "purchase_date", null: false
    t.string "platform", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["original_transaction_id"], name: "index_mobbie_purchases_on_original_transaction_id", unique: true
    t.index ["product_id"], name: "index_mobbie_purchases_on_product_id"
    t.index ["platform"], name: "index_mobbie_purchases_on_platform"
    t.index ["purchase_date"], name: "index_mobbie_purchases_on_purchase_date"
  end

  add_foreign_key "mobbie_support_tickets", "mobbie_users", column: "user_id"
  add_foreign_key "mobbie_paywall_offerings", "mobbie_paywall_configs", column: "paywall_config_id"
  add_foreign_key "mobbie_paywall_features", "mobbie_paywall_configs", column: "paywall_config_id"
  add_foreign_key "mobbie_subscriptions", "mobbie_users", column: "user_id"
  add_foreign_key "mobbie_subscriptions", "mobbie_subscription_plans", column: "subscription_plan_id"
  add_foreign_key "mobbie_purchases", "mobbie_users", column: "user_id"
end