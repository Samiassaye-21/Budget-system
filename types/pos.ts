export type ShiftType = 'day' | 'night';
export type AppMode = 'gate' | 'cups' | 'pos' | 'kitchen' | 'admin' | 'manual-recon';
export type KitchenRoute = 'Day shift' | 'Night shift' | 'Bue delivery';

export type ProductCategory = 'Food' | 'Juice' | 'Beverage';

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: ProductCategory;
  tone: string;
  emoji: string;
  image?: string;
  isAvailable: boolean;
}

export interface OrderItem extends Product {
  quantity: number;
}

export type PaymentMethod = 'Cash' | 'Transfer' | 'Pay later' | 'Credit' | 'Delivery';

export interface Order {
  id: string;
  shiftId: string;
  cashierName: string;
  items: OrderItem[];
  subtotal: number;
  tax: number;
  total: number;
  paymentMethod: PaymentMethod;
  notes?: string;
  createdAt: string;
}

export interface ShiftExpense {
  id: string;
  shiftId: string;
  category: string;
  description: string;
  amount: number;
  loggedAt: string;
}

export interface CustomerDebt {
  id: string;
  customerName: string;
  note: string;
  cupCount: number;
  pricePerCup: number;
  amount: number; // cupCount * pricePerCup
  isRecovered: boolean;
  shiftIdCreated: string;
  shiftIdRecovered?: string;
  createdAt: string;
  recoveredAt?: string;
}

export interface ShiftSession {
  id: string;
  shiftType: ShiftType;
  cashierName: string;
  openingCups: number;
  status: 'active' | 'closed';
  startedAt: string;
  closedAt?: string;
}

export interface KitchenTicket {
  id: string;
  route: KitchenRoute;
  shiftId?: string;
  items: OrderItem[];
  totalQuantity: number;
  createdAt: string;
}

export interface FoodItemReconciliation {
  id: string;
  name: string;
  emoji?: string;
  kitchenCookedCount: number;
  waiterSoldCount: number;
  variance: number;
}

export interface TransferRecord {
  id: string;
  senderName: string;
  amount: number;
  note: string;
}

export interface FoodBoxEntry {
  name: string;
  emoji: string;
  opening: number;
  leftover: number;
  consumed: number; // auto: opening - leftover
  kitchenCooked: number; // from kitchen lookup (0 if not found)
}

export interface FoodSoldEntry {
  name: string;
  emoji: string;
  sold: number;
  kitchenCooked: number;
  variance: number; // auto: sold - kitchenCooked
}

export interface JuiceEntry {
  name: string;
  emoji: string;
  sold: number;
}

export interface ManualPendingPayment {
  id: string;
  customerName: string;
  amount: number;
  note: string;
}

export interface ManualRecoveredPayment {
  debtId: string;
  customerName: string;
  amount: number;
}

export interface ShiftReconciliation {
  id: string;
  shiftId: string;
  shiftType: ShiftType;
  cashierName: string;
  
  // Step 1: Sales breakdown
  grossRevenue: number;
  cashSales: number;
  transferSales: number;
  creditSales: number;
  deliverySales: number;
  tipSales: number;
  totalOrdersCount: number;

  // Step 2: Cup inventory count & Food cross-check
  openingCups: number;
  addedCups: number;
  leftoverCups: number;
  calculatedCupsSold: number;
  tabletCupsSold: number;
  cupsVariance: number;

  totalKitchenFoodCooked: number;
  totalWaiterFoodSold: number;
  foodVariance: number;
  foodItemsReconciliation: FoodItemReconciliation[];

  // Step 3: Expenses
  totalExpenses: number;
  expenses: ShiftExpense[];

  // Step 4: Recovered Debts in Cups
  totalRecoveredCups: number;
  totalRecoveredDebts: number;
  recoveredDebts: CustomerDebt[];

  // Step 5: Cash Handover
  netCashToOwner: number;
  shiftNotes: string;
  closedAt: string;

  // Extended manual entries fields (optional on auto, populated on manual)
  entryMode?: 'auto' | 'manual';
  shiftDate?: string;
  juiceBreakdown?: JuiceEntry[];
  foodBoxInventory?: FoodBoxEntry[];
  foodSoldBreakdown?: FoodSoldEntry[];
  kitchenDataFound?: boolean;
}

export interface ManualShiftReconciliation extends ShiftReconciliation {
  entryMode: 'manual';
  shiftDate: string; // ISO date string 'YYYY-MM-DD'
  juiceBreakdown: JuiceEntry[];
  foodBoxInventory: FoodBoxEntry[];
  foodSoldBreakdown: FoodSoldEntry[];
  transferRecords: TransferRecord[];
  pendingPayments: ManualPendingPayment[];
  recoveredPayments: ManualRecoveredPayment[];
  kitchenDataFound: boolean;
}

export interface DeliveryRecord {
  id: string;
  partnerName: string; // e.g. 'BeU Delivery', 'Direct Rider - Abebe'
  orderCount: number;
  amount: number;
  isSettled: boolean;
  shiftType: ShiftType;
  shiftId?: string;
  date: string;
  settledAt?: string;
  notes?: string;
}

export interface InventoryPurchase {
  id: string;
  itemName: string;
  category: string; // 'Fruits', 'Dairy', 'Packaging', 'Groceries', 'General'
  quantity: number;
  unit: string; // 'kg', 'crate', 'box', 'piece', 'liter'
  unitPrice: number;
  totalCost: number;
  date: string;
  purchasedBy?: string;
  notes?: string;
}

export interface GeneralExpense {
  id: string;
  category: string; // 'Rent', 'Utilities', 'Staff Wages', 'Repairs & Maintenance', 'Transport', 'Taxes & Licenses', 'Other'
  description: string;
  amount: number;
  date: string;
  receiptNumber?: string;
  paidFrom?: 'Cash' | 'Bank / Telebirr';
}

export interface SystemConfig {
  dayShiftWorkerName: string;
  nightShiftWorkerName: string;
  juiceUnitPrice: number;
  currency: string;
}


