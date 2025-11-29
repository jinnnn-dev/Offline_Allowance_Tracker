# Offline Allowance Tracker - Features Overview
## Developer Presentation to Client

---

## 🎯 Application Overview

The **Offline Allowance Tracker** is a Flutter-based mobile application designed to help users (primarily students) manage their daily or weekly allowance effectively. The app works **completely offline** using local device storage, ensuring privacy and accessibility without internet dependency.

---

## 📋 Core Features

### 1. **Allowance Setup & Configuration**
**What it does:**
- Initial setup screen where users configure their allowance amount and frequency
- Users can set either a **daily** or **weekly** allowance budget
- The app remembers the last reset date to properly calculate remaining budget

**How it works:**
- On first app launch, user is directed to setup screen
- User enters their allowance amount (e.g., "$20 per day")
- User selects frequency: Daily or Weekly
- Data is saved locally to device storage using SharedPreferences
- User can return to Settings screen anytime to modify these values
- The system automatically tracks when allowance was last reset

**Business Value:** Establishes baseline budget that drives all other calculations

---

### 2. **Dashboard (Main Home Screen)**
**What it does:**
- Central hub showing real-time financial overview
- Displays today's spending, remaining balance, and savings progress
- Provides smart prompts and personalized budgeting tips
- Shows recent expenses and key metrics at a glance

**How it works:**
- **Today's Spending Display:** Shows total amount spent today against daily allowance
- **Remaining Balance:** Calculates allowance minus expenses
- **Visual Progress Indicator:** Bar chart showing spending vs. remaining
- **Recent Expenses List:** Latest 5 transactions in reverse chronological order
- **Savings Tracking:** Shows total saved and monthly savings progress
- **Smart Savings Prompts:** 
  - If user has leftover money today and hasn't logged savings, displays prompt
  - If user had leftover yesterday and didn't save it, shows reminder
- **Under-Budget Streak:** Counts consecutive days/weeks user stayed within budget
- **Budgeting Tips:** AI-generated suggestions based on spending patterns

**Business Value:** Gives users instant financial awareness and encourages good habits

---

### 3. **Add/Edit Expenses**
**What it does:**
- Record new expenses or modify existing ones
- Categorize spending for better analysis
- Add optional notes for detailed transaction tracking
- Edit previously recorded expenses

**How it works:**
- User taps "Add Expense" button from any screen
- Form includes:
  - **Expense Name:** What was purchased (e.g., "Lunch", "Textbook")
  - **Amount:** Cost in currency
  - **Category:** Choose from 5 categories:
    - Food
    - School
    - Transportation
    - Entertainment
    - Other
  - **Date:** Automatically set to today, can be changed
  - **Note:** Optional additional details
- Each expense gets unique ID for tracking
- Changes are auto-saved to local storage
- User can edit expense by tapping on it from history/recent list

**Business Value:** Creates detailed transaction record for analysis and accountability

---

### 4. **Expense History**
**What it does:**
- View complete history of all expenses
- Filter, search, and organize expenses
- Multiple view modes for different analytical needs
- Edit or delete existing expenses

**How it works:**
- **List View:** Shows all expenses in chronological order (newest first)
- **Weekly View:** Groups expenses by week with weekly totals
- **Monthly View:** Groups expenses by month with monthly totals
- **Filtering:** 
  - Filter by category (Food, School, Transportation, etc.)
  - "All" category shows everything
- **Search:** Full-text search across expense names and notes
- **Actions:**
  - Tap expense to edit it
  - Swipe or tap delete button to remove
  - Confirmation dialog prevents accidental deletion
- **Date Navigation:** Can view expenses from any date in the past

**Business Value:** Complete audit trail of spending with flexible analysis options

---

### 5. **Category Breakdown Analysis**
**What it does:**
- Visualize spending distribution across categories
- Identify where money is being spent most
- Compare patterns across different time periods
- Spot overspending in specific categories

**How it works:**
- **Pie Chart Visualization:** Shows percentage breakdown of spending by category
- **Color Coding:** Each category has distinct color for easy identification
- **Time Period Selection:**
  - This Month: Current calendar month
  - This Week: Current week (Monday-Sunday)
  - All Time: Every transaction ever recorded
- **Category Cards Display:**
  - Category name and color indicator
  - Amount spent in that category
  - Percentage of total spending
- **Interactive Elements:**
  - Tap on pie chart slices to highlight category
  - Tap category cards to see detailed breakdown
  - Refresh data with pull-to-refresh gesture

**Business Value:** Reveals spending patterns and helps users make smarter category-based budget decisions

---

### 6. **Savings Tracker**
**What it does:**
- Record money saved from leftover allowance
- Track carry-over amounts for next period
- Set monthly savings goals and monitor progress
- Celebrate savings milestones

**How it works:**
- **Manual Savings Entry:**
  - After spending, user can log leftover amount as "saved"
  - Option to carry over to next period instead of losing it
  - Date-stamped for tracking when savings occurred
- **Two Actions:**
  - **Saved:** Money kept in separate savings account
  - **Carry-Over:** Unspent money rolls into next period's allowance
- **Monthly Savings Target:**
  - User can set custom monthly savings goal for each month
  - Progress bar shows % toward goal
  - Visual indication when target is met
- **Savings History:**
  - Complete list of all savings and carry-over entries
  - Sorted by date (newest first)
  - Shows action type and amount
- **Total Calculations:**
  - Cumulative total of all saved amounts
  - Monthly breakdown of savings
  - Monthly goal comparison

**Business Value:** Encourages healthy financial habits and makes saving visible and rewarding

---

### 7. **Settings**
**What it does:**
- Manage allowance configuration
- Adjust app preferences
- Access help and information
- Reset or update core settings

**How it works:**
- **Allowance Settings:**
  - View current allowance amount and frequency
  - Edit allowance without losing expense history
  - Change frequency between daily and weekly
  - Update amount for raises or adjustments
- **Information Display:**
  - Shows current configuration clearly
  - Display format: "₹/₿ [Amount] per [Frequency]"
- **Version Info:**
  - App version number displayed
  - Helpful for support and troubleshooting

**Business Value:** Flexibility to adapt to changing circumstances without data loss

---

### 8. **Splash Screen & App Navigation**
**What it does:**
- Professional app launch experience
- Smart routing based on setup status
- Smooth navigation between all features

**How it works:**
- **Launch Flow:**
  - Splash screen appears for 500ms with app branding
  - App checks if allowance is configured
  - If NOT configured → Routes to Setup Screen
  - If configured → Routes to Dashboard
- **Bottom Navigation (on Dashboard):**
  - Dashboard tab (home icon)
  - Add Expense tab (plus icon)
  - History tab (list icon)
  - Category Breakdown tab (pie chart icon)
  - Savings tab (piggy bank icon)
  - Settings tab (gear icon)

**Business Value:** Intuitive user experience with logical information hierarchy

---

## 💾 Data Persistence

**Technology:** SharedPreferences (local device storage)

**What data is stored:**
- Allowance configuration (amount, frequency, reset date)
- All expense records (name, amount, category, date, note)
- Savings entries (amount, date, action type)
- Monthly savings targets
- Savings reminders and tracking metadata

**Key Features:**
- ✅ Works completely offline
- ✅ No internet required
- ✅ Data stays on device (privacy-first)
- ✅ Automatic persistence (auto-save)
- ✅ Survives app closure and device restart

---

## 🧮 Smart Calculations

### Real-time Balance Calculation
```
Remaining Balance = Daily Allowance - Today's Spending
```

### Monthly Savings Progress
```
Monthly Saved = Sum of all saved entries in current month
```

### Category Breakdown
```
Category Percentage = (Category Total / Grand Total) × 100%
```

### Under-Budget Streak
```
Consecutive days/weeks where: Spending ≤ Allowance
```

---

## 🎨 Design Features

- **Material Design 3:** Modern, clean interface following latest design guidelines
- **Color Scheme:** Blue primary color with accessible contrast
- **Responsive Layout:** Works on phones of all sizes
- **Loading States:** Smooth loading indicators during data operations
- **Confirmation Dialogs:** Safety prompts before destructive actions
- **Snackbar Notifications:** User feedback for all major actions

---

## 📱 Supported Platforms

- iOS
- Android
- Web
- macOS
- Linux
- Windows

---

## 🔐 Security & Privacy

- **No Cloud Sync:** All data remains on user's device
- **No Tracking:** No analytics or user tracking
- **No Permissions:** Minimal required permissions
- **Local Encryption:** SharedPreferences handles secure local storage
- **No User Accounts:** Completely anonymous, no login required

---

## 🚀 Key Technical Advantages

1. **Offline-First:** No dependency on internet connectivity
2. **Fast Performance:** Instant data access from local storage
3. **Privacy-Focused:** User data never leaves the device
4. **Lightweight:** Minimal storage footprint
5. **Reliable:** No server downtime or sync issues
6. **Cross-Platform:** Single Flutter codebase supports all platforms

---

## 📊 Use Cases

### Student User
- Track daily allowance from parents
- Monitor spending across school/food/entertainment
- Save for a specific goal (new phone, laptop, etc.)
- Review spending patterns weekly

### Parent
- Give allowance to child with configurable amounts
- Monitor spending progress
- Encourage saving habits
- Help teach financial responsibility

### Budget-Conscious Individual
- Track personal small budget
- Identify spending patterns
- Challenge self to stay under budget
- Build savings gradually

---

## ✨ Unique Selling Points

1. **Zero Setup:** Works immediately with minimal configuration
2. **No Account Required:** Privacy without compromise
3. **Flexible Categories:** Covers most common spending types
4. **Smart Reminders:** Prompts to save leftover money
5. **Streak Motivation:** Gamifies staying within budget
6. **Offline Capability:** Works anywhere, anytime
7. **Simple Interface:** Teenagers can use it easily
8. **Complete History:** Never lose transaction records

---

## 🔄 Data Flow

```
App Launch
    ↓
Check Setup Status
    ├→ Not Setup: Go to Setup Screen
    └→ Setup Complete: Go to Dashboard
    
Dashboard (User Home)
    ├→ Add Expense → Store to History
    ├→ View History → Filter/Search
    ├→ View Categories → Analyze by Type
    ├→ Track Savings → Log Progress
    └→ Manage Settings → Update Config
```

---

## 📈 Version Information

- **Framework:** Flutter 3.10.0+
- **State Management:** StatefulWidget
- **Local Storage:** SharedPreferences 2.0.0+
- **Date Handling:** Intl Package
- **Charts:** FL Chart 0.66.0
- **UI Design:** Material Design 3

---

## Summary

The Offline Allowance Tracker is a **comprehensive yet simple** financial management tool designed specifically for budget-conscious users who want complete control and privacy over their spending data. It combines essential features (expense tracking, categorization, savings) with motivational elements (streaks, goals) to encourage good financial habits—all while working entirely offline.

