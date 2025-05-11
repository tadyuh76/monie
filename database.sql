erDiagram
    USER {
        varchar(50) user_id PK
        varchar(100) email UK
        varchar(50) display_name
        varchar(255) profile_image_url
        varchar(20) color_mode
        varchar(20) language
    }
    
    NOTIFICATION {
        varchar(50) notification_id PK
        varchar(50) user_id FK
        numeric(15,2) amount
        varchar(30) type
        varchar(100) title
        text message
        boolean is_read
        timestamp with time zone created_at
    }
    
    GROUP {
        varchar(50) group_id PK
        varchar(50) admin_id FK
        varchar(100) name
        text description
        timestamp with time zone created_at
    }
    
    GROUP_MEMBER {
        varchar(50) group_id FK
        varchar(50) user_id FK
        varchar(30) role
        timestamp with time zone joined_at
    }
    
    GROUP_TRANSACTION {
        uuid uuid PK
        varchar(50) group_id FK
        varchar(50) transaction_id FK
        varchar(30) status
    }
    
    BUDGET {
        varchar(50) budget_id PK
        varchar(50) user_id FK
        varchar(50) category_id FK
        numeric(15,2) amount
        date start_date
        date end_date
        boolean is_recurring
        boolean is_saving
        varchar(20) frequency
        varchar(20) color
    }
    
    RECURRING_TRANSACTION {
        varchar(50) recurring_id PK
        varchar(50) category_id FK
        varchar(50) account_id FK
        varchar(50) budget_id FK
        numeric(15,2) amount
        varchar(255) description
        varchar(20) frequency
        date start_date
        date end_date
        boolean is_active
        smallint day_of_month
        smallint day_of_week
    }
    
    ACCOUNT {
        varchar(50) account_id PK
        varchar(50) user_id FK
        varchar(100) name
        varchar(30) type
        numeric(15,2) balance
        varchar(3) currency
        varchar(20) color
    }
    
    TRANSACTION {
        varchar(50) transaction_id PK
        varchar(50) category_id FK
        varchar(50) account_id FK
        varchar(50) budget_id FK
        varchar(50) user_id FK
        numeric(15,2) amount
        timestamp with time zone date
        varchar(255) description
        boolean is_recurring
        varchar(255) receipt_url
        timestamp with time zone created_at
        timestamp with time zone updated_at
    }
    
    RECEIPT {
        varchar(50) receipt_id PK
        varchar(50) transaction_id FK
        varchar(255) image_url
        timestamp with time zone upload_date
        jsonb ocr_data
    }
    
    CATEGORY {
        varchar(50) category_id PK
        varchar(50) user_id FK
        varchar(100) name
        varchar(50) icon
        varchar(20) color
        boolean is_income
        boolean is_default
    }
    
    NOTIFICATION }o--|| USER : "receives"
    GROUP_MEMBER }o--|| USER : "joins"
    GROUP_MEMBER }o--|| GROUP : "includes"
    GROUP }o--|| USER : "manages"
    BUDGET }o--|| USER : "sets"
    RECURRING_TRANSACTION }o--|| USER : "schedules"
    ACCOUNT }o--|| USER : "contains"
    TRANSACTION }o--|| USER : "records"
    TRANSACTION }o--|| GROUP_TRANSACTION : "includes"
    RECEIPT }o--|| TRANSACTION : "attaches"
    RECURRING_TRANSACTION }o--|| ACCOUNT : "belongs_to"
    TRANSACTION }o--|| ACCOUNT : "belongs_to"
    BUDGET }o--|| CATEGORY : "limits"
    RECURRING_TRANSACTION }o--|| CATEGORY : "categorized_in"
    TRANSACTION }o--|| CATEGORY : "categorized_in"
